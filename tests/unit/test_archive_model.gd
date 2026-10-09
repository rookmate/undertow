extends TestCase
## The Archive's rules: what is listed, in what order, and when trust moves.


func before_each() -> void:
	GameState.new_run()


func _carry(picks: Array[String]) -> void:
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var offer := CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run)
	CoreChoice.apply(ContentIds.LEVEL_VELLUM, offer, picks)


func test_every_log_is_listed_recovered_first() -> void:
	var picks: Array[String] = ["vellum_power_lattice", ContentIds.CORE_TRUTH_STACKS]
	_carry(picks)
	var entries := ArchiveModel.entries(GameState.run)
	check_eq(entries.size(), ContentDb.log_ids().size(), "one entry per log")
	var seen_unrecovered := false
	for e: ArchiveModel.Entry in entries:
		if e.state == ArchiveModel.State.UNRECOVERED:
			seen_unrecovered = true
		else:
			check_false(seen_unrecovered, "recovered entries come before unrecovered ones")
	var unlocked := entries.filter(func(e: ArchiveModel.Entry) -> bool: return e.state == ArchiveModel.State.UNLOCKED)
	check_eq(unlocked.size(), 2)
	check_eq((unlocked[0] as ArchiveModel.Entry).kind, "comforting", "the Steward's own records first")


func test_left_behind_logs_are_unrecovered_and_cannot_be_replayed() -> void:
	var picks: Array[String] = ["vellum_power_lattice", "vellum_power_feed"]
	_carry(picks)
	var r := ArchiveModel.replay("log_0522_feed_adjustment")
	check(r.error != "", "the Harbor Bridge log stayed in the dark")
	check_eq(GameState.run.noor_trust, 0)


func test_trust_moves_only_on_the_first_replay() -> void:
	var picks: Array[String] = ["vellum_truth_0522", ContentIds.CORE_TRUTH_STACKS]
	_carry(picks)
	var def := ContentDb.memory_log("log_0522_feed_adjustment")
	var first := ArchiveModel.replay("log_0522_feed_adjustment")
	check(first.first_time)
	check_eq(GameState.run.noor_trust, int(def["noor"]["trust"]))
	check_eq(GameState.run.teo_trust, int(def["teo"]["trust"]))
	var again := ArchiveModel.replay("log_0522_feed_adjustment")
	check_false(again.first_time)
	check_eq(GameState.run.noor_trust, int(def["noor"]["trust"]), "replaying again changes nothing")


func test_absent_companions_do_not_react() -> void:
	var picks: Array[String] = ["vellum_truth_0522", ContentIds.CORE_TRUTH_STACKS]
	_carry(picks)
	GameState.set_present(RunState.WHO_TEO, false)
	ArchiveModel.replay("log_0522_feed_adjustment")
	check_eq(GameState.run.teo_trust, 0, "Teo isn't here to react")
	check(GameState.run.noor_trust != 0)


func test_every_log_has_a_record_and_both_reactions() -> void:
	for id: String in ContentDb.log_ids():
		var def := ContentDb.memory_log(id)
		check((def.get("record", []) as Array).size() >= 3, "%s has a decision record" % id)
		check(str(def.get("steward_now", "")) != "", "%s has the Steward's comment" % id)
		check(def.get("noor", {}).has("text") and def.get("teo", {}).has("text"), "%s has both reactions" % id)
		check(["comforting", "truth", "unindexed"].has(str(def.get("kind"))), "%s has a kind" % id)
