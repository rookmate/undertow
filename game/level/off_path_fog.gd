class_name OffPathFog
extends Node2D
## The Marrow, sitting on the places the Lattice doesn't reach. While the Steward listens, the
## unindexed cells sink into near-black (it has nothing to show you there); muted, the fog thins and
## what you carry, and what you find, shows through.

const VOICE_ON_ALPHA := 0.72
const MUTED_ALPHA := 0.22

var grid: LevelGrid
var _alpha: float = VOICE_ON_ALPHA
var _t: float = 0.0
var _cells: Array[Vector2i] = []


func setup(level_grid: LevelGrid) -> void:
	grid = level_grid
	z_index = -12
	for c: Vector2i in grid.all_cells():
		var f := grid.floor_at(c)
		if f == LevelGrid.Floor.STACKS or f == LevelGrid.Floor.OLD_QUAY or f == LevelGrid.Floor.STAIRS or f == LevelGrid.Floor.GRATING:
			_cells.append(c)


func _process(delta: float) -> void:
	_t += delta
	var target := VOICE_ON_ALPHA if Steward.voice_on else MUTED_ALPHA
	_alpha = move_toward(_alpha, target, delta * 1.2)
	queue_redraw()


func _draw() -> void:
	for c: Vector2i in _cells:
		var drift := 0.08 * sin(_t * 0.7 + c.x * 1.3 + c.y * 0.9)
		draw_colored_polygon(Iso.cell_diamond(c), Color(Palette.NEAR_BLACK, clampf(_alpha + drift, 0.0, 1.0)))
	# Slow wisps of fog over the island.
	for i: int in 6:
		if _cells.is_empty():
			break
		var c := _cells[(i * 7) % _cells.size()]
		var p := Iso.cell_center(c) + Vector2(sin(_t * 0.25 + i) * 60.0, cos(_t * 0.2 + i * 2.0) * 20.0)
		draw_colored_polygon(_wisp(p, 150.0, 40.0), Color(Palette.FOG, 0.05))


static func _wisp(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
