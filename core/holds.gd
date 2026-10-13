class_name Holds
extends RefCounted
## Holds (design/deeper-districts.md): something people did by hand, done again while the Steward's
## machines come to stop you, and what it opens. The words and numbers from data/holds.json; the crank's
## place from its district's map ('@ x,y <hold id>'). Read-only; GameState records which are done.

const PATH := "res://data/holds.json"

static var _all: Dictionary = {}


static func _load() -> Dictionary:
	if _all.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var holds: Variant = (parsed as Dictionary).get("holds") if parsed is Dictionary else null
		if holds is Dictionary:
			_all = holds
		else:
			Diagnostics.error("Holds: %s is missing or malformed" % PATH)
	return _all


static func has(hold_id: String) -> bool:
	return _load().has(hold_id)


static func def(hold_id: String) -> Dictionary:
	var d: Variant = _load().get(hold_id)
	return d if d is Dictionary else {}


## How long it runs, all told (seconds of you being there).
static func seconds(hold_id: String) -> float:
	return float(def(hold_id).get("seconds", 30.0))


## Its waves, in order: each a list of enemy kinds (Level.spawn_kind).
static func waves(hold_id: String) -> Array:
	var w: Variant = def(hold_id).get("waves")
	return w if w is Array else []


## The passage it opens (its base name: "<name>_down" and "<name>_up" on the map).
static func opens(hold_id: String) -> String:
	return str(def(hold_id).get("opens", ""))


## The hold that keeps a passage shut ("" if none).
static func keeping(passage_name: String) -> String:
	for id: String in _load():
		if opens(id) == passage_name:
			return id
	return ""


static func text(hold_id: String, field: String) -> String:
	return str(def(hold_id).get(field, ""))


## Everything wrong with the holds, or nothing: each has its numbers, its words, waves of kinds there are.
static func problems() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in _load():
		var d := def(id)
		if seconds(id) <= 0.0:
			out.append("%s: no running time" % id)
		for field: String in ["verb", "doing", "locked", "opens"]:
			if str(d.get(field, "")) == "":
				out.append("%s: no %s" % [id, field])
		for wave: Variant in waves(id):
			if not wave is Array or (wave as Array).is_empty():
				out.append("%s: an empty wave" % id)
				continue
			for kind: Variant in wave:
				if not Level.ENEMY_KINDS.has(str(kind)):
					out.append("%s: no such enemy as %s" % [id, kind])
	return out
