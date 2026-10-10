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
		var f := drawn_floor(grid, cell)
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
			LevelGrid.Floor.VOID:
				_drop(cell)


## Plain floor characters: what a placed thing's cell is drawn as, taken from a neighbour.
const PLAIN_FLOORS := ".,:_iqnxh" + Tiles.HOSPITAL_TILE + Tiles.ASPHALT + Tiles.STAFF_FLOOR + Tiles.SEAWALL \
	+ Tiles.LOW_STREET + Tiles.GRATING
## Placed things (people, finds, spawns) stand on whatever floor surrounds them.
const MARKERS := "TUWwPCckXVO]BZy"


## The floor a cell is drawn with: its own, except a placed thing's cell borrows a plain neighbour's
## (a truth cache in a bedroom sits on floorboards, not on the stacks' paper). Drawing only.
static func drawn_floor(level_grid: LevelGrid, cell: Vector2i) -> LevelGrid.Floor:
	if MARKERS.contains(level_grid.char_at(cell)):
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			if PLAIN_FLOORS.contains(level_grid.char_at(cell + d)):
				return level_grid.floor_at(cell + d)
	return level_grid.floor_at(cell)


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
func _grating(cell: Vector2i) -> void:
	draw_colored_polygon(Iso.cell_diamond(cell), Palette.WATER_DEEP)
	for k: int in 5:
		var u := (k + 0.5) / 5.0
		draw_line(_at(cell, u, 0.0), _at(cell, u, 1.0), Palette.GRATING, 3.0, true)
		draw_line(_at(cell, 0.0, u), _at(cell, 1.0, u), Palette.GRATING, 2.0, true)

