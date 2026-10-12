class_name CommonsPeople
extends RefCounted
## The Commons' people (Harbor Ward's building on the Ark, design/act-3.md). With the Commons standing,
## the survivors you woke live there and each says something of their own, by where you woke them; and
## the Wardfolk who came over from the Ward, who never wore a Lanyard, talk about Noor. The words from
## data/companions/commons.json. Read-only.

const PATH := "res://data/companions/commons.json"
## Each district with people to wake has at least this many lines, so neighbours don't all say the same.
const MIN_LINES := 2

static var _all: Dictionary = {}


static func _load() -> Dictionary:
	if _all.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_all = parsed
		else:
			Diagnostics.error("CommonsPeople: %s is missing or malformed" % PATH)
	return _all


## Where a survivor was woken: their id's district ("loop_waiting_carriage_1" is the Loop's).
static func district_of(survivor_id: String) -> String:
	return survivor_id.get_slice("_", 0)


## What a survivor says, living in the Commons: one of their district's lines, always the same one for
## the same person ("" if their district has none).
static func survivor_line(survivor_id: String) -> String:
	var lines := _strings(_dict(_load().get("survivors")).get(district_of(survivor_id)))
	return lines[absi(hash(survivor_id)) % lines.size()] if not lines.is_empty() else ""


## What the k-th of the Wardfolk says: out in the Ward (`in_the_ward`), about the curfew and Noor going
## by; on the Ark, about Noor, home with you or staying in the Ward.
static func wardfolk_line(k: int, run: RunState, in_the_ward: bool = false) -> String:
	var key := "in_the_ward" if in_the_ward else ("noor_home" if run.noor_present else "noor_stayed")
	var lines := _strings(_dict(_load().get("wardfolk")).get(key))
	return lines[k % lines.size()] if not lines.is_empty() else ""


## Everything wrong with the words, or nothing: every district with someone to wake has its lines (at
## least MIN_LINES), and the Wardfolk have theirs either way Noor's turn went.
static func problems() -> PackedStringArray:
	var out := PackedStringArray()
	var survivors := _dict(_load().get("survivors"))
	for district: String in LevelCatalog.LEVELS:
		var map := FileAccess.get_file_as_string(LevelCatalog.map_of(district))
		if not map.contains(" %s_waiting_" % district):
			continue
		var n := _strings(survivors.get(district)).size()
		if n < MIN_LINES:
			out.append("%s: people to wake there, %d lines for them in the Commons (at least %d)" % [district, n, MIN_LINES])
	var wardfolk := _dict(_load().get("wardfolk"))
	for key: String in ["in_the_ward", "noor_home", "noor_stayed"]:
		if _strings(wardfolk.get(key)).size() < MIN_LINES:
			out.append("the Wardfolk need at least %d lines for %s" % [MIN_LINES, key])
	return out


static func _dict(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


static func _strings(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for s: Variant in v:
			if s is String and (s as String) != "":
				out.append(s)
	return out
