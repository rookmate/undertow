class_name FloorLayer
extends Node2D
## Draws every ground cell of a level once: wet cobble, flagstone pavement, the old quay, the stacks'
## paper-strewn floor, stairs and canal water. Placeholder shapes in the palette, at image 10's scale.

var grid: LevelGrid
var look: DistrictLook = DistrictLook.new()


func setup(level_grid: LevelGrid, district_look: DistrictLook) -> void:
	grid = level_grid
	look = district_look
	z_index = -20
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	for cell: Vector2i in grid.all_cells():
		var f := grid.floor_at(cell)
		match f:
			LevelGrid.Floor.COBBLE:
				_cobble(cell)
			LevelGrid.Floor.PAVEMENT, LevelGrid.Floor.RAILING:
				_flagstones(cell, look.pavement, 2)
			LevelGrid.Floor.LOW_WALL:
				_flagstones(cell, look.stone, 1)
			LevelGrid.Floor.OLD_QUAY:
				_flagstones(cell, look.stone, 2)
			LevelGrid.Floor.STACKS:
				_stacks_floor(cell)
			LevelGrid.Floor.STAIRS:
				_stairs(cell)
			LevelGrid.Floor.WATER:
				_water(cell)
			LevelGrid.Floor.CONCRETE:
				_flagstones(cell, look.stone.lightened(0.12), 1)
			LevelGrid.Floor.FOUNDATION:
				_foundation(cell)


func _rng(cell: Vector2i, salt: int = 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, salt))
	return rng


## Point inside a cell from fractional grid offsets (0..1, 0..1).
func _at(cell: Vector2i, u: float, v: float) -> Vector2:
	return Iso.grid_to_world(Vector2(cell.x + u, cell.y + v))


func _sub_diamond(cell: Vector2i, u0: float, v0: float, step: float, inset: float) -> PackedVector2Array:
	return PackedVector2Array([
		_at(cell, u0 + inset, v0 + inset), _at(cell, u0 + step - inset, v0 + inset),
		_at(cell, u0 + step - inset, v0 + step - inset), _at(cell, u0 + inset, v0 + step - inset),
	])


func _cobble(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.ground_a.darkened(0.35))
	var rng := _rng(cell)
	const N := 4
	var step := 1.0 / N
	for i: int in N:
		for j: int in N:
			var base := look.ground_a.lerp(look.ground_b, rng.randf())
			if rng.randf() < 0.18:
				base = base.lerp(look.ground_wet, 0.6)
			draw_colored_polygon(_sub_diamond(cell, i * step, j * step, step, 0.03), base)


func _flagstones(cell: Vector2i, tone: Color, n: int) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), tone.darkened(0.35))
	var rng := _rng(cell, 1)
	var step := 1.0 / n
	for i: int in n:
		for j: int in n:
			var c := tone.lerp(look.ground_wet, rng.randf() * 0.35)
			draw_colored_polygon(_sub_diamond(cell, i * step, j * step, step, 0.02), c)


func _stacks_floor(cell: Vector2i) -> void:
	_flagstones(cell, look.stone.darkened(0.25), 2)
	var rng := _rng(cell, 2)
	for k: int in rng.randi_range(1, 4):
		var u := rng.randf_range(0.15, 0.85)
		var v := rng.randf_range(0.15, 0.85)
		var s := rng.randf_range(0.08, 0.16)
		var sheet := PackedVector2Array([_at(cell, u, v), _at(cell, u + s, v), _at(cell, u + s, v + s * 0.8), _at(cell, u, v + s * 0.8)])
		draw_colored_polygon(sheet, Color(Palette.PAPER, rng.randf_range(0.25, 0.5)))


func _stairs(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.stone.darkened(0.3))
	for k: int in 5:
		var u := 0.1 + k * 0.18
		draw_line(_at(cell, u, 0.0), _at(cell, u, 1.0), Color(Palette.NEAR_BLACK, 0.55), 3.0, true)


## An unbuilt plot on the Ark: a darker slab with rebar stubs, waiting for a district's core.
func _foundation(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.stone.darkened(0.35))
	draw_colored_polygon(_sub_diamond(cell, 0.08, 0.08, 0.84, 0.0), look.stone.darkened(0.15))
	var rng := _rng(cell, 4)
	for k: int in 3:
		var p := _at(cell, rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8))
		draw_line(p, p + Vector2(0, -10), Palette.IRON_DARK, 2.0)


func _water(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.water)
	var rng := _rng(cell, 3)
	if rng.randf() < 0.55:
		var u := rng.randf_range(0.1, 0.7)
		var v := rng.randf_range(0.1, 0.9)
		draw_line(_at(cell, u, v), _at(cell, u + rng.randf_range(0.15, 0.3), v), Color(Palette.WATER_SHEEN, 0.7), 2.0, true)
