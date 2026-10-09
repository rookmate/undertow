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

const FIRST_LEVEL := "kestrel"

## Playable districts. "after": districts that must be completed first (the world bible's acts).
const LEVELS: Dictionary[String, Dictionary] = {
	"kestrel": {
		"name": "Kestrel Heights",
		"act": 1,
		"after": [],
		"scene": "res://game/level/kestrel_heights.tscn",
		"map": "res://data/levels/kestrel_heights.txt",
		"restores": "",
	},
	"loop": {
		"name": "The Loop",
		"act": 1,
		"after": ["kestrel"],
		"scene": "res://game/level/loop_north.tscn",
		"map": "res://data/levels/loop_north.txt",
		"restores": "signal_room",
		"boss": "conductor",
	},
	"tideworks": {
		"name": "The Tideworks",
		"act": 1,
		"after": ["loop"],
		"scene": "res://game/level/tideworks.tscn",
		"map": "res://data/levels/tideworks.txt",
		"restores": "workshop",
		"boss": "crane",
	},
	"vellum": {
		"name": "The Vellum",
		"act": 2,
		# Act 2 opens after the Tideworks (design/act-1.md).
		"after": ["tideworks"],
		"scene": "res://game/level/vellum_street.tscn",
		"map": "res://data/levels/vellum_street.txt",
		"restores": "archive",
	},
}

## Every district of Meridian for the Loop map, built or not, with its place on the map (0..1 across and
## down: the hills north-west, the docks east, the sea south, the Ark in the estuary).
const CITY: Array[Dictionary] = [
	{"id": "kestrel", "name": "Kestrel Heights", "act": 1, "at": Vector2(0.27, 0.2)},
	{"id": "loop", "name": "The Loop", "act": 1, "at": Vector2(0.64, 0.16)},
	{"id": "tideworks", "name": "The Tideworks", "act": 1, "at": Vector2(0.84, 0.48)},
	{"id": "mercy", "name": "Mercy General", "act": 2, "at": Vector2(0.18, 0.5)},
	{"id": "vellum", "name": "The Vellum", "act": 2, "at": Vector2(0.36, 0.66)},
	{"id": "greywater", "name": "Greywater", "act": 2, "at": Vector2(0.56, 0.8)},
	{"id": "harbor", "name": "Harbor Ward", "act": 3, "at": Vector2(0.84, 0.78)},
	{"id": "spire", "name": "The Spire", "act": 3, "at": Vector2(0.5, 0.45)},
]
## Where the Ark sits on the Loop map.
const ARK_AT := Vector2(0.7, 0.94)


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


## A district can be travelled to once every district before it is done.
static func is_open(run: RunState, level_id: String) -> bool:
	if not has_level(level_id):
		return false
	for before: Variant in LEVELS[level_id].get("after", []):
		if not run.levels_completed.has(str(before)):
			return false
	return true


## Districts open and not yet done, in the order they're listed.
static func open_districts(run: RunState) -> Array[String]:
	var out: Array[String] = []
	for id: String in LEVELS:
		if is_open(run, id) and not run.levels_completed.has(id):
			out.append(id)
	return out


## The boss a district ends with ("" for none): its 'B' cell on the map.
static func boss_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("boss", ""))


static func act_of(level_id: String) -> int:
	return int(LEVELS.get(level_id, {}).get("act", 0))
