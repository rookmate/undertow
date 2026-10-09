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
		"map": "res://data/levels/vellum_street.txt",
		"restores": "archive",
	},
}


static func has_level(level_id: String) -> bool:
	return LEVELS.has(level_id)


static func scene_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("scene", ""))


static func map_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("map", ""))


static func name_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("name", level_id))


## The Ark building this district's Reliquary restores ("" if none).
static func restores(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("restores", ""))


## The district a saved location refers to ("" for the Ark or nothing).
static func level_in(location: String) -> String:
	var at := location.find(":")
	return location.substr(at + 1) if at >= 0 else ""


## Every district's map and content, checked together before play (at boot, and by the tests).
static func check_all() -> PackedStringArray:
	var grids: Dictionary[String, LevelGrid] = {}
	for level_id: String in LEVELS:
		grids[level_id] = LevelGrid.load_file(map_of(level_id))
	return check(grids)


## Each map is sound and names real content; every placed thing's id is unique across all districts
## (rescues and finds are tracked by id across the run); every district's Reliquary is a real choice.
static func check(grids: Dictionary[String, LevelGrid]) -> PackedStringArray:
	var problems := PackedStringArray()
	var placed_in: Dictionary[String, String] = {}
	for level_id: String in grids:
		var grid := grids[level_id]
		for p: String in grid.validate(false) + grid.content_problems():
			problems.append("%s: %s" % [level_id, p])
		for c: Vector2i in grid.entity_ids:
			var id := grid.entity_ids[c]
			if placed_in.has(id) and placed_in[id] != level_id:
				problems.append("id %s is placed in both %s and %s" % [id, placed_in[id], level_id])
			placed_in[id] = level_id
		var broken := CoreChoice.offer_problem(level_id, ContentDb.reliquary(level_id))
		if broken != "":
			problems.append("%s: %s" % [level_id, broken])
	return problems
