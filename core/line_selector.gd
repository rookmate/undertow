class_name LineSelector
extends RefCounted
## Picks the Steward's next line for an event (brief, "Adaptive narration"): lines live in tagged pools
## (event × tone) and the playstyle profile's lean decides which tone is likely. It drifts toward the
## voice the player most wants to hear: risk-takers get praise for boldness, the careful get praise for
## care. Recent lines aren't repeated.

const TONES: Array[StringName] = [&"bold", &"cautious", &"neutral"]
## What a line is for. Signed orders silence by purpose (Narrator.allows()).
const FACT := &"fact"
const WARNING := &"warning"
const PRAISE := &"praise"
const PURPOSES: Array[StringName] = [FACT, WARNING, PRAISE]
const RECENT_MEMORY := 8

class Line:
	var id: String
	var event: StringName
	var tone: StringName
	var text: String
	## District the line belongs to ("" = anywhere). A new district never hears another's lines.
	var level: String = ""

var lines_by_event: Dictionary[StringName, Array] = {}
var event_rules: Dictionary[StringName, Dictionary] = {}
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
## lean); inside that tone the least recently heard line is used, so lines don't repeat back to back
## while the drift toward the flattering tone stays strong even with small pools. A district's own lines
## win: if it has any for this event, only those are used (its entry line is its lie, and is heard);
## the lines for anywhere are for districts that have none.
func pick(event: StringName, lean: float, rng: RandomNumberGenerator, level: String = "", only_tone: StringName = &"") -> Line:
	var pool: Array = []
	var own: Array = []
	for l: Line in lines_by_event.get(event, []):
		if l.level == "":
			pool.append(l)
		elif l.level == level:
			own.append(l)
	if not own.is_empty():
		pool = own
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
	var options: Array = by_tone[chosen_tone]
	var fresh: Array[Line] = []
	for l: Line in options:
		if not recent.has(l.id):
			fresh.append(l)
	var line: Line
	if not fresh.is_empty():
		line = fresh[rng.randi() % fresh.size()]
	else:
		# Every line of this tone was heard recently: take the one heard longest ago.
		line = options[0]
		var oldest := recent.size()
		for l: Line in options:
			var at := recent.find(l.id)
			if at < oldest:
				oldest = at
				line = l
	recent.erase(line.id)
	recent.append(line.id)
	while recent.size() > RECENT_MEMORY:
		recent.remove_at(0)
	return line


func all_lines() -> Array[Line]:
	var out: Array[Line] = []
	for event: StringName in lines_by_event:
		for l: Line in lines_by_event[event]:
			out.append(l)
	return out
