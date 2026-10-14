extends TestCase
## Adaptive narration end to end in the real level: the Steward watches play, the profile leans, and a
## risky replay sounds different from a cautious one (brief: "On a replay, different playstyles should
## produce noticeably different narration").

var level: Level
var heard: Array[String] = []


func _start_run() -> void:
	GameState.new_run()
	Narrator.reset_session()
	Narrator.seed_rng(1234)
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func _listen(_id: String, text: String) -> void:
	heard.append(text)


func before_each() -> void:
	heard.clear()
	Narrator.line_spoken.connect(_listen)


func after_each() -> void:
	Narrator.line_spoken.disconnect(_listen)
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)


## Kills a staged Custodian at `tiles` away, the way the baton or drone would.
func _kill_at(tiles: int) -> void:
	var c := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(0, -tiles), Custodian.MAX_INTEGRITY)
	c.take_hit(1000.0, Vector2(0, -1), 0.0, 0.0)
	await wait_frames(1)


## A run's worth of one playstyle, then the lines the Steward says about kills.
func _play(style: String) -> Array[String]:
	await _start_run()
	for i: int in 8:
		if style == "risky":
			await _kill_at(1)
		else:
			level.player.dodged.emit(Vector2(0, 1))
			await _kill_at(4)
	var lines: Array[String] = []
	for i: int in 30:
		Narrator.reset_session()
		var id := Narrator.notify(&"kill")
		if id != "":
			lines.append(id)
	return lines


func test_the_watch_feeds_the_profile_from_play() -> void:
	await _start_run()
	await _kill_at(1)
	check(GameState.run.playstyle_profile.risk > 0.0, "a close kill reads as risk")
	level.player.dodged.emit(Vector2(1, 0))
	check(GameState.run.playstyle_profile.caution > 0.0, "a dodge reads as caution")
	check(heard.size() >= 1, "and the Steward said something about it")


func test_muted_the_steward_is_not_listening() -> void:
	await _start_run()
	Steward.set_voice(false)
	await _kill_at(1)
	level.player.dodged.emit(Vector2(1, 0))
	check_eq(GameState.run.playstyle_profile.risk, 0.0)
	check_eq(GameState.run.playstyle_profile.caution, 0.0)
	check(Narrator.notify(&"kill") == "", "and says nothing")


func test_risky_and_cautious_replays_sound_different() -> void:
	var risky := await _play("risky")
	check(GameState.run.playstyle_profile.lean() > 0.4, "risky run leans bold (%.2f)" % GameState.run.playstyle_profile.lean())
	await after_each()
	Narrator.line_spoken.connect(_listen)
	var careful := await _play("cautious")
	check(GameState.run.playstyle_profile.lean() < -0.4, "cautious run leans careful (%.2f)" % GameState.run.playstyle_profile.lean())
	var share := func(ids: Array[String], prefix: String) -> float:
		return ids.filter(func(id: String) -> bool: return id.begins_with(prefix)).size() / float(ids.size())
	var risky_bold: float = share.call(risky, "KILL_B")
	var careful_bold: float = share.call(careful, "KILL_B")
	var risky_careful: float = share.call(risky, "KILL_C")
	var careful_careful: float = share.call(careful, "KILL_C")
	check(risky_bold > 0.6, "risky replay: %.0f%% bold lines" % (risky_bold * 100.0))
	check(careful_careful > 0.6, "cautious replay: %.0f%% careful lines" % (careful_careful * 100.0))
	check(risky_bold - careful_bold > 0.45 and careful_careful - risky_careful > 0.45, "the two replays sound noticeably different")


func test_leaving_the_lattice_is_noticed() -> void:
	await _start_run()
	level.player.position = Iso.cell_center(Vector2i(17, 27))
	await wait_frames(3)
	check(GameState.run.playstyle_profile.risk > 0.0, "stepping off the path reads as risk")
	var said: LineSelector.Line = null
	for l: LineSelector.Line in Narrator.selector.all_lines():
		if l.id == Narrator.last_line_id:
			said = l
	check(said != null and said.event == &"path_left", "and the Steward says so (%s)" % Narrator.last_line_id)


func test_a_new_run_starts_with_fresh_narration() -> void:
	await _start_run()
	Narrator.notify(&"kill")
	check(Narrator.tone_counts.values().reduce(func(a: int, b: int) -> int: return a + b, 0) > 0)
	GameState.new_run()
	check_eq(Narrator.tone_counts.values().reduce(func(a: int, b: int) -> int: return a + b, 0), 0, "counts reset")
	check(Narrator.selector.recent.is_empty(), "recent lines forgotten")
	check(Narrator.notify(&"kill") != "", "and nothing from the last run's cooldowns blocks it")


func test_the_muted_loadout_has_no_steward_line() -> void:
	Steward.set_voice(false)
	var screen := (load("res://ui/loadout/loadout.tscn") as PackedScene).instantiate() as Control
	add_child(screen)
	await wait_frames(2)
	var steward_line := false
	for n: Node in screen.find_children("*", "Label", true, false):
		steward_line = steward_line or (n as Label).text == VoiceLines.fixed("loadout_nudge")
	check_false(steward_line, "muted, the Steward says nothing on the loadout")
	screen.queue_free()
	Steward.set_voice(true)
