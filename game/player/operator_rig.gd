class_name OperatorRig
extends RefCounted
## Painted cutout limbs share fixed joint anchors. No pose is independently resized to fit a box.
## The root stays at the feet; only the drawing moves, including the earpiece and carried lantern.


static func paint(ci: CanvasItem, gait: OperatorGait, direction: String, side: float, carrying: bool, flash: float) -> void:
	var prefix := "rig_%s_" % direction
	var bob := gait.bob()
	var hip := Vector2(0, -68 + bob)
	# Mirroring changes the painted view, not the world contact points.
	var far_foot := (Vector2(10, -4) + gait.foot(true)) * Vector2(side, 1)
	var near_foot := (Vector2(-10, 4) + gait.foot(false)) * Vector2(side, 1)
	var tint := Color.WHITE * (1.0 + flash * 1.8)
	tint.a = 1.0
	var key := "rig_carry_" + direction if carrying else prefix + "torso"
	var frame := ArtCatalog.frame(key)
	# Carrying uses the same body scale: Noor adds silhouette, not a smaller Operator.
	var height := 138.0 if carrying else 103.0
	var scale := height / frame.region.size.y
	var root := frame.anchors["hip"] - frame.region.position
	var rect := Rect2(hip - root * scale, frame.region.size * scale)
	var swing := arm_swing(gait, direction)
	var knee_direction := Iso.grid_to_world(gait.direction).normalized() * Vector2(side, 1)
	if not carrying:
		_arm(ci, prefix, ArtCatalog.anchor(key, "far_shoulder", rect), -swing, tint.darkened(0.15))
	_leg(ci, prefix, hip + Vector2(10 * side, -3), far_foot, knee_direction, tint.darkened(0.13))
	_leg(ci, prefix, hip + Vector2(-10 * side, 3), near_foot, knee_direction, tint)
	ArtCatalog.paint(ci, key, rect, tint)
	if not carrying:
		_arm(ci, prefix, ArtCatalog.anchor(key, "near_shoulder", rect), swing, tint)
	var ear := ArtCatalog.anchor(key, "ear", rect)
	ci.draw_circle(ear, 2.6, Palette.STEWARD_GOLD_HOT if Steward.voice_on else Palette.IRON_DARK, true, -1.0, true)
	if Steward.voice_on:
		ci.draw_circle(ear, 7.0, Color(Palette.STEWARD_GOLD, 0.2), true, -1.0, true)
	if carrying:
		var lantern := ArtCatalog.anchor(key, "lantern", rect)
		ci.draw_circle(lantern, 14.0, Color(Palette.TRUTH_CYAN, 0.15), true, -1.0, true)
		ci.draw_circle(lantern, 3.5, Palette.TRUTH_CYAN_HOT, true, -1.0, true)


static func arm_swing(gait: OperatorGait, direction: String) -> float:
	# Rear-view shoulders exchange sides; each arm still opposes its corresponding foot.
	# Mirroring swaps both the shoulder's physical side and the painted arm's displacement.
	var shoulder_side := -1.0 if direction == "back" else 1.0
	var forward := Iso.grid_to_world(gait.direction).normalized()
	return cos(gait.phase * TAU) * 0.3 * gait.weight * forward.x * shoulder_side


static func _arm(ci: CanvasItem, prefix: String, shoulder: Vector2, angle: float, tint: Color) -> void:
	_part(ci, prefix + "arm", shoulder, shoulder + Vector2(5, 63).rotated(angle), 63.0, tint)


static func _leg(ci: CanvasItem, prefix: String, hip: Vector2, foot: Vector2, knee_direction: Vector2, tint: Color) -> void:
	var ankle := foot - Vector2(0, 9)
	var knee := knee_between(hip, ankle, knee_direction)
	_part(ci, prefix + "thigh", hip, knee, 39.0, tint)
	_part(ci, prefix + "shin", knee, ankle, 32.0, tint)
	var boot := ArtCatalog.frame(prefix + "boot")
	var shin := ArtCatalog.frame(prefix + "shin")
	var scale := 32.0 / shin.anchors["joint"].distance_to(shin.anchors["tip"])
	ArtCatalog.paint(ci, prefix + "boot", Rect2(foot - (boot.anchors["sole"] - boot.region.position) * scale, boot.region.size * scale), tint)


static func knee_between(hip: Vector2, foot: Vector2, forward: Vector2) -> Vector2:
	# Bend projects along the ground-facing direction, not sideways in the image plane.
	# Foreshortening is intentional; cloth width stays fixed as the knee passes forward.
	var axis := foot - hip
	var length := minf(axis.length(), 77.8)
	var bend := sqrt(maxf(0.0, 39.0 * 39.0 - length * length * 0.25))
	return (hip + foot) * 0.5 + forward * minf(bend, 6.0)


static func _part(ci: CanvasItem, key: String, a: Vector2, b: Vector2, rest_length: float, tint: Color) -> void:
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
