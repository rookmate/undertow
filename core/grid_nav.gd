class_name GridNav
extends RefCounted
## A* over a level's cells. `allow` decides which cells can be walked: enemies use every walkable
## cell; the Steward's predicted path only uses cells the Lattice reaches (step 3).

var astar: AStarGrid2D = AStarGrid2D.new()
var grid: LevelGrid


func _init(level_grid: LevelGrid, allow: Callable) -> void:
	grid = level_grid
	astar.region = Rect2i(Vector2i.ZERO, grid.size)
	astar.cell_size = Vector2.ONE
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for c: Vector2i in grid.all_cells():
		astar.set_point_solid(c, not bool(allow.call(c)))


func is_open(cell: Vector2i) -> bool:
	return astar.is_in_boundsv(cell) and not astar.is_point_solid(cell)


## Cells from `from` to `to`, both included. Empty if either end is closed or there is no route.
func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_open(from) or not is_open(to):
		return []
	return astar.get_id_path(from, to)
