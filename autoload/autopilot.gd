extends Node
## Scripted player for the gate's runs and for progress recordings. Does nothing unless the game is
## launched with `-- --autopilot`. Options (after `--`):
##   --autopilot-seconds=N      stop after N seconds (default 30); a scenario that reaches its end sooner
##                              (the campaign) stops there
##   --autopilot-scenario=NAME  what to do (see make_scenario): "slice" (default: New Game, Kestrel
##                              Heights, the Ark, the Loop map), "campaign" (New Game through Kestrel
##                              Heights, the Loop, a save and Continue, the Tideworks, Mercy General
##                              and the Vellum to the Archive, one run throughout), "loop",
##                              "tideworks", "mercy", "greywater", "vellum" (a prepared run to that
##                              district and the Ark after it),
##                              "ring_gallery", "options" (the options screen from the title) or "tour"
##                              (straight into --autopilot-level=ID: photographs its start, checkpoints,
##                              finds and Reliquary, voice on and muted; for looking at a district)
##   --autopilot-shots=DIR      save screenshots at named moments into DIR
##   --autopilot-mortal         the Operator can go down. By default it can't (DECISIONS 178): damage
##                              lands, but at 1 Integrity it stays up, and the run notes where it would
##                              have gone down (by district and boss) and totals it at the end. The runs
##                              prove the game works start to end; how hard a fight is, mortal runs and
##                              playtesting say.
## This node is the pilot's hands and its checklist: arguments, save isolation, checks, timing, input,
## walking and fighting. What happens in each scene is the scenario's (autoload/autopilot/scenarios/);
## how each district is played is its route's (autoload/autopilot/routes/). Every check a scenario
## needs is registered up front; at the end the autopilot prints "AUTOPILOT PASS" and exits 0 only if
## every one passed.

const LONG_RUN_SECONDS := 55.0
## Whether the Operator can go down (--autopilot-mortal); where it would have, by district.
var mortal: bool = false
var near_misses: Dictionary[String, int] = {}
const AUTOPILOT_SAVES := "user://autopilot"
const SCENARIOS: Array[String] = ["slice", "campaign", "loop", "tideworks", "mercy", "greywater", "vellum", "harbor", "spire", "ending_reboot", "ending_unplug", "ending_rewrite", "revisit", "tool_door", "ring_gallery", "options", "tour"]

const DistrictRun := preload("res://autoload/autopilot/scenarios/district_run.gd")
const Campaign := preload("res://autoload/autopilot/scenarios/campaign.gd")
const RingGallery := preload("res://autoload/autopilot/scenarios/ring_gallery.gd")
const OptionsTour := preload("res://autoload/autopilot/scenarios/options_tour.gd")
const Tour := preload("res://autoload/autopilot/scenarios/tour.gd")
const EndingRun := preload("res://autoload/autopilot/scenarios/ending_run.gd")
const RevisitRun := preload("res://autoload/autopilot/scenarios/revisit_run.gd")
const ToolDoorRun := preload("res://autoload/autopilot/scenarios/tool_door_run.gd")

var active: bool = false
var seconds: float = 30.0
var scenario: String = "slice"
var shots_dir: String = ""
## The district a "tour" visits.
var tour_level: String = ""
## What this run does (null until the run starts).
var plan: AutopilotScenario
## Turn away from a Clerk about to flash the Feed, the way a player who knows would (on by default; a
## route turns it off to be caught once). Back on with every new scene.
var turn_from_feed: bool = true

