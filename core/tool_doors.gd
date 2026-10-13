class_name ToolDoors
extends RefCounted
## Doors one of the Ark's tools opens (DECISIONS 188, design/deeper-districts.md): a Steward lock the
## Signal Jammer jams, a dead lift the Defib Gauntlet jolts back to life. You usually find one before you
## have its tool, and come back for what's behind it. The words and the tool from data/tool_doors.json;
## the door's place from its district's map ('@ x,y <door id>'). Read-only; GameState records which are
## open.

const PATH := "res://data/tool_doors.json"

static var _all: Dictionary = {}


static func _load() -> Dictionary:
	if _all.is_empty():
		var json := JSON.new()
		var doors: Variant = null
		if json.parse(FileAccess.get_file_as_string(PATH)) == OK and json.data is Dictionary:
			doors = (json.data as Dictionary).get("doors")
		if doors is Dictionary:
			_all = doors
		else:
			Diagnostics.error("ToolDoors: %s is missing or malformed" % PATH)
	return _all


static func has(door_id: String) -> bool:
	return _load().has(door_id)


static func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _load():
		out.append(id)
	return out


static func text(door_id: String, field: String) -> String:
	var d: Variant = _load().get(door_id)
	return str((d as Dictionary).get(field, "")) if d is Dictionary else ""


## The weapon you have to bring to open it.
static func tool(door_id: String) -> String:
	return text(door_id, "tool")


## The truth core behind it.
static func truth(door_id: String) -> String:
	return text(door_id, "truth")


## Everything wrong with the doors, or nothing: each has a real tool, its words and a truth behind it.
static func problems() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in _load():
		if not WeaponDefs.is_playable(tool(id)):
			out.append("%s: no such tool as %s" % [id, tool(id)])
		for field: String in ["verb", "locked", "bring"]:
			if text(id, field) == "":
				out.append("%s: no %s" % [id, field])
		if not ContentDb.is_truth(truth(id)):
			out.append("%s: %s isn't a truth core" % [id, truth(id)])
	return out
