extends TestCase
## Places the Steward remarks on (a map's '& x,y line_id'): each one of its fixed lines, on a lit path
## cell; said once a run when you come near while it's with you, never over another line, and not while
## you've muted it.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func test_every_place_is_a_line_on_the_path() -> void:
	var seen: Dictionary[String, String] = {}
	for district: String in LevelCatalog.LEVELS:
		var g := LevelGrid.load_file(LevelCatalog.map_of(district))
		check(g.parse_errors.is_empty(), "%s reads: %s" % [district, g.parse_errors])
		for c: Vector2i in g.places:
			var id := g.places[c]
			check(VoiceLines.fixed(id) != "", "%s: %s is one of its lines" % [district, id])
			check(g.is_walkable(c) and g.is_indexed(c), "%s: %s at %s is on the lit path" % [district, id, c])
			check_false(seen.has(id), "%s used once (also in %s)" % [id, seen.get(id, "")])
			seen[id] = district
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "greywater", "vellum"]:
		var n := LevelGrid.load_file(LevelCatalog.map_of(district)).places.size()
		check(n >= 5, "%s has places to remark on (%d)" % [district, n])


## Kestrel Heights, its entry line said and over.
func _open_kestrel() -> void:
	level = (load(LevelCatalog.scene_of("kestrel")) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_seconds(StewardWatch.ENTER_DELAY + Narrator.MIN_GAP + 0.5)
	Sound.hush()


func _first_place() -> Vector2i:
	for c: Vector2i in level.grid.places:
		if level.grid.places[c] == "place_kestrel_gate":
			return c
	return Vector2i(-1, -1)


func test_it_remarks_once_when_you_come_near() -> void:
	await _open_kestrel()
	var c := _first_place()
	check(c.x >= 0, "the gate is a place")
	var heard: Array[String] = []
	Narrator.line_spoken.connect(func(id: String, _t: String) -> void: heard.append(id))
	level.player.position = Iso.cell_center(c)
	await wait_physics_frames(4)
	check(heard.has("place_kestrel_gate"), "near it, the Steward says its line (%s)" % [heard])
	Sound.hush()
	level.player.position = Iso.cell_center(level.grid.start_cell())
	await wait_physics_frames(4)
	await wait_seconds(Narrator.MIN_GAP + 0.2)
	heard.clear()
	level.player.position = Iso.cell_center(c)
	await wait_physics_frames(4)
	check_false(heard.has("place_kestrel_gate"), "once a run")


func test_not_while_muted_and_not_over_another_line() -> void:
	await _open_kestrel()
	var c := _first_place()
	Steward.set_voice(false)
	level.player.position = Iso.cell_center(c)
	await wait_physics_frames(4)
	check_false(Narrator.selector.recent.has("place_kestrel_gate"), "muted, it isn't listening")
	Steward.set_voice(true)
	Narrator.speak_text("VOICE_BACK_N1", "There you are. I kept your place.", LineSelector.FACT)
	await wait_physics_frames(4)
	check_eq(Sound.voice_line, "VOICE_BACK_N1", "it doesn't talk over itself")
	check_false(Narrator.selector.recent.has("place_kestrel_gate"), "it waits")
	Sound.hush()
	await wait_seconds(Narrator.MIN_GAP + 0.2)
	await wait_physics_frames(4)
	check(Narrator.selector.recent.has("place_kestrel_gate"), "and says it into the silence after")
