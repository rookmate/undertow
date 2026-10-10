class_name LevelGrid
extends RefCounted
## A level's layout, parsed from a text map in data/levels/ (legend at the top of each file). A map
## may rename its own characters to named tiles with '% <char> <tile>' lines (Tiles); the grid stores
## the tiles' internal codes, so the rest of the game never sees the map's own letters.

enum Floor { VOID, BUILDING, COBBLE, PAVEMENT, OLD_QUAY, STACKS, STAIRS, WATER, RAILING, LOW_WALL, CONCRETE, FOUNDATION, LAWN, STEPS, TIMBER, GRAVEL, TRACK, CARRIAGE, GANTRY, CAB, TILE, ASPHALT, STAFF, SEAWALL, LOW_STREET, KELP, GRATING, PARQUET }

const FLOOR_OF: Dictionary[String, Floor] = {
	" ": Floor.VOID, "#": Floor.BUILDING, "d": Floor.BUILDING, "m": Floor.BUILDING, "g": Floor.BUILDING,
	".": Floor.COBBLE, ",": Floor.PAVEMENT, ":": Floor.OLD_QUAY, "_": Floor.STACKS, "S": Floor.STAIRS,
	"~": Floor.WATER, "=": Floor.RAILING, "-": Floor.LOW_WALL,
	"L": Floor.PAVEMENT, "K": Floor.COBBLE, "t": Floor.COBBLE, "o": Floor.PAVEMENT, "|": Floor.STACKS,
	"P": Floor.COBBLE, "C": Floor.COBBLE, "R": Floor.COBBLE, "c": Floor.COBBLE, "k": Floor.COBBLE,
	"W": Floor.PAVEMENT, "w": Floor.STACKS, "T": Floor.STACKS, "U": Floor.STACKS,
	"n": Floor.CONCRETE, "G": Floor.CONCRETE, "a": Floor.CONCRETE, "N": Floor.CONCRETE, "Y": Floor.CONCRETE,
	"s": Floor.CONCRETE, "D": Floor.CONCRETE, "f": Floor.FOUNDATION, "A": Floor.BUILDING,
	"p": Floor.CONCRETE, "M": Floor.BUILDING, "e": Floor.CONCRETE, "I": Floor.BUILDING, "z": Floor.CONCRETE,
	# Kestrel Heights
	"l": Floor.BUILDING, "v": Floor.LAWN, "H": Floor.LAWN, "j": Floor.LAWN, "F": Floor.COBBLE, "Q": Floor.COBBLE,
	"X": Floor.COBBLE, "E": Floor.STEPS, "i": Floor.TIMBER, "q": Floor.GRAVEL, "b": Floor.TIMBER,
	# Bosses: a boss's own cell, its lanes (1, 2, 3), the signal box, the barrier that opens when it falls.
	"B": Floor.TRACK, "1": Floor.TRACK, "2": Floor.TRACK, "3": Floor.TRACK, "Z": Floor.COBBLE, "y": Floor.TRACK,
	# The Loop
	"h": Floor.CARRIAGE, "r": Floor.CARRIAGE, "u": Floor.GANTRY, "x": Floor.CAB, "J": Floor.CAB, "*": Floor.PAVEMENT,
	# The Tideworks
	"[": Floor.COBBLE, "]": Floor.COBBLE, "^": Floor.COBBLE, "V": Floor.OLD_QUAY, "O": Floor.COBBLE,
	# Named tiles (Tiles), reached through a map's own legend.
	Tiles.HOSPITAL_TILE: Floor.TILE, Tiles.ASPHALT: Floor.ASPHALT, Tiles.STAFF_FLOOR: Floor.STAFF,
	Tiles.PARTITION: Floor.TILE, Tiles.WARD_SEAL: Floor.TILE, Tiles.AMBULANCE: Floor.ASPHALT,
	Tiles.NURSE_DESK: Floor.STAFF, Tiles.STERILIZER: Floor.TILE, Tiles.HOSPITAL_WALL: Floor.BUILDING,
	Tiles.HOSPITAL_DOOR: Floor.BUILDING, Tiles.HOSPITAL_BED: Floor.TILE,
	Tiles.CLINIC: Floor.BUILDING, Tiles.CLINIC_DOOR: Floor.CONCRETE, Tiles.PUMPHOUSE: Floor.BUILDING,
	Tiles.PUMPHOUSE_DOOR: Floor.CONCRETE,
	Tiles.SEAWALL: Floor.SEAWALL, Tiles.LOW_STREET: Floor.LOW_STREET, Tiles.KELP: Floor.KELP,
	Tiles.MARROW: Floor.LOW_STREET, Tiles.GRATING: Floor.GRATING, Tiles.PUMP_WALL: Floor.BUILDING,
	Tiles.PUMP_DOOR: Floor.BUILDING, Tiles.TURBINE: Floor.WATER, Tiles.TIDE_GAUGE: Floor.LOW_STREET,
	Tiles.NEWSROOM_FLOOR: Floor.PARQUET, Tiles.NEWSROOM_DESK: Floor.PARQUET,
}
## Characters whose cell blocks movement.
## Lawns (and the hedges, planters and sprinklers on them) are the Steward's gardens: looked at, not
## walked on. The smart gate 'Q' is solid only while closed (SmartGate), so it isn't listed.
const SOLID := " #dmgAlMI~=-L|KtoRTvHjFbrJ*[^" + Tiles.PARTITION + Tiles.AMBULANCE + Tiles.NURSE_DESK \
	+ Tiles.HOSPITAL_WALL + Tiles.HOSPITAL_DOOR + Tiles.HOSPITAL_BED + Tiles.CLINIC + Tiles.PUMP_WALL \
	+ Tiles.PUMP_DOOR + Tiles.TURBINE + Tiles.TIDE_GAUGE + Tiles.PUMPHOUSE + Tiles.NEWSROOM_DESK
