extends Node
## Scripted player for the gate's 30-second run and for progress recordings. Does nothing unless the
## game is launched with `-- --autopilot`. Options (after `--`):
##   --autopilot-seconds=N      stop after N seconds (default 30)
##   --autopilot-scenario=NAME  what to do: "slice" (default) or "ring_gallery"
##   --autopilot-shots=DIR      save screenshots at named moments into DIR
## Each scene script registers the checks it expects; at the end the autopilot prints
## "AUTOPILOT PASS" and exits 0 only if every expected check passed.

var active: bool = false
var seconds: float = 30.0
var scenario: String = "slice"
var shots_dir: String = ""

var _elapsed: float = 0.0
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
	SceneRouter.scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred(SceneRouter.current_key)


func _process(delta: float) -> void:
	# Process delta is scaled by time_scale; undo that so slow-motion doesn't stretch the run.
	_elapsed += delta / maxf(Engine.time_scale, 0.01)
	if _elapsed >= seconds and not _finished:
		_finish()


# --- Checks -------------------------------------------------------------------------------------
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
		&"level_vellum":
			_drive_level(gen)


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


func _drive_level(gen: int) -> void:
	pass_check("level_reached")
	var level := get_tree().current_scene as Level
	if level == null or level.player == null:
		return
	var player := level.player
	pass_check("player_spawned")
	expect("dodge_performed")
	player.dodged.connect(func(_d: Vector2) -> void: pass_check("dodge_performed"), CONNECT_ONE_SHOT)
	if not await _wait(1.2, gen):
		return
	await snap("level_start")
	# Walk into the building band on the left (grid -x): the walls must hold.
	expect("walls_block")
	if not await hold_ground(Vector2(-1, 0), 1.6, gen):
		return
	check(level.grid.is_walkable(player.cell()) and player.cell().x >= 9, "walls_block")
	# Up the street, round the stalled tram, into the plaza by the Reliquary.
	var route: Array[Vector2i] = [Vector2i(12, 37), Vector2i(13, 33), Vector2i(14, 30), Vector2i(13, 26), Vector2i(12, 21), Vector2i(11, 15), Vector2i(9, 10), Vector2i(5, 9)]
	expect("route_completed")
	for i: int in route.size():
		if i == 2 or i == 5:
			tap(&"dodge")
		if not await walk_to(player, route[i], 9.0, gen):
			return
		if i == 3:
			await snap("level_mid")
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(5, 9)) <= 1.5, "arrived_by_reliquary")
	await snap("level_plaza")