var _elapsed: float = 0.0
## Real frame times (ms) while a district is on screen, for the performance report.
var _frame_ms: PackedFloat32Array = []
## Where those frames went (ms): the game's own main-thread work (physics, scripts, _draw callbacks),
## submitting the frame to the renderer, and the GPU.
var _logic_ms: PackedFloat32Array = []
var _submit_ms: PackedFloat32Array = []
var _gpu_ms: PackedFloat32Array = []
var _tick_start_us: int = 0
var _pre_draw_us: int = 0
var _last_frame_us: int = 0
var _checks: Dictionary[String, bool] = {}
var _generation: int = 0
var _finished: bool = false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	# For the gate's district tours: every playable district, one per line, then quit.
	if args.has("--list-districts"):
		for id: String in LevelCatalog.LEVELS:
			print("DISTRICT ", id)
		# The count last: tools/check.sh fails a listing cut short.
		print("DISTRICTS ", LevelCatalog.LEVELS.size())
		set_process(false)
		Sound.quit.call_deferred(0)
		return
	active = args.has("--autopilot")
	if not active:
		set_process(false)
		return
	for arg: String in args:
		if arg.begins_with("--autopilot-seconds="):
			seconds = maxf(1.0, arg.get_slice("=", 1).to_float())
		elif arg.begins_with("--autopilot-scenario="):
			scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--autopilot-level="):
			tour_level = arg.get_slice("=", 1)
		elif arg.begins_with("--autopilot-shots="):
			shots_dir = arg.get_slice("=", 1)
		elif arg == "--autopilot-mortal":
			mortal = true
	# The scenario names a save folder, so it is checked before anything touches the disk.
	var save_dir := save_dir_for(scenario)
	plan = make_scenario(scenario, tour_level)
	if save_dir == "" or plan == null:
		push_error("Autopilot: unknown scenario '%s' (known: %s)" % [scenario, ", ".join(SCENARIOS)])
		print("AUTOPILOT FAIL: known_scenario")
		set_process(false)
		Sound.quit.call_deferred(1)
		return
	if plan.problem() != "":
		push_error("Autopilot: scenario '%s' can't run: %s" % [scenario, plan.problem()])
		print("AUTOPILOT FAIL: scenario_ready")
		set_process(false)
		Sound.quit.call_deferred(1)
		return
	plan.long_run = seconds >= LONG_RUN_SECONDS
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[autopilot] scenario=%s seconds=%.0f" % [scenario, seconds])
	# Never touch the player's save: every automated run gets its own, emptied before it starts.
	SaveService.use_directory(save_dir)
	SaveService.delete_save()
	SaveService.forget_legacy()
	# Default settings (bindings, volumes) whatever the player chose: runs must be repeatable.
	Options.use_path(save_dir.path_join("settings.cfg"))
	for c: String in plan.expected():
		expect(c)
	check(is_isolated(SaveService.store.dir_path) and not SaveService.has_save(), "save_isolated")
	SceneRouter.scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred(SceneRouter.current_key)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	get_tree().physics_frame.connect(_on_tick_start)
	get_tree().process_frame.connect(_on_tick_start)
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)


## The scenario a name stands for, or null if there's no such scenario (the run is refused).
func make_scenario(scenario_name: String, level_id: String = "") -> AutopilotScenario:
	match scenario_name:
		"slice":
			return DistrictRun.new("kestrel", true)
		"loop", "tideworks", "mercy", "greywater", "vellum", "harbor", "spire":
			return DistrictRun.new(scenario_name, false)
		"campaign":
			return Campaign.new()
		"ending_reboot", "ending_unplug", "ending_rewrite":
			return EndingRun.new(scenario_name.trim_prefix("ending_"))
		"revisit":
			return RevisitRun.new()
		"tool_door":
			return ToolDoorRun.new()
		"ring_gallery":
			return RingGallery.new()
		"options":
			return OptionsTour.new()
		"tour":
			return Tour.new(level_id)
	return null


func _process(delta: float) -> void:
	# Process delta is scaled by time_scale; undo that so slow-motion doesn't stretch the run.
	_elapsed += delta / maxf(Engine.time_scale, 0.01)
	var now := Time.get_ticks_usec()
	if SceneRouter.current_key == SceneRouter.LEVEL_KEY and _last_frame_us > 0 and not SceneRouter.is_busy():
		_frame_ms.append((now - _last_frame_us) / 1000.0)
	_last_frame_us = now
	if _elapsed >= seconds and not _finished:
		_finish()


func _measuring() -> bool:
	return SceneRouter.current_key == SceneRouter.LEVEL_KEY and not SceneRouter.is_busy() and not _finished


## The first physics or process tick after a frame was drawn starts the next frame's game work.
func _on_tick_start() -> void:
	if _tick_start_us == 0:
		_tick_start_us = Time.get_ticks_usec()


