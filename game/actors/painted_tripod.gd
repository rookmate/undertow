class_name PaintedTripod
extends RefCounted


static func paint(ci: CanvasItem, gait: StrideCycle, facing: Vector2, flash: float) -> Vector2:
	var screen := Iso.grid_to_world(facing)
	var side := -1.0 if screen.x < 0.0 else 1.0
	var prefix := "rig_lamplighter_%s_" % ("back" if screen.y < -0.25 else "front")
	var torso := ArtCatalog.frame(prefix + "torso")
	var hip := Vector2(0, -67 + gait.bob() * 0.5)
	var scale := 60.0 / (torso.anchors["hip"].y - torso.region.position.y)
	var rect := Rect2(hip - (torso.anchors["hip"] - torso.region.position) * scale, torso.region.size * scale)
	var tint := Color.WHITE * (1.0 + flash * 1.8)
	tint.a = 1.0
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(side, 1))
	for i: int in 3:
		var bases: Array[Vector2] = [Vector2(-22, 4), Vector2(20, 2), Vector2(0, -12)]
		var foot := (bases[i] + gait.foot_index(i)) * Vector2(side, 1)
		var knee := (hip + foot) * 0.5 + Vector2(bases[i].x * side * 0.5, -6)
		PaintedParts.segment(ci, prefix + "thigh", hip, knee, 39.0, tint)
		PaintedParts.segment(ci, prefix + "shin", knee, foot - Vector2(0, 4), 32.0, tint)
		var boot := ArtCatalog.frame(prefix + "boot")
		var boot_scale := 16.0 / boot.region.size.x
		ArtCatalog.paint(ci, prefix + "boot", Rect2(foot - (boot.anchors["sole"] - boot.region.position) * boot_scale, boot.region.size * boot_scale), tint)
	ArtCatalog.paint(ci, prefix + "torso", rect, tint)
	ci.draw_set_transform(Vector2.ZERO)
	return ArtCatalog.anchor(prefix + "torso", "lens", rect) * Vector2(side, 1)
