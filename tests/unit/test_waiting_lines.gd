extends TestCase
## Each of the Waiting has their own words when woken (data/companions/waiting.json): every one placed on
## a district's map, and no two the same.


func test_everyone_waiting_has_their_own_words() -> void:
	var seen: Dictionary[String, String] = {}
	for district: String in LevelCatalog.LEVELS:
		var g := LevelGrid.load_file(LevelCatalog.map_of(district))
		for c: Vector2i in g.cells_with("W") + g.cells_with("w"):
			var id := g.entity_id(c)
			var line := TheWaiting.woken_line(id)
			check_false(TheWaiting.WOKEN_LINES.has(line), "%s (%s) has a line of their own" % [id, district])
			check_false(seen.has(line), "%s says the same as %s" % [id, seen.get(line, "")])
			seen[line] = id
	check(seen.size() >= 20, "the Waiting all over the city (%d)" % seen.size())


func test_someone_unnamed_still_says_something() -> void:
	check(TheWaiting.WOKEN_LINES.has(TheWaiting.woken_line("nobody_on_any_map")))
