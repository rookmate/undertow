class_name Overrides
extends RefCounted
## Standing orders the Steward must obey (brief, "Overrides"), signed in the Signal Room on the Ark. Each
## makes the game harder and unlocks the Steward's reasoning (its reply when you sign it, and when you
## revoke it). The orders are writer-editable content in data/overrides.json; their effects are code:
##   no_trap_warnings  Assists: no threat warnings
##   no_slowmo         Assists: no slowed time on a close dodge
##   let_me_aim        Assists: no aim assist
##   no_path           Assists: no predicted path (the map still works)
##   survivors_first   Operator: more damage taken while any of the Waiting are near
##   no_praise         Narrator: only facts and warnings, and its tone stops adapting

const PATH := "res://data/overrides.json"

const NO_TRAP_WARNINGS := "no_trap_warnings"
const NO_SLOWMO := "no_slowmo"
const LET_ME_AIM := "let_me_aim"
const NO_PATH := "no_path"
const SURVIVORS_FIRST := "survivors_first"
const NO_PRAISE := "no_praise"
## Every order with an effect in code, in the order the Signal Room lists them.
const IDS: Array[String] = [NO_TRAP_WARNINGS, NO_SLOWMO, LET_ME_AIM, NO_PATH, SURVIVORS_FIRST, NO_PRAISE]
## Near the Waiting with survivors_first signed, damage taken is multiplied by this.
const SURVIVORS_FIRST_DAMAGE := 1.25
const SURVIVORS_FIRST_TILES := 6.0

static var _defs: Dictionary = {}
static var errors: PackedStringArray = []


static func ensure_loaded() -> void:
	if not _defs.is_empty() or not errors.is_empty():
		return
	var json := JSON.new()
	var problems := PackedStringArray()
	if json.parse(FileAccess.get_file_as_string(PATH)) != OK or not json.data is Dictionary:
		problems.append("%s is not valid JSON" % PATH)
	else:
		_defs = validate((json.data as Dictionary).get("overrides", {}), problems)
	errors = problems
	for e: String in errors:
		Diagnostics.error("Overrides: %s" % e)


## Keeps only complete orders the game has an effect for, and reports the rest (and any missing).
static func validate(raw: Variant, problems: PackedStringArray) -> Dictionary:
	var out := {}
	if not raw is Dictionary:
		problems.append("'overrides' must be an object")
		return out
	for id: Variant in raw:
		var d: Variant = raw[id]
		if not IDS.has(str(id)):
			problems.append("%s: no such order in the game" % id)
			continue
		if not d is Dictionary:
			problems.append("%s must be an object" % id)
			continue
		var ok := true
		for key: String in ["order", "effect", "unlocks", "sign", "revoke"]:
			if not (d as Dictionary).get(key) is String or str(d[key]) == "":
				problems.append("%s: needs %s" % [id, key])
				ok = false
		var pip_count: Variant = (d as Dictionary).get("pips")
		if not (pip_count is float or pip_count is int) or int(pip_count) < 1 or int(pip_count) > 3:
			problems.append("%s: pips must be 1 to 3" % id)
			ok = false
		if ok:
			out[str(id)] = d
	for id: String in IDS:
		var reported := false
		for p: String in problems:
			reported = reported or p.begins_with(id)
		if not out.has(id) and not reported:
			problems.append("%s: missing" % id)
	return out


static func is_known(override_id: String) -> bool:
	ensure_loaded()
	return _defs.has(override_id)


static func order_text(override_id: String) -> String:
	return field(override_id, "order")


static func field(override_id: String, name: String) -> String:
	ensure_loaded()
	return str((_defs.get(override_id, {}) as Dictionary).get(name, ""))


static func pips(override_id: String) -> int:
	ensure_loaded()
	return int((_defs.get(override_id, {}) as Dictionary).get("pips", 0))


## How much harder the signed orders make the city: their pips over every order's.
static func difficulty(signed: Array[String]) -> Vector2i:
	var total := 0
	var on := 0
	for id: String in IDS:
		total += pips(id)
		if signed.has(id):
			on += pips(id)
	return Vector2i(on, total)


## The voice line ids of the Steward's replies.
static func reply_line(override_id: String, signed: bool) -> String:
	return "override_%s_%s" % [override_id, "sign" if signed else "revoke"]
