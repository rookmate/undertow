extends TestCase
## The ending (design/act-3.md): the Spire's Reliquary restores the Council Chamber on the Ark; its door
## opens the final choice. Reboot and Unplug are always there, Rewrite only once its three conditions
## hold. A choice asks once more, then the run is finished: its ending saved, a Rewrite remembered past
## it. The epilogues: Reboot voiced and ending the sentence the Quiet cut off, Unplug in total silence,
## Rewrite speaking to Noor, Teo and the Commons; then the credits, then the title, where the finished
## run isn't continued and, after a Rewrite, the ring's gap is filled.

const SCRATCH := "user://test_endings"

var ark: ArkLevel
var screen: Epilogue
var title: Control
var _real_dir: String


func before_each() -> void:
	_real_dir = SaveService.store.dir_path
	SaveService.use_directory(SCRATCH)
	SaveService.delete_save()
	SaveService.forget_legacy()
	GameState.new_run()
	GameState.meet_companions()
	for id: String in ["kestrel", "loop", "tideworks", "mercy", "vellum", "harbor", "spire"]:
		GameState.complete_level(id)
		var building := LevelCatalog.restores(id)
		if building != "":
			GameState.restore_building(building)
	GameState.teo_turn(false)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	Sound.set_silent(false)
	for n: Node in [ark, screen, title]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	ark = null
	screen = null
	title = null
	await wait_frames(2)
	SaveService.delete_save()
	SaveService.forget_legacy()
	SaveService.use_directory(_real_dir)


func _earn_rewrite() -> void:
	for id: String in ["kestrel_truth_evacuation", "loop_truth_long_night", "mercy_truth_0417", "vellum_truth_0522", "harbor_truth_council_order"]:
		GameState.take_core(id, true)
	GameState.add_voice_time(600.0, true)
	GameState.add_voice_time(600.0, false)


func _open_ark() -> void:
	ark = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(3)


func _chamber_door() -> ArkFixture:
	for n: Node in ark.world.get_children():
		if n is ArkFixture and (n as ArkFixture).kind == ArkFixture.Kind.COUNCIL_DOOR:
			return n
	return null


func test_the_spire_restores_the_chamber_and_its_door_opens_the_choice() -> void:
	check(GameState.run.buildings_restored.has("council_chamber"), "the Spire's Reliquary restores it")
	await _open_ark()
	check(ark.council_chamber != null, "sunk into the foundation behind Noor")
	var door := _chamber_door()
	check(door != null, "its door")
	ark.player.position = Iso.cell_center(Vector2i(14, 9))
	await wait_physics_frames(2)
	check(ark.player.interact_target() == door, "within reach from beside it")
	door.interact(ark.player)
	await wait_frames(2)
	check(ark.final_choice != null and Modals.is_top(ark.final_choice), "the final choice")


func test_without_its_conditions_there_is_no_third_door() -> void:
	await _open_ark()
	var choice := ark.open_final_choice()
	await wait_frames(2)
	check_eq(choice.offered, [Endings.REBOOT, Endings.UNPLUG] as Array[String], "Reboot and Unplug, always")
	check(choice.door(Endings.REWRITE) == null, "no Rewrite door at all")
	check_false(ark.council_chamber.rewrite_open)


func test_with_them_rewrite_is_there() -> void:
	_earn_rewrite()
	check(EndingRules.evaluate(GameState.run).rewrite, "earned")
	await _open_ark()
	check(ark.council_chamber.rewrite_open, "the third door stands in the chamber")
	var choice := ark.open_final_choice()
	await wait_frames(2)
	check(choice.door(Endings.REWRITE) != null, "and on the screen")


