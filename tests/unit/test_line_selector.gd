extends TestCase
## The Steward's line pools and the adaptive selection.

const PATH := "res://data/narration/steward_lines.json"

var selector: LineSelector


func before_each() -> void:
	selector = LineSelector.load_file(PATH)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_pool_loads_cleanly() -> void:
	check(selector.errors.is_empty(), "no errors: %s" % [selector.errors])
	check(selector.all_lines().size() >= 40, "a real pool of lines")


func test_every_declared_event_has_a_neutral_fallback() -> void:
	for event: StringName in selector.event_rules:
		var has_neutral := false
		for l: LineSelector.Line in selector.lines_by_event.get(event, []):
			if l.tone == &"neutral":
				has_neutral = true
		check(has_neutral, "%s has a neutral line" % event)


func test_every_line_belongs_to_a_declared_event() -> void:
	for l: LineSelector.Line in selector.all_lines():
		check(selector.event_rules.has(l.event), "%s's event %s is declared" % [l.id, l.event])


## World bible: "The Steward never says 'I decided.' It says 'it was determined.'"
func test_the_steward_never_says_i_decided() -> void:
	for l: LineSelector.Line in selector.all_lines():
		check_false(l.text.to_lower().contains("i decided"), "%s: %s" % [l.id, l.text])


func test_tone_weights_follow_the_lean() -> void:
	var flat := LineSelector.tone_weights(0.0)
	check(flat[&"neutral"] > flat[&"bold"] and flat[&"neutral"] > flat[&"cautious"], "undecided: mostly neutral")
	var risky := LineSelector.tone_weights(0.9)
	check(risky[&"bold"] > risky[&"neutral"] * 4.0 and risky[&"bold"] > risky[&"cautious"] * 4.0, "risk-takers hear boldness")
	var careful := LineSelector.tone_weights(-0.9)
	check(careful[&"cautious"] > careful[&"neutral"] * 4.0, "the careful hear caution")


func test_no_immediate_repeats_within_a_tone() -> void:
	var rng := _rng(7)
	var last_by_tone: Dictionary[StringName, String] = {}
	for i: int in 60:
		var l := selector.pick(&"kill", 0.0, rng)
		check(l.id != last_by_tone.get(l.tone, ""), "repeated %s straight after itself" % l.id)
		last_by_tone[l.tone] = l.id


func test_lean_drives_what_is_said() -> void:
	var bold := 0
	var cautious := 0
	var rng := _rng(11)
	for i: int in 120:
		var l := selector.pick(&"kill", 0.85, rng)
		if l.tone == &"bold":
			bold += 1
	var rng2 := _rng(11)
	selector.recent.clear()
	for i: int in 120:
		var l := selector.pick(&"kill", -0.85, rng2)
		if l.tone == &"cautious":
			cautious += 1
	check(bold > 72, "risky profile: mostly bold kill lines (%d/120)" % bold)
	check(cautious > 72, "cautious profile: mostly cautious kill lines (%d/120)" % cautious)


func test_unknown_event_says_nothing() -> void:
	check(selector.pick(&"made_tea", 0.0, _rng(1)) == null)


func test_bad_data_is_reported_not_crashed_on() -> void:
	var s := LineSelector.new()
	s.load_data({"lines": [{"id": "A", "event": "kill", "tone": "smug", "text": "x"}, {"id": "", "event": "kill", "text": "y"}, 5]})
	check(s.errors.size() == 3, "three problems reported: %s" % [s.errors])
	check(s.all_lines().is_empty())


func test_a_new_district_never_hears_another_districts_lines() -> void:
	var rng := _rng(5)
	for i: int in 60:
		var l := selector.pick(&"level_enter", 0.0, rng, "tideworks")
		check(l != null and not l.text.contains("Vellum"), "tideworks heard %s" % (l.id if l != null else "nothing"))
	var vellum_heard := false
	for i: int in 60:
		var l := selector.pick(&"level_enter", 0.0, rng, "vellum")
		vellum_heard = vellum_heard or l.level == "vellum"
	check(vellum_heard, "the Vellum still gets its own lines")


func test_every_event_has_a_neutral_line_for_anywhere() -> void:
	for event: StringName in selector.event_rules:
		var generic := false
		for l: LineSelector.Line in selector.lines_by_event.get(event, []):
			generic = generic or (l.tone == &"neutral" and l.level == "")
		check(generic, "%s works in any district" % event)
