class_name PaintedBiped
extends RefCounted
## Shared painted joints for the walking machines and coat-wearing civilians.


static func paint(ci: CanvasItem, model: String, gait: StrideCycle, facing: Vector2, height: float, flash: float = 0.0, attack: float = 0.0, tint: Color = Color.WHITE) -> Dictionary[String, Vector2]:
	var screen := Iso.grid_to_world(facing)
	var side := -1.0 if screen.x < 0.0 else 1.0
	var view := "back" if screen.y < -0.25 else "front"
	var civilian := model in ["noor", "teo", "survivor"]
	var prefix := "rig_%s_%s_" % [model, view]
	var legs := "rig_%s_" % model if civilian else prefix
	var body := ArtCatalog.frame(prefix + "torso")
	var size := height / 138.0
	var hip := Vector2(0, -height * (0.48 if civilian else 0.52) + gait.bob() * size)
	var scale := (height + hip.y) / (body.anchors["hip"].y - body.region.position.y)
	var rect := Rect2(hip - (body.anchors["hip"] - body.region.position) * scale, body.region.size * scale)
	var shade := tint * (1.0 + flash * 1.8)
	shade.a = tint.a
	var anchors: Dictionary[String, Vector2] = {}
	for id: String in body.anchors:
		anchors[id] = ArtCatalog.anchor(prefix + "torso", id, rect)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(side, 1))
	if not civilian and model != "warden":
		_arm(ci, prefix, anchors["far_shoulder"], hip, gait, height, attack, shade.darkened(0.15))
	_leg(ci, legs, hip + Vector2(7 * side * size, -2 * size), (Vector2(7 * size, -3 * size) + gait.foot(true)) * Vector2(side, 1), gait.direction, side, size, shade.darkened(0.15))
	_leg(ci, legs, hip + Vector2(-7 * side * size, 2 * size), (Vector2(-7 * size, 3 * size) + gait.foot(false)) * Vector2(side, 1), gait.direction, side, size, shade)
	ArtCatalog.paint(ci, prefix + "torso", rect, shade)
	if not civilian:
		anchors["weapon"] = _arm(ci, prefix, anchors["near_shoulder"], hip, gait, height, attack, shade)
	ci.draw_set_transform(Vector2.ZERO)
	for id: String in anchors:
		anchors[id].x *= side
	return anchors


static func _arm(ci: CanvasItem, prefix: String, shoulder: Vector2, hip: Vector2, gait: StrideCycle, height: float, attack: float, tint: Color) -> Vector2:
	var source := ArtCatalog.frame(prefix + "arm")
	var arm_length := height * 0.36
	var end := arm_end(prefix, shoulder, hip, gait, height, attack)
	PaintedParts.segment(ci, prefix + "arm", shoulder, end, arm_length, tint)
	return PaintedParts.attachment(prefix + "arm", source.anchors.get("weapon", source.anchors["tip"]), shoulder, end, arm_length)


static func arm_end(prefix: String, shoulder: Vector2, hip: Vector2, gait: StrideCycle, height: float, attack: float) -> Vector2:
	var source := ArtCatalog.frame(prefix + "arm")
	var forward := Iso.grid_to_world(gait.direction).normalized()
	var swing := -cos(gait.phase * TAU) * 0.3 * gait.weight * forward.x * signf(shoulder.x - hip.x)
	# The upright baton sweeps forward; the Clerk's underslung launcher throws overarm.
	var stroke := 1.0 if prefix in ["rig_warden_front_", "rig_warden_back_"] else -1.0
	var angle := swing + attack * stroke * 1.15
	var rest := (source.anchors["tip"] - source.anchors["joint"]).normalized() * height * 0.36
	return shoulder + rest.rotated(angle)


static func _leg(ci: CanvasItem, prefix: String, hip: Vector2, foot: Vector2, direction: Vector2, side: float, size: float, tint: Color) -> void:
	var ankle := foot - Vector2(0, 7 * size)
	var forward := Iso.grid_to_world(direction).normalized() * Vector2(side, 1)
	var knee := (hip + ankle) * 0.5 + forward * minf(5 * size, hip.distance_to(ankle) * 0.06)
	PaintedParts.segment(ci, prefix + "thigh", hip, knee, 36 * size, tint)
	PaintedParts.segment(ci, prefix + "calf", knee, ankle, 31 * size, tint)
	var boot := ArtCatalog.frame(prefix + "boot")
	var calf := ArtCatalog.frame(prefix + "calf")
	var scale := 31 * size / calf.anchors["joint"].distance_to(calf.anchors["tip"])
	ArtCatalog.paint(ci, prefix + "boot", Rect2(foot - (boot.anchors["sole"] - boot.region.position) * scale, boot.region.size * scale), tint)
