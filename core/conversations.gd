class_name Conversations
extends RefCounted
## What Noor and Teo say about each Act 2 district, once, after you've been (and how you can answer),
## from data/companions/conversations.json. Read-only; GameState records which have been had.

const PATH := "res://data/companions/conversations.json"
## The answers, in the order they're offered: side with Noor, side with Teo, say nothing.
const SIDES: Array[String] = ["noor", "teo", "none"]

static var _all: Dictionary = {}


static func _load() -> Dictionary:
	if _all.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and (parsed as Dictionary).get("conversations") is Dictionary:
			_all = (parsed as Dictionary)["conversations"]
		else:
			Diagnostics.error("Conversations: %s is missing or malformed" % PATH)
	return _all


static func has(district: String) -> bool:
	return _load().has(district)


## A district's conversation ({} if it has none).
static func of(district: String) -> Dictionary:
	var c: Variant = _load().get(district, {})
	return c if c is Dictionary else {}


## One answer: {label, noor, teo, reply_noor, reply_teo} ({} if there's no such answer).
static func choice(district: String, side: String) -> Dictionary:
	var c: Variant = (of(district).get("choices", {}) as Dictionary).get(side, {})
	return c if c is Dictionary else {}


## Everything wrong with the conversations, or nothing: every Act 2 district has one, each with both
## lines and all three answers, each answer with its label, whole-number trust changes and both replies.
static func problems() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in LevelCatalog.LEVELS:
		if int(LevelCatalog.LEVELS[id].get("act", 0)) == 2 and not has(id):
			out.append("%s (Act 2) has no conversation" % id)
	for district: String in _load():
		if not LevelCatalog.has_level(district):
			out.append("a conversation about %s, which isn't a district" % district)
		var c := of(district)
		for who: String in ["noor", "teo"]:
			if str(c.get(who, "")).strip_edges() == "":
				out.append("%s: %s says nothing" % [district, who])
		for side: String in SIDES:
			var a := choice(district, side)
			if str(a.get("label", "")).strip_edges() == "":
				out.append("%s: the '%s' answer has no label" % [district, side])
			for who: String in ["noor", "teo"]:
				var v: Variant = a.get(who)
				if not (v is float and v == floorf(v)):
					out.append("%s: the '%s' answer's %s trust isn't a whole number" % [district, side, who])
				if str(a.get("reply_" + who, "")).strip_edges() == "":
					out.append("%s: %s doesn't reply to '%s'" % [district, who, side])
	return out
