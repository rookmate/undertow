class_name FloorLayer
extends Node2D
## Draws the ground cells of a level once: wet cobble, flagstone pavement, the old quay, the stacks'
## paper-strewn floor, stairs and canal water. Placeholder shapes in the palette, at image 10's scale.
## A level's floor is a set of these, one per CHUNK × CHUNK block of cells (build()): Godot skips the
## ones off screen, so a big district costs no more to draw than what you can see.

## Cells a side in one block.
const CHUNK := 4

var grid: LevelGrid
var look: DistrictLook = DistrictLook.new()
## The cells this one draws (all of them, if empty).
var region: Rect2i = Rect2i()


## The level's whole floor, in blocks, added to `parent`.
static func build(parent: Node, level_grid: LevelGrid, district_look: DistrictLook) -> Array[FloorLayer]:
	var out: Array[FloorLayer] = []
	for y: int in range(0, level_grid.size.y, CHUNK):
		for x: int in range(0, level_grid.size.x, CHUNK):
			var block := FloorLayer.new()
			block.name = "Floor_%d_%d" % [x, y]
			parent.add_child(block)
			block.setup(level_grid, district_look, Rect2i(x, y, CHUNK, CHUNK).intersection(Rect2i(Vector2i.ZERO, level_grid.size)))
			out.append(block)
	return out


func setup(level_grid: LevelGrid, district_look: DistrictLook, cells: Rect2i = Rect2i()) -> void:
	grid = level_grid
	look = district_look
	region = cells
	z_index = -20
	queue_redraw()


func _cells() -> Array[Vector2i]:
	if region.size == Vector2i.ZERO:
		return grid.all_cells()
	var out: Array[Vector2i] = []
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			out.append(Vector2i(x, y))
	return out


func _draw() -> void:
	if grid == null:
		return
	for cell: Vector2i in _cells():
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
			LevelGrid.Floor.LAWN:
				_lawn(cell)
			LevelGrid.Floor.STEPS:
				_steps(cell)
			LevelGrid.Floor.TIMBER:
				_timber(cell)
			LevelGrid.Floor.GRAVEL:
				_gravel(cell)
			LevelGrid.Floor.TRACK:
				_track(cell)
			LevelGrid.Floor.CARRIAGE:
				_carriage(cell)
			LevelGrid.Floor.GANTRY:
				_gantry(cell)
			LevelGrid.Floor.CAB:
				_cab(cell)
			LevelGrid.Floor.TILE:
				_ward_tiles(cell)
			LevelGrid.Floor.ASPHALT:
				_asphalt(cell)
			LevelGrid.Floor.STAFF:
				_lino(cell)
			LevelGrid.Floor.SEAWALL:
				_flagstones(cell, look.ground_a, 2)
			LevelGrid.Floor.LOW_STREET:
				_low_street(cell)
			LevelGrid.Floor.KELP:
				_kelp(cell)
			LevelGrid.Floor.GRATING:
				_grating(cell)
			LevelGrid.Floor.PARQUET:
				_parquet(cell)
			LevelGrid.Floor.PIER:
				_pier(cell)
			LevelGrid.Floor.WARD_STONE:
				_flagstones(cell, Palette.WARD_STONE if (cell.x + cell.y) % 2 == 0 else Palette.WARD_STONE_B, 2)
			LevelGrid.Floor.GLASS:
				_glass(cell)
			LevelGrid.Floor.CULVERT:
				_culvert(cell)
			LevelGrid.Floor.VOID:
				_drop(cell)


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


## The Steward's lawns: mown in stripes, wet.
func _lawn(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.lawn)
	if (cell.x + cell.y) % 2 == 0:
		draw_colored_polygon(PackedVector2Array([_at(cell, 0.0, 0.0), _at(cell, 1.0, 0.0), _at(cell, 1.0, 0.5), _at(cell, 0.0, 0.5)]), look.lawn_stripe)


## Stone steps between terraces, on the path.
func _steps(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.pavement.darkened(0.2))
	for k: int in 4:
		var v := 0.12 + k * 0.24
		draw_line(_at(cell, 0.0, v), _at(cell, 1.0, v), Color(Palette.NEAR_BLACK, 0.45), 3.0, true)
		draw_line(_at(cell, 0.0, v + 0.05), _at(cell, 1.0, v + 0.05), Color(look.ground_wet, 0.5), 1.5, true)


## A room's floorboards.
func _timber(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.timber)
	for k: int in 5:
		var u := 0.1 + k * 0.2
		draw_line(_at(cell, u, 0.0), _at(cell, u, 1.0), Color(Palette.NEAR_BLACK, 0.3), 1.5, true)


