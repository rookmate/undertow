class_name ContentDb
extends RefCounted
## Writer-editable content: memory cores (data/cores/cores.json) and memory logs
## (data/logs/memory_logs.json). Loaded once, read everywhere.

const CORES_PATH := "res://data/cores/cores.json"
const LOGS_PATH := "res://data/logs/memory_logs.json"

static var _cores: Dictionary = {}
static var _reliquaries: Dictionary = {}
static var _logs: Dictionary = {}
static var _loaded: bool = false
static var errors: PackedStringArray = []


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cores := _read(CORES_PATH)
	_cores = cores.get("cores", {})
	_reliquaries = cores.get("reliquaries", {})
	_logs = _read(LOGS_PATH).get("logs", {})


static func _read(path: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		errors.append("%s is not valid JSON" % path)
		return {}
	return json.data


static func core(core_id: String) -> Dictionary:
	ensure_loaded()
	var c: Variant = _cores.get(core_id, {})
	return c if c is Dictionary else {}


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
	var raw: Variant = _reliquaries.get(level_id, [])
	if raw is Array:
		for id: Variant in raw:
			out.append(str(id))
	return out


static func memory_log(log_id: String) -> Dictionary:
	ensure_loaded()
	var l: Variant = _logs.get(log_id, {})
	return l if l is Dictionary else {}


static func log_ids() -> Array[String]:
	ensure_loaded()
	var out: Array[String] = []
	for k: Variant in _logs:
		out.append(str(k))
	return out
