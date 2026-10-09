extends TestCase
## Districts open in the world bible's order: each once every district before it is done.


func test_districts_open_in_order() -> void:
	var run := RunState.new()
	for id: String in LevelCatalog.LEVELS:
		var after: Array = LevelCatalog.LEVELS[id].get("after", [])
		check_eq(LevelCatalog.is_open(run, id), after.is_empty(), "%s is open at the start only if nothing comes before it" % id)
		for before: Variant in after:
			check(LevelCatalog.has_level(str(before)), "%s comes after %s, which exists" % [id, before])
	check_false(LevelCatalog.is_open(run, "nowhere"))
	check(LevelCatalog.open_districts(run).has(LevelCatalog.FIRST_LEVEL), "the first district is open on a new run")
	run.levels_completed.append(LevelCatalog.FIRST_LEVEL)
	check_false(LevelCatalog.open_districts(run).has(LevelCatalog.FIRST_LEVEL), "done districts aren't offered again")


func test_every_built_district_is_on_the_loop_map() -> void:
	var on_map: Array[String] = []
	for d: Dictionary in LevelCatalog.CITY:
		on_map.append(str(d["id"]))
		var at: Vector2 = d["at"]
		check(at.x >= 0.0 and at.x <= 1.0 and at.y >= 0.0 and at.y <= 1.0, "%s sits on the map" % d["id"])
	for id: String in LevelCatalog.LEVELS:
		check(on_map.has(id), "%s is on the Loop map" % id)
		check(LevelCatalog.act_of(id) >= 1, "%s belongs to an act" % id)


func test_old_saves_keep_the_slices_weapons_and_new_runs_start_with_what_the_act_gives() -> void:
	var v1 := {"version": 1, "location": "ark"}
	var old := RunState.from_dict(v1)
	check_eq(old.weapons_owned, WeaponDefs.SLICE_SET, "a vertical-slice save keeps all three weapons")
	var fresh := RunState.new()
	check_eq(fresh.weapons_owned, WeaponDefs.STARTING)
	fresh.weapons_owned = [WeaponDefs.BATON]
	fresh.scrap = 7
	fresh.upgrades = {"baton:tuned": 1}
	var back := RunState.from_dict(fresh.to_dict())
	check_eq(back.weapons_owned, [WeaponDefs.BATON])
	check_eq(back.scrap, 7)
	check_eq(back.upgrades, {"baton:tuned": 1})
	var odd := RunState.from_dict({"version": 2, "weapons_owned": ["spoon"], "scrap": -4, "upgrades": {"baton:tuned": 99}})
	check_eq(odd.weapons_owned, WeaponDefs.STARTING, "unknown weapons dropped; never nothing to fight with")
	check_eq(odd.scrap, 0)
	check_eq(odd.upgrades["baton:tuned"], Tunables.UPGRADE_LEVELS)


## A boss and its map are checked together: a fight that can't start (no lanes for the Conductor, no
## 'B', a boss the game doesn't have) would otherwise leave its barriers shut for good.
func test_a_boss_and_its_map_are_checked_together() -> void:
	var conductor := LevelGrid.parse("########\n#.B....#\n#.1111.#\n#.2222.#\n#.3333.#\n#.Z..P.#\n#..yyR.#\n########")
	check(LevelCatalog.boss_problems("conductor", conductor).is_empty(), "%s" % [LevelCatalog.boss_problems("conductor", conductor)])
	check_false(LevelCatalog.boss_problems("crane", conductor).is_empty(), "the crane has no lanes")
	check_false(LevelCatalog.boss_problems("", conductor).is_empty(), "a boss's markers on a map without one")
	check_false(LevelCatalog.boss_problems("tram", conductor).is_empty(), "no such boss")
	var no_lanes := LevelGrid.parse("#######\n#.B...#\n#.Z.P.#\n#..yyR#\n#######")
	check_eq(LevelCatalog.boss_problems("conductor", no_lanes).size(), 1, "the Conductor needs its lanes")
	check(LevelCatalog.boss_problems("crane", no_lanes).is_empty())
	var no_b := LevelGrid.parse("#######\n#.....#\n#.Z.P.#\n#..yyR#\n#######")
	check_eq(LevelCatalog.boss_problems("crane", no_b).size(), 1, "no 'B'")
	var no_z := LevelGrid.parse("#######\n#.B...#\n#...P.#\n#..yyR#\n#######")
	check_eq(LevelCatalog.boss_problems("crane", no_z).size(), 1, "no weak point: no second way to win")
	var plain := LevelGrid.parse("#####\n#P.R#\n#####")
	check(LevelCatalog.boss_problems("", plain).is_empty())


## Counting markers isn't enough: a fight the player can't get to, or a lane the carriage can't run
## along, is refused too.
func test_a_boss_must_be_a_fight_you_can_reach() -> void:
	# The Crane sealed in a chamber below, the Reliquary behind a barrier: the fight could never start.
	var sealed := LevelGrid.parse("#######\n#.P..R#\n#..yy.#\n#######\n#.B.Z.#\n#.....#\n#######")
	check_eq(LevelCatalog.boss_problems("crane", sealed).size(), 2, "%s" % [LevelCatalog.boss_problems("crane", sealed)])
	# A barrier across the only way to the boss.
	var walled := LevelGrid.parse("#########\n#.P.y.B.#\n#...#.Z.#\n#...#..R#\n#########")
	check_false(LevelCatalog.boss_problems("crane", walled).is_empty(), "the barrier shuts the way to it")
	# A Conductor lane broken in two, and one bent round a corner.
	var broken := LevelGrid.parse("########\n#.B....#\n#.11.1.#\n#.2222.#\n#.333..#\n#...3..#\n#.Z..P.#\n#..yyR.#\n########")
	var problems := LevelCatalog.boss_problems("conductor", broken)
	check(problems.size() == 2 and "\n".join(problems).contains("lane '1'") and "\n".join(problems).contains("lane '3'"), "%s" % [problems])
