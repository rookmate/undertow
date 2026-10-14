class_name ArtCatalog
extends RefCounted
## Painted frames shared by world drawing and item illustrations. Missing art is an error.

const MANIFEST := "res://assets/art/complete/catalog.json"

class Frame extends RefCounted:
	var texture: AtlasTexture
	var atlas: Texture2D
	var region: Rect2
	var uv: PackedVector2Array
	var anchors: Dictionary[String, Vector2] = {}

static var _frames: Dictionary[String, Frame] = {}
static var _loaded: bool = false


static func frame(key: String) -> Frame:
	_load()
	if not _frames.has(key):
		push_error("Missing painted art: %s" % key)
		return null
	return _frames[key]


static func keys() -> Array[String]:
	_load()
	return _frames.keys()


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not data is Dictionary:
		push_error("Invalid painted art catalog")
		return
	var textures: Dictionary[String, Texture2D] = {}
	for key: String in data:
		var entry: Dictionary = data[key]
		var path: String = entry["path"]
		if not textures.has(path):
			textures[path] = load(path) as Texture2D
		var atlas := textures[path]
		if atlas == null:
			push_error("Cannot load painted art: %s" % path)
			continue
		var r: Array = entry["region"]
		var item := Frame.new()
		item.atlas = atlas
		item.region = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		item.texture = AtlasTexture.new()
		item.texture.atlas = atlas
		item.texture.region = item.region
		item.texture.filter_clip = true
		for anchor_id: String in entry.get("anchors", {}):
			var point: Array = entry["anchors"][anchor_id]
			item.anchors[anchor_id] = Vector2(float(point[0]), float(point[1]))
		item.uv = PackedVector2Array()
		for corner: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
			item.uv.append((item.region.position + corner * item.region.size) / atlas.get_size())
		_frames[key] = item


static func paint(ci: CanvasItem, key: String, dest: Rect2, tint: Color = Color.WHITE) -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var item := frame(key)
	if item != null:
		ci.draw_texture_rect(item.texture, dest, false, tint)


static func actor(ci: CanvasItem, key: String, height: float, offset: Vector2 = Vector2.ZERO, flash: float = 0.0, tint: Color = Color.WHITE) -> void:
	var item := frame(key)
	if item == null:
		return
	var size := item.region.size * (height / item.region.size.y)
	paint(ci, key, Rect2(offset + Vector2(-size.x * 0.5, -height), size), tint * (1.0 + flash * 1.8))


## Points are top-left, top-right, bottom-right, bottom-left in the painted surface's coordinates.
static func mapped(ci: CanvasItem, key: String, points: PackedVector2Array, tint: Color = Color.WHITE) -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var item := frame(key)
	if item != null:
		ci.draw_polygon(points, PackedColorArray([tint]), item.uv, item.atlas)


static func surface(ci: CanvasItem, key: String, cell: Vector2i, tint: Color = Color.WHITE) -> void:
	var item := frame(key)
	if item == null:
		return
	var start := Vector2(posmod(cell.x, 2), posmod(cell.y, 2)) * 0.5
	var uv := PackedVector2Array()
	for corner: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
		uv.append((item.region.position + (start + corner * 0.5) * item.region.size) / item.atlas.get_size())
	ci.draw_polygon(Iso.cell_diamond(cell), PackedColorArray([tint]), uv, item.atlas)


static func link(ci: CanvasItem, key: String, a: Vector2, b: Vector2, width: float, tint: Color = Color.WHITE) -> void:
	if a.distance_squared_to(b) < 0.001:
		return
	var side := (b - a).normalized().orthogonal() * width * 0.5
	var item := frame(key)
	if item == null:
		return
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var uv := item.uv
	if item.region.size.y > item.region.size.x:
		uv = PackedVector2Array([item.uv[3], item.uv[0], item.uv[1], item.uv[2]])
	ci.draw_polygon(PackedVector2Array([a - side, b - side, b + side, a + side]), PackedColorArray([tint]), uv, item.atlas)


static func texture(key: String) -> Texture2D:
	var item := frame(key)
	return item.texture if item != null else null


static func anchor(key: String, anchor_id: String, dest: Rect2) -> Vector2:
	var item := frame(key)
	if item == null or not item.anchors.has(anchor_id):
		push_error("Missing painted anchor: %s/%s" % [key, anchor_id])
		return dest.get_center()
	return dest.position + (item.anchors[anchor_id] - item.region.position) / item.region.size * dest.size


static func actor_anchor(key: String, anchor_id: String, height: float, offset: Vector2 = Vector2.ZERO) -> Vector2:
	var item := frame(key)
	if item == null:
		return offset
	var size := item.region.size * (height / item.region.size.y)
	return anchor(key, anchor_id, Rect2(offset + Vector2(-size.x * 0.5, -height), size))


static func fit(ci: CanvasItem, key: String, bounds: Rect2, tint: Color = Color.WHITE) -> void:
	var item := frame(key)
	if item == null:
		return
	var scale := minf(bounds.size.x / item.region.size.x, bounds.size.y / item.region.size.y)
	var size := item.region.size * scale
	paint(ci, key, Rect2(bounds.get_center() - size * 0.5, size), tint)


## Native source crops preserve the painting while shutters and gate leaves open.
static func slice(ci: CanvasItem, key: String, dest: Rect2, fraction: Rect2) -> void:
	var item := frame(key)
	if item != null:
		var source := Rect2(item.region.position + fraction.position * item.region.size, fraction.size * item.region.size)
		ci.draw_texture_rect_region(item.atlas, dest, source)


static func door(ci: CanvasItem, key: String, bounds: Rect2, opened: float, double_leaf: bool = false) -> void:
	if opened <= 0.001:
		paint(ci, key, bounds)
		return
	var jamb := 0.14
	slice(ci, key, Rect2(bounds.position, bounds.size * Vector2(jamb, 1)), Rect2(0, 0, jamb, 1))
	slice(ci, key, Rect2(bounds.position + Vector2(bounds.size.x * (1 - jamb), 0), bounds.size * Vector2(jamb, 1)), Rect2(1 - jamb, 0, jamb, 1))
	slice(ci, key, Rect2(bounds.position + Vector2(bounds.size.x * jamb, 0), bounds.size * Vector2(1 - jamb * 2, 0.16)), Rect2(jamb, 0, 1 - jamb * 2, 0.16))
	var leaf_width := (1 - jamb * 2) * (1 - opened)
	if leaf_width < 0.01:
		return
	var leaf := Rect2(bounds.position + bounds.size * Vector2(jamb, 0.16), bounds.size * Vector2(leaf_width, 0.84))
	if double_leaf:
		leaf.size.x *= 0.5
		slice(ci, key, leaf, Rect2(jamb, 0.16, 0.5 - jamb, 0.84))
		leaf.position.x = bounds.end.x - bounds.size.x * jamb - leaf.size.x
		slice(ci, key, leaf, Rect2(0.5, 0.16, 0.5 - jamb, 0.84))
	else:
		slice(ci, key, leaf, Rect2(jamb, 0.16, 1 - jamb * 2, 0.84))
