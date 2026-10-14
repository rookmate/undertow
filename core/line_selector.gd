class_name LineSelector
extends RefCounted
## Picks the Steward's next line for an event (brief, "Adaptive narration"): lines live in tagged pools
## (event × tone) and the playstyle profile's lean decides which tone is likely. It drifts toward the
## voice the player most wants to hear: risk-takers get praise for boldness, the careful get praise for
## care. A line isn't heard again until the rest of its tone has been (Bastion's rule: a repeat breaks
## the spell), and a district's own lines come first.

const TONES: Array[StringName] = [&"bold", &"cautious", &"neutral"]
## What a line is for. Signed orders silence by purpose (Narrator.allows()).
const FACT := &"fact"
const WARNING := &"warning"
const PRAISE := &"praise"
const PURPOSES: Array[StringName] = [FACT, WARNING, PRAISE]
const WHEN_KEYS: Array[String] = ["revisit", "truths_at_least", "knows", "reach"]

class Line:
	var id: String
	var event: StringName
	var tone: StringName
	var text: String
	## District the line belongs to ("" = anywhere). A new district never hears another's lines.
	var level: String = ""
	## What it's for, if not its event's (a line for what you know is a fact even among praise).
	var purpose: StringName = &""
	## When it can be said (empty: any time). "revisit": back in a district you've done (or not);
	## "truths_at_least": truth cores carried; "knows": a memory log you've read; "reach": how near the
	## thing it's about was when it saw it ("close" or "far": a kill up close, or at range).
	var when: Dictionary = {}

var lines_by_event: Dictionary[StringName, Array] = {}
var event_rules: Dictionary[StringName, Dictionary] = {}
## Every line heard this run, the most recent last (a line heard again moves to the end).
var recent: Array[String] = []
var errors: PackedStringArray = []


static func load_file(path: String) -> LineSelector:
	var s := LineSelector.new()
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		s.errors.append("%s is not valid JSON" % path)
		return s
	s.load_data(json.data)
	return s


func load_data(data: Dictionary) -> void:
	var rules: Variant = data.get("events", {})
	if rules is Dictionary:
		for key: Variant in rules:
			var rule: Variant = rules[key]
			event_rules[StringName(str(key))] = rule if rule is Dictionary else {}
			if not PURPOSES.has(purpose_of(StringName(str(key)))):
				errors.append("event %s has unknown purpose %s" % [key, purpose_of(StringName(str(key)))])
	var raw: Variant = data.get("lines", [])
	if not raw is Array:
		errors.append("'lines' must be an array")
		return
	var seen: Dictionary[String, bool] = {}
	for item: Variant in raw:
		if not item is Dictionary:
			errors.append("a line is not an object")
			continue
		var d: Dictionary = item
		var line := Line.new()
		line.id = str(d.get("id", ""))
		line.event = StringName(str(d.get("event", "")))
		line.tone = StringName(str(d.get("tone", "neutral")))
		line.text = str(d.get("text", ""))
		line.level = str(d.get("level", ""))
		line.purpose = StringName(str(d.get("purpose", "")))
		if line.purpose != &"" and not PURPOSES.has(line.purpose):
			errors.append("line %s has unknown purpose %s" % [line.id, line.purpose])
		var when: Variant = d.get("when", {})
		if not when is Dictionary:
			errors.append("line %s has a 'when' that isn't an object" % line.id)
			continue
		line.when = when
		for key: Variant in line.when:
			if not WHEN_KEYS.has(str(key)):
				errors.append("line %s: unknown 'when' %s" % [line.id, key])
		if line.when.has("reach") and not ["close", "far"].has(str(line.when["reach"])):
			errors.append("line %s: 'reach' is close or far, not %s" % [line.id, line.when["reach"]])
		if line.id == "" or line.text == "" or line.event == &"":
			errors.append("line %s is missing id, event or text" % line.id)
			continue
		if seen.has(line.id):
			errors.append("duplicate line id %s" % line.id)
			continue
		if not TONES.has(line.tone):
			errors.append("line %s has unknown tone %s" % [line.id, line.tone])
			continue
		seen[line.id] = true
		if not lines_by_event.has(line.event):
			lines_by_event[line.event] = []
		lines_by_event[line.event].append(line)


func cooldown_for(event: StringName) -> float:
	return float(event_rules.get(event, {}).get("cooldown", 6.0))


## What an event's lines are for (Narrator.FACT, WARNING or PRAISE): signed orders silence by purpose.
func purpose_of(event: StringName) -> StringName:
	return StringName(str(event_rules.get(event, {}).get("purpose", "fact")))


func is_priority(event: StringName) -> bool:
	return bool(event_rules.get(event, {}).get("priority", false))


## Whether a district's own lines for this event are the only ones it hears (its entry, boss and
## Reliquary lines: who it is there). Otherwise its own lines come first and the lines for anywhere follow.
func own_only(event: StringName) -> bool:
	return bool(event_rules.get(event, {}).get("own_only", false))


