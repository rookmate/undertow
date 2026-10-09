class_name LevelCatalog
extends RefCounted
## Every playable district and how it connects to the rest of the game: the scene that builds it and the
## Ark building its Reliquary restores. Adding a district means adding its map, scene and content and
## one entry here; routing, Continue and the core choice follow from it.
##
## Saved locations (RunState.location) name a district by id:
##   "loadout:<id>"    picking weapons for that district
##   "level:<id>"      inside it (Continue resumes at its loadout: weapons are picked before each level)
##   "reliquary:<id>"  its Reliquary opened, cores not chosen yet
##   "ark"             the hub

const FIRST_LEVEL := "vellum"

const LEVELS: Dictionary[String, Dictionary] = {
	"vellum": {
		"name": "The Vellum",
		"scene": "res://game/level/vellum_street.tscn",
		"restores": "archive",
	},
}


static func has_level(level_id: String) -> bool:
	return LEVELS.has(level_id)


static func scene_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("scene", ""))


static func name_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("name", level_id))


## The Ark building this district's Reliquary restores ("" if none).
static func restores(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("restores", ""))


## The district a saved location refers to ("" for the Ark or nothing).
static func level_in(location: String) -> String:
	var at := location.find(":")
	return location.substr(at + 1) if at >= 0 else ""
