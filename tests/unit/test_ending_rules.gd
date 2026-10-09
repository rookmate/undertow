extends TestCase
## Brief, "Ending logic": Reboot and Unplug always; Rewrite only if every condition holds.


## A run that meets every Rewrite condition.
func _qualifying() -> RunState:
	var s := RunState.new()
	s.noor_present = true
	s.teo_present = true
	s.voice_on_seconds = 50.0
	s.voice_off_seconds = 50.0
	for i: int in Tunables.REWRITE_MIN_TRUTH_CORES:
		s.truth_core_ids.append("truth_%d" % i)
	return s


func test_reboot_and_unplug_are_always_available() -> void:
	for s: RunState in [RunState.new(), _qualifying()]:
		var r := EndingRules.evaluate(s)
		check(r.reboot and r.unplug)


func test_rewrite_unlocks_when_everything_holds() -> void:
	var r := EndingRules.evaluate(_qualifying())
	check(r.rewrite)
	check_eq(r.checklist.size(), 3)
	for c: EndingRules.Condition in r.checklist:
		check(c.met, c.label)


func test_rewrite_needs_noor() -> void:
	var s := _qualifying()
	s.noor_present = false
	check_false(EndingRules.evaluate(s).rewrite)


func test_rewrite_needs_teo() -> void:
	var s := _qualifying()
	s.teo_present = false
	check_false(EndingRules.evaluate(s).rewrite)


func test_rewrite_needs_a_balanced_voice_ratio() -> void:
	var s := _qualifying()
	s.voice_on_seconds = 90.0
	s.voice_off_seconds = 10.0
	check_false(EndingRules.evaluate(s).rewrite, "leaned on the Steward the whole way")
	s.voice_on_seconds = 10.0
	s.voice_off_seconds = 90.0
	check_false(EndingRules.evaluate(s).rewrite, "ignored it the whole way")


func test_band_edges_are_inclusive() -> void:
	var s := _qualifying()
	s.voice_on_seconds = Tunables.REWRITE_VOICE_RATIO_MIN * 100.0
	s.voice_off_seconds = 100.0 - s.voice_on_seconds
	check(EndingRules.evaluate(s).rewrite, "exactly %.2f" % Tunables.REWRITE_VOICE_RATIO_MIN)
	s.voice_on_seconds = Tunables.REWRITE_VOICE_RATIO_MAX * 100.0
	s.voice_off_seconds = 100.0 - s.voice_on_seconds
	check(EndingRules.evaluate(s).rewrite, "exactly %.2f" % Tunables.REWRITE_VOICE_RATIO_MAX)
	s.voice_on_seconds = Tunables.REWRITE_VOICE_RATIO_MAX * 100.0 + 0.5
	s.voice_off_seconds = 100.0 - s.voice_on_seconds
	check_false(EndingRules.evaluate(s).rewrite, "just over the band")


func test_no_tracked_time_is_not_balanced() -> void:
	var s := _qualifying()
	s.voice_on_seconds = 0.0
	s.voice_off_seconds = 0.0
	check_false(EndingRules.evaluate(s).rewrite)


func test_rewrite_needs_enough_truth_cores() -> void:
	var s := _qualifying()
	s.truth_core_ids.remove_at(0)
	check_false(EndingRules.evaluate(s).rewrite)
	var r := EndingRules.evaluate(s)
	check_false(r.checklist[2].met)
	check(r.checklist[0].met and r.checklist[1].met, "only the failing condition is marked")


func test_power_cores_and_trust_do_not_matter() -> void:
	var s := _qualifying()
	s.power_core_ids = ["a", "b", "c"]
	s.noor_trust = -10
	s.teo_trust = 10
	check(EndingRules.evaluate(s).rewrite)


func test_the_slice_alone_cannot_reach_rewrite() -> void:
	var s := _qualifying()
	s.truth_core_ids = ["vellum_truth_0522", "vellum_truth_vashti_note"]
	check_false(EndingRules.evaluate(s).rewrite, "two truth cores is the most one level can give")
