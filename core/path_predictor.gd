class_name PathPredictor
extends RefCounted
## The Steward's predicted path (brief, "Predictive path rendering"): from where the Operator stands
## to where the Steward expects them to go, over the cells its Lattice reaches and nothing else.
## Exactly Tunables.PATH_TILES_AHEAD tiles are shown, all ahead of the Operator's feet. Off the
## Lattice the Steward can't see you, so there is no path.

## Path cells closer than this (in tiles) to the Operator count as underfoot and are skipped.
const UNDERFOOT_TILES := 0.6

var grid: LevelGrid
var nav: GridNav
var goal: Vector2i = Vector2i(-1, -1)
## The route the Steward has committed to. Kept while the Operator stays on it (so equal-cost
## alternatives don't make the tiles flicker), re-planned the moment they step off it.
var route: Array[Vector2i] = []


func _init(level_grid: LevelGrid) -> void:
	grid = level_grid
	nav = GridNav.new(grid, func(c: Vector2i) -> bool: return grid.is_indexed(c) and grid.is_walkable(c) and not grid.is_occupied(c))
	# Tiles meet edge to edge along the street, as in image 10: no diagonal steps.
	nav.astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav.astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav.astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	nav.astar.update()
	for c: Vector2i in grid.all_cells():
		nav.astar.set_point_solid(c, not (grid.is_indexed(c) and grid.is_walkable(c) and not grid.is_occupied(c)))


## Sets the destination to the open Lattice cell beside `target` that is quickest to reach from `from`.
func aim_at(target: Vector2i, from: Vector2i) -> void:
	var best := Vector2i(-1, -1)
	var best_len := 1 << 30
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var c := target + d
		if not nav.is_open(c):
			continue
		var p := nav.path(from, c)
		if not p.is_empty() and p.size() < best_len:
			best = c
			best_len = p.size()
	goal = best
	route = []


## The Lattice reaches this cell. Coverage is about hardware, not about whether a route can pass through
## the cell: a lamp post's cell is lit even though the route goes round the post.
func covers(cell: Vector2i) -> bool:
	return grid.is_indexed(cell)


## The next tiles ahead of an Operator standing at `world_position` (screen space). Never the cell
## under their feet, never one within UNDERFOOT_TILES of them, never more than `count`.
func predict(world_position: Vector2, count: int = Tunables.PATH_TILES_AHEAD) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var here := Iso.world_to_cell(world_position)
	if goal.x < 0 or not covers(here):
		return out
	var start := here if nav.is_open(here) else _nearest_open(here, world_position)
	if start.x < 0:
		return out
	var at := route.find(start)
	if at == -1:
		route = nav.path(start, goal)
		at = 0
	for i: int in range(at, route.size()):
		var c := route[i]
		if c == here or Iso.ground_distance(world_position, Iso.cell_center(c)) < UNDERFOOT_TILES:
			continue
		out.append(c)
		if out.size() >= count:
			break
	return out


## Standing in the open part of a cell the route can't use (a lamp post's corner, beside a resident):
## start from the open neighbour nearest the feet.
func _nearest_open(cell: Vector2i, world_position: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var n := cell + d
		if not nav.is_open(n):
			continue
		var dist := Iso.ground_distance(world_position, Iso.cell_center(n))
		if dist < best_d:
			best_d = dist
			best = n
	return best
