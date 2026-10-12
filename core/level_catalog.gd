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
## Noor and Teo join once this district (the end of Act 1) is done.
const COMPANIONS_JOIN_AFTER := "tideworks"

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
	"mercy": {
		"name": "Mercy General",
		"act": 2,
		# Act 2's districts open together once Act 1 is done, in any order (design/act-2.md).
		"after": ["tideworks"],
		"scene": "res://game/level/mercy_general.tscn",
		"map": "res://data/levels/mercy_general.txt",
		"restores": "clinic",
		"boss": "surgeon",
	},
	"greywater": {
		"name": "Greywater",
		"act": 2,
		"after": ["tideworks"],
		"scene": "res://game/level/greywater.tscn",
		"map": "res://data/levels/greywater.txt",
		"restores": "pumphouse",
		"boss": "lung",
	},
	"vellum": {
		"name": "The Vellum",
		"act": 2,
		# Act 2 opens after the Tideworks (design/act-1.md).
		"after": ["tideworks"],
		"scene": "res://game/level/vellum_street.tscn",
		"map": "res://data/levels/vellum_street.txt",
		"restores": "archive",
		"boss": "editor",
	},
	"harbor": {
		"name": "Harbor Ward",
		"act": 3,
		# Opens once two of Act 2's three are done; the third stays open, and optional (design/act-3.md).
		"after_any": ["mercy", "vellum", "greywater"],
		"after_count": 2,
		"scene": "res://game/level/harbor_ward.tscn",
		"map": "res://data/levels/harbor_ward.txt",
		"restores": "",
		# The Wardfolk wired their own: no Lattice anywhere in it but the ferry slip and the border.
		"lattice": false,
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

## Every boss in the game and what its fight needs on the map besides its 'B' and its weak point 'Z':
## how many lanes ('1', '2', '3', each a track of two cells or more).
const BOSSES: Dictionary[String, Dictionary] = {
	"conductor": {"lanes": 3},
	"crane": {"lanes": 0},
	"surgeon": {"lanes": 0},
	"lung": {"lanes": 0},
	"editor": {"lanes": 0},
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
		for p: String in grid.validate(false, has_lattice(level_id)) + grid.content_problems():
			problems.append("%s: %s" % [level_id, p])
		for c: Vector2i in grid.entity_ids:
			var id := grid.entity_ids[c]
			if placed_in.has(id) and placed_in[id] != level_id:
				problems.append("id %s is placed in both %s and %s" % [id, placed_in[id], level_id])
			placed_in[id] = level_id
		var broken := CoreChoice.offer_problem(level_id, ContentDb.reliquary(level_id))
		if broken != "":
			problems.append("%s: %s" % [level_id, broken])
		for p: String in boss_problems(boss_of(level_id), grid):
			problems.append("%s: %s" % [level_id, p])
	return problems


## Everything wrong between a district's boss ("" for none) and its map: the boss's 'B', its weak point
## 'Z' (the other way to win), its lanes (each a straight unbroken track: the carriage runs end to end),
## and barriers 'y', which only a boss's fall opens. With the barriers shut, the boss and its weak point
## must both be reachable from the start, or the fight could never begin and the barriers never open. A
## map that fails this never loads.
static func boss_problems(boss_id: String, grid: LevelGrid) -> PackedStringArray:
	var problems := PackedStringArray()
	var lanes := 0
	for digit: String in ["1", "2", "3"]:
		var n := grid.cells_with(digit).size()
		lanes += 1 if n > 0 else 0
		if n == 1:
			problems.append("lane '%s' is a single cell" % digit)
	if boss_id == "":
		for ch: String in ["B", "Z", "y"]:
			if not grid.cells_with(ch).is_empty():
				problems.append("'%s' on the map, but the district has no boss" % ch)
		if lanes > 0:
			problems.append("lanes on the map, but the district has no boss")
		return problems
	if not BOSSES.has(boss_id):
		problems.append("no boss called '%s' in the game" % boss_id)
		return problems
	if grid.cells_with("B").size() != 1:
		problems.append("the %s needs exactly one 'B', found %d" % [boss_id, grid.cells_with("B").size()])
	if grid.cells_with("Z").size() != 1:
		problems.append("the %s's weak point needs exactly one 'Z', found %d" % [boss_id, grid.cells_with("Z").size()])
	var wanted := int(BOSSES[boss_id]["lanes"])
	if lanes != wanted:
		problems.append("the %s needs %d lane%s ('1' to '%d'), found %d" % [boss_id, wanted, "" if wanted == 1 else "s", wanted, lanes])
	for digit: String in ["1", "2", "3"]:
		if not _straight_run(grid.cells_with(digit)):
			problems.append("lane '%s' isn't one straight, unbroken track" % digit)
	if not problems.is_empty():
		return problems
	var reach := grid.reachable_from(grid.start_cell(), false, "y")
	for marker: String in ["B", "Z"]:
		if not _within_reach(reach, grid.first(marker)):
			problems.append("with the barriers shut, the %s can't be reached from the start" % ("boss" if marker == "B" else "weak point"))
	return problems


## True for no cells, or cells in one row or column with no gaps.
static func _straight_run(cells: Array[Vector2i]) -> bool:
	if cells.is_empty():
		return true
	var same_row := cells.all(func(c: Vector2i) -> bool: return c.y == cells[0].y)
	var same_column := cells.all(func(c: Vector2i) -> bool: return c.x == cells[0].x)
	if not same_row and not same_column:
		return false
	var along: Array[int] = []
	for c: Vector2i in cells:
		along.append(c.x if same_row else c.y)
	return along.max() - along.min() + 1 == cells.size()


## The cell or one beside it is in `reach`.
static func _within_reach(reach: Dictionary[Vector2i, bool], cell: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if reach.has(cell + d):
			return true
	return false


## A district can be travelled to once every district before it ("after") is done, and enough of the
## ones it needs some of ("after_any", "after_count": Harbor Ward, after two of Act 2's three).
static func is_open(run: RunState, level_id: String) -> bool:
	if not has_level(level_id):
		return false
	for before: Variant in LEVELS[level_id].get("after", []):
		if not run.levels_completed.has(str(before)):
			return false
	var any: Array = LEVELS[level_id].get("after_any", [])
	var done := any.filter(func(d: Variant) -> bool: return run.levels_completed.has(str(d))).size()
	return done >= int(LEVELS[level_id].get("after_count", 0))


## Whether the Lattice reaches into a district at all (Harbor Ward's people wired their own).
static func has_lattice(level_id: String) -> bool:
	return bool(LEVELS.get(level_id, {}).get("lattice", true))


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
