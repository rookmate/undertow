class_name TerrainEdges
extends Node2D
## Painted quay walls and bridge undersides. Physical ground defines support, not navigation:
## lawns, buildings and occupied cells support their neighbours just as streets do.

var grid: LevelGrid
var look: DistrictLook
var cells: Array[Vector2i] = []


static func supports(kind: LevelGrid.Floor) -> bool:
	return kind not in [LevelGrid.Floor.VOID, LevelGrid.Floor.WATER]


static func exposed(grid_data: LevelGrid, cell: Vector2i, direction: Vector2i) -> bool:
	return supports(grid_data.floor_at(cell)) and not supports(grid_data.floor_at(cell + direction))


func _draw() -> void:
	for cell: Vector2i in cells:
		if not supports(grid.floor_at(cell)):
			continue
		var diamond := Iso.cell_diamond(cell)
		if exposed(grid, cell, Vector2i.RIGHT):
			_face(cell, diamond[1], diamond[2], Vector2i.RIGHT, 0.78)
		if exposed(grid, cell, Vector2i.DOWN):
			_face(cell, diamond[2], diamond[3], Vector2i.DOWN, 0.56)


func _face(cell: Vector2i, a: Vector2, b: Vector2, direction: Vector2i, shade: float) -> void:
	var beside_water := grid.floor_at(cell + direction) == LevelGrid.Floor.WATER
	var depth := 28.0 if beside_water else (144.0 if look.district_id == "loop" else 92.0)
	var drop := Vector2(0, depth)
	var key := "mat_foundation"
	var kind := grid.floor_at(cell)
	var top := Color.WHITE * shade
	top.a = 1.0
	if kind in [LevelGrid.Floor.TIMBER, LevelGrid.Floor.PIER]:
		ArtCatalog.actor(self, "piling", depth * 0.9, a + drop * 0.9, 0.0, top.darkened(0.2))
		_strip(cell, "edge_timber", a - Vector2(0, 3), b - Vector2(0, 3), 30.0, top)
		return
	elif kind in [LevelGrid.Floor.TRACK, LevelGrid.Floor.GANTRY, LevelGrid.Floor.CARRIAGE, LevelGrid.Floor.CAB, LevelGrid.Floor.GRATING]:
		_strip(cell, "edge_steel", a, b, 44.0, top)
		return
	elif look.district_id in ["greywater", "mercy", "spire"]:
		key = "mat_concrete"
	var frame := ArtCatalog.frame(key)
	var middle := top.darkened(0.35)
	var bottom := Color(middle, 0.0 if not beside_water else 0.6)
	var seam := drop * 0.55
	var uv_middle_left := frame.uv[0].lerp(frame.uv[3], 0.55)
	var uv_middle_right := frame.uv[1].lerp(frame.uv[2], 0.55)
	draw_polygon(PackedVector2Array([a, b, b + seam, a + seam]), PackedColorArray([top, top, middle, middle]), PackedVector2Array([frame.uv[0], frame.uv[1], uv_middle_right, uv_middle_left]), frame.atlas)
	draw_polygon(PackedVector2Array([a + seam, b + seam, b + drop, a + drop]), PackedColorArray([middle, middle, bottom, bottom]), PackedVector2Array([uv_middle_left, uv_middle_right, frame.uv[2], frame.uv[3]]), frame.atlas)
	_strip(cell, "edge_roots" if kind == LevelGrid.Floor.LAWN else "edge_stone", a - Vector2(0, 3), b - Vector2(0, 3), 24.0, top)


func _strip(cell: Vector2i, key: String, a: Vector2, b: Vector2, height: float, tint: Color) -> void:
	var frame := ArtCatalog.frame(key)
	# Four adjoining faces use different quarters of the same long painting.
	var start := float(posmod(cell.x + cell.y, 4)) * 0.25
	var uv := PackedVector2Array()
	for corner: Vector2 in [Vector2(start, 0), Vector2(start + 0.25, 0), Vector2(start + 0.25, 1), Vector2(start, 1)]:
		uv.append((frame.region.position + corner * frame.region.size) / frame.atlas.get_size())
	draw_polygon(PackedVector2Array([a, b, b + Vector2(0, height), a + Vector2(0, height)]), PackedColorArray([tint]), uv, frame.atlas)
