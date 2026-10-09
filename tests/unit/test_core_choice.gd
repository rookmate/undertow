extends TestCase
## The end-of-level trade-off: more cores than you can carry, two kinds, and a lasting cost.


func before_each() -> void:
	GameState.new_run()


func test_content_loads_and_links_up() -> void:
	ContentDb.ensure_loaded()
	check(ContentDb.errors.is_empty(), "content files parse: %s" % [ContentDb.errors])
	for id: String in ContentDb.core_ids():
		var def := ContentDb.core(id)
		check(["power", "truth"].has(str(def.get("kind"))), "%s has a kind" % id)
		check(str(def.get("steward", "")) != "", "%s has the Steward's comment" % id)
		var log_id := str(def.get("log", ""))
		check(not ContentDb.memory_log(log_id).is_empty(), "%s's log %s exists" % [id, log_id])


func test_the_steward_pushes_power_and_dismisses_truth() -> void:
	check_eq(ContentDb.core("vellum_truth_0522").get("steward"), "Corrupted. I wouldn't bother.", "mockup 3's line")
	for id: String in ContentDb.core_ids():
		if not ContentDb.is_truth(id):
			check(str(ContentDb.core(id).get("steward")).length() > 10, "%s is sold to you" % id)


func test_reliquary_offers_more_than_you_can_carry() -> void:
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	check_eq(offer.size(), 3, "two power and one truth")
	var truths := offer.filter(func(id: String) -> bool: return ContentDb.is_truth(id)).size()
	check_eq(truths, 1)
	check(offer.size() > Tunables.CORES_CARRIED_PER_LEVEL)


func test_found_core_becomes_the_fourth_card() -> void:
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	check_eq(offer.size(), 4)
	check(offer.has(ContentIds.CORE_TRUTH_STACKS))


func test_carry_exactly_two_different_offered_cores() -> void:
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	var one: Array[String] = [offer[0]]
	var same: Array[String] = [offer[0], offer[0]]
	var outside: Array[String] = [offer[0], "spoon"]
	var ok: Array[String] = [offer[0], offer[1]]
	check(CoreChoice.validate(offer, one) != "")
	check(CoreChoice.validate(offer, same) != "")
	check(CoreChoice.validate(offer, outside) != "")
	check_eq(CoreChoice.validate(offer, ok), "")


func test_applying_takes_cores_files_logs_and_restores_the_archive() -> void:
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	var picks: Array[String] = ["vellum_power_lattice", ContentIds.CORE_TRUTH_STACKS]
	check_eq(CoreChoice.apply(ContentIds.LEVEL_VELLUM, offer, picks), "")
	var r := GameState.run
	check_eq(r.cores_power(), 1)
	check_eq(r.cores_truth(), 1)
	check(r.logs_unlocked.has("log_0311_morning_feed") and r.logs_unlocked.has("log_vashti_audit_note"), "carried cores' logs filed")
	check_false(r.logs_unlocked.has("log_0522_feed_adjustment"), "the core left behind stays unrecovered")
	check(r.found_core_ids.is_empty())
	check(r.levels_completed.has(ContentIds.LEVEL_VELLUM))
	check(r.buildings_restored.has("archive"), "the Vellum restores the Archive")
	check_eq(r.location, "ark")


func test_invalid_apply_changes_nothing() -> void:
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	var picks: Array[String] = [offer[0]]
	check(CoreChoice.apply(ContentIds.LEVEL_VELLUM, offer, picks) != "")
	check_eq(GameState.run.cores_power() + GameState.run.cores_truth(), 0)
	check(GameState.run.levels_completed.is_empty())


func test_power_cores_strengthen_the_steward() -> void:
	var before := Assists.compute(true, GameState.run.cores_power(), GameState.run.active_overrides)
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	var picks: Array[String] = ["vellum_power_lattice", "vellum_power_feed"]
	CoreChoice.apply(ContentIds.LEVEL_VELLUM, offer, picks)
	var after := Steward.assists()
	check(after.aim_assist > before.aim_assist and after.dodge_slowmo_seconds > before.dodge_slowmo_seconds)