## Track bed: ballast, sleepers, two rails running along the cell.
func _track(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.gravel.darkened(0.25))
	for k: int in 4:
		var u := 0.12 + k * 0.25
		draw_line(_at(cell, u, 0.1), _at(cell, u, 0.9), Color(look.timber.darkened(0.2), 0.9), 5.0, true)
	for v: float in [0.3, 0.7]:
		draw_line(_at(cell, 0.0, v), _at(cell, 1.0, v), Palette.IRON_DARK.lightened(0.25), 3.0, true)


## A carriage's floor: worn lino between the seat rows, dead screens' glow long gone.
func _carriage(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.wall_top.lightened(0.18))
	draw_line(_at(cell, 0.0, 0.5), _at(cell, 1.0, 0.5), Color(Palette.NEAR_BLACK, 0.25), 2.0, true)


## Steel grating over the drop.
func _gantry(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Color(Palette.IRON_DARK.lightened(0.2), 0.95))
	for k: int in 6:
		var u := 0.08 + k * 0.17
		draw_line(_at(cell, u, 0.0), _at(cell, u, 1.0), Color(Palette.NEAR_BLACK, 0.5), 1.5, true)


## The driver's cab: chequer plate, no Lattice.
func _cab(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.IRON_DARK.lightened(0.1))
	for k: int in 3:
		for j: int in 3:
			draw_circle(_at(cell, 0.2 + k * 0.3, 0.2 + j * 0.3), 2.0, Color(Palette.GREY_COLD, 0.3))


## The drop beside the rails: the fog, where a district has it.
func _drop(cell: Vector2i) -> void:
	if look.void_fog.a <= 0.0:
		return
	var near := false
	for dy: int in range(-2, 3):
		for dx: int in range(-2, 3):
			near = near or grid.is_walkable(cell + Vector2i(dx, dy))
	if near:
		draw_colored_polygon(Iso.cell_diamond(cell), look.void_fog)


## A garden walk the Lattice never lit.
func _gravel(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.gravel)
	var rng := _rng(cell, 5)
	for k: int in 14:
		draw_circle(_at(cell, rng.randf_range(0.08, 0.92), rng.randf_range(0.08, 0.92)), 1.5, Color(Palette.NEAR_BLACK, 0.3))


func _water(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.water)
	var rng := _rng(cell, 3)
	if rng.randf() < 0.55:
		var u := rng.randf_range(0.1, 0.7)
		var v := rng.randf_range(0.1, 0.9)
		draw_line(_at(cell, u, v), _at(cell, u + rng.randf_range(0.15, 0.3), v), Color(Palette.WATER_SHEEN, 0.7), 2.0, true)


## Hospital floor: square tiles in two greys with dark grout, a scuff here and there.
func _ward_tiles(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.grout)
	var rng := _rng(cell, 7)
	var step := 1.0 / 3.0
	for i: int in 3:
		for j: int in 3:
			var base := look.ground_a if (i + j) % 2 == 0 else look.ground_b
			draw_colored_polygon(_sub_diamond(cell, i * step, j * step, step, 0.035), base.darkened(rng.randf_range(0.0, 0.08)))


## The ambulance yard: dark asphalt with worn bay lines.
func _asphalt(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.asphalt)
	if (cell.x + cell.y) % 3 == 0:
		draw_line(_at(cell, 0.5, 0.05), _at(cell, 0.5, 0.95), Color(Palette.YARD_PAINT, 0.18), 2.0, true)


## Lino laid by people: warm, scuffed, in long strips.
## The newsroom's parquet: short blocks laid in alternating directions, worn pale where chairs rolled.
func _parquet(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.PARQUET)
	for i: int in 2:
		for j: int in 2:
			var along_x := (i + j) % 2 == 0
			var block := _sub_diamond(cell, i * 0.5, j * 0.5, 0.5, 0.02)
			draw_colored_polygon(block, Palette.PARQUET_B if along_x else Palette.PARQUET)
			for k: int in 3:
				var t := 0.125 + k * 0.125
				if along_x:
					draw_line(_at(cell, i * 0.5, j * 0.5 + t), _at(cell, i * 0.5 + 0.5, j * 0.5 + t), Color(Palette.NEAR_BLACK, 0.22), 1.0, true)
				else:
					draw_line(_at(cell, i * 0.5 + t, j * 0.5), _at(cell, i * 0.5 + t, j * 0.5 + 0.5), Color(Palette.NEAR_BLACK, 0.22), 1.0, true)


## Pier planks on pilings: dark water showing in the gaps between the boards.
func _pier(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.water.darkened(0.2))
	var rng := _rng(cell, 11)
	for k: int in 4:
		var u0 := k * 0.25 + 0.02
		var plank := PackedVector2Array([_at(cell, u0, 0.0), _at(cell, u0 + 0.21, 0.0), _at(cell, u0 + 0.21, 1.0), _at(cell, u0, 1.0)])
		draw_colored_polygon(plank, (Palette.PIER_PLANK if k % 2 == 0 else Palette.PIER_PLANK_B).darkened(rng.randf_range(0.0, 0.15)))
	draw_line(_at(cell, 0.0, 0.5), _at(cell, 1.0, 0.5), Color(Palette.NEAR_BLACK, 0.3), 2.0, true)


