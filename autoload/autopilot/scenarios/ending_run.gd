extends AutopilotScenario
## One of the three endings, from a prepared run home from the Spire with the Council Chamber standing.
## Down into it, the door picked and confirmed the way a player would, the epilogue watched to the end
## (Reboot: its voice, ending the sentence the Quiet cut off; Unplug: total silence, the words on the
## screen only; Rewrite: it speaks to Noor, to Teo, to the Commons), the credits, and the title after:
## the finished run kept but not continued, and after a Rewrite the ring's gap filled.

const DISTRICTS: Array[String] = ["kestrel", "loop", "tideworks", "mercy", "greywater", "vellum", "harbor", "spire"]
const TRUTHS: Array[String] = ["kestrel_truth_evacuation", "loop_truth_long_night", "tideworks_truth_strike_records", "mercy_truth_0417", "greywater_truth_plaque", "vellum_truth_0522", "harbor_truth_council_order", "spire_truth_quiet"]

var ending: String = ""
## The epilogue has played: the next title is the one after it.
var _ended: bool = false


func _init(which: String) -> void:
	ending = which


func problem() -> String:
	return "" if Endings.ALL.has(ending) else "no such ending: %s" % ending


func expected() -> Array[String]:
	var out := super()
	out.append_array([
		"ark_reached", "chamber_standing", "doors_offered", "asked_once_more", "ending_chosen", "epilogue_played",
		"epilogue_" + ending, "credits_rolled", "title_after", "run_kept_not_continued", "title_ring_after",
	])
	return out


## Home from the Spire with everything built, Noor home and Teo staying. Only a Rewrite run has earned
## its door (the voice on for half of play, eight truths kept); the others haven't (two truths).
func _prepare() -> void:
	GameState.new_run()
	GameState.meet_companions()
	for id: String in DISTRICTS:
		GameState.complete_level(id)
		var building := LevelCatalog.restores(id)
		if building != "":
			GameState.restore_building(building)
	GameState.teo_turn(false)
	var truths := TRUTHS if ending == Endings.REWRITE else TRUTHS.slice(0, 2)
	for id: String in truths:
		GameState.take_core(id, true)
	GameState.add_voice_time(600.0, true)
	GameState.add_voice_time(600.0 if ending == Endings.REWRITE else 60.0, false)
	GameState.set_location("ark")


func on_title(title: Node, gen: int) -> void:
	if not _ended:
		SceneRouter.goto(&"ark", _prepare)
		return
	Autopilot.pass_check("title_after")
	Autopilot.check((title.get("_continue") as Button).disabled and SaveService.has_save() and GameState.run.ending == ending, "run_kept_not_continued")
	if not await Autopilot.wait(1.5, gen):
		return
	var ring := (title.get("_wordmark") as Wordmark).ring
	var want := StewardRing.State.REWRITE if ending == Endings.REWRITE else StewardRing.State.IDLE
	Autopilot.check(ring.state == want and SaveService.rewritten() == (ending == Endings.REWRITE), "title_ring_after")
	await Autopilot.snap("ending_%s_title" % ending)
	Autopilot.finish_now()


func on_ark(ark: ArkLevel, gen: int) -> void:
	Autopilot.pass_check("ark_reached")
	Autopilot.check(ark.council_chamber != null, "chamber_standing")
	if not await Autopilot.wait(1.0, gen):
		return
	await Autopilot.snap("ending_%s_chamber" % ending)
	if not await Autopilot.advance_to(ark, ark.player, Vector2i(14, 9), 20.0, gen):
		return
	await Autopilot.snap("ending_%s_at_the_chamber" % ending)
	Autopilot.tap(&"interact")
	if not await Autopilot.wait(0.8, gen):
		return
	var choice := ark.final_choice
	if choice == null:
		return
	if not await Autopilot.wait(1.5, gen):
		return
	Autopilot.check(choice.offered.size() == (3 if ending == Endings.REWRITE else 2) and choice.door(ending) != null, "doors_offered")
	await Autopilot.snap("ending_%s_doors" % ending)
	choice.door(ending).grab_focus()
	await Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(1.0, gen):
		return
	Autopilot.check(choice.asking == ending, "asked_once_more")
	await Autopilot.snap("ending_%s_asked" % ending)
	(choice.get("_yes") as Button).grab_focus()
	Autopilot.tap(&"ui_accept")


func on_epilogue(screen: Epilogue, gen: int) -> void:
	_ended = true
	Autopilot.check(GameState.run.ending == ending and screen.ending == ending, "ending_chosen")
	Autopilot.pass_check("epilogue_played")
	var said: Array[String] = []
	var silent := true
	var shot := -1
	var cards: Array = Endings.EPILOGUES[ending]
	while not Autopilot.stale(gen) and screen.at < cards.size():
		if Sound.voice_line != "" and not said.has(Sound.voice_line):
			said.append(Sound.voice_line)
		silent = silent and Sound.silent and Sound.voice_line == ""
		if screen.at != shot:
			shot = screen.at
			await Autopilot.wait(0.6, gen)
			await Autopilot.snap("ending_%s_card_%d" % [ending, shot])
		await (Engine.get_main_loop() as SceneTree).process_frame
	if Autopilot.stale(gen):
		return
	match ending:
		Endings.REBOOT:
			Autopilot.check(",".join(said) == "epilogue_reboot_1,epilogue_reboot_2,epilogue_reboot_3,epilogue_reboot_4" \
				and VoiceLines.fixed(said[said.size() - 1]) == "Good morning, Meridian. Today will be a good day.", "epilogue_reboot")
		Endings.UNPLUG:
			Autopilot.check(said.is_empty() and silent, "epilogue_unplug")
		Endings.REWRITE:
			var words := ""
			for id: String in said:
				words += VoiceLines.fixed(id) + " "
			Autopilot.check(said.size() == 4 and words.contains("Noor") and words.contains("Teo") and words.contains("Commons"), "epilogue_rewrite")
	Autopilot.check(screen.shown() == Epilogue.CREDITS, "credits_rolled")
	await Autopilot.snap("ending_%s_credits" % ending)
