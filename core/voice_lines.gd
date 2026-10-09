class_name VoiceLines
extends RefCounted
## Every line the Steward speaks, by stable id: its narration pools, its comment on each core card, its
## present-day comment on each memory log, and a few fixed lines. Each id names a voice file,
## assets/voice/<id>.ogg, built by tools/make_voice.py (placeholder text-to-speech until there's an actor).

const NARRATION_PATH := "res://data/narration/steward_lines.json"
const FIXED_PATH := "res://data/narration/steward_fixed.json"
const DIR := "res://assets/voice/"
## Ids become file names.
const SAFE_ID := "^[A-Za-z0-9_]+$"

static var _fixed: Dictionary = {}
static var _purposes: Dictionary[String, StringName] = {}


static func all() -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	var pools := LineSelector.load_file(NARRATION_PATH)
	for event: StringName in pools.lines_by_event:
		for line: LineSelector.Line in pools.lines_by_event[event]:
			out[line.id] = line.text
	for id: String in _fixed_lines():
		out[id] = fixed(id)
	for id: String in ContentDb.core_ids():
		out[core_line(id)] = str(ContentDb.core(id).get("steward", ""))
	for id: String in ContentDb.log_ids():
		out[log_line(id)] = str(ContentDb.memory_log(id).get("steward_now", ""))
	for id: String in Overrides.IDS:
		if Overrides.is_known(id):
			out[Overrides.reply_line(id, true)] = Overrides.field(id, "sign")
			out[Overrides.reply_line(id, false)] = Overrides.field(id, "revoke")
	return out


## A fixed line's text ("" if there's no such line).
static func fixed(id: String) -> String:
	return str((_fixed_lines().get(id, {}) as Dictionary).get("text", ""))


## What a fixed line is for (LineSelector.FACT, WARNING or PRAISE).
static func purpose(id: String) -> StringName:
	return StringName(str((_fixed_lines().get(id, {}) as Dictionary).get("purpose", "")))


## What any of the Steward's lines is for, by id, or &"" for an id that isn't one of its lines: a fixed
## line's own purpose, a pooled line's event's, and fact for its comments on cores and memory logs and
## its replies to orders (which never flatter).
static func purpose_of(id: String) -> StringName:
	if _purposes.is_empty():
		var pools := LineSelector.load_file(NARRATION_PATH)
		for event: StringName in pools.lines_by_event:
			for line: LineSelector.Line in pools.lines_by_event[event]:
				_purposes[line.id] = pools.purpose_of(event)
		for fixed_id: String in _fixed_lines():
			_purposes[fixed_id] = purpose(fixed_id)
		for core_id: String in ContentDb.core_ids():
			_purposes[core_line(core_id)] = LineSelector.FACT
		for log_id: String in ContentDb.log_ids():
			_purposes[log_line(log_id)] = LineSelector.FACT
		for order: String in Overrides.IDS:
			_purposes[Overrides.reply_line(order, true)] = LineSelector.FACT
			_purposes[Overrides.reply_line(order, false)] = LineSelector.FACT
	return _purposes.get(id, &"")


static func core_line(core_id: String) -> String:
	return "core_" + core_id


static func log_line(log_id: String) -> String:
	return "now_" + log_id


static func clip_path(id: String) -> String:
	return DIR + id + ".ogg"


static func has_clip(id: String) -> bool:
	return ResourceLoader.exists(clip_path(id))


static func _fixed_lines() -> Dictionary:
	if _fixed.is_empty():
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(FIXED_PATH)) == OK and json.data is Dictionary:
			var problems := PackedStringArray()
			_fixed = validate_fixed((json.data as Dictionary).get("lines", {}), problems)
			for p: String in problems:
				Diagnostics.error("VoiceLines: %s" % p)
		else:
			Diagnostics.error("VoiceLines: %s is not valid JSON" % FIXED_PATH)
	return _fixed


## Keeps the fixed lines that have a safe id, text and a known purpose; reports the rest.
static func validate_fixed(raw: Variant, problems: PackedStringArray) -> Dictionary:
	var out := {}
	if not raw is Dictionary:
		problems.append("'lines' must be an object")
		return out
	for id: Variant in raw:
		var d: Variant = raw[id]
		if RegEx.create_from_string(SAFE_ID).search(str(id)) == null:
			problems.append("%s: not a usable id" % id)
		elif not d is Dictionary or not (d as Dictionary).get("text") is String or str(d["text"]) == "":
			problems.append("%s: needs text" % id)
		elif not LineSelector.PURPOSES.has(StringName(str((d as Dictionary).get("purpose", "")))):
			problems.append("%s: purpose must be one of %s" % [id, LineSelector.PURPOSES])
		else:
			out[str(id)] = d
	return out