## People stand on these cells: walkable floor, but nothing should route through them.
const OCCUPIED := "WwNY"
## Placed things that need a stable id from an '@' line (people, caches, logs).
const NEEDS_ID := "WwTUV"

var size: Vector2i = Vector2i.ZERO
## Stable ids of placed things, from the map's '@ x,y id' lines.
var entity_ids: Dictionary[Vector2i, String] = {}
## Place hints from the map's '! x,y text' lines: shown near that cell ({action} becomes its key).
var hints: Dictionary[Vector2i, String] = {}
## Problems found while parsing (bad '@', '!' or '%' lines); validate() adds the rest.
var parse_errors: PackedStringArray = []
## The map's own legend: its characters renamed to named tiles' codes ('% <char> <tile>' lines).
var legend: Dictionary[String, String] = {}
var _rows: PackedStringArray = []


static func load_file(path: String) -> LevelGrid:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		Diagnostics.error("LevelGrid: could not read %s" % path)
	return parse(text)


static func parse(text: String) -> LevelGrid:
	var grid := LevelGrid.new()
	for line: String in text.split("\n"):
		var row := line.trim_suffix("\r")
		if row.begins_with(";"):
			continue
		if row.begins_with("@"):
			grid._parse_id_line(row)
			continue
		if row.begins_with("!"):
			grid._parse_hint_line(row)
			continue
		if row.begins_with("%"):
			grid._parse_legend_line(row)
			continue
		grid._rows.append(row)
	if not grid.legend.is_empty():
		for i: int in grid._rows.size():
			grid._rows[i] = grid._translated(grid._rows[i])
	while grid._rows.size() > 0 and grid._rows[grid._rows.size() - 1].strip_edges() == "":
		grid._rows.remove_at(grid._rows.size() - 1)
	var width := 0
	for row: String in grid._rows:
		width = maxi(width, row.length())
	for i: int in grid._rows.size():
		grid._rows[i] = grid._rows[i].rpad(width)
	grid.size = Vector2i(width, grid._rows.size())
	return grid


func _parse_id_line(line: String) -> void:
	var parts := line.substr(1).strip_edges().split(" ", false)
	var xy := parts[0].split(",") if parts.size() == 2 else PackedStringArray()
	if xy.size() != 2 or not xy[0].is_valid_int() or not xy[1].is_valid_int():
		parse_errors.append("bad id line '%s' (expected '@ x,y id')" % line)
		return
	entity_ids[Vector2i(xy[0].to_int(), xy[1].to_int())] = parts[1]


func _parse_hint_line(line: String) -> void:
	var rest := line.substr(1).strip_edges()
	var space := rest.find(" ")
	var xy := rest.substr(0, space).split(",") if space > 0 else PackedStringArray()
	if xy.size() != 2 or not xy[0].is_valid_int() or not xy[1].is_valid_int() or rest.substr(space + 1).strip_edges() == "":
		parse_errors.append("bad hint line '%s' (expected '! x,y text')" % line)
		return
	hints[Vector2i(xy[0].to_int(), xy[1].to_int())] = rest.substr(space + 1).strip_edges()


