extends Node
## Native cycle review with real enemy AI/physics and real boss phase clocks.

var level: Level
var subject: Node2D
var camera: Camera2D
var caption: Label
var group: String = "enemies"
var _seen: Dictionary[int, bool] = {}
var _subject_filter: String = ""
var _phases: Dictionary[int, bool] = {}
var _last_phase: int = -1
var _cycle_starts: int = 0
var _failed: bool = false


func _ready() -> void:
	SaveService.use_directory("user://actor_motion_saves")
	Options.use_path("user://actor_motion_settings.cfg")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--animation-group="):
			group = arg.trim_prefix("--animation-group=")
		if arg.begins_with("--animation-subject="):
			_subject_filter = arg.trim_prefix("--animation-subject=")
	var ui := CanvasLayer.new()
	ui.layer = 100
	add_child(ui)
	caption = Label.new()
	caption.position = Vector2(30, 24)
	caption.add_theme_font_size_override("font_size", 25)
	ui.add_child(caption)
	_run.call_deferred()


func _process(_delta: float) -> void:
	if is_instance_valid(level) and is_instance_valid(level.player):
		# Keep the target alive without making it invulnerable to snatching or hooks.
		level.player.integrity.value = level.player.integrity.max_value
	if is_instance_valid(subject) and is_instance_valid(camera):
		camera.global_position = subject.global_position + Vector2(0, -60)
		if subject is Enemy:
			_seen[(subject as Enemy).state] = true
		if subject is Boss:
			var phase: int = subject.get("phase")
			_phases[phase] = true
			if phase == 1 and _last_phase != phase:
				_cycle_starts += 1
			_last_phase = phase


