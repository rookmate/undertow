class_name FloorLayer
extends Node2D
## Draws the ground cells of a level once: wet cobble, flagstone pavement, the old quay, the stacks'
## paper-strewn floor, stairs and canal water, using painted materials at the brief's scale.
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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
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
		var kind := grid.floor_at(cell)
		if kind == LevelGrid.Floor.VOID:
			_drop(cell)
			continue
		if kind == LevelGrid.Floor.BUILDING:
			continue
		var key := ArtBindings.ground_key(kind, look.district_id)
		var tint := Color.WHITE
		if kind == LevelGrid.Floor.ASPHALT or kind == LevelGrid.Floor.CULVERT:
			tint = Color.WHITE.darkened(0.4)
		ArtCatalog.surface(self, key, cell, tint)
		if kind == LevelGrid.Floor.GLASS and posmod(cell.x * 7 + cell.y * 3, 11) == 0:
			var ring := RingPainter.Look.new()
			ring.thin = true
			ring.color = Palette.GREY_COLD
			ring.alpha = 0.22
			ring.show_center = false
			ring.halo = 0.0
			draw_set_transform(Iso.cell_center(cell), 0.0, Vector2(1.0, Iso.SQUASH))
			RingPainter.paint(self, Vector2.ZERO, Iso.HALF_W * 0.45, ring)
			draw_set_transform(Vector2.ZERO)


func _drop(cell: Vector2i) -> void:
	if look.void_fog.a <= 0.0:
		return
	var near := false
	for dy: int in range(-2, 3):
		for dx: int in range(-2, 3):
			near = near or grid.is_walkable(cell + Vector2i(dx, dy))
	if near:
		draw_colored_polygon(Iso.cell_diamond(cell), look.void_fog)
