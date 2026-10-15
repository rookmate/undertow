class_name PaintedHover
extends RefCounted
## Reuse the original painted hull and appendage regions, preserving their source scale.


## `aim`: the screen direction its claw or nozzles reach toward as they extend (toward what it's after);
## `brightness`: how much its painting is lifted (a dark machine on dark streets).
static func paint(ci: CanvasItem, model: String, facing: Vector2, height: float, offset: Vector2, flash: float, extend: float, gripping: bool, aim: Vector2 = Vector2(0, 1), brightness: float = 1.0) -> Array[Vector2]:
	var screen := Iso.grid_to_world(facing)
	var side := -1.0 if screen.x < 0.0 else 1.0
	var key := model + ("_back" if screen.y < -0.25 else "_front")
	var full := ArtCatalog.frame(key)
	var scale := height / full.region.size.y
	var origin := offset - Vector2(full.region.size.x * scale * 0.5, height)
	var tint := Color.WHITE * (brightness + flash * 1.8)
	tint.a = 1.0
	var tips: Array[Vector2] = []
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(side, 1))
	# Reaching toward its target (in the mirrored drawing), and lowering a little as it does.
	var reach := Vector2(aim.x * side, aim.y).normalized() * 12.0 + Vector2(0, 4)
	var parts := PackedStringArray(["claw"]) if model == "salvager" else PackedStringArray(["nozzle_left", "nozzle_right"])
	for part: String in parts:
		var frame := ArtCatalog.frame(key + "_" + part)
		var anchor := frame.anchors["joint"]
		var joint := origin + (anchor - full.region.position) * scale
		var to := joint + reach * extend
		var size := Vector2(scale * (0.72 if gripping else 1.0), scale)
		if extend > 0.01:
			ArtCatalog.link(ci, "arm_link", joint, to, 3.0, tint)
		ArtCatalog.paint(ci, key + "_" + part, Rect2(to - (anchor - frame.region.position) * size, frame.region.size * size), tint)
		tips.append((to + Vector2(0, (frame.region.end.y - anchor.y) * scale)) * Vector2(side, 1))
	var hull := ArtCatalog.frame(key + "_hull")
	ArtCatalog.paint(ci, key + "_hull", Rect2(origin + (hull.region.position - full.region.position) * scale, hull.region.size * scale), tint)
	ci.draw_set_transform(Vector2.ZERO)
	return tips