## '% <char> <tile>': in this map, <char> means the named tile (Tiles.BY_NAME).
func _parse_legend_line(line: String) -> void:
	var parts := line.substr(1).strip_edges().split(" ", false)
	if parts.size() != 2 or parts[0].length() != 1:
		parse_errors.append("bad legend line '%s' (expected '%% <char> <tile>')" % line)
		return
	var code := Tiles.code_of(parts[1])
	if code == "":
		parse_errors.append("legend line '%s': no tile called '%s'" % [line, parts[1]])
		return
	legend[parts[0]] = code


func _translated(row: String) -> String:
	var out := ""
	for i: int in row.length():
		out += legend.get(row[i], row[i])
	return out


func entity_id(cell: Vector2i) -> String:
	return entity_ids.get(cell, "")


## Everything wrong with this map, or nothing. A level refuses to load (and saves nothing) unless this
## is empty. `hub` maps start on 'p' and have no Reliquary; level maps start on 'P' and need one.
func validate(hub: bool) -> PackedStringArray:
	var problems := PackedStringArray(parse_errors)
	if size.x == 0 or size.y == 0:
		problems.append("the map is empty")
		return problems
	for c: Vector2i in all_cells():
		var ch := char_at(c)
		if not FLOOR_OF.has(ch):
			problems.append("unknown map character '%s' at %s" % [ch, c])
	var start_marker := "p" if hub else "P"
	if cells_with(start_marker).size() != 1:
		problems.append("needs exactly one start '%s', found %d" % [start_marker, cells_with(start_marker).size()])
	var seen: Dictionary[String, Vector2i] = {}
	for c: Vector2i in all_cells():
		if not NEEDS_ID.contains(char_at(c)):
			continue
		var id := entity_id(c)
		if id == "":
			problems.append("'%s' at %s has no '@' id line" % [char_at(c), c])
		elif seen.has(id):
			problems.append("id %s used at %s and %s" % [id, seen[id], c])
		else:
			seen[id] = c
	for c: Vector2i in entity_ids:
		if not NEEDS_ID.contains(char_at(c)):
			problems.append("'@' id line for %s, but nothing there needs an id" % c)
	if not hub and problems.is_empty():
		var reliquaries := cells_with("R")
		if reliquaries.size() != 1:
			problems.append("needs exactly one Reliquary 'R', found %d" % reliquaries.size())
		else:
			var reach := reachable_from(start_cell(), true)
			var door := false
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				door = door or reach.has(reliquaries[0] + d)
			if not door:
				problems.append("the Reliquary can't be reached along the Lattice from the start")
	return problems


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func char_at(cell: Vector2i) -> String:
	if not in_bounds(cell):
		return " "
	return _rows[cell.y][cell.x]


func floor_at(cell: Vector2i) -> Floor:
	return FLOOR_OF.get(char_at(cell), Floor.VOID)


## The content each placed thing names exists and is the right kind: a cache 'T' holds a truth core, a
## slip 'U' an unindexed log. People ('W', 'w') are only named; LevelCatalog.check keeps names unique.
func content_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	for c: Vector2i in entity_ids:
		var id := entity_ids[c]
		match char_at(c):
			"T":
				if not ContentDb.is_truth(id):
					problems.append("the cache at %s holds %s, which isn't a truth core" % [c, id])
			"U":
				if str(ContentDb.memory_log(id).get("kind", "")) != "unindexed":
					problems.append("the slip at %s holds %s, which isn't an unindexed log" % [c, id])
			"V":
				if not WeaponDefs.is_playable(id):
					problems.append("the find at %s is %s, which isn't a weapon in the game" % [c, id])
	return problems


## Unknown characters fail closed: solid, never accidental invisible floor.
func is_solid(cell: Vector2i) -> bool:
	var ch := char_at(cell)
	return not FLOOR_OF.has(ch) or SOLID.contains(ch)


func is_walkable(cell: Vector2i) -> bool:
	return not is_solid(cell)


func is_occupied(cell: Vector2i) -> bool:
	return OCCUPIED.contains(char_at(cell))


## The Lattice reaches this cell: it is lit, on the Steward's map and routable by its path.
func is_indexed(cell: Vector2i) -> bool:
	var f := floor_at(cell)
	return f == Floor.COBBLE or f == Floor.PAVEMENT or f == Floor.STEPS or f == Floor.TRACK or f == Floor.CARRIAGE or f == Floor.GANTRY \
		or f == Floor.TILE or f == Floor.ASPHALT or f == Floor.SEAWALL or f == Floor.LOW_STREET or f == Floor.KELP \
		or f == Floor.PARQUET


