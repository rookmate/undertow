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


func test_a_districts_own_lines_win() -> void:
	var sel := LineSelector.load_file(VoiceLines.NARRATION_PATH)
	var rng := RandomNumberGenerator.new()
	for i: int in 30:
		rng.seed = i
		var line := sel.pick(&"level_enter", (i % 3) - 1.0, rng, "loop")
		check(line != null and line.level == "loop", "the Loop greets you in its own words, not the generic ones (%s)" % (line.id if line != null else "none"))
	var elsewhere := sel.pick(&"level_enter", 0.0, rng, "nowhere_built_yet")
	check(elsewhere != null and elsewhere.level == "", "a district with no lines of its own still gets one for anywhere")


const DISTRICTS: Array[String] = ["kestrel", "loop", "tideworks", "mercy", "greywater", "vellum"]
const REACTIVE: Array[StringName] = [&"kill", &"multi_kill", &"dodge_close", &"hurt", &"low_integrity", &"respawn", &"idle", &"checkpoint", &"path_left", &"path_returned", &"weapon_manual", &"voice_restored"]


## Every district you fight in has its own words for what you do there (not a generic pool): for each
## reactive event, and a deep pool for what you do most.
func test_every_district_has_its_own_words() -> void:
	for district: String in DISTRICTS:
		for event: StringName in REACTIVE:
			var own: Array = selector.lines_by_event.get(event, []).filter(func(l: LineSelector.Line) -> bool: return l.level == district)
			check(not own.is_empty(), "%s has its own %s lines" % [district, event])
		var kills: Array = selector.lines_by_event.get(&"kill", []).filter(func(l: LineSelector.Line) -> bool: return l.level == district)
		for tone: StringName in LineSelector.TONES:
			check(kills.filter(func(l: LineSelector.Line) -> bool: return l.tone == tone).size() >= 3, "%s: three kill lines or more for %s" % [district, tone])


## No line is heard twice until every line of its tone has been: the district's own first, then the
## lines for anywhere.
func test_nothing_repeats_until_its_tone_is_heard_out() -> void:
	selector.recent.clear()
	var rng := _rng(3)
	# The lines that can be said knowing nothing yet (none for what you've learned).
	var bold: Array = selector.lines_by_event.get(&"kill", []).filter(func(l: LineSelector.Line) -> bool: return l.tone == &"bold" and (l.level == "" or l.level == "loop") and LineSelector.fits(l, {}))
	var heard: Array[String] = []
	var own_done := false
	var guard := 0
	while heard.size() < bold.size() and guard < 400:
		guard += 1
		var l := selector.pick(&"kill", 1.0, rng, "loop")
		if l.tone != &"bold":
			continue
		check_false(heard.has(l.id), "%s heard again before the rest of the bold lines" % l.id)
		if l.level == "":
			own_done = true
		else:
			check_false(own_done, "the Loop's own lines come before the lines for anywhere (%s)" % l.id)
		heard.append(l.id)
	check_eq(heard.size(), bold.size(), "every bold kill line heard once")


## A district's entry, boss and Reliquary lines are its own when it has them, every time.
func test_who_it_is_there_is_its_own() -> void:
	for event: StringName in [&"level_enter", &"boss_engaged", &"reliquary_near"]:
		check(selector.own_only(event), "%s is the district's own" % event)
	check_false(selector.own_only(&"kill"))


## Back in a district you've done, it greets you as someone who's been before; the first time, never.
func test_a_revisit_is_greeted_as_one() -> void:
	var rng := _rng(9)
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "greywater", "vellum", "harbor"]:
		selector.recent.clear()
		var first := selector.pick(&"level_enter", 0.0, rng, district, &"", {"revisit": false})
		check(first != null and not first.when.get("revisit", false), "%s, first time: %s" % [district, first.id if first != null else "nothing"])
		selector.recent.clear()
		var again := selector.pick(&"level_enter", 0.0, rng, district, &"", {"revisit": true})
		check(again != null and again.level == district and again.when.get("revisit", false), "%s, again: its own revisit line (%s)" % [district, again.id if again != null else "nothing"])
	selector.recent.clear()
	var reliq := selector.pick(&"reliquary_near", 0.0, rng, "mercy", &"", {"revisit": true})
	check(reliq != null and reliq.when.get("revisit", false), "an opened Reliquary is spoken of as one (%s)" % (reliq.id if reliq != null else "nothing"))


## What it says changes with what you know: lines for truths carried and logs read come first, once.
func test_what_it_knows_you_know() -> void:
	selector.recent.clear()
	var rng := _rng(4)
	var before := selector.pick(&"idle", 0.0, rng, "loop", &"", {"truths": 0, "knows": []})
	check(before != null and before.when.is_empty(), "knowing nothing, an ordinary line")
	selector.recent.clear()
	var knows: Array[String] = ["log_0522_feed_adjustment"]
	var after := selector.pick(&"idle", 0.0, rng, "loop", &"", {"truths": 0, "knows": knows})
	check(after != null and after.id == "IDLE_KNOWS_BRIDGE", "having read the bridge record, it says so (%s)" % (after.id if after != null else "nothing"))
	var next := selector.pick(&"idle", 0.0, rng, "loop", &"", {"truths": 0, "knows": knows})
	check(next != null and next.id != "IDLE_KNOWS_BRIDGE", "once")
	selector.recent.clear()
	var late := selector.pick(&"path_left", 0.0, rng, "loop", &"", {"truths": 6})
	check(late != null and late.when.has("truths_at_least"), "late in the game it stops pretending (%s)" % (late.id if late != null else "nothing"))


