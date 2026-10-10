class_name ContentDb
extends RefCounted
## Writer-editable content: memory cores (data/cores/cores.json) and memory logs
## (data/logs/memory_logs.json). Validated on load: shapes, kinds, cross-references, and that every
## Reliquary offers more cores than can be carried. Invalid entries are dropped and reported (as engine
## errors, so the gate fails), never half-used.

const CORES_PATH := "res://data/cores/cores.json"
const LOGS_PATH := "res://data/logs/memory_logs.json"
const CORE_KINDS: Array[String] = ["power", "truth"]
const LOG_KINDS: Array[String] = ["comforting", "truth", "unindexed"]
## What a log may be about, besides its kind: "triage" records are the Clinic's too ("" for none).
const LOG_TOPICS: Array[String] = ["", "triage"]

static var _cores: Dictionary = {}
static var _reliquaries: Dictionary = {}
static var _logs: Dictionary = {}
static var _loaded: bool = false
static var errors: PackedStringArray = []


static func ensure_loaded() -> void:
	if _loaded:
		return
	var out := PackedStringArray()
	var loaded := validate_documents(_read(CORES_PATH, out), _read(LOGS_PATH, out), out)
	_cores = loaded["cores"]
	_reliquaries = loaded["reliquaries"]
	_logs = loaded["logs"]
	errors = out
	_loaded = true
	for e: String in errors:
		Diagnostics.error("ContentDb: %s" % e)


## Checks both documents and returns only what is valid: {cores, reliquaries, logs}. Problems are added
## to `problems`. Pure, so tests can feed it broken content.
static func validate_documents(cores_doc: Dictionary, logs_doc: Dictionary, problems: PackedStringArray) -> Dictionary:
	var logs := {}
	for need: Array in [[cores_doc, "cores"], [cores_doc, "reliquaries"], [logs_doc, "logs"]]:
		if not (need[0] as Dictionary).has(need[1]):
			problems.append("'%s' is missing" % need[1])
	var raw_logs: Variant = logs_doc.get("logs", {})
	if not raw_logs is Dictionary:
		problems.append("'logs' must be an object")
		raw_logs = {}
	for id: Variant in raw_logs:
		var clean := _clean_log(str(id), raw_logs[id], problems)
		if not clean.is_empty():
			logs[str(id)] = clean
	var cores := {}
	var raw_cores: Variant = cores_doc.get("cores", {})
	if not raw_cores is Dictionary:
		problems.append("'cores' must be an object")
		raw_cores = {}
	for id: Variant in raw_cores:
		var clean := _clean_core(str(id), raw_cores[id], logs, problems)
		if not clean.is_empty():
			cores[str(id)] = clean
	var reliquaries := {}
	var raw_rel: Variant = cores_doc.get("reliquaries", {})
	if not raw_rel is Dictionary:
		problems.append("'reliquaries' must be an object")
		raw_rel = {}
	for level: Variant in raw_rel:
		var list: Variant = raw_rel[level]
		if not list is Array:
			problems.append("reliquary %s must be a list of core ids" % level)
			continue
		var ids: Array[String] = []
		for id: Variant in list:
			if not cores.has(str(id)):
				problems.append("reliquary %s offers unknown core %s" % [level, id])
			elif not ids.has(str(id)):
				ids.append(str(id))
		if ids.size() <= Tunables.CORES_CARRIED_PER_LEVEL:
			# Dropped, not kept: a Reliquary that isn't a real choice must not complete a level.
			problems.append("reliquary %s offers %d cores; it must offer more than the %d you can carry" % [level, ids.size(), Tunables.CORES_CARRIED_PER_LEVEL])
			continue
		reliquaries[str(level)] = ids
	return {"cores": cores, "reliquaries": reliquaries, "logs": logs}


static func _clean_log(id: String, raw: Variant, problems: PackedStringArray) -> Dictionary:
	if not raw is Dictionary:
		problems.append("log %s must be an object" % id)
		return {}
	var d: Dictionary = raw
	var bad := func(why: String) -> Dictionary:
		problems.append("log %s: %s" % [id, why])
		return {}
	if not d.get("title") is String or str(d["title"]) == "":
		return bad.call("needs a title")
	if not LOG_KINDS.has(str(d.get("kind", ""))):
		return bad.call("kind must be one of %s" % [LOG_KINDS])
	var record: Variant = d.get("record")
	if not record is Array or (record as Array).is_empty() or not (record as Array).all(func(x: Variant) -> bool: return x is String):
		return bad.call("record must be a non-empty list of lines")
	if not d.get("steward_now") is String:
		return bad.call("needs the Steward's present-day comment")
	if not d.get("topic", "") is String or not LOG_TOPICS.has(str(d.get("topic", ""))):
		return bad.call("topic must be one of %s" % [LOG_TOPICS])
	var reactions := {}
	for who: String in ["noor", "teo"]:
		var r: Variant = d.get(who)
		if not r is Dictionary or not (r as Dictionary).get("text") is String or not ((r as Dictionary).get("trust") is float or (r as Dictionary).get("trust") is int):
			return bad.call("%s needs {text, trust}" % who)
		reactions[who] = {"text": str(r["text"]), "trust": int(r["trust"])}
	return {
		"title": str(d["title"]), "kind": str(d["kind"]), "core": str(d.get("core", "")),
		"record": record, "steward_now": str(d["steward_now"]), "noor": reactions["noor"], "teo": reactions["teo"],
		"topic": str(d.get("topic", "")),
	}


static func _clean_core(id: String, raw: Variant, logs: Dictionary, problems: PackedStringArray) -> Dictionary:
	if not raw is Dictionary:
		problems.append("core %s must be an object" % id)
		return {}
	var d: Dictionary = raw
	if not CORE_KINDS.has(str(d.get("kind", ""))):
		problems.append("core %s: kind must be power or truth" % id)
		return {}
	for field: String in ["name", "steward", "log"]:
		if not d.get(field) is String or str(d[field]) == "":
			problems.append("core %s: needs %s" % [id, field])
			return {}
	if not logs.has(str(d["log"])):
		problems.append("core %s: its log %s doesn't exist" % [id, d["log"]])
		return {}
	return {
		"kind": str(d["kind"]), "name": str(d["name"]), "origin": str(d.get("origin", "")),
		"blurb": str(d.get("blurb", "")), "steward": str(d["steward"]), "log": str(d["log"]),
	}


static func _read(path: String, problems: PackedStringArray) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		problems.append("%s is not valid JSON" % path)
		return {}
	return json.data


static func core(core_id: String) -> Dictionary:
	ensure_loaded()
	return _cores.get(core_id, {})


static func is_truth(core_id: String) -> bool:
	return str(core(core_id).get("kind", "")) == "truth"


static func core_ids() -> Array[String]:
	ensure_loaded()
	var out: Array[String] = []
	for k: Variant in _cores:
		out.append(str(k))
	return out


## The cores a level's Reliquary holds.
static func reliquary(level_id: String) -> Array[String]:
	ensure_loaded()
	var out: Array[String] = []
	for id: Variant in _reliquaries.get(level_id, []):
		out.append(str(id))
	return out


static func memory_log(log_id: String) -> Dictionary:
	ensure_loaded()
	return _logs.get(log_id, {})


static func log_ids() -> Array[String]:
	ensure_loaded()
	var out: Array[String] = []
	for k: Variant in _logs:
		out.append(str(k))
	return out
