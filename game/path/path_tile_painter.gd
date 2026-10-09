class_name PathTilePainter
extends RefCounted
## One gilded path tile as in image 10: a glowing diamond border, an inner diamond, and a four-petal
## inlay with curled tips pointing to the corners.

const INSET := 0.17


static func paint(ci: CanvasItem, center: Vector2, alpha: float) -> void:
	var hw := Iso.HALF_W * 0.92
	var hh := Iso.HALF_H * 0.92
	var outer := PackedVector2Array([center + Vector2(0, -hh), center + Vector2(hw, 0), center + Vector2(0, hh), center + Vector2(-hw, 0)])
	var k := 1.0 - INSET * 2.0
	var inner := PackedVector2Array([center + Vector2(0, -hh * k), center + Vector2(hw * k, 0), center + Vector2(0, hh * k), center + Vector2(-hw * k, 0)])
	var hot := Color(Palette.STEWARD_GOLD_HOT, alpha)
	var soft := Color(Palette.STEWARD_GOLD, 0.16 * alpha)
	ci.draw_colored_polygon(outer, soft)
	var outer_loop := outer.duplicate()
	outer_loop.append(outer[0])
	ci.draw_polyline(outer_loop, hot, 3.0, true)
	var inner_loop := inner.duplicate()
	inner_loop.append(inner[0])
	ci.draw_polyline(inner_loop, Color(Palette.STEWARD_GOLD, 0.7 * alpha), 1.5, true)
	# Four petals toward the corners, squashed onto the ground plane.
	for corner: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		var tip := center + Vector2(corner.x * hw, corner.y * hh) * 0.62
		_petal(ci, center, tip, Color(Palette.STEWARD_GOLD, 0.9 * alpha), Color(Palette.STEWARD_GOLD, 0.22 * alpha))
	# Small curls between the petals.
	for diag: Vector2 in [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
		var p := center + Vector2(diag.x * hw * 0.3, diag.y * hh * 0.3)
		ci.draw_arc(p, 5.0, diag.angle() - 1.2, diag.angle() + 2.4, 8, Color(Palette.STEWARD_GOLD, 0.7 * alpha), 1.5, true)
	ci.draw_circle(center, 3.5, hot, true, -1.0, true)


static func _petal(ci: CanvasItem, base: Vector2, tip: Vector2, line: Color, fill: Color) -> void:
	var axis := tip - base
	var normal := axis.orthogonal().normalized() * minf(axis.length() * 0.28, 12.0)
	var pts := PackedVector2Array()
	const N := 10
	for i: int in N + 1:
		var s := float(i) / N
		pts.append(base + axis * s + normal * sin(PI * s))
	for i: int in range(N - 1, 0, -1):
		var s := float(i) / N
		pts.append(base + axis * s - normal * sin(PI * s))
	ci.draw_colored_polygon(pts, fill)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, line, 1.5, true)
