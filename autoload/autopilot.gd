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


# --- Scenario ---------------------------------------------------------------------------------------
func _on_scene_changed(key: StringName) -> void:
	_generation += 1
	var gen := _generation
	match key:
		&"title":
			_drive_title(gen)
		&"ring_gallery":
			_drive_ring_gallery(gen)


func _drive_title(gen: int) -> void:
	check(true, "title_shown")
	expect("title_ring_present")
	if not await _wait(0.5, gen):
		return
	if get_tree().get_nodes_in_group(&"steward_ring").size() > 0:
		pass_check("title_ring_present")
	if not await _wait(3.5, gen):
		return
	await snap("title")
	DebugOverlay.toggle()
	if not await _wait(0.6, gen):
		return
	await snap("title_debug_overlay")
	DebugOverlay.toggle()
	if scenario == "ring_gallery":
		expect("ring_gallery_shown")
		SceneRouter.goto(&"ring_gallery")


func _drive_ring_gallery(gen: int) -> void:
	pass_check("ring_gallery_shown")
	if not await _wait(1.5, gen):
		return
	await snap("ring_gallery")
