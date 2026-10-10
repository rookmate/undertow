extends TestCase
## Noor and Teo's conversations about the Act 2 districts: one each, once, after you've been, the next
## time you talk to either of them; your answer moves their trust and is kept.


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)


func test_every_act_2_district_has_a_whole_conversation() -> void:
	check_eq(Conversations.problems(), PackedStringArray(), "the conversations are whole")
	for id: String in ["mercy", "greywater", "vellum"]:
		check(Conversations.has(id), "%s has one" % id)


func test_one_is_pending_only_after_a_district_with_them_on_the_ark() -> void:
	var r := GameState.run
	check_eq(r.pending_conversation(), "", "nothing yet")
	r.levels_completed.append("mercy")
	check_eq(r.pending_conversation(), "", "they haven't joined (the Tideworks isn't done)")
	r.levels_completed.append("tideworks")
	check_eq(r.pending_conversation(), "mercy", "Mercy General, now they're here")
	r.noor_present = false
	check_eq(r.pending_conversation(), "", "not with one of them gone")


func test_answering_moves_trust_once_and_is_kept() -> void:
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "mercy", "greywater"] as Array[String])
	var noor := r.noor_trust
	var teo := r.teo_trust
	var side := Conversations.choice("mercy", "noor")
	check(GameState.have_conversation("mercy", "noor"), "answered")
	check_eq(r.noor_trust, noor + int(side["noor"]))
	check_eq(r.teo_trust, teo + int(side["teo"]))
	check_false(GameState.have_conversation("mercy", "teo"), "once")
	check_eq(r.noor_trust, noor + int(side["noor"]), "trust unmoved the second time")
	check_eq(r.pending_conversation(), "greywater", "on to the next district's")
	check_false(GameState.have_conversation("greywater", "shrug"), "only the answers on offer")
	var loaded := RunState.from_dict(r.to_dict())
	check_eq(loaded.conversations_had, r.conversations_had, "saved")


func test_the_screen_answers_once_and_backing_out_leaves_it_for_later() -> void:
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "vellum"] as Array[String])
	var screen := ConversationScreen.new()
	screen.district = "vellum"
	add_child(screen)
	await wait_frames(2)
	screen.close()
	await wait_frames(2)
	check_eq(r.pending_conversation(), "vellum", "left without answering: still to come")
	var again := ConversationScreen.new()
	again.district = "vellum"
	add_child(again)
	await wait_frames(2)
	var before := r.teo_trust
	again.answer("teo")
	check_eq(again.answered, "teo")
	check_eq(r.teo_trust, before + int(Conversations.choice("vellum", "teo")["teo"]))
	again.answer("noor")
	check_eq(again.answered, "teo", "one answer")
	check_eq(r.pending_conversation(), "")
	again.close()
	await wait_frames(2)


func test_the_loop_map_says_what_is_still_to_come() -> void:
	var names := CityMap.still_to_come()
	check(names.has("Harbor Ward") and names.has("The Spire"), "Act 3's districts: %s" % [names])
	check_false(names.has("The Vellum"), "and not the ones you can already reach")