func _on_pre_draw() -> void:
	_pre_draw_us = Time.get_ticks_usec()
	if _tick_start_us > 0 and _measuring():
		_logic_ms.append((_pre_draw_us - _tick_start_us) / 1000.0)


func _on_post_draw() -> void:
	if _pre_draw_us > 0 and _measuring():
		_submit_ms.append((Time.get_ticks_usec() - _pre_draw_us) / 1000.0)
		_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	_tick_start_us = 0


## The autopilot's own save folder for a known scenario, or "" for anything else (a name like "../saves"
## must never become a path).
func save_dir_for(scenario_name: String) -> String:
	return AUTOPILOT_SAVES.path_join(scenario_name) if SCENARIOS.has(scenario_name) else ""


## True if `dir` really is inside the autopilot's folder (compared as resolved paths, not strings).
func is_isolated(dir: String) -> bool:
	var root := ProjectSettings.globalize_path(AUTOPILOT_SAVES).simplify_path()
	var resolved := ProjectSettings.globalize_path(dir).simplify_path()
	return resolved.begins_with(root + "/")


# --- Checks -------------------------------------------------------------------------------------
func expect(check_id: String) -> void:
	if not _checks.has(check_id):
		_checks[check_id] = false


## Marks a check passed (said once in the log, however often a route passes it).
func pass_check(check_id: String) -> void:
	if not _checks.get(check_id, false):
		print("[autopilot] ok: ", check_id)
	_checks[check_id] = true


func check(condition: bool, check_id: String) -> void:
	expect(check_id)
	if condition:
		pass_check(check_id)


func _finish() -> void:
	_finished = true
	_report_performance()
	if not mortal:
		var total := 0
		var parts: PackedStringArray = []
		for id: String in near_misses:
			total += near_misses[id]
			parts.append("%s %d" % [id, near_misses[id]])
		print("[autopilot] would have gone down %d times%s" % [total, (": " + ", ".join(parts)) if total > 0 else ""])
	var failed: PackedStringArray = []
	for c: String in _checks:
		if not _checks[c]:
			failed.append(c)
	if failed.is_empty():
		print("AUTOPILOT PASS (%d checks, %.1fs)" % [_checks.size(), _elapsed])
		Sound.quit(0)
	else:
		print("AUTOPILOT FAIL: ", ", ".join(failed))
		Sound.quit(1)


## Frame times in the district: average and the slowest 1%, at whatever resolution and frame cap the
## run used. Evidence only; the target (60 fps at 1080p on Steam Deck) needs the Deck itself.
func _report_performance() -> void:
	if _frame_ms.size() < 30:
		return
	var sorted := _frame_ms.duplicate()
	sorted.sort()
	var total := 0.0
	for ms: float in sorted:
		total += ms
	var avg := total / sorted.size()
	var worst := sorted[int(sorted.size() * 0.99)]
	print("[perf] %d frames in the district at %s: avg %.2f ms (%.0f fps), 1%% low %.2f ms (%.0f fps)" % [
		sorted.size(), get_viewport().get_visible_rect().size, avg, 1000.0 / avg, worst, 1000.0 / worst])
	print("[perf] median / 1%% worst: game logic %.2f / %.2f ms, frame submit %.2f / %.2f ms, GPU %.2f / %.2f ms" % [
		_pct(_logic_ms, 0.5), _pct(_logic_ms, 0.99), _pct(_submit_ms, 0.5), _pct(_submit_ms, 0.99),
		_pct(_gpu_ms, 0.5), _pct(_gpu_ms, 0.99)])


