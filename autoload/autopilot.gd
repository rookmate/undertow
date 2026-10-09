extends Node
## Scripted player for the gate's 30-second run and for progress recordings. Does nothing unless the
## game is launched with `-- --autopilot`. Options (after `--`):
##   --autopilot-seconds=N      stop after N seconds (default 30)
##   --autopilot-scenario=NAME  what to do: "slice" (default) or "ring_gallery"
##   --autopilot-shots=DIR      save screenshots at named moments into DIR
## Each scene script registers the checks it expects; at the end the autopilot prints
## "AUTOPILOT PASS" and exits 0 only if every expected check passed.

## Everything a scenario must achieve, registered up front so a run that stops early can't pass.
const SLICE_SHORT: Array[String] = [
	"save_isolated", "title_shown", "title_ring_present", "loadout_shown", "loadout_applied",
	"level_reached", "player_spawned", "walls_block", "path_three_tiles_ahead", "voice_muted_by_key",
	"muted_lamps_dark", "muted_hand_lamp_on", "muted_cold_grade", "muted_path_and_map",
	"muted_assists_off", "voice_restored_lamps", "voice_restored", "narration_heard",
	"dodge_performed", "enemy_killed",
]
## Runs of LONG_RUN_SECONDS or more play the whole slice to the dock.
const SLICE_LONG: Array[String] = [
	"threat_warning_shown", "slowmo_on_dodge", "stacks_reached", "stacks_hidden_while_listening",
	"steward_blind_in_stacks", "found_unindexed_log", "found_truth_core", "woke_survivor_in_stacks",
	"woke_survivor_in_doorway", "route_completed", "arrived_by_reliquary", "playstyle_profiled",
	"core_choice_shown", "four_cards_with_the_found_core", "cores_carried",
	"level_completed_archive_restored", "saved_after_choice", "ark_reached",
	"archive_restored_on_the_ark", "noor_and_teo_present", "survivors_on_the_ark", "archive_replayed",
	"trust_changed", "end_of_slice_shown", "endings_offered_with_rewrite_locked",
]
const RING_GALLERY: Array[String] = ["save_isolated", "title_shown", "title_ring_present", "ring_gallery_shown"]
const LONG_RUN_SECONDS := 55.0
const AUTOPILOT_SAVES := "user://autopilot"

var active: bool = false
var seconds: float = 30.0
var scenario: String = "slice"
var shots_dir: String = ""

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
	active = args.has("--autopilot")
	if not active:
		set_process(false)
		return
	for arg: String in args:
		if arg.begins_with("--autopilot-seconds="):
			seconds = maxf(1.0, arg.get_slice("=", 1).to_float())
		elif arg.begins_with("--autopilot-scenario="):
			scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--autopilot-shots="):
			shots_dir = arg.get_slice("=", 1)
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[autopilot] scenario=%s seconds=%.0f" % [scenario, seconds])
	# Never touch the player's save: every automated run gets its own, emptied before it starts.
	SaveService.use_directory(AUTOPILOT_SAVES.path_join(scenario))
	SaveService.delete_save()
	_register_expected()
	check(SaveService.store.dir_path != SaveService.DEFAULT_DIR and not SaveService.has_save(), "save_isolated")
	SceneRouter.scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred(SceneRouter.current_key)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	get_tree().physics_frame.connect(_on_tick_start)
	get_tree().process_frame.connect(_on_tick_start)
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)


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


# --- Checks -------------------------------------------------------------------------------------
func _register_expected() -> void:
	var required: Array[String] = []
	match scenario:
		"slice":
			required = SLICE_SHORT.duplicate()
			if seconds >= LONG_RUN_SECONDS:
				required.append_array(SLICE_LONG)
		"ring_gallery":
			required = RING_GALLERY.duplicate()
		_:
			push_error("Autopilot: unknown scenario '%s'" % scenario)
			required = ["known_scenario"]
	for c: String in required:
		expect(c)


func expect(check_id: String) -> void:
	if not _checks.has(check_id):
		_checks[check_id] = false


func pass_check(check_id: String) -> void:
	_checks[check_id] = true
	print("[autopilot] ok: ", check_id)


func check(condition: bool, check_id: String) -> void:
	expect(check_id)
	if condition:
		pass_check(check_id)


