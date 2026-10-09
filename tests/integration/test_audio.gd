extends TestCase
## The game's sound: every cue exists, cues play on their buses, and the Steward's sounds follow its
## voice (its chime comes with its words; the Lattice hums only while it is with you).

var level: Level


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	Steward.set_coverage(true)
	if is_instance_valid(level):
		level.queue_free()
		await wait_frames(2)
	Sound.set_ambience({})


func _start_level(path: String = "res://game/level/vellum_street.tscn") -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load(path) as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)




func test_every_cue_and_layer_has_its_sounds() -> void:
	for cue: StringName in Sound.CUES:
		for file: String in Sound.CUES[cue]["files"]:
			check(ResourceLoader.exists(Sound.DIR + file + ".ogg"), "%s: %s.ogg exists" % [cue, file])
	for layer: StringName in Sound.AMBIENCE:
		var path := Sound.DIR + str(Sound.AMBIENCE[layer]["file"]) + ".ogg"
		check(ResourceLoader.exists(path), "%s loops %s" % [layer, path])
	for bus: StringName in Sound.BUSES:
		check(AudioServer.get_bus_index(bus) != -1, "bus %s exists" % bus)


func test_a_cue_plays_on_its_bus_where_it_happens() -> void:
	var p := Sound.play(&"dodge", Vector2(300, 200)) as AudioStreamPlayer2D
	check(p != null and p.stream != null and p.stream.resource_path.get_file().begins_with("dodge_"), "a world sound is set up")
	check_eq(p.bus, &"SFX")
	check_eq(p.global_position, Vector2(300, 200), "where it happened")
	check_eq(Sound.history.back(), {"cue": &"dodge", "bus": &"SFX", "at": Vector2(300, 200)}, "and recorded")
	var ui := Sound.play(&"ui_accept") as AudioStreamPlayer
	check(ui != null and ui.bus == &"UI", "interface sounds are flat, on the UI bus")
	check_eq(Sound.audible, AudioServer.get_driver_name() != "Dummy", "started only where it can be heard")


func test_unknown_cues_are_reported() -> void:
	Diagnostics.capture()
	check(Sound.play(&"no_such_cue") == null)
	var reports := Diagnostics.release()
	check(reports.size() == 1 and reports[0].contains("no_such_cue"), "%s" % [reports])


func test_volume_sliders_set_the_buses() -> void:
	var before := Sound.volume(&"SFX")
	Sound.set_volume(&"SFX", 0.5)
	check_near(Sound.volume(&"SFX"), 0.5, 0.001)
	Sound.set_volume(&"SFX", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "zero mutes the bus")
	check_eq(Sound.volume(&"SFX"), 0.0)
	Sound.set_volume(&"SFX", before)


func test_the_steward_chimes_when_it_speaks_and_never_while_muted() -> void:
	await _start_level()
	var chimes := Sound.heard(&"steward_chime")
	Narrator.speak_text("test_line", "There you are.", LineSelector.FACT)
	check_eq(Sound.heard(&"steward_chime"), chimes + 1, "its words come with its chime")
	Steward.set_voice(false)
	Narrator.speak_text("test_line", "There you are.", LineSelector.FACT)
	check_eq(Narrator.notify(&"kill"), "", "muted, nothing is said")
	check_eq(Sound.heard(&"steward_chime"), chimes + 1, "and nothing chimes")


func test_the_lattice_hums_only_while_the_steward_is_with_you() -> void:
	await _start_level()
	await wait_frames(2)
	check_eq(Sound.layer_target(&"rain"), 1.0, "rain on the street")
	check_eq(Sound.layer_target(&"lattice_hum"), 1.0, "the lamps hum while it listens")
	Steward.set_voice(false)
	await wait_frames(2)
	check_eq(Sound.layer_target(&"lattice_hum"), 0.0, "muted, the hum stops")
	Steward.set_voice(true)
	level.player.position = Iso.cell_center(Vector2i(18, 28))
	await wait_seconds(Level.COVERAGE_GRACE + 0.3)
	check_eq(Sound.layer_target(&"lattice_hum"), 0.0, "off the Lattice there's no hum either")
	check_eq(Sound.layer_target(&"underground"), 1.0, "the stacks close in")
	check(Sound.layer_target(&"rain") < 0.5, "the rain is far above")


func test_the_ark_sits_in_the_estuary_wind() -> void:
	GameState.new_run()
	GameState.restore_building("archive")
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	check_eq(Sound.layer_target(&"estuary"), 1.0)
	check_eq(Sound.layer_target(&"lattice_hum"), 0.0, "no Lattice on the Ark")


func test_walking_makes_footsteps_by_surface() -> void:
	await _start_level()
	var before := Sound.heard(&"step_wet")
	var start := level.player.position
	for i: int in 12:
		level.player.position = start + Iso.ground_velocity(Vector2(0, -1), 0.2 * (i + 1))
		await wait_frames(1)
	check(Sound.heard(&"step_wet") > before, "wet stone underfoot on the street")
	check_eq(LevelAudio.step_cue(LevelGrid.Floor.STACKS), &"step_dry", "dry paper and concrete in the stacks")


func test_the_voice_switch_clicks_but_loading_a_save_does_not() -> void:
	Steward.set_voice(true)
	var offs := Sound.heard(&"voice_off")
	var ons := Sound.heard(&"voice_on")
	Steward.toggle_voice()
	check_eq(Sound.heard(&"voice_off"), offs + 1, "switching it off is heard")
	Steward.toggle_voice()
	check_eq(Sound.heard(&"voice_on"), ons + 1, "and on")
	Steward.set_voice(false)
	Steward.set_voice(true)
	check_eq(Sound.heard(&"voice_off") + Sound.heard(&"voice_on"), offs + ons + 2, "setting it from a save is silent")


## Quitting silences everything and then waits a moment for the audio thread; whatever the game does in
## that moment (a respawn, the Steward's word on it) mustn't start a sound, or it leaks at exit.
func test_nothing_new_starts_once_the_game_is_closing() -> void:
	Sound.set_ambience({})
	Sound.closing = true
	var cues := Sound.heard(&"respawn")
	var voices := Sound.heard(&"voice")
	check(Sound.play(&"respawn") == null, "no cue")
	check_eq(Sound.say("RESPAWN_N1"), 0.0, "no line")
	Sound.set_ambience({&"rain": 1.0})
	check_eq(Sound.layer_target(&"rain"), 0.0, "no ambience")
	check_eq(Sound.heard(&"respawn"), cues)
	check_eq(Sound.heard(&"voice"), voices)
	Sound.closing = false
