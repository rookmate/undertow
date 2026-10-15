class_name PaintedParts
extends RefCounted
## Joint-mapped painted cutouts; preserve transverse width while limbs foreshorten.


static func segment(ci: CanvasItem, key: String, a: Vector2, b: Vector2, rest_length: float, tint: Color) -> void:
	var frame := ArtCatalog.frame(key)
	var joint := frame.anchors["joint"]
	var source_axis := frame.anchors["tip"] - joint
	var target_axis := b - a
	var source_forward := source_axis.normalized()
	var target_forward := target_axis.normalized()
	var width_scale := rest_length / source_axis.length()
	var points := PackedVector2Array()
	for corner: Vector2 in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
		var p := frame.region.position + corner * frame.region.size - joint
		points.append(a + target_axis * (p.dot(source_forward) / source_axis.length()) + target_forward.orthogonal() * p.dot(source_forward.orthogonal()) * width_scale)
	ci.draw_polygon(points, PackedColorArray([tint]), frame.uv, frame.atlas)


static func attachment(key: String, source_point: Vector2, a: Vector2, b: Vector2, rest_length: float) -> Vector2:
	var frame := ArtCatalog.frame(key)
	var axis := frame.anchors["tip"] - frame.anchors["joint"]
	var target := b - a
	var p := source_point - frame.anchors["joint"]
	return a + target * (p.dot(axis.normalized()) / axis.length()) + target.normalized().orthogonal() * p.dot(axis.normalized().orthogonal()) * rest_length / axis.length()
