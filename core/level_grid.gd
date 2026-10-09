class_name LevelGrid
extends RefCounted
## A level's layout, parsed from a text map in data/levels/ (legend at the top of each file).

enum Floor { VOID, BUILDING, COBBLE, PAVEMENT, OLD_QUAY, STACKS, STAIRS, WATER, RAILING, LOW_WALL, CONCRETE, FOUNDATION }

const FLOOR_OF: Dictionary[String, Floor] = {
	" ": Floor.VOID, "#": Floor.BUILDING, "d": Floor.BUILDING, "m": Floor.BUILDING, "g": Floor.BUILDING,
	".": Floor.COBBLE, ",": Floor.PAVEMENT, ":": Floor.OLD_QUAY, "_": Floor.STACKS, "S": Floor.STAIRS,
	"~": Floor.WATER, "=": Floor.RAILING, "-": Floor.LOW_WALL,
	"L": Floor.PAVEMENT, "K": Floor.COBBLE, "t": Floor.COBBLE, "o": Floor.PAVEMENT, "|": Floor.STACKS,
	"P": Floor.COBBLE, "C": Floor.COBBLE, "R": Floor.COBBLE, "c": Floor.COBBLE, "k": Floor.COBBLE,
	"W": Floor.PAVEMENT, "w": Floor.STACKS, "T": Floor.STACKS, "U": Floor.STACKS,
	"n": Floor.CONCRETE, "G": Floor.CONCRETE, "a": Floor.CONCRETE, "N": Floor.CONCRETE, "Y": Floor.CONCRETE,
	"s": Floor.CONCRETE, "D": Floor.CONCRETE, "f": Floor.FOUNDATION, "A": Floor.BUILDING,
}
## Characters whose cell blocks movement.
const SOLID := " #dmgA~=-L|KtoRT"
## People stand on these cells: walkable floor, but nothing should route through them.
const OCCUPIED := "WwNY"

var size: Vector2i = Vector2i.ZERO
var _rows: PackedStringArray = []


static func load_file(path: String) -> LevelGrid:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("LevelGrid: could not read %s" % path)
	return parse(text)


static func parse(text: String) -> LevelGrid:
	var grid := LevelGrid.new()
	for line: String in text.split("\n"):
		var row := line.trim_suffix("\r")
		if row.begins_with(";"):
			continue
		grid._rows.append(row)
	while grid._rows.size() > 0 and grid._rows[grid._rows.size() - 1].strip_edges() == "":
		grid._rows.remove_at(grid._rows.size() - 1)
	var width := 0
	for row: String in grid._rows:
		width = maxi(width, row.length())
	for i: int in grid._rows.size():
		grid._rows[i] = grid._rows[i].rpad(width)
	grid.size = Vector2i(width, grid._rows.size())
	return grid


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func char_at(cell: Vector2i) -> String:
	if not in_bounds(cell):
		return " "
	return _rows[cell.y][cell.x]


func floor_at(cell: Vector2i) -> Floor:
	return FLOOR_OF.get(char_at(cell), Floor.VOID)


func is_solid(cell: Vector2i) -> bool:
	return SOLID.contains(char_at(cell))


func is_walkable(cell: Vector2i) -> bool:
	return not is_solid(cell)


func is_occupied(cell: Vector2i) -> bool:
	return OCCUPIED.contains(char_at(cell))


## The Lattice reaches this cell: it is lit, on the Steward's map and routable by its path.
func is_indexed(cell: Vector2i) -> bool:
	var f := floor_at(cell)
	return f == Floor.COBBLE or f == Floor.PAVEMENT


## Thrown and fired things stop at buildings and tall props, and fly over water, rails and low walls.
func blocks_projectiles(cell: Vector2i) -> bool:
	if not in_bounds(cell):
		return true
	return is_building(cell) or "Kt|R".contains(char_at(cell))


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


func first(ch: String) -> Vector2i:
	var found := cells_with(ch)
	return found[0] if not found.is_empty() else Vector2i(-1, -1)


func all_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in size.y:
		for x: int in size.x:
			out.append(Vector2i(x, y))
	return out


## Cells reachable on foot from `start` (4-neighbour flood fill), optionally only through indexed cells.
func reachable_from(start: Vector2i, indexed_only: bool = false) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n := c + d
			if seen.has(n) or not is_walkable(n):
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
