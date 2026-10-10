class_name MarrowFog
extends Node2D
## The thick Marrow (Greywater): sea fog so dense the path lights are halos, sitting on the low streets
## by the channel. It's on the Lattice, but the Steward can't see through it: no path is drawn in it,
## with the voice on or off (PathPredictor), and its map leaves it blank. Pale, not dark: it's fog, not
## absence.

const ALPHA := 0.5

var cells: Array[Vector2i] = []
var _t: float = 0.0


func setup(fog_cells: Array[Vector2i]) -> void:
	cells = fog_cells
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for c: Vector2i in cells:
		var drift := 0.06 * sin(_t * 0.6 + c.x * 1.1 + c.y * 0.7)
		draw_colored_polygon(Iso.cell_diamond(c), Color(Palette.FOG, ALPHA * 0.5 + drift))
	for i: int in mini(cells.size(), 10):
		var c := cells[(i * 11) % cells.size()]
		var p := Iso.cell_center(c) + Vector2(sin(_t * 0.2 + i) * 70.0, cos(_t * 0.17 + i * 1.7) * 26.0 - 40.0)
		draw_colored_polygon(OffPathFog._wisp(p, 170.0, 54.0), Color(Palette.FOG, 0.12))