static func _pct(values: PackedFloat32Array, at: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[mini(int(sorted.size() * at), sorted.size() - 1)]

## Ends the run now (a scenario that has reached its end): passes only if every check has.
func finish_now() -> void:
	if not _finished:
		_finish()


# --- Helpers for scenarios and routes --------------------------------------------------------------
## Seconds since the run started, unscaled: real time in a live run, the movie's own time when recording
## (Movie Maker renders slower than real time, and the sound is mixed to its frames).
func run_seconds() -> float:
	return _elapsed


## True once the scene this coroutine started in has gone (or the run ended): it should stop.
func stale(gen: int) -> bool:
	return gen != _generation or _finished


## Waits `duration` seconds (unscaled). Returns false if the scene changed meanwhile, so callers can
## stop: `if not await Autopilot.wait(1.0, gen): return`.
func wait(duration: float, gen: int) -> bool:
	await get_tree().create_timer(duration, true, false, true).timeout
	return not stale(gen)


## Waits until `condition` holds (true) or `timeout` real seconds pass (false).
func until(condition: Callable, timeout: float, gen: int) -> bool:
	var spent := 0.0
	while spent < timeout:
		if stale(gen):
			return false
		if condition.call():
			return true
		await get_tree().process_frame
		spent += get_process_delta_time() / maxf(Engine.time_scale, 0.01)
	return bool(condition.call())


## One physics frame; returns its (game-time) length.
func physics_step() -> float:
	await get_tree().physics_frame
	return get_physics_process_delta_time()


## Presses and releases an action through the input pipeline, so UI focus navigation sees it too.
func tap(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)


func snap(shot_name: String) -> void:
	if shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	if get_viewport().use_hdr_2d:
		img = Screenshot.linear_to_srgb(img, 1600)
	img.save_png(shots_dir.path_join(shot_name + ".png"))
	# Converting and saving takes far longer than a frame; keep that out of the performance report.
	_last_frame_us = 0
	# And out of the route's clock: the next frame's delta is the save. A wait started on that frame
	# would count it as time gone by (a 0.6 s wait right after a shot could end a frame later, before
	# an action tapped just before it is even released). Let it go by first.
	await get_tree().process_frame
	await get_tree().process_frame


## Every boss barrier in the scene is open.
func barriers_open() -> bool:
	return get_tree().get_nodes_in_group(&"boss_barriers").all(func(n: Node) -> bool: return (n as BossBarrier).open)


# --- Movement helpers -------------------------------------------------------------------------------
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]


## Holds the move actions like an analog stick pointing at screen-space `input` (0 releases).
func press_move(input: Vector2) -> void:
	var strengths := {
		&"move_right": maxf(input.x, 0.0), &"move_left": maxf(-input.x, 0.0),
		&"move_down": maxf(input.y, 0.0), &"move_up": maxf(-input.y, 0.0),
	}
	for action: StringName in MOVE_ACTIONS:
		var v: float = strengths[action]
		if v > 0.01:
			Input.action_press(action, v)
		else:
			Input.action_release(action)


## Stick input that walks along grid direction `ground` (inverse of Iso.input_to_ground).
func input_for_ground(ground: Vector2) -> Vector2:
	return Vector2(ground.x - ground.y, ground.x + ground.y).normalized()


## Walks the player to the centre of `cell`. Returns false on timeout or if the scene changed.
func walk_to(player: Node2D, cell: Vector2i, timeout: float, gen: int) -> bool:
	var target := Iso.cell_center(cell)
	var spent := 0.0
	while true:
		if stale(gen) or not is_instance_valid(player):
			press_move(Vector2.ZERO)
			return false
		if Iso.ground_distance(player.global_position, target) < 0.3:
			press_move(Vector2.ZERO)
			return true
		press_move(input_for_ground(Iso.ground_dir_between(player.global_position, target)))
		await get_tree().physics_frame
		spent += get_physics_process_delta_time()
		if spent > timeout:
			press_move(Vector2.ZERO)
			print("[autopilot] walk_to %s timed out at %s" % [cell, Iso.world_to_cell(player.global_position)])
			return false
	return false


## Holds a ground direction for `duration` seconds.
func hold_ground(ground: Vector2, duration: float, gen: int) -> bool:
	press_move(input_for_ground(ground))
	var ok := await wait(duration, gen)
	press_move(Vector2.ZERO)
	return ok