## Low enough to flood at high tide (Greywater's low streets, kelp and all).
func floods(cell: Vector2i) -> bool:
	var f := floor_at(cell)
	return (f == Floor.LOW_STREET or f == Floor.KELP) and is_walkable(cell)


## Under the thick Marrow: the Steward's hardware reaches it, but it can't see through.
func is_marrow(cell: Vector2i) -> bool:
	return char_at(cell) == Tiles.MARROW


## Tall things stop sight, swings and shots: buildings and tall props. Water, rails and low walls don't.
func blocks_line(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return is_building(cell) or "Kt|R".contains(char_at(cell))


## Grid-space parameter (0..1) along `from`→`to` where the segment first touches a blocking cell (0 if
## it starts inside one), or -1 if it never does. Walks every cell the segment crosses, exactly, so no
## speed or tick length can step over a wall or slip through a corner. A segment passing exactly through
## a cell corner touches both cells beside it.
func first_block(from: Vector2, to: Vector2) -> float:
	var cell := Vector2i(floori(from.x), floori(from.y))
	if blocks_line(cell):
		return 0.0
	var end := Vector2i(floori(to.x), floori(to.y))
	var d := to - from
	var step := Vector2i(int(signf(d.x)), int(signf(d.y)))
	var t_delta := Vector2(INF if d.x == 0.0 else absf(1.0 / d.x), INF if d.y == 0.0 else absf(1.0 / d.y))
	var t_max := Vector2(
		INF if d.x == 0.0 else (float(cell.x + (1 if d.x > 0.0 else 0)) - from.x) / d.x,
		INF if d.y == 0.0 else (float(cell.y + (1 if d.y > 0.0 else 0)) - from.y) / d.y)
	# Bounded by the cells between the ends, in case rounding never lands exactly on `end`.
	for i: int in absi(end.x - cell.x) + absi(end.y - cell.y) + 2:
		if cell == end:
			break
		var t := minf(t_max.x, t_max.y)
		if t > 1.0:
			break
		if t_max.x < t_max.y:
			cell.x += step.x
			t_max.x += t_delta.x
		elif t_max.y < t_max.x:
			cell.y += step.y
			t_max.y += t_delta.y
		else:
			if blocks_line(cell + Vector2i(step.x, 0)) or blocks_line(cell + Vector2i(0, step.y)):
				return t
			cell += step
			t_max += t_delta
		if blocks_line(cell):
			return t
	return -1.0


## Nothing tall between two screen positions on the ground. People never stand inside a blocking cell
## (their bodies collide with it), so the cells at the ends are checked like any other.
func line_clear(a: Vector2, b: Vector2) -> bool:
	return first_block(Iso.world_to_grid(a), Iso.world_to_grid(b)) < 0.0


func is_building(cell: Vector2i) -> bool:
	return floor_at(cell) == Floor.BUILDING


func cells_with(ch: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in size.y:
		var row := _rows[y]
		var x := row.find(ch)
		while x != -1:
			out.append(Vector2i(x, y))
			x = row.find(ch, x + 1)
	return out


## Where the Operator starts: 'P' on a level's lit street, 'p' on a hub's bare concrete.
func start_cell() -> Vector2i:
	var on_street := first("P")
	return on_street if on_street.x >= 0 else first("p")


func first(ch: String) -> Vector2i:
	var found := cells_with(ch)
	return found[0] if not found.is_empty() else Vector2i(-1, -1)


func all_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			out.append(Vector2i(x, y))
	return out


## Cells reachable on foot from `start` (4-neighbour flood fill), optionally only through indexed cells,
## with the map characters in `closed` treated as shut (a boss's barriers 'y' before it falls).
func reachable_from(start: Vector2i, indexed_only: bool = false, closed: String = "") -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n := c + d
			if seen.has(n) or not is_walkable(n) or (closed != "" and closed.contains(char_at(n))):
				continue
			if indexed_only and not is_indexed(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen


## Screen-space bounding box of every cell that isn't void, for camera limits.
func world_bounds() -> Rect2:
	var r := Rect2()
	var first_cell := true
	for c: Vector2i in all_cells():
		if floor_at(c) == Floor.VOID:
			continue
		for p: Vector2 in Iso.cell_diamond(c):
			if first_cell:
				r = Rect2(p, Vector2.ZERO)
				first_cell = false
			else:
				r = r.expand(p)
	return r
