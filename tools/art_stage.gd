extends Node
## Capture assembled district art, boss poses and the restored Ark in a native Godot renderer.

var output: String = "res://reports/art-complete/stage"
var level: Level
var root: Window

func _ready() -> void:
	# Synthetic level checkpoints must stay separate from the player's run and settings.
	SaveService.use_directory("user://art_preview_saves")
	Options.use_path("user://art_preview_settings.cfg")
	root = get_tree().root
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--art-shots="):
			output = arg.trim_prefix("--art-shots=")
	_run.call_deferred()

func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame

func _capture(label: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if root.use_hdr_2d:
		capture = Screenshot.linear_to_srgb(capture, 1600)
	var result := capture.save_png(output.path_join(label + ".png"))
	if result != OK:
		push_error("Art stage capture failed: %s" % result)
	print("ART STAGE: ", label)

func _open(path: String) -> void:
	if level != null:
		level.queue_free()
		await _frames(3)
	level = (load(path) as PackedScene).instantiate() as Level
	root.add_child(level)
	await _frames(5)
	Sound.hush()
	level.player.set_physics_process(false)
	for enemy: Enemy in level.living_enemies():
		enemy.set_physics_process(false)
	level.camera.position_smoothing_enabled = false

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Art stage requires a rendering display")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for id: String in LevelCatalog.LEVELS:
		AutopilotRoute.for_district(id).prepare()
		Steward.set_voice(true)
		await _open(LevelCatalog.LEVELS[id].scene)
		await _capture(id + "_start")
		if level.boss != null:
			var boss := level.boss
			level.player.position = boss.position + Vector2(0, 150)
			level.camera.position = Vector2(0, -120)
			level.camera.limit_left = -1000000
			level.camera.limit_top = -1000000
			level.camera.limit_right = 1000000
			level.camera.limit_bottom = 1000000
			level.camera.zoom = Vector2(1.5, 1.5)
			await _capture(id + "_boss")
			if boss is Conductor:
				boss.call("_enter_phase", Conductor.Phase.VENT)
			elif boss is Crane:
				boss.call("_enter_phase", Crane.Phase.STALLED)
			elif boss is Surgeon:
				boss.call("_enter_phase", Surgeon.Phase.STALLED)
			elif boss is Lung:
				boss.call("_enter_phase", Lung.Phase.STALLED)
			elif boss is Editor:
				boss.call("_enter_phase", Editor.Phase.JAMMED)
			elif boss is WardenPrime:
				boss.call("_enter_phase", WardenPrime.Phase.STALLED)
			await _capture(id + "_opening")
		if id == "harbor":
			level.player.set_carrying(true)
			var body := level.player.get("_body") as OperatorBody
			for facing: Vector2 in [Vector2(0, 1), Vector2(0, -1)]:
				body.update_pose(facing, Vector2.ZERO, Dodge.new(), 0.0)
				await _capture("noor_carried_" + ("front" if facing.y > 0 else "back"))
			var roll := Dodge.new()
			roll.try_start(Vector2(0, 1))
			roll.update(0.15)
			body.update_pose(Vector2(0, 1), Vector2.ONE, roll, 0.15)
			await _capture("noor_carried_dodge")
			level.player.set_carrying(false)
			body.downed = true
			await _capture("operator_downed")
			body.downed = false
			body.update_pose(level.player.facing_ground, Vector2.ZERO, Dodge.new(), 0.0)
		Steward.set_voice(false)
		await _capture(id + "_muted")
	GameState.new_run()
	for id: String in LevelCatalog.LEVELS:
		GameState.complete_level(id)
		var building: String = LevelCatalog.LEVELS[id].restores
		if building != "" and not GameState.run.buildings_restored.has(building):
			GameState.run.buildings_restored.append(building)
	GameState.meet_companions()
	GameState.noor_comes_home()
	GameState.run.buildings_restored.append(GameState.MAST)
	GameState.add_survivor("vellum_waiting_doorway")
	GameState.add_survivor("mercy_waiting_night_nurse")
	Steward.set_voice(true)
	await _open("res://game/ark/ark.tscn")
	await _capture("ark_restored")
	for who: ArkFigure.Who in [ArkFigure.Who.NOOR, ArkFigure.Who.TEO, ArkFigure.Who.WARDFOLK]:
		for child: Node in level.world.get_children():
			if child is ArkFigure and (child as ArkFigure).who == who:
				level.player.position = (child as ArkFigure).position + Vector2(70, 40)
				await _capture("ark_person_%d" % who)
				break
	var ark := level as ArkLevel
	var map := ark.open_city_map()
	await _capture("city_map")
	map.close()
	await _frames(2)
	level.queue_free()
	level = null
	await _frames(3)
	print("ART STAGE PASS")
	Sound.quit()