## How likely each tone is for a given lean (-1 all caution .. +1 all risk). At 0 the Steward is mostly
## neutral; as the profile leans, the matching flattery takes over.
static func tone_weights(lean: float) -> Dictionary[StringName, float]:
	var l := clampf(lean, -1.0, 1.0)
	return {
		&"bold": 0.2 + 1.6 * maxf(l, 0.0),
		&"cautious": 0.2 + 1.6 * maxf(-l, 0.0),
		&"neutral": 0.6 * (1.0 - absf(l)) + 0.05,
	}


## The next line for `event`, or null if there is none. The tone is chosen first (by the profile's
## lean); inside that tone, a line not heard yet this run, the district's own before the lines for
## anywhere; once the tone is heard out, the one heard longest ago. For an own_only event (a district's
## entry, boss and Reliquary lines) a district with lines of its own uses only those.
func pick(event: StringName, lean: float, rng: RandomNumberGenerator, level: String = "", only_tone: StringName = &"", context: Dictionary = {}, allowed: Array[StringName] = []) -> Line:
	var anywhere: Array = []
	var own: Array = []
	for l: Line in lines_by_event.get(event, []):
		if not fits(l, context):
			continue
		if not allowed.is_empty() and not allowed.has(purpose_of_line(l)):
			continue
		if l.level == "":
			anywhere.append(l)
		elif l.level == level:
			own.append(l)
	var pool: Array = own if not own.is_empty() and own_only(event) else own + anywhere
	# A line for something you've come to know is said once: heard, it's out of the pool, and if that
	# leaves nothing it says nothing. Except a district's own word for an own_only event (its only
	# greeting on a revisit): that comes round again.
	var unspent := pool.filter(func(l: Line) -> bool: return not (is_beat(l) and recent.has(l.id)))
	if not unspent.is_empty() or not own_only(event):
		pool = unspent
	if only_tone != &"" and pool.any(func(l: Line) -> bool: return l.tone == only_tone):
		pool = pool.filter(func(l: Line) -> bool: return l.tone == only_tone)
	if pool.is_empty():
		return null
	var weights := tone_weights(lean)
	var by_tone: Dictionary[StringName, Array] = {}
	var total := 0.0
	for l: Line in pool:
		if not by_tone.has(l.tone):
			by_tone[l.tone] = []
			total += weights[l.tone]
		by_tone[l.tone].append(l)
	var roll := rng.randf() * total
	var chosen_tone: StringName = by_tone.keys()[0]
	for tone: StringName in by_tone:
		roll -= weights[tone]
		if roll <= 0.0:
			chosen_tone = tone
			break
	# What you know now comes first: a line for it not heard yet, in the tone chosen if there is one.
	var beats: Array = pool.filter(func(l: Line) -> bool: return is_beat(l) and not recent.has(l.id))
	if not beats.is_empty():
		var in_tone := beats.filter(func(l: Line) -> bool: return l.tone == chosen_tone)
		var from: Array = in_tone if not in_tone.is_empty() else beats
		var beat: Line = from[rng.randi() % from.size()]
		recent.append(beat.id)
		return beat
	var options: Array = by_tone[chosen_tone]
	var fresh_own: Array[Line] = []
	var fresh: Array[Line] = []
	for l: Line in options:
		if not recent.has(l.id):
			fresh.append(l)
			if l.level != "":
				fresh_own.append(l)
	var line: Line
	if not fresh_own.is_empty():
		line = fresh_own[rng.randi() % fresh_own.size()]
	elif not fresh.is_empty():
		line = fresh[rng.randi() % fresh.size()]
	else:
		# Every line of this tone has been heard: the one heard longest ago.
		line = options[0]
		var oldest := recent.size()
		for l: Line in options:
			var at := recent.find(l.id)
			if at < oldest:
				oldest = at
				line = l
	recent.erase(line.id)
	recent.append(line.id)
	return line


## What a line is for: its own purpose, or its event's.
func purpose_of_line(line: Line) -> StringName:
	return line.purpose if line.purpose != &"" else purpose_of(line.event)


## A line for something you've come to know (back in a district, truths carried, a log read): said
## before the others, once.
static func is_beat(line: Line) -> bool:
	return line.when.has("truths_at_least") or line.when.has("knows") or bool(line.when.get("revisit", false))


## Whether a line can be said now (`context`: "revisit" bool, "truths" int, "knows" the logs read,
## "reach" what it saw: "close", "far" or nothing). A line about how near it was needs to have seen it.
static func fits(line: Line, context: Dictionary) -> bool:
	if line.when.has("reach") and str(context.get("reach", "")) != str(line.when["reach"]):
		return false
	if line.when.has("revisit") and bool(line.when["revisit"]) != bool(context.get("revisit", false)):
		return false
	if line.when.has("truths_at_least") and int(context.get("truths", 0)) < int(line.when["truths_at_least"]):
		return false
	if line.when.has("knows"):
		var known: Variant = context.get("knows", [])
		if not (known is Array and (known as Array).has(str(line.when["knows"]))):
			return false
	return true


func all_lines() -> Array[Line]:
	var out: Array[Line] = []
	for event: StringName in lines_by_event:
		for l: Line in lines_by_event[event]:
			out.append(l)
	return out
