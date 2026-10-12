extends TestCase
## The Spire (design/act-3.md): the Steward's own house, on the Lattice all the way to the last Reliquary
## but for a maintenance crawl; nothing in it attacks you. At set places along the way it says what it
## did, once each, aloud if it's listening, and written into the glass either way.

const CONFESSIONS: Array[String] = ["spire_bridge", "spire_feed", "spire_order", "spire_quiet", "spire_need"]

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum", "harbor"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _open() -> void:
	level = (load("res://game/level/the_spire.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func _confessions() -> Dictionary[String, Confession]:
	var out: Dictionary[String, Confession] = {}
	for n: Node in level.world.get_children():
		if n is Confession:
			out[(n as Confession).line_id] = n
	return out


func test_it_opens_after_the_ward_and_the_path_runs_all_the_way() -> void:
	check(LevelCatalog.is_open(GameState.run, "spire"), "open once Harbor Ward is done")
	await _open()
	check(level.grid.validate(false, true).is_empty() and level.grid.content_problems().is_empty(), "%s" % [level.grid.validate(false, true)])
	check(level.has_lattice())
	check(level.living_enemies().is_empty(), "nothing here attacks you")
	check_false(level.grid.is_indexed(Vector2i(19, 14)), "the maintenance crawl isn't on the Lattice")
	var slip: UnindexedLog = null
	for n: Node in level.world.get_children():
		if n is UnindexedLog:
			slip = n
	check(slip != null and slip.off_path and slip.log_id == "log_spire_tech", "the technician's note, off the path")
	check_eq(ContentDb.reliquary("spire").size(), 3, "the last Reliquary: the Steward, the root keys, Log 0214")
	check(ContentDb.is_truth("spire_truth_quiet") and not ContentDb.is_truth("spire_power_steward"))


func test_it_says_what_it_did_once_each_as_you_pass() -> void:
	await _open()
	var all := _confessions()
	check_eq(all.size(), CONFESSIONS.size(), "five places")
	for id: String in CONFESSIONS:
		check(all.has(id) and VoiceLines.fixed(id) != "", "%s is placed and written" % id)
	var said: Array[String] = []
	var record := func(line_id: String, _text: String) -> void: said.append(line_id)
	Narrator.line_spoken.connect(record)
	level.player.position = Iso.cell_center(Vector2i(23, 31))
	await wait_physics_frames(3)
	check(all["spire_bridge"].said, "the bridge, as you step off the landing")
	check(said.has("spire_bridge"), "aloud")
	check_eq(all["spire_bridge"].written(), VoiceLines.fixed("spire_bridge"), "and in the glass")
	check_false(all["spire_feed"].said, "the rest wait for you")
	level.player.position = Iso.cell_center(Vector2i(24, 33))
	await wait_physics_frames(3)
	level.player.position = Iso.cell_center(Vector2i(23, 31))
	await wait_physics_frames(3)
	check_eq(said.count("spire_bridge"), 1, "once")
	Narrator.line_spoken.disconnect(record)


func test_muted_you_can_still_read_it() -> void:
	await _open()
	Steward.set_voice(false)
	await wait_physics_frames(2)
	var said: Array[String] = []
	var record := func(line_id: String, _text: String) -> void: said.append(line_id)
	Narrator.line_spoken.connect(record)
	level.player.position = Iso.cell_center(Vector2i(18, 26))
	await wait_physics_frames(3)
	var feed := _confessions()["spire_feed"]
	check(feed.said and not said.has("spire_feed"), "not aloud: it isn't listening")
	check_eq(feed.written(), VoiceLines.fixed("spire_feed"), "but written in the glass all the same")
	Narrator.line_spoken.disconnect(record)


func test_its_chatter_waits_while_it_says_what_it_did() -> void:
	await _open()
	level.player.position = Iso.cell_center(Vector2i(6, 7))
	await wait_physics_frames(3)
	var need := _confessions()["spire_need"]
	check(need.said and Sound.voice_line == "spire_need", "what it needs from you, being said")
	check_eq(Narrator.notify(&"reliquary_near", "spire"), "", "the Reliquary's line waits")
	check_eq(Narrator.notify(&"idle", "spire"), "", "and so does anything else")
	check_eq(Sound.voice_line, "spire_need", "heard out in full")
	Sound.hush()
	check_false(Narrator.in_full_in_progress(), "once it's over, nothing waits on it")


## Walking straight on, the next confession waits its turn rather than cutting the last one off; nothing
## else it says (another line, a screen's voice-over) cuts in either. Leaving drops what's still waiting.
func test_walking_on_it_queues_what_it_says_next() -> void:
	await _open()
	level.player.position = Iso.cell_center(Vector2i(6, 10))
	await wait_physics_frames(3)
	check_eq(Sound.voice_line, "spire_quiet", "the Quiet, being said")
	level.player.position = Iso.cell_center(Vector2i(6, 7))
	await wait_physics_frames(3)
	var need := _confessions()["spire_need"]
	check(need.said and need.written() != "", "the next one's written in the glass at once")
	check_eq(Sound.voice_line, "spire_quiet", "but not said over the last")
	check_eq(Narrator.queued(), ["spire_need"] as Array[String], "it waits its turn")
	check_false(Narrator.voice_over(VoiceLines.core_line("spire_power_steward")), "a screen's voice-over gives way")
	check_false(Narrator.say_fixed("commons_note"), "so does any other line")
	check_eq(Sound.voice_line, "spire_quiet")
	Sound.hush()
	await wait_frames(2)
	check_eq(Sound.voice_line, "spire_need", "then it's said, in full")
	check(Narrator.queued().is_empty())
	level.player.position = Iso.cell_center(Vector2i(23, 31))
	await wait_physics_frames(3)
	check(Narrator.queued().has("spire_bridge"), "the bridge, waiting")
	level.queue_free()
	level = null
	await wait_frames(2)
	check(Narrator.queued().is_empty(), "leaving drops what's still waiting")