# --- Scenes -----------------------------------------------------------------------------------------
## Each scene hands over to the scenario. Coroutines from the scene before see stale() and stop.
func _on_scene_changed(key: StringName) -> void:
	_generation += 1
	var gen := _generation
	turn_from_feed = true
	press_move(Vector2.ZERO)
	var scene := get_tree().current_scene
	match key:
		&"title":
			_at_title(scene, gen)
		&"ring_gallery":
			plan.on_ring_gallery(gen)
		&"loadout":
			plan.on_loadout(scene, gen)
		SceneRouter.LEVEL_KEY:
			var level := scene as Level
			if level != null and level.player != null:
				# Going down (or, unkillable, where it would have) is worth knowing in a run's log. Once per level.
				if not level.has_meta(&"autopilot_watching"):
					level.set_meta(&"autopilot_watching", true)
					level.player.cannot_go_down = not mortal
					var note := func(what: String) -> void:
						var b := level.boss
						print("[autopilot] %s in %s at %s%s" % [what, level.level_id, level.player.cell(),
							" (boss %s at %d%%)" % [b.boss_name, roundi(b.integrity.ratio() * 100.0)] if is_instance_valid(b) and b.is_engaged and b.is_alive() else ""])
					level.player.downed.connect(func() -> void: note.call("downed"))
					level.player.would_have_gone_down.connect(func() -> void:
						near_misses[level.level_id] = int(near_misses.get(level.level_id, 0)) + 1
						note.call("would have gone down"))
				plan.on_level(level, gen)
		&"core_choice":
			plan.on_core_choice(scene, gen)
		&"ark":
			var ark := scene as ArkLevel
			if ark != null:
				plan.on_ark(ark, gen)
		&"epilogue":
			var epilogue := scene as Epilogue
			if epilogue != null:
				plan.on_epilogue(epilogue, gen)


## Every scenario starts here: the title and its ring, photographed, then the scenario's choice.
func _at_title(title: Node, gen: int) -> void:
	check(true, "title_shown")
	if not await wait(0.5, gen):
		return
	if get_tree().get_nodes_in_group(&"steward_ring").size() > 0:
		pass_check("title_ring_present")
	if not await wait(3.0, gen):
		return
	await snap("title")
	plan.on_title(title, gen)


## Walks to the dock and opens the map of the city. Returns false if that didn't happen.
func open_city_map(ark: ArkLevel, gen: int) -> bool:
	for cell: Vector2i in [Vector2i(17, 17), Vector2i(19, 19), Vector2i(20, 20)]:
		if not await advance_to(ark, ark.player, cell, 20.0, gen):
			return false
	tap(&"interact")
	return await wait(1.0, gen) and ark.city_map != null


## Walks to `cell` and presses Interact.
func use_at(level: Level, player: Operator, cell: Vector2i, gen: int) -> bool:
	if not await advance_to(level, player, cell, 20.0, gen):
		return false
	tap(&"interact")
	return await wait(0.8, gen)


## Walks toward `cell`, stopping to fight anything that comes within reach. Returns false on timeout
## or scene change.
func advance_to(level: Level, player: Operator, cell: Vector2i, timeout: float, gen: int) -> bool:
	var target := Iso.cell_center(cell)
	var spent := 0.0
	var frame := 0
	var route: Array[Vector2i] = []
	var repath := 0.0
	while true:
		if stale(gen) or not is_instance_valid(player):
			release_all()
			return false
		frame += 1
		# Carrying someone you can't fight: roll out of a windup's reach instead, and keep walking.
		var threat := nearest_threat(level, player, 3.4) if player.can_act() or player.dodge.is_rolling() else null
		var feed := feed_coming(level, player) if turn_from_feed else null
		var swing := nearest_threat(level, player, 1.8) if player.carrying else null
		if swing != null and swing.state == Enemy.State.WINDUP and player.dodge.can_start():
			var away := Iso.ground_dir_between(swing.global_position, player.global_position)
			press_move(input_for_ground(Vector2(-away.y, away.x) + away))
			tap(&"dodge")
		elif feed != null and player.is_alive():
			# Turn your back on the screen until it's flashed.
			release_attacks()
			press_move(input_for_ground(Iso.ground_dir_between(feed.global_position, player.global_position)))
			repath = 0.0
		elif threat != null and player.is_alive():
			fight(player, threat, frame)
			repath = 0.0
		else:
			release_attacks()
			if Iso.ground_distance(player.global_position, target) < 0.15:
				press_move(Vector2.ZERO)
				return true
			repath -= get_physics_process_delta_time()
			if repath <= 0.0:
				repath = 0.5
				route = level.enemy_nav.path(player.cell(), cell)
			while route.size() > 1 and route[0] == player.cell():
				route.remove_at(0)
			var next := target
			if route.size() > 1 and Iso.ground_distance(player.global_position, target) > 1.2:
				next = Iso.cell_center(route[0])
			press_move(input_for_ground(Iso.ground_dir_between(player.global_position, next)))
		await get_tree().physics_frame
		spent += get_physics_process_delta_time()
		if spent > timeout:
			release_all()
			var near := nearest_threat(level, player, 3.4)
			print("[autopilot] advance_to %s timed out at %s%s" % [cell, player.cell(), " (fighting %s at %s)" % [near.get_class(), near.grid_cell()] if near != null else ""])
			return false
	return false


