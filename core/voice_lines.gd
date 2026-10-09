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


static func all() -> Dictionary[String, String]:
	var out: Dictionary[String, String] = {}
	var pools := LineSelector.load_file(NARRATION_PATH)
	for event: StringName in pools.lines_by_event:
		for line: LineSelector.Line in pools.lines_by_event[event]:
			out[line.id] = line.text
	for id: String in _fixed_lines():
		out[id] = str(_fixed_lines()[id])
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
	return str(_fixed_lines().get(id, ""))


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
			_fixed = (json.data as Dictionary).get("lines", {})
		else:
			Diagnostics.error("VoiceLines: %s is not valid JSON" % FIXED_PATH)
	return _fixed