func _finish() -> void:
	_finished = true
	_report_performance()
	var failed: PackedStringArray = []
	for c: String in _checks:
		if not _checks[c]:
			failed.append(c)
	if failed.is_empty():
		print("AUTOPILOT PASS (%d checks, %.1fs)" % [_checks.size(), _elapsed])
		get_tree().quit(0)
	else:
		print("AUTOPILOT FAIL: ", ", ".join(failed))
		get_tree().quit(1)


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


# --- Helpers for scene scripts --------------------------------------------------------------------
## Waits `duration` seconds (unscaled). Returns false if the scene changed meanwhile, so callers can
## stop: `if not await _wait(1.0, gen): return`.
func _wait(duration: float, gen: int) -> bool:
	await get_tree().create_timer(duration, true, false, true).timeout
	return gen == _generation and not _finished


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
	if shots_dir == "":
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
static func input_for_ground(ground: Vector2) -> Vector2:
	return Vector2(ground.x - ground.y, ground.x + ground.y).normalized()


## Walks the player to the centre of `cell`. Returns false on timeout or if the scene changed.
func walk_to(player: Node2D, cell: Vector2i, timeout: float, gen: int) -> bool:
	var target := Iso.cell_center(cell)
	var spent := 0.0
	while true:
		if gen != _generation or _finished or not is_instance_valid(player):
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
	var ok := await _wait(duration, gen)
	press_move(Vector2.ZERO)
	return ok


# --- Scenario ---------------------------------------------------------------------------------------
func _on_scene_changed(key: StringName) -> void:
	_generation += 1
	var gen := _generation
	press_move(Vector2.ZERO)
	match key:
		&"title":
			_drive_title(gen)
		&"ring_gallery":
			_drive_ring_gallery(gen)
		&"loadout":
			_drive_loadout(gen)
		SceneRouter.LEVEL_KEY:
			_drive_level(gen)
		&"core_choice":
			_drive_core_choice(gen)
		&"ark":
			_drive_ark(gen)


func _drive_title(gen: int) -> void:
	check(true, "title_shown")
	expect("title_ring_present")
	if not await _wait(0.5, gen):
		return
	if get_tree().get_nodes_in_group(&"steward_ring").size() > 0:
		pass_check("title_ring_present")
	if not await _wait(3.0, gen):
		return
	await snap("title")
	if scenario == "ring_gallery":
		expect("ring_gallery_shown")
		SceneRouter.goto(&"ring_gallery")
	elif scenario == "slice":
		expect("level_reached")
		# New Game has focus; accept it the way a controller or keyboard would.
		tap(&"ui_accept")


func _drive_ring_gallery(gen: int) -> void:
	pass_check("ring_gallery_shown")
	if not await _wait(1.5, gen):
		return
	await snap("ring_gallery")


func _drive_loadout(gen: int) -> void:
	pass_check("loadout_shown")
	var screen := get_tree().current_scene
	if not await _wait(1.5, gen):
		return
	await snap("loadout")
	# Run the baton by hand, the way a player clicking the slot's toggle would.
	screen.call("_on_mode_toggled", 0)
	if not await _wait(1.0, gen):
		return
	await snap("loadout_manual_baton")
	var depart := screen.get("_depart") as Button
	expect("loadout_applied")
	depart.grab_focus()
	tap(&"ui_accept")


func _drive_level(gen: int) -> void:
	var level := get_tree().current_scene as Level
	if level == null or level.player == null or level.level_id != LevelCatalog.FIRST_LEVEL:
		return
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	var ids: Array[String] = []
	for w: Weapon in player.weapons:
		ids.append(w.weapon_id)
	check(ids == [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE] and player.weapons[0].chosen_mode == Loadout.Mode.MANUAL, "loadout_applied")
	# Aim with the right stick from here on, like a controller player.
	Controls.device = Controls.Device.PAD
	expect("dodge_performed")
	player.dodged.connect(func(_d: Vector2) -> void: pass_check("dodge_performed"), CONNECT_ONE_SHOT)
	expect("enemy_killed")
	expect("narration_heard")
	Narrator.line_spoken.connect(func(_id: String, _t: String) -> void: pass_check("narration_heard"), CONNECT_ONE_SHOT)
	var start_count := level.living_enemies().size()
	if not await _wait(1.2, gen):
		return
	await snap("level_start")
	expect("walls_block")
	if not await hold_ground(Vector2(-1, 0), 1.0, gen):
		return
	check(level.grid.is_walkable(player.cell()) and player.cell().x >= 9, "walls_block")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	await snap("path")
	if not await _toggle_voice_and_check(level, player, gen):
		return
	var route: Array[Vector2i] = [Vector2i(12, 37), Vector2i(13, 33), Vector2i(14, 30), Vector2i(13, 26), Vector2i(12, 21), Vector2i(11, 15), Vector2i(9, 10), Vector2i(5, 9)]
	var long_run := seconds >= LONG_RUN_SECONDS
	if long_run:
		expect("route_completed")
		expect("threat_warning_shown")
		expect("slowmo_on_dodge")
		level.slow_mo.started.connect(func(_s: float) -> void: pass_check("slowmo_on_dodge"), CONNECT_ONE_SHOT)
		_watch_threats(level, gen)
	var shot_fight := false
	for i: int in route.size():
		if not await advance_to(level, player, route[i], 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
		if not shot_fight and level.living_enemies().size() < start_count:
			shot_fight = true
			await snap("level_after_fight")
		if long_run and i == 1:
			if not await _visit_stacks(level, player, gen):
				return
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(5, 9)) <= 1.5, "arrived_by_reliquary")
	var p := GameState.run.playstyle_profile
	check(p.risk + p.caution > 0.0, "playstyle_profiled")
	if long_run:
		expect("core_choice_shown")
		if not await advance_to(level, player, Vector2i(4, 8), 15.0, gen):
			return
		tap(&"interact")
	await snap("level_plaza")


