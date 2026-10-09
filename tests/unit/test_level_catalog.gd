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