## A Clerk in sight, past halfway through winding up the Feed at the Operator (null if none).
func feed_coming(level: Level, player: Operator) -> Clerk:
	for e: Enemy in level.living_enemies():
		var clerk := e as Clerk
		if clerk == null or clerk.state != Enemy.State.WINDUP or not clerk.flash_next or clerk.windup_progress() < 0.5:
			continue
		if Iso.ground_distance(player.global_position, clerk.global_position) <= Clerk.FLASH_REACH + 0.5 \
				and level.grid.line_clear(player.global_position, clerk.global_position):
			return clerk
	return null


func nearest_threat(level: Level, player: Operator, reach: float) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	for e: Enemy in level.living_enemies():
		# Weak points aren't threats; bosses have their own fight (their district's route).
		if not e.is_threat or not e.is_hittable() or e is Boss:
			continue
		var d := Iso.ground_distance(player.global_position, e.global_position)
		if d <= best_d:
			best = e
			best_d = d
	return best


## One frame of fighting: aim at the threat with the right stick, close in for the baton (pressed on
## the beat, every ~0.3 s), keep the drone firing, and roll away from a red-orange windup.
func fight(player: Operator, threat: Enemy, frame: int) -> void:
	var to := Iso.ground_dir_between(player.global_position, threat.global_position)
	var dist := Iso.ground_distance(player.global_position, threat.global_position)
	press_aim(input_for_ground(to))
	if threat.state == Enemy.State.WINDUP and dist < 1.6 and player.dodge.can_start():
		press_move(input_for_ground(Vector2(-to.y, to.x)))
		tap(&"dodge")
		return
	var step := input_for_ground(to)
	# Something solid between you (a crank, an ambulance, a desk): go round it, not into it.
	var level := player.level
	if dist > 1.2 and level != null and not _walkable_line(level, player.global_position, threat.global_position):
		for c: Vector2i in level.enemy_nav.path(player.cell(), threat.grid_cell()):
			if c != player.cell():
				step = input_for_ground(Iso.ground_dir_between(player.global_position, Iso.cell_center(c)))
				break
	press_move(step if dist > 1.2 else Vector2.ZERO)
	if dist <= 1.7 and frame % 18 < 2:
		Input.action_press(&"attack_primary")
	else:
		Input.action_release(&"attack_primary")
	if dist > 1.4:
		Input.action_press(&"attack_secondary")
	else:
		Input.action_release(&"attack_secondary")


## Whether you could walk straight from `a` to `b` (world): every cell on the way is walkable.
func _walkable_line(level: Level, a: Vector2, b: Vector2) -> bool:
	var steps := maxi(1, ceili(Iso.ground_distance(a, b) / 0.3))
	for i: int in range(1, steps):
		if not level.grid.is_walkable(Iso.world_to_cell(a.lerp(b, float(i) / steps))):
			return false
	return true


func press_aim(input: Vector2) -> void:
	var strengths := {
		&"aim_right": maxf(input.x, 0.0), &"aim_left": maxf(-input.x, 0.0),
		&"aim_down": maxf(input.y, 0.0), &"aim_up": maxf(-input.y, 0.0),
	}
	for action: StringName in strengths:
		var v: float = strengths[action]
		if v > 0.01:
			Input.action_press(action, v)
		else:
			Input.action_release(action)


func release_attacks() -> void:
	Input.action_release(&"attack_primary")
	Input.action_release(&"attack_secondary")
	press_aim(Vector2.ZERO)


func release_all() -> void:
	press_move(Vector2.ZERO)
	release_attacks()