## The Reliquary's cards: carry one of each, the off-path truth core and the Lattice power core.
func _drive_core_choice(gen: int) -> void:
	pass_check("core_choice_shown")
	var screen := get_tree().current_scene
	var offered: Array[String] = screen.get("offered")
	check(offered.size() == 4 and offered.has(ContentIds.CORE_TRUTH_STACKS), "four_cards_with_the_found_core")
	if not await _wait(1.5, gen):
		return
	await snap("core_choice")
	screen.call("_toggle", ContentIds.CORE_TRUTH_STACKS)
	screen.call("_toggle", "vellum_power_lattice")
	if not await _wait(0.8, gen):
		return
	await snap("core_choice_picked")
	var confirm := screen.get("_confirm") as Button
	confirm.grab_focus()
	tap(&"ui_accept")
	if not await _wait(1.0, gen):
		return
	var r := GameState.run
	check(r.cores_power() == 1 and r.cores_truth() == 1 and r.found_core_ids.is_empty(), "cores_carried")
	check(r.levels_completed.has(ContentIds.LEVEL_VELLUM) and r.buildings_restored.has("archive") and r.logs_unlocked.has("log_vashti_audit_note"), "level_completed_archive_restored")
	check(SaveService.has_save(), "saved_after_choice")
	await snap("core_choice_done")
	expect("ark_reached")
	confirm.grab_focus()
	tap(&"ui_accept")


## The Ark: the restored Archive, Noor and Teo, the survivors; replay two memories, talk, take the skiff.
func _drive_ark(gen: int) -> void:
	pass_check("ark_reached")
	var ark := get_tree().current_scene as ArkLevel
	if ark == null:
		return
	var player := ark.player
	var archive_cells := 0
	var figures: Dictionary[String, int] = {}
	for n: Node in ark.world.get_children():
		if n is BuildingCell and (n as BuildingCell).facade == BuildingCell.Facade.ARCHIVE:
			archive_cells += 1
		if n is ArkFigure:
			var key := (n as ArkFigure).display_name()
			figures[key] = int(figures.get(key, 0)) + 1
	check(archive_cells > 0, "archive_restored_on_the_ark")
	check(figures.get("NOOR", 0) == 1 and figures.get("TEO", 0) == 1, "noor_and_teo_present")
	check(int(figures.get("SURVIVOR", 0)) == GameState.run.survivors_found(), "survivors_on_the_ark")
	if not await _wait(1.5, gen):
		return
	await snap("ark")
	for c: String in ["archive_replayed", "trust_changed", "end_of_slice_shown"]:
		expect(c)
	if not await advance_to(ark, player, Vector2i(10, 7), 20.0, gen):
		return
	tap(&"interact")
	if not await _wait(0.8, gen):
		return
	var screen := ark.archive_screen
	if screen == null:
		return
	await snap("archive")
	var noor_before := GameState.run.noor_trust
	var teo_before := GameState.run.teo_trust
	for log_id: String in ["log_0311_morning_feed", "log_vashti_audit_note"]:
		screen.select(log_id)
		screen.call("_on_replay")
		var lines := (ContentDb.memory_log(log_id).get("record", []) as Array).size()
		if not await _wait(lines * ArchiveScreen.LINE_SECONDS + 1.2, gen):
			return
		await snap("archive_" + log_id)
	check(GameState.run.logs_replayed.size() >= 2, "archive_replayed")
	check(GameState.run.noor_trust != noor_before or GameState.run.teo_trust != teo_before, "trust_changed")
	tap(&"ui_cancel")
	if not await _wait(0.8, gen):
		return
	if not await _use_at(ark, player, Vector2i(12, 9), gen):
		return
	await snap("ark_noor")
	for cell: Vector2i in [Vector2i(17, 17), Vector2i(19, 19), Vector2i(20, 20)]:
		if not await advance_to(ark, player, cell, 20.0, gen):
			return
	tap(&"interact")
	if not await _wait(1.0, gen):
		return
	check(ark.end_panel != null, "end_of_slice_shown")
	await snap("end_of_slice")
	var rewrite := EndingRules.evaluate(GameState.run)
	check(rewrite.reboot and rewrite.unplug and not rewrite.rewrite and rewrite.checklist.size() == 3, "endings_offered_with_rewrite_locked")
	if not await _wait(1.0, gen):
		return
	DebugOverlay.toggle()
	if not await _wait(0.5, gen):
		return
	await snap("debug_overlay_final")
	DebugOverlay.toggle()


