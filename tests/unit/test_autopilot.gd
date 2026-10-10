extends TestCase
## The autopilot's scenarios and district routes: every scenario name it accepts makes a scenario, every
## district has a route (adding a district without one fails here), and the campaign's checks are each
## district's own.


func test_every_scenario_name_makes_a_scenario_and_nothing_else_does() -> void:
	for scenario_name: String in Autopilot.SCENARIOS:
		var plan := Autopilot.make_scenario(scenario_name, LevelCatalog.FIRST_LEVEL)
		check(plan != null, "%s is a scenario" % scenario_name)
		if plan != null:
			check_eq(plan.problem(), "", "%s is ready to run" % scenario_name)
			var expected := plan.expected()
			check(expected.has("save_isolated") and expected.has("title_shown"), "%s starts on the title" % scenario_name)
	for bad: String in ["", "nope", "../saves", "Campaign"]:
		check(Autopilot.make_scenario(bad) == null, "'%s' is refused" % bad)


func test_every_district_has_a_route() -> void:
	for id: String in LevelCatalog.LEVELS:
		var route := AutopilotRoute.for_district(id)
		check(route != null, "%s has an autopilot route" % id)
		if route == null:
			continue
		check_eq(route.id, id)
		route.long_run = true
		var names := route.checks()
		check(names.has("route_completed") and names.has("ark_reached"), "%s is played through to the Ark" % id)
		for c: String in names:
			check_eq(names.count(c), 1, "%s's check %s is listed once" % [id, c])
	check(AutopilotRoute.for_district("greywater") == null, "a district not built has no route")


func test_the_campaign_checks_each_district_by_name() -> void:
	var plan := Autopilot.make_scenario("campaign")
	plan.long_run = true
	var expected := plan.expected()
	for c: String in expected:
		check_eq(expected.count(c), 1, "%s is expected once" % c)
	for id: String in ["kestrel", "loop", "tideworks", "mercy", "vellum"]:
		check(expected.has(id + ":route_completed") and expected.has(id + ":ark_reached"), "%s, tagged" % id)
	check_false(expected.has("route_completed"), "no untagged district check a district could pass for another")
	check(expected.has("campaign_saved_and_continued") and expected.has("mercy:gauntlet_found"))


func test_a_prepared_run_is_only_what_the_districts_before_it_gave() -> void:
	var vellum := AutopilotRoute.for_district("vellum")
	vellum.prepare()
	var run := GameState.run
	for before: String in ["kestrel", "loop", "tideworks"]:
		check(run.levels_completed.has(before), "%s done" % before)
	check(run.weapons_owned.has(WeaponDefs.RIOT_DRONE), "the drone the Tideworks gave")
	check_false(run.weapons_owned.has(WeaponDefs.DEFIB), "the Gauntlet is the Vellum's own to find")
	check_eq(run.location, "loadout:vellum")
	GameState.new_run()