func test_a_choice_asks_once_more_then_it_is_final() -> void:
	await _open_ark()
	var choice := ark.open_final_choice()
	var went := [false]
	choice.on_chosen = func() -> void: went[0] = true
	await wait_frames(2)
	choice.choose(Endings.UNPLUG)
	check_eq(choice.asking, Endings.UNPLUG, "asked once more")
	check_eq(GameState.run.ending, "", "nothing's decided yet")
	choice.back()
	check_eq(choice.asking, "", "not yet: back to the doors")
	choice.choose(Endings.REWRITE)
	check_eq(choice.asking, "", "a door that isn't there can't be picked")
	choice.choose(Endings.REBOOT)
	choice.confirm()
	await wait_frames(2)
	check(went[0], "on to the epilogue")
	check_eq(GameState.run.ending, Endings.REBOOT, "the run's ending")
	check_eq(GameState.run.location, "ending")
	check_eq(SceneRouter.destination_for(GameState.run.location), &"", "a finished run goes nowhere on Continue")
	var loaded := RunState.from_dict(GameState.run.to_dict())
	check_eq(loaded.ending, Endings.REBOOT, "saved")
	GameState.choose_ending(Endings.UNPLUG)
	check_eq(GameState.run.ending, Endings.REBOOT, "and final")
	check_false(SaveService.rewritten(), "only a Rewrite is remembered past the run")


func _play(ending: String) -> Array[String]:
	GameState.run.ending = ending
	screen = (load("res://ui/epilogue/epilogue.tscn") as PackedScene).instantiate() as Epilogue
	var done := [false]
	screen.on_done = func() -> void: done[0] = true
	add_child(screen)
	await wait_frames(1)
	var said: Array[String] = []
	var cards: Array = Endings.EPILOGUES[ending]
	for k: int in cards.size():
		check_eq(screen.at, k)
		var card: Dictionary = cards[k]
		if card.has("say"):
			said.append(Sound.voice_line)
			check_eq(screen.shown(), VoiceLines.fixed(str(card["say"])), "its words on screen")
		else:
			check_eq(screen.shown(), str(card["text"]))
		screen.next_card()
	check_eq(screen.shown(), Epilogue.CREDITS, "then the credits")
	check_false(done[0])
	screen.next_card()
	check(done[0] and screen.finished, "then the title")
	return said


func test_reboot_is_voiced_and_ends_the_sentence() -> void:
	var said := await _play(Endings.REBOOT)
	check_eq(",".join(said), "epilogue_reboot_1,epilogue_reboot_2,epilogue_reboot_3,epilogue_reboot_4", "warm and unbroken")
	check_eq(VoiceLines.fixed("epilogue_reboot_4"), "Good morning, Meridian. Today will be a good day.")


func test_unplug_is_silent() -> void:
	var heard := Sound.heard(&"voice")
	screen = (load("res://ui/epilogue/epilogue.tscn") as PackedScene).instantiate() as Epilogue
	screen.ending = Endings.UNPLUG
	screen.on_done = func() -> void: pass
	add_child(screen)
	await wait_frames(1)
	check(Sound.silent, "no sound at all")
	var master := AudioServer.get_bus_index(&"Master")
	check(AudioServer.is_bus_mute(master), "the whole mix off")
	check(Sound.play(&"ui_accept") == null, "nothing plays")
	check_eq(Sound.say("epilogue_reboot_1"), 0.0, "not even its voice")
	for k: int in Endings.EPILOGUES[Endings.UNPLUG].size():
		screen.next_card()
	check_eq(Sound.heard(&"voice"), heard, "no voice")
	screen.next_card()
	check_false(Sound.silent, "sound back once it's over")
	check_false(AudioServer.is_bus_mute(master))


func test_rewrite_speaks_to_them_and_is_remembered() -> void:
	_earn_rewrite()
	GameState.choose_ending(Endings.REWRITE)
	check(SaveService.rewritten(), "remembered past the run")
	var said := await _play(Endings.REWRITE)
	var words := ""
	for id: String in said:
		words += VoiceLines.fixed(id) + " "
	check(words.contains("Noor") and words.contains("Teo") and words.contains("Commons"), "it speaks to someone other than you")
	GameState.new_run()
	check(SaveService.rewritten(), "a new run doesn't forget it")


func test_the_title_keeps_a_finished_run_but_wont_continue_it() -> void:
	GameState.choose_ending(Endings.UNPLUG)
	check(SaveService.save_run(GameState.run) == OK)
	title = (load("res://ui/title/title.tscn") as PackedScene).instantiate() as Control
	add_child(title)
	await wait_frames(2)
	check(SaveService.has_save(), "kept")
	check((title.get("_continue") as Button).disabled, "but not continued: only New Game")