## Off the path: down the stair into the overflow stacks. Nothing there while the Steward listens;
## muted, read the slip, take the truth core, wake the resident there and the one in the doorway.
func _visit_stacks(level: Level, player: Operator, gen: int) -> bool:
	for c: String in ["stacks_reached", "stacks_hidden_while_listening", "found_unindexed_log", "found_truth_core", "woke_survivor_in_stacks", "woke_survivor_in_doorway"]:
		expect(c)
	for cell: Vector2i in [Vector2i(15, 27), Vector2i(15, 26), Vector2i(16, 26), Vector2i(17, 26), Vector2i(18, 28)]:
		if not await advance_to(level, player, cell, 20.0, gen):
			return false
	pass_check("stacks_reached")
	var cache: TruthCache = null
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n is TruthCache:
			cache = n
	check(level.predicted_path.shown.is_empty() and cache != null and not cache.is_present(), "stacks_hidden_while_listening")
	# Off the Lattice the voice is still on, but the Steward can't see the Operator.
	check(await _until(func() -> bool: return Steward.voice_on and Steward.assists().signal_lost and level.hud.minimap.charted_label().ends_with("SIGNAL LOST"), 2.0, gen), "steward_blind_in_stacks")
	await snap("stacks_listening")
	tap(&"voice_toggle")
	if not await _wait(1.2, gen):
		return false
	await snap("stacks_muted")
	if not await _use_at(level, player, Vector2i(18, 28), gen):
		return false
	check(GameState.run.logs_unlocked.has(ContentIds.LOG_UNINDEXED_SLIP), "found_unindexed_log")
	if not await _use_at(level, player, Vector2i(19, 24), gen):
		return false
	check(GameState.run.found_core_ids.has(ContentIds.CORE_TRUTH_STACKS), "found_truth_core")
	await snap("stacks_truth_core")
	if not await _use_at(level, player, Vector2i(18, 30), gen):
		return false
	check(GameState.run.survivor_ids.has(ContentIds.SURVIVOR_STACKS), "woke_survivor_in_stacks")
	await snap("stacks_woken")
	for cell: Vector2i in [Vector2i(17, 26), Vector2i(16, 26), Vector2i(15, 26)]:
		if not await advance_to(level, player, cell, 20.0, gen):
			return false
	if not await _use_at(level, player, Vector2i(10, 25), gen):
		return false
	check(GameState.run.survivor_ids.has(ContentIds.SURVIVOR_DOORWAY), "woke_survivor_in_doorway")
	tap(&"voice_toggle")
	return await _wait(0.5, gen)