func _hold(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _open(path: String, keep_boss: bool = false) -> void:
	subject = null
	if is_instance_valid(level):
		level.queue_free()
		await get_tree().process_frame
	GameState.new_run()
	GameState.run.scrap = 9
	level = (load(path) as PackedScene).instantiate() as Level
	add_child(level)
	await get_tree().process_frame
	for e: Enemy in level.living_enemies():
		if not keep_boss or not (e is Boss or e is WeakPoint):
			e.queue_free()
	level.hud.hide()
	# Neutral inspection light survives voice changes used to exercise hostile behavior.
	Steward.voice_changed.disconnect(level.lighting._on_voice_changed)
	Steward.coverage_changed.disconnect(level.lighting._on_coverage_changed)
	level.lighting.grade.set_shader_parameter(&"amount", 0.0)
	level.get("_ambient").color = Color(0.9, 0.9, 0.95)
	level.player.set_physics_process(false)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	level.add_child(camera)
	camera.make_current()
	Sound.hush()
	await get_tree().process_frame


func _run() -> void:
	if group == "bosses":
		await _bosses()
	elif group == "people":
		await _people()
	else:
		await _enemies()
	print("ACTOR MOTION STAGE ", "FAIL" if _failed else "PASS", ": ", group)
	Sound.quit(1 if _failed else 0)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failed = true
		push_error(message)


func _enemies() -> void:
	var scripts: Array[Script] = [preload("res://game/enemies/clerk.gd"), preload("res://game/enemies/warden.gd"), preload("res://game/enemies/lamplighter.gd"), preload("res://game/enemies/custodian.gd"), preload("res://game/enemies/salvager.gd"), preload("res://game/enemies/sterilizer.gd")]
	for script: Script in scripts:
		if _subject_filter != "" and script.get_global_name().to_lower() != _subject_filter:
			continue
		await _open("res://tools/actor_motion_arena.tscn")
		Steward.set_voice(true)
		var enemy := script.new() as Enemy
		level.add_enemy(enemy, Vector2i(6, 3), 1000.0)
		subject = enemy
		_seen.clear()
		level.player.position = Iso.cell_center(Vector2i(12, 3))
		caption.text = script.get_global_name() + " / pursuit, turns, windup and release"
		if enemy is Lamplighter:
			enemy.home = Iso.cell_center(Vector2i(12, 3))
		await _hold(3.0)
		level.player.position = enemy.position + Iso.grid_to_world(Vector2(-0.9, 0))
		if enemy is Lamplighter:
			Steward.set_voice(false)
		await _hold(4.0)
		level.player.position = enemy.position + Iso.grid_to_world(Vector2(0, -0.9))
		await _hold(3.0)
		_check(_seen.has(Enemy.State.WINDUP), "Actor preview did not exercise an attack: " + script.get_global_name())
		print("ACTOR CHECK: ", script.get_global_name(), " states=", _seen.keys())
		caption.text = script.get_global_name() + " / stun, recovery, death"
		enemy.take_hit(1.0, Vector2.ZERO, 0.0, 1.0)
		await _hold(1.3)
		enemy.take_hit(10000.0, Vector2.ZERO, 0.0, 0.0)
		await _hold(0.7)


func _bosses() -> void:
	var required := {
		"conductor": [Conductor.Phase.WARN, Conductor.Phase.RUN, Conductor.Phase.GAP, Conductor.Phase.VENT],
		"crane": [Crane.Phase.LIFT, Crane.Phase.AIM, Crane.Phase.DROP, Crane.Phase.SWING_WARN, Crane.Phase.SWING, Crane.Phase.REST],
		"surgeon": [Surgeon.Phase.MARK, Surgeon.Phase.CUT, Surgeon.Phase.MIST_WARN, Surgeon.Phase.MIST, Surgeon.Phase.SUTURE],
		"lung": [Lung.Phase.FILL, Lung.Phase.FLOOD, Lung.Phase.SURGE_WARN, Lung.Phase.SURGE, Lung.Phase.VENT],
		"editor": [Editor.Phase.ROLL_WARN, Editor.Phase.ROLL, Editor.Phase.PULP, Editor.Phase.FEED_WARN, Editor.Phase.FEED, Editor.Phase.INK],
		"warden_prime": [WardenPrime.Phase.SWEEP, WardenPrime.Phase.CHARGE_WARN, WardenPrime.Phase.CHARGE],
	}
	for id: String in ["conductor", "crane", "surgeon", "lung", "editor", "warden_prime"]:
		if _subject_filter != "" and id != _subject_filter:
			continue
		await _open("res://tests/fixtures/%s_arena.tscn" % id, true)
		Steward.set_voice(false)
		subject = level.boss
		_phases.clear()
		_last_phase = -1
		_cycle_starts = 0
		camera.zoom = Vector2(1.3, 1.3)
		level.player.position = subject.position + Iso.grid_to_world(Vector2(3, 0))
		caption.text = id.capitalize() + " / complete live attack cycle and opening"
		var elapsed := 0.0
		while elapsed < 60.0 and (_cycle_starts < 2 or not required[id].all(func(p: int) -> bool: return _phases.has(p))):
			await _hold(0.1)
			elapsed += 0.1
		_check(level.boss.is_fighting and _cycle_starts >= 2 and required[id].all(func(p: int) -> bool: return _phases.has(p)), "Incomplete live boss cycle: " + id)
		# Exercise its actual manual vulnerability action, when that window next arrives.
		elapsed = 0.0
		while elapsed < 20.0 and not level.boss.is_switching():
			await _hold(0.1)
			elapsed += 0.1
		if level.boss.is_switching():
			level.boss.on_weak_point_hit()
			_check(level.boss.is_vulnerable(), "Manual action did not open boss: " + id)
			caption.text = id.capitalize() + " / manual opening and recovery"
			await _hold(7.0)
		else:
			_check(false, "Manual window never arrived: " + id)
		print("BOSS CHECK: ", id, " phases=", _phases.keys(), " starts=", _cycle_starts)


func _people() -> void:
	await _open("res://tools/actor_motion_arena.tscn")
	Steward.set_voice(false)
	level.player.hide()
	for who: ArkFigure.Who in [ArkFigure.Who.NOOR, ArkFigure.Who.TEO, ArkFigure.Who.SURVIVOR]:
		var person := ArkFigure.new()
		person.setup(level, Vector2i(6, 8), who)
		level.world.add_child(person)
		subject = person
		caption.text = person.display_name() + " / actual arrival route and stop"
		var start := person.position
		person.walk_along([start + Iso.grid_to_world(Vector2(3, 0)), start + Iso.grid_to_world(Vector2(3, -3)), start], 6.0, 0.5)
		await _hold(7.5)
		person.queue_free()
	var waiting := TheWaiting.new()
	waiting.setup(level, Vector2i(8, 8), "motion_preview_resident", false)
	level.world.add_child(waiting)
	subject = waiting
	caption.text = "Waiting / wake and departure"
	await _hold(0.7)
	waiting.interact(level.player)
	await _hold(3.2)
