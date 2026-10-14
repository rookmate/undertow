class_name DrawOps
extends RefCounted
## A recorded list of 2D draw calls. Lets a node build its geometry once and split it between a base
## canvas item (lit by the scene) and an Emissive child (light sources, unaffected by the dark).

var _ops: Array[Array] = []


func clear() -> void:
	_ops.clear()


func is_empty() -> bool:
	return _ops.is_empty()


func poly(points: PackedVector2Array, color: Color) -> void:
	_ops.append([0, points, color])


func textured_poly(points: PackedVector2Array, uv: PackedVector2Array, texture: Texture2D, tint: Color = Color.WHITE) -> void:
	# Polygon drawing uses the underlying texture RID, so AtlasTexture crops need explicit UVs.
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		var mapped := PackedVector2Array()
		for point: Vector2 in uv:
			mapped.append((atlas.region.position + point * atlas.region.size) / atlas.atlas.get_size())
		uv = mapped
		texture = atlas.atlas
	_ops.append([3, points, PackedColorArray([tint]), uv, texture])


## A shaded foreground for painted details that sit above emissive window or lens fills.
func add_layer(parent: Node, layer_name: StringName) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.draw.connect(func() -> void: paint(layer))
	parent.add_child(layer)
	return layer


func polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	_ops.append([1, points, color, width])


func line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	_ops.append([1, PackedVector2Array([a, b]), color, width])


func circle(center: Vector2, radius: float, color: Color) -> void:
	_ops.append([2, center, radius, color])


func sprite(key: String, dest: Rect2, tint: Color = Color.WHITE) -> void:
	_ops.append([4, key, dest, tint])


func paint(ci: CanvasItem) -> void:
	for op: Array in _ops:
		match op[0]:
			0:
				ci.draw_colored_polygon(op[1], op[2])
			1:
				ci.draw_polyline(op[1], op[2], op[3], true)
			2:
				ci.draw_circle(op[1], op[2], op[3], true, -1.0, true)
			3:
				ci.draw_polygon(op[1], op[2], op[3], op[4])
			4:
				ArtCatalog.paint(ci, op[1], op[2], op[3])
