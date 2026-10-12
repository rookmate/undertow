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


## DECISIONS 137, as a rule of its own (not read back from the data that applies it).
func test_siding_with_one_is_plus_two_and_minus_one_and_nothing_is_nothing() -> void:
	check_eq(Conversations.trust_change("noor", "noor"), 2)
	check_eq(Conversations.trust_change("noor", "teo"), -1)
	check_eq(Conversations.trust_change("teo", "teo"), 2)
	check_eq(Conversations.trust_change("teo", "noor"), -1)
	check_eq(Conversations.trust_change("none", "noor"), 0)
	check_eq(Conversations.trust_change("none", "teo"), 0)
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "mercy", "greywater", "vellum"] as Array[String])
	check(GameState.have_conversation("mercy", "noor"))
	check_eq(Vector2i(r.noor_trust, r.teo_trust), Vector2i(2, -1), "sided with Noor")
	check(GameState.have_conversation("greywater", "teo"))
	check_eq(Vector2i(r.noor_trust, r.teo_trust), Vector2i(1, 1), "then with Teo")
	check(GameState.have_conversation("vellum", "none"))
	check_eq(Vector2i(r.noor_trust, r.teo_trust), Vector2i(1, 1), "then said nothing")


func test_trust_stays_within_its_limits() -> void:
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "mercy"] as Array[String])
	r.noor_trust = Tunables.TRUST_MAX - 1
	r.teo_trust = Tunables.TRUST_MIN
	check(GameState.have_conversation("mercy", "noor"))
	check_eq(r.noor_trust, Tunables.TRUST_MAX, "up to the top, no further")
	check_eq(r.teo_trust, Tunables.TRUST_MIN, "down to the bottom, no further")


func test_with_one_of_them_gone_nothing_is_had() -> void:
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "mercy"] as Array[String])
	r.teo_present = false
	check_false(GameState.have_conversation("mercy", "noor"), "Teo isn't here")
	check_eq(Vector2i(r.noor_trust, r.teo_trust), Vector2i.ZERO, "nobody's trust moved")
	check(r.conversations_had.is_empty(), "and it isn't used up")


func test_malformed_conversations_are_explained_not_crashed_on() -> void:
	for bad: Variant in ["a string", [], {"mercy": []}, {"mercy": {"noor": 3, "teo": "", "choices": "none"}},
			{"mercy": {"noor": "x", "teo": "y", "choices": {"noor": [], "teo": {"label": 1}}}}]:
		check(not Conversations.problems_in(bad).is_empty(), "%s is reported" % [bad])
	var whole := {"mercy": {"noor": "x", "teo": "y", "choices": {}}}
	for side: String in Conversations.SIDES:
		whole["mercy"]["choices"][side] = {"label": "l", "reply_noor": "n", "reply_teo": "t"}
	var left := Conversations.problems_in(whole)
	check(left.size() == 2 and left[0].contains("greywater") and left[1].contains("vellum"), "a whole one passes; only the missing districts are reported: %s" % [left])


func test_answering_moves_trust_once_and_is_kept() -> void:
	var r := GameState.run
	r.levels_completed.append_array(["tideworks", "mercy", "greywater"] as Array[String])
	check(GameState.have_conversation("mercy", "noor"), "answered")
	var after := Vector2i(r.noor_trust, r.teo_trust)
	check_false(GameState.have_conversation("mercy", "teo"), "once")
	check_eq(Vector2i(r.noor_trust, r.teo_trust), after, "trust unmoved the second time")
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
	check_eq(r.teo_trust, before + 2)
	again.answer("noor")
	check_eq(again.answered, "teo", "one answer")
	check_eq(r.pending_conversation(), "")
	again.close()
	await wait_frames(2)


func test_the_loop_map_says_what_is_still_to_come() -> void:
	var names := CityMap.still_to_come()
	check(names.is_empty(), "every district is built: nothing's still to come (%s)" % [names])
	for d: Dictionary in LevelCatalog.CITY:
		check_eq(names.has(str(d["name"])), not LevelCatalog.has_level(str(d["id"])), "%s: listed only while it isn't built" % d["name"])
