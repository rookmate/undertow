extends TestCase
## The Clinic (the Ark, from Mercy General): it stands once Mercy General's cores come home, stocks you
## up with field dressings whenever you're home, and keeps the triage records. A dressing (its own key)
## puts Integrity back.

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	Input.action_release(&"use_item")
	if not Steward.voice_on:
		Steward.set_voice(true)
	if is_instance_valid(level):
		level.queue_free()
	await wait_frames(2)


func _open(path: String) -> void:
	level = (load(path) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func _clinic_cells(ark: ArkLevel) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == BuildingCell.Facade.CLINIC:
			n += 1
	return n


func _clinic_doors(ark: ArkLevel) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is ArkFixture and (c as ArkFixture).kind == ArkFixture.Kind.CLINIC_DOOR:
			n += 1
	return n


func test_the_clinic_stands_once_mercy_general_is_done_and_stocks_you_up() -> void:
	await _open("res://game/ark/ark.tscn")
	var ark := level as ArkLevel
	check_eq(_clinic_cells(ark) + _clinic_doors(ark), 0, "no Clinic before Mercy General")
	check_eq(GameState.run.dressings, 0, "and nothing to stock you up")
	level.queue_free()
	await wait_frames(1)
	GameState.restore_building("clinic")
	await _open("res://game/ark/ark.tscn")
	ark = level as ArkLevel
	check(_clinic_cells(ark) > 0 and _clinic_doors(ark) == 1, "the Clinic stands, with its door")
	check_eq(GameState.run.dressings, Tunables.DRESSINGS_MAX, "home, it stocks you up")
	var screen := ark.open_clinic()
	await wait_frames(2)
	check(Modals.is_top(screen) and get_tree().paused, "a screen of its own")
	screen.close()


func test_a_dressing_puts_integrity_back_with_its_own_key() -> void:
	GameState.restore_building("clinic")
	GameState.restock_dressings()
	await _open("res://game/level/mercy_general.tscn")
	level.remove_all_enemies()
	var p := level.player
	Input.action_press(&"use_item")
	await wait_physics_frames(2)
	Input.action_release(&"use_item")
	await wait_physics_frames(1)
	check_eq(GameState.run.dressings, Tunables.DRESSINGS_MAX, "unhurt, it stays in the pack")
	p.integrity.take(60.0)
	Input.action_press(&"use_item")
	await wait_physics_frames(2)
	Input.action_release(&"use_item")
	await wait_physics_frames(1)
	check_near(p.integrity.value, 40.0 + Tunables.DRESSING_HEAL, 0.01, "40 back")
	check_eq(GameState.run.dressings, Tunables.DRESSINGS_MAX - 1)
	p.integrity.take(5.0)
	check(p.use_dressing(), "another")
	check_near(p.integrity.value, p.integrity.max_value, 0.01, "never past full")
	GameState.run.dressings = 0
	p.integrity.take(30.0)
	check_false(p.use_dressing(), "none left, nothing happens")


## Recovered triage records are readable there; while it listens the Steward says its piece, aloud.
func test_the_clinic_keeps_the_triage_records() -> void:
	GameState.restore_building("clinic")
	GameState.unlock_log("log_0417_last_ambulance")
	await _open("res://game/ark/ark.tscn")
	var ids := ClinicScreen.triage_logs()
	check(ids.size() >= 4 and ids[0] == "log_0417_last_ambulance", "the recovered record first: %s" % [ids])
	for id: String in ids:
		check_eq(str(ContentDb.memory_log(id).get("topic", "")), ClinicScreen.TOPIC)
	var screen := (level as ArkLevel).open_clinic()
	await wait_frames(2)
	screen.read("log_0417_last_ambulance")
	check(str(screen.get("_record").text).contains("FLEET AVAILABLE: 1"), "the record")
	check_eq(Sound.voice_line, VoiceLines.log_line("log_0417_last_ambulance"), "and the Steward's word on it, aloud")
	check(str(screen.get("_reply").text) != "")
	Steward.set_voice(false)
	screen.read("log_0417_last_ambulance")
	check_eq(str(screen.get("_reply").text), "", "muted, it keeps its comment to itself")
	screen.read("log_night_sheets")
	check_false(str(screen.get("_record").text).contains("NIGHT NURSES"), "an unrecovered record can't be read")
	screen.close()


## Rebind the dressing in Options over the Clinic (or pick up the other controller) and its instruction
## follows at once.
func test_the_clinics_instruction_follows_the_binding() -> void:
	GameState.restore_building("clinic")
	await _open("res://game/ark/ark.tscn")
	var screen := (level as ArkLevel).open_clinic()
	await wait_frames(2)
	var how := screen.get("_how") as Label
	check(how.text.contains(Controls.prompt(&"use_item")), "it names the dressing's key: %s" % how.text)
	check(Controls.set_binding(&"use_item", ["key", KEY_T]), "rebound to T")
	check(how.text.contains("  T  "), "and now says T: %s" % how.text)
	Controls.device = Controls.Device.PAD
	check(how.text.contains(Controls.prompt(&"use_item")), "on a controller, its button: %s" % how.text)
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	Controls.reset_bindings()
	screen.close()
