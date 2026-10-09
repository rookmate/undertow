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


func polyline(points: PackedVector2Array, color: Color, width: float) -> void:
	_ops.append([1, points, color, width])


func line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	_ops.append([1, PackedVector2Array([a, b]), color, width])


func circle(center: Vector2, radius: float, color: Color) -> void:
	_ops.append([2, center, radius, color])


func paint(ci: CanvasItem) -> void:
	for op: Array in _ops:
		match op[0]:
			0:
				ci.draw_colored_polygon(op[1], op[2])
			1:
				ci.draw_polyline(op[1], op[2], op[3], true)
			2:
				ci.draw_circle(op[1], op[2], op[3], true, -1.0, true)