## Mutes the Steward with the voice key and checks everything the brief's voice table says changes,
## then turns it back on.
func _toggle_voice_and_check(level: Level, player: Operator, gen: int) -> bool:
	var toggles := GameState.run.voice_toggle_count
	tap(&"voice_toggle")
	var all_lamps := func(lit: bool) -> bool:
		for n: Node in get_tree().get_nodes_in_group(&"lattice_lamps"):
			if (n as LampPost).lit != lit:
				return false
		return true
	check(await _until(func() -> bool: return not Steward.voice_on and GameState.run.voice_toggle_count == toggles + 1, 1.0, gen), "voice_muted_by_key")
	check(await _until(func() -> bool: return all_lamps.call(false), 3.0, gen), "muted_lamps_dark")
	check(player.carried_light_on(), "muted_hand_lamp_on")
	check(await _until(func() -> bool: return level.lighting.grade_amount() > 0.95, 3.0, gen), "muted_cold_grade")
	var a := Steward.assists()
	check(level.predicted_path.shown.is_empty() and level.hud.minimap.mode() == Assists.MapMode.HAND_SCAN, "muted_path_and_map")
	check(not a.threat_warnings and a.aim_assist == 0.0 and a.dodge_slowmo_seconds == 0.0 and not player.weapons[1].is_tuned() and a.damage_taken_mult > 1.0, "muted_assists_off")
	await snap("muted_street")
	tap(&"voice_toggle")
	check(await _until(func() -> bool: return Steward.voice_on and all_lamps.call(true), 3.0, gen), "voice_restored_lamps")
	check(await _until(func() -> bool: return level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD and level.hud.subtitles.is_speaking(), 3.0, gen), "voice_restored")
	await snap("voice_restored")
	return gen == _generation


## Waits until `condition` holds (true) or `timeout` seconds pass (false).
func _until(condition: Callable, timeout: float, gen: int) -> bool:
	var spent := 0.0
	while spent < timeout:
		if gen != _generation or _finished:
			return false
		if condition.call():
			return true
		await get_tree().process_frame
		spent += get_process_delta_time() / maxf(Engine.time_scale, 0.01)
	return bool(condition.call())


func _watch_threats(level: Level, gen: int) -> void:
	while gen == _generation and not _finished:
		if not level.hud.view.active_threats().is_empty():
			pass_check("threat_warning_shown")
			await snap("threat_warning")
			return
		await get_tree().physics_frame


## Walks to `cell` and presses Interact.
func _use_at(level: Level, player: Operator, cell: Vector2i, gen: int) -> bool:
	if not await advance_to(level, player, cell, 20.0, gen):
		return false
	tap(&"interact")
	return await _wait(0.8, gen)


## Walks toward `cell`, stopping to fight anything that comes within reach. Returns false on timeout
## or scene change.
func advance_to(level: Level, player: Operator, cell: Vector2i, timeout: float, gen: int) -> bool:
	var target := Iso.cell_center(cell)
	var spent := 0.0
	var frame := 0
	var route: Array[Vector2i] = []
	var repath := 0.0
	while true:
		if gen != _generation or _finished or not is_instance_valid(player):
			_release_all()
			return false
		frame += 1
		var threat := _nearest_threat(level, player, 3.4)
		if threat != null and player.is_alive():
			_fight(player, threat, frame)
			repath = 0.0
		else:
			_release_attacks()
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
			_release_all()
			print("[autopilot] advance_to %s timed out at %s" % [cell, player.cell()])
			return false
	return false


func _nearest_threat(level: Level, player: Operator, reach: float) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	for e: Enemy in level.living_enemies():
		var d := Iso.ground_distance(player.global_position, e.global_position)
		if d <= best_d:
			best = e
			best_d = d
	return best


## One frame of fighting: aim at the threat with the right stick, close in for the baton (pressed on
## the beat, every ~0.3 s), keep the drone firing, and roll away from a red-orange windup.
func _fight(player: Operator, threat: Enemy, frame: int) -> void:
	var to := Iso.ground_dir_between(player.global_position, threat.global_position)
	var dist := Iso.ground_distance(player.global_position, threat.global_position)
	_press_aim(input_for_ground(to))
	if threat.state == Enemy.State.WINDUP and dist < 1.6 and player.dodge.can_start():
		press_move(input_for_ground(Vector2(-to.y, to.x)))
		tap(&"dodge")
		return
	press_move(input_for_ground(to) if dist > 1.2 else Vector2.ZERO)
	if dist <= 1.7 and frame % 18 < 2:
		Input.action_press(&"attack_primary")
	else:
		Input.action_release(&"attack_primary")
	if dist > 1.4:
		Input.action_press(&"attack_secondary")
	else:
		Input.action_release(&"attack_secondary")


func _press_aim(input: Vector2) -> void:
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


func _release_attacks() -> void:
	Input.action_release(&"attack_primary")
	Input.action_release(&"attack_secondary")
	_press_aim(Vector2.ZERO)


func _release_all() -> void:
	press_move(Vector2.ZERO)
	_release_attacks()