func _lino(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), look.staff_floor)
	for k: int in 3:
		var v := (k + 1) * 0.25
		draw_line(_at(cell, 0.0, v), _at(cell, 1.0, v), Color(Palette.NEAR_BLACK, 0.18), 1.0, true)


## A low street in Greywater: dark wet concrete, a tide line of silt, standing puddles.
func _low_street(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.LOW_STREET)
	var rng := _rng(cell, 11)
	if rng.randf() < 0.45:
		draw_colored_polygon(_sub_diamond(cell, rng.randf_range(0.1, 0.5), rng.randf_range(0.1, 0.5), 0.4, 0.0), Color(Palette.LOW_STREET_WET, 0.7))
	draw_line(_at(cell, 0.0, 0.85), _at(cell, 1.0, 0.85), Color(Palette.PAPER, 0.08), 1.5, true)


## Kelp left by the tide across a low street.
func _kelp(cell: Vector2i) -> void:
	_low_street(cell)
	var rng := _rng(cell, 13)
	for k: int in 5:
		var a := _at(cell, rng.randf_range(0.1, 0.9), rng.randf_range(0.1, 0.9))
		var b := a + Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-6.0, 6.0))
		draw_line(a, b, Palette.KELP if k % 2 == 0 else Palette.KELP_DARK, 4.0, true)


## Iron grating in the old pump room, over dark water.
## The Spire's black glass: four panes to a cell, a cold vein through some, and here and there the ring
## burned into it, an afterimage in grey (nothing in it is gold but its lamps).
func _glass(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.NEAR_BLACK)
	var rng := _rng(cell, 7)
	for i: int in 2:
		for j: int in 2:
			var c := look.ground_a.lerp(look.ground_b, rng.randf())
			draw_colored_polygon(_sub_diamond(cell, i * 0.5, j * 0.5, 0.5, 0.012), c)
	# A sheen across the near corner, as if something lit were standing behind you.
	draw_line(_at(cell, 0.15, 0.85), _at(cell, 0.55, 0.95), Color(Palette.SPIRE_COLD, 0.08), 2.0, true)
	if rng.randf() < 0.2:
		# A cold vein along one of the seams between panes.
		var v := 0.5 + rng.randf_range(-0.02, 0.02)
		var along_u := rng.randf() < 0.5
		var a := _at(cell, 0.0, v) if along_u else _at(cell, v, 0.0)
		var b := _at(cell, 1.0, v) if along_u else _at(cell, v, 1.0)
		draw_line(a, b, Color(Palette.SPIRE_COLD, 0.16), 1.5, true)
	if posmod(cell.x * 7 + cell.y * 3, 11) == 0:
		var ring := RingPainter.Look.new()
		ring.thin = true
		ring.color = Palette.GREY_COLD
		ring.alpha = 0.22
		ring.show_center = false
		ring.halo = 0.0
		draw_set_transform(Iso.cell_center(cell), 0.0, Vector2(1.0, Iso.SQUASH))
		RingPainter.paint(self, Vector2.ZERO, Iso.HALF_W * 0.45, ring)
		draw_set_transform(Vector2.ZERO)


## A descent's floor: old wet brick under the street, a gutter of black water down some of it, moss.
func _culvert(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.NEAR_BLACK)
	var rng := _rng(cell, 9)
	for i: int in 3:
		for j: int in 3:
			var c := Palette.STONE_OLD.darkened(0.55 + rng.randf() * 0.15)
			draw_colored_polygon(_sub_diamond(cell, i / 3.0, j / 3.0, 1.0 / 3.0, 0.02), c)
	if (cell.x + cell.y) % 3 == 0:
		draw_line(_at(cell, 0.0, 0.5), _at(cell, 1.0, 0.5), Color(Palette.WATER_DEEP, 0.9), 5.0, true)
		draw_line(_at(cell, 0.0, 0.5), _at(cell, 1.0, 0.5), Color(Palette.WATER_SHEEN, 0.25), 1.5, true)
	if rng.randf() < 0.3:
		draw_circle(_at(cell, rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)), 4.0, Color(Palette.LAWN.darkened(0.5), 0.6), true, -1.0, true)


func _grating(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.WATER_DEEP)
	for k: int in 5:
		var u := (k + 0.5) / 5.0
		draw_line(_at(cell, u, 0.0), _at(cell, u, 1.0), Palette.GRATING, 3.0, true)
		draw_line(_at(cell, 0.0, u), _at(cell, 1.0, u), Palette.GRATING, 2.0, true)

