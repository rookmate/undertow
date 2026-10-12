extends TestCase
## The Steward speaks its lines aloud (placeholder voice): every line has a current recording, it speaks
## only when its narration is allowed, and it stops mid-word when muted or out of reach.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	if is_instance_valid(level):
		level.queue_free()
	await wait_frames(2)


func test_every_steward_line_has_a_current_recording() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/manifest.json"))
	var safe := RegEx.create_from_string(VoiceLines.SAFE_ID)
	var lines := VoiceLines.all()
	check(lines.size() >= 70, "the narration pools, cores, logs and fixed lines (%d)" % lines.size())
	for id: String in lines:
		check(safe.search(id) != null, "%s can be a file name" % id)
		check(LineSelector.PURPOSES.has(VoiceLines.purpose_of(id)), "%s has a purpose the orders can judge" % id)
		check(VoiceLines.has_clip(id), "%s is voiced (run tools/make_voice.py)" % id)
		var recorded := str((manifest.get(id, {}) as Dictionary).get("text", ""))
		check_eq(recorded, lines[id], "%s's recording says the current text (run tools/make_voice.py)" % id)
	for id: String in manifest:
		check(lines.has(id), "%s is recorded but no longer a line" % id)
	for id: String in ["title_quiet", "waiting_refusal", "loadout_nudge"]:
		check(VoiceLines.fixed(id) != "", "fixed line %s exists" % id)


func test_narration_is_spoken_not_chimed() -> void:
	var voices := Sound.heard(&"voice")
	var chimes := Sound.heard(&"steward_chime")
	Narrator.speak_text("VOICE_BACK_N1", "There you are. I kept your place.", LineSelector.FACT)
	check_eq(Sound.heard(&"voice"), voices + 1, "said aloud")
	check_eq(Sound.voice_line, "VOICE_BACK_N1")
	check_eq(Sound.heard(&"steward_chime"), chimes, "no chime when there's a voice")
	Narrator.speak_text("not_voiced_yet", "A line nobody recorded.", LineSelector.FACT)
	check_eq(Sound.heard(&"steward_chime"), chimes + 1, "the chime stands in for a line not voiced yet")


func test_muting_or_losing_the_signal_cuts_it_off_mid_word() -> void:
	Narrator.speak_text("VOICE_BACK_N1", "There you are. I kept your place.", LineSelector.FACT)
	check_eq(Sound.voice_line, "VOICE_BACK_N1")
	Steward.set_voice(false)
	check_eq(Sound.voice_line, "", "muted, it stops")
	var voices := Sound.heard(&"voice")
	Narrator.speak_text("VOICE_BACK_N1", "There you are. I kept your place.", LineSelector.FACT)
	check_eq(Sound.heard(&"voice"), voices, "and says nothing while muted")
	Steward.set_voice(true)
	Narrator.speak_text("VOICE_BACK_N1", "There you are. I kept your place.", LineSelector.FACT)
	Steward.set_coverage(false)
	check_eq(Sound.voice_line, "", "out of its reach, it stops too")


func test_subtitles_last_as_long_as_the_voice() -> void:
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	var id := VoiceLines.log_line("log_0522_feed_adjustment")
	Narrator.speak_text(id, VoiceLines.all()[id], LineSelector.FACT)
	var subs := level.hud.subtitles
	check(subs.get("_left") >= Sound.voice_length(id), "on screen for the whole %.1f s line" % Sound.voice_length(id))
	Steward.set_coverage(false)
	check_false(subs.is_speaking(), "and gone when it loses you")


