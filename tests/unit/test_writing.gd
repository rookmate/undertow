extends TestCase
## The writing keeps a few promises (design/writing-review.md): Noor and Teo are both meant to be right,
## so Teo doesn't spend the logs confessing; the Steward's lines don't say the same thing twice; and the
## Quiet happened at one time.


func test_teo_argues_as_well_as_confesses() -> void:
	var confessions := 0
	var total := 0
	for id: String in ContentDb.log_ids():
		var teo := str((ContentDb.memory_log(id).get("teo", {}) as Dictionary).get("text", ""))
		if teo == "":
			continue
		total += 1
		for tell: String in ["I signed off", "I was in the room", "That was me", "I wrote", "was mine"]:
			if teo.contains(tell):
				confessions += 1
				break
	check(total >= 40, "Teo has a word on the logs (%d)" % total)
	check(confessions * 4 <= total, "and mostly not a confession (%d of %d)" % [confessions, total])


## Its reactive lines (the narration pool) never say the same words twice.
func test_no_narration_line_is_said_twice() -> void:
	var seen: Dictionary[String, String] = {}
	for l: LineSelector.Line in Narrator.selector.all_lines():
		check_false(seen.has(l.text), "%s says the same as %s: %s" % [l.id, seen.get(l.text, ""), l.text])
		seen[l.text] = l.id


func test_the_quiet_was_at_two_fourteen() -> void:
	for id: String in ContentDb.log_ids():
		for line: String in ContentDb.memory_log(id).get("record", []):
			check_false(line.contains("03:14"), "%s: the Quiet was at 02:14 (%s)" % [id, line])
