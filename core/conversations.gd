class_name Conversations
extends RefCounted
## What Noor and Teo say about each Act 2 district, once, after you've been, and how you can answer:
## the words from data/companions/conversations.json, what an answer does to their trust from TRUST
## (a rule, DECISIONS 137, not content). Read-only; GameState records which have been had.

const PATH := "res://data/companions/conversations.json"
## The answers, in the order they're offered: side with Noor, side with Teo, say nothing.
const SIDES: Array[String] = ["noor", "teo", "none"]
## What each answer does to each of them: the one you side with +2, the other -1; nothing, nothing.
const TRUST: Dictionary[String, Dictionary] = {
	"noor": {"noor": 2, "teo": -1},
	"teo": {"noor": -1, "teo": 2},
	"none": {"noor": 0, "teo": 0},
}
## What every answer says (and each of them replies).
const ANSWER_FIELDS: Array[String] = ["label", "reply_noor", "reply_teo"]

static var _all: Dictionary = {}


static func _load() -> Dictionary:
	if _all.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		var all: Variant = (parsed as Dictionary).get("conversations") if parsed is Dictionary else null
		if all is Dictionary:
			_all = all
		else:
			Diagnostics.error("Conversations: %s is missing or malformed" % PATH)
	return _all


static func has(district: String) -> bool:
	return _load().has(district)


## How an answer moves one of them (0 for an answer that isn't on offer).
static func trust_change(side: String, who: String) -> int:
	return int((TRUST.get(side, {}) as Dictionary).get(who, 0))


## What Noor or Teo says about a district ("" if nothing).
static func line(district: String, who: String) -> String:
	var v: Variant = _dict(_load().get(district)).get(who)
	return v if v is String else ""


## One answer's words: its label, or one of their replies ("" if there are none).
static func answer_text(district: String, side: String, field: String) -> String:
	var choices := _dict(_dict(_load().get(district)).get("choices"))
	var v: Variant = _dict(choices.get(side)).get(field)
	return v if v is String else ""


## Everything wrong with the conversations, or nothing.
static func problems() -> PackedStringArray:
	return problems_in(_load())


## Everything wrong with a set of conversations (by district): every Act 2 district has one, about a
## real district, with both their lines and all three answers, each with its label and both replies,
## all of them text. Never fails on a malformed shape: it says what's wrong.
static func problems_in(all: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if not all is Dictionary:
		out.append("the conversations aren't a table by district")
		return out
	for id: String in LevelCatalog.LEVELS:
		if int(LevelCatalog.LEVELS[id].get("act", 0)) == 2 and not (all as Dictionary).has(id):
			out.append("%s (Act 2) has no conversation" % id)
	for district: Variant in all:
		var c: Variant = (all as Dictionary)[district]
		if not LevelCatalog.has_level(str(district)):
			out.append("a conversation about %s, which isn't a district" % district)
		if not c is Dictionary:
			out.append("%s: the conversation isn't a table" % district)
			continue
		for who: String in ["noor", "teo"]:
			if not _text((c as Dictionary).get(who)):
				out.append("%s: %s says nothing" % [district, who])
		var choices: Variant = (c as Dictionary).get("choices")
		if not choices is Dictionary:
			out.append("%s: its answers aren't a table" % district)
			continue
		for side: String in SIDES:
			var a: Variant = (choices as Dictionary).get(side)
			if not a is Dictionary:
				out.append("%s: the '%s' answer is missing" % [district, side])
				continue
			for field: String in ANSWER_FIELDS:
				if not _text((a as Dictionary).get(field)):
					out.append("%s: the '%s' answer has no %s" % [district, side, field])
	return out


static func _dict(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


static func _text(v: Variant) -> bool:
	return v is String and (v as String).strip_edges() != ""