func test_every_when_is_real() -> void:
	for l: LineSelector.Line in selector.all_lines():
		if l.when.has("knows"):
			check(not ContentDb.memory_log(str(l.when["knows"])).is_empty(), "%s knows a real log (%s)" % [l.id, l.when["knows"]])


## A line for something you've come to know is said once: heard, it doesn't come round again while
## there's anything else to say.
func test_a_beat_is_said_once() -> void:
	selector.recent.clear()
	var rng := _rng(2)
	var knows: Array[String] = ["log_0522_feed_adjustment"]
	var heard: Array[String] = []
	for i: int in 12:
		var l := selector.pick(&"idle", 0.0, rng, "loop", &"neutral", {"knows": knows})
		heard.append(l.id)
	check_eq(heard.count("IDLE_KNOWS_BRIDGE"), 1, "the bridge, once in twelve (%s)" % [heard])


## Under "Stop praising me" (praise not allowed), its lines for what you know are facts and still said.
func test_what_it_knows_is_a_fact() -> void:
	selector.recent.clear()
	var knows: Array[String] = ["log_0522_feed_adjustment"]
	var facts: Array[StringName] = [LineSelector.FACT, LineSelector.WARNING]
	var l := selector.pick(&"idle", 0.0, _rng(5), "loop", &"neutral", {"knows": knows}, facts)
	check(l != null and l.id == "IDLE_KNOWS_BRIDGE", "the bridge, even with praise silenced (%s)" % (l.id if l != null else "nothing"))
	var plain := selector.pick(&"idle", 0.0, _rng(6), "loop", &"neutral", {}, facts)
	check(plain == null, "and no idle flattery")


## A beat heard is spent: under "Stop praising me", once the bridge has been said, standing still says
## nothing rather than the bridge again. A district's only revisit greeting still greets every revisit.
func test_a_spent_beat_leaves_silence() -> void:
	selector.recent.clear()
	var knows: Array[String] = ["log_0522_feed_adjustment"]
	var facts: Array[StringName] = [LineSelector.FACT, LineSelector.WARNING]
	var first := selector.pick(&"idle", 0.0, _rng(5), "loop", &"neutral", {"knows": knows}, facts)
	check(first != null and first.id == "IDLE_KNOWS_BRIDGE", "the bridge, once")
	for i: int in 4:
		var again := selector.pick(&"idle", 0.0, _rng(6 + i), "loop", &"neutral", {"knows": knows}, facts)
		check(again == null, "then nothing (%s)" % (again.id if again != null else ""))
	for i: int in 3:
		var hello := selector.pick(&"level_enter", 0.0, _rng(20 + i), "harbor", &"", {"revisit": true})
		check(hello != null and hello.id == "HARBOR_REVISIT_N1", "the Ward greets a revisit, every time")


## A line about how near it was (a kill up close, or at range) is said only when it saw that.
func test_it_says_how_near_only_when_it_saw() -> void:
	var close_lines: Array[String] = []
	var far_lines: Array[String] = []
	for l: LineSelector.Line in selector.all_lines():
		match str(l.when.get("reach", "")):
			"close": close_lines.append(l.id)
			"far": far_lines.append(l.id)
	check(close_lines.has("KILL_B2") and far_lines.has("KILL_C2"), "up close and at range are conditions")
	for seen: Dictionary in [{}, {"reach": "close"}, {"reach": "far"}]:
		selector.recent.clear()
		var rng := _rng(3)
		for i: int in 30:
			for lean: float in [1.0, -1.0]:
				for event: StringName in [&"kill", &"multi_kill"]:
					var l := selector.pick(event, lean, rng, "tideworks", &"", seen)
					check(l != null, "%s %s says something" % [event, seen])
					if l == null:
						continue
					var reach := str(seen.get("reach", ""))
					check(reach == "close" or not close_lines.has(l.id), "%s only up close (seen %s)" % [l.id, seen])
					check(reach == "far" or not far_lines.has(l.id), "%s only at range (seen %s)" % [l.id, seen])


## A line about a machine's job is said only for that machine: in each district with more than one kind,
## every kind gets something said, and never another kind's line.
func test_it_says_what_it_killed_only_when_it_was() -> void:
	var kinds_of: Dictionary[String, Array] = {
		"tideworks": ["custodian", "salvager"], "greywater": ["custodian", "salvager"],
		"vellum": ["custodian", "clerk"], "mercy": ["custodian", "sterilizer"],
		"loop": ["custodian", ""], "kestrel": ["custodian", ""],
	}
	for district: String in kinds_of:
		for kind: String in kinds_of[district]:
			selector.recent.clear()
			var rng := _rng(11)
			for i: int in 12:
				for event: StringName in [&"kill", &"multi_kill"]:
					# "": two of different kinds at once.
					var seen := {"kind": kind} if kind != "" else {}
					var l := selector.pick(event, 0.0, rng, district, &"neutral", seen)
					check(l != null, "%s: something for a %s" % [district, kind])
					if l != null:
						var said := str(l.when.get("kind", kind))
						check_eq(said, kind, "%s: %s is about a %s, not a %s" % [district, l.id, said, kind])