## A voiced line's text keeps the recording's own clock: up exactly as long as the voice has left, plus
## the fade, through a pause and through the slowed time of a perfect dodge (a blow evaded mid-roll).
func test_subtitles_keep_the_voices_clock_through_pause_and_slow_time() -> void:
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	# Nothing else to say meanwhile: its line on arriving said, its remarks on how you play stopped.
	await wait_seconds(1.6)
	level.watch.process_mode = Node.PROCESS_MODE_DISABLED
	var subs := level.hud.subtitles
	var id := VoiceLines.log_line("log_0522_feed_adjustment")
	Narrator.speak_text(id, VoiceLines.all()[id], LineSelector.FACT)
	var in_step := func() -> bool: return absf(float(subs.get("_left")) - (Sound.voice_left() + Subtitles.FADE)) < 0.03
	check(Sound.voice_left() > 3.0 and in_step.call(), "a long line, its text up for as long as it has left")
	var left := Sound.voice_left()
	get_tree().paused = true
	await wait_frames(30)
	get_tree().paused = false
	check_near(left - Sound.voice_left(), 0.5, 0.05, "paused, the recording plays on")
	check(in_step.call(), "and its text keeps time with it")
	Input.action_press(&"dodge")
	await wait_physics_frames(2)
	Input.action_release(&"dodge")
	level.player.take_hit(5.0, level.player.global_position + Vector2(40, 0))
	check(level.slow_mo.is_active() and Engine.time_scale < 1.0, "a blow evaded mid-roll slows time")
	left = Sound.voice_left()
	await wait_frames(30)
	check_near(left - Sound.voice_left(), 0.5, 0.05, "the recording doesn't slow with it")
	check(in_step.call(), "nor does its text")
	level.slow_mo.cancel()
	var waited := 0
	while Sound.voice_line == id and waited < 1200:
		await wait_frames(1)
		waited += 1
	check_eq(subs.text, VoiceLines.all()[id], "still this line")
	check(subs.is_speaking(), "when the voice ends the text is still up, fading")
	# Then gone, once the fade and any reading time still owed are spent.
	await wait_seconds(maxf(float(subs.get("_floor")), Subtitles.FADE) + 0.1)
	check_false(subs.is_speaking(), "and then gone")


func test_trying_to_wake_the_waiting_while_it_listens_is_refused_aloud() -> void:
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	var waiting: TheWaiting = null
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n is TheWaiting and level.is_ancestor_of(n):
			waiting = n
	check(waiting != null, "there's one of the Waiting on the street")
	waiting.refused(level.player)
	check_eq(Sound.voice_line, "waiting_refusal", "\"They're resting. Leave them.\"")
	check_false(waiting.woken)


func test_the_steward_comments_on_the_card_you_look_at_only_while_listening() -> void:
	var screen := (load("res://ui/core_choice/core_choice.tscn") as PackedScene).instantiate() as Control
	add_child(screen)
	await wait_frames(2)
	var offered: Array = screen.get("offered")
	check_eq(Sound.voice_line, VoiceLines.core_line(str(offered[0])), "the focused card")
	var cards: Dictionary = screen.get("_cards")
	(cards[offered[1]] as Button).grab_focus()
	check_eq(Sound.voice_line, VoiceLines.core_line(str(offered[1])), "and the next one you look at")
	screen.queue_free()
	await wait_frames(1)
	Steward.set_voice(false)
	var voices := Sound.heard(&"voice")
	var muted := (load("res://ui/core_choice/core_choice.tscn") as PackedScene).instantiate() as Control
	add_child(muted)
	await wait_frames(2)
	check_eq(Sound.heard(&"voice"), voices, "muted, it doesn't sell you anything")
	muted.queue_free()


## A long line (the Spire's) wraps onto rows that fit the screen, and nothing of it is lost.
func test_a_long_line_wraps_on_screen() -> void:
	var line := VoiceLines.fixed("spire_need")
	var font := UiFonts.narration()
	var rows := Subtitles.wrapped(line, font, 34, Subtitles.MAX_WIDTH)
	check(rows.size() >= 2, "it doesn't fit on one row")
	for row: String in rows:
		check(font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x <= Subtitles.MAX_WIDTH, "%s fits" % row)
	check_eq(" ".join(rows), line, "every word, in order")
	check_eq(Subtitles.wrapped("They're resting. Leave them.", font, 34, Subtitles.MAX_WIDTH).size(), 1, "a short one stays on one row")
