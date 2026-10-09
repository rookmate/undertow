class_name Exploration
extends Node
## What the Operator has seen with their own eyes: walkable cells within a few tiles of where they've
## been. The muted "hand scan" map shows only these. Counts every walkable cell, including the ones the
## Steward never indexed, so the percentage is honest.

const SIGHT_TILES := 3

## Newly seen cells, so the map can redraw just the part that changed.
signal discovered(cells: Array[Vector2i])

var grid: LevelGrid
var explored: Dictionary[Vector2i, bool] = {}
var total_walkable: int = 0
var _last_cell: Vector2i = Vector2i(-999, -999)


func setup(level_grid: LevelGrid) -> void:
	grid = level_grid
	for c: Vector2i in grid.all_cells():
		if grid.is_walkable(c):
			total_walkable += 1


func observe(cell: Vector2i) -> void:
	if cell == _last_cell:
		return
	_last_cell = cell
	var fresh: Array[Vector2i] = []
	for dy: int in range(-SIGHT_TILES, SIGHT_TILES + 1):
		for dx: int in range(-SIGHT_TILES, SIGHT_TILES + 1):
			if absi(dx) + absi(dy) > SIGHT_TILES + 1:
				continue
			var c := cell + Vector2i(dx, dy)
			if grid.is_walkable(c) and not explored.has(c):
				explored[c] = true
				fresh.append(c)
	if not fresh.is_empty():
		discovered.emit(fresh)


func charted_ratio() -> float:
	if total_walkable == 0:
		return 0.0
	return float(explored.size()) / total_walkable
