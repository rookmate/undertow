extends Node2D
## Native, repeatable movement recording. Real Operator physics and input; isolated saves/settings.
## godot --write-movie /tmp/motion.avi --fixed-fps 30 --disable-vsync res://tools/motion_stage.tscn

var player: Operator
var caption: Label


func _ready() -> void:
	SaveService.use_directory("user://motion_preview_saves")
	Options.use_path("user://motion_preview_settings.cfg")
	GameState.new_run()
	var grid := LevelGrid.parse((".".repeat(24) + "\n").repeat(24))
	FloorLayer.build(self, grid, DistrictLook.for_district("kestrel"))
	player = Operator.new()
	player.position = Iso.cell_center(Vector2i(12, 12))
	add_child(player)
	var camera := Camera2D.new()
	camera.position = Vector2(0, -70)
	camera.zoom = Vector2(2.5, 2.5)
	player.add_child(camera)
	var ui := CanvasLayer.new()
	add_child(ui)
	caption = Label.new()
	caption.position = Vector2(32, 28)
	caption.add_theme_font_size_override("font_size", 24)
	ui.add_child(caption)
	_run.call_deferred()


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _walk(action: StringName, label: String) -> void:
	caption.text = label
	Input.action_press(action)
	await _hold(2.0)
	Input.action_release(action)
	await _hold(0.35)


func _run() -> void:
	await _hold(0.5)
	for carry: bool in [false, true]:
		player.set_carrying(carry)
		var prefix := "Carrying Noor / " if carry else "Walking / "
		for action: StringName in [&"move_down", &"move_right", &"move_up", &"move_left"]:
			await _walk(action, prefix + String(action).trim_prefix("move_"))
		caption.text = prefix + "continuous reversals and turns"
		for action: StringName in [&"move_down", &"move_up", &"move_right", &"move_left"]:
			Input.action_press(action)
			await _hold(0.65)
			Input.action_release(action)
		caption.text = prefix + "dodge, then rest"
		player.dodge.try_start(player.facing_ground)
		await _hold(0.8)
	player.set_carrying(false)
	caption.text = "Hit reaction / no walking during knockback"
	player.take_hit(5, player.position - Vector2(50, 0))
	await _hold(1.0)
	caption.text = "Downed"
	player.self_damage(1000)
	await _hold(1.0)
	print("MOTION STAGE PASS")
	Sound.quit()
