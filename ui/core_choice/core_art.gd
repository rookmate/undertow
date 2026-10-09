class_name CoreArt
extends Control
## Placeholder core art (art direction, "Objects"): power cores are faceted amber prisms lit from inside,
## cut like jewellery (the Steward's gold); truth cores are dull cracked spheres with a faint blink
## inside, which look broken (found alone: truth cyan).

var truth: bool = false
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	if truth:
		draw_circle(c, 46.0, Palette.GREY_DEEP, true, -1.0, true)
		draw_arc(c, 46.0, 0.0, TAU, 40, Palette.GREY_COLD.darkened(0.25), 2.0, true)
		for crack: PackedVector2Array in [
			PackedVector2Array([c + Vector2(-30, -22), c + Vector2(-8, -4), c + Vector2(-20, 22)]),
			PackedVector2Array([c + Vector2(16, -38), c + Vector2(8, -12), c + Vector2(32, 10)]),
			PackedVector2Array([c + Vector2(-8, -4), c + Vector2(8, -12)]),
		]:
			draw_polyline(crack, Palette.NEAR_BLACK, 3.0, true)
		var blink := 0.3 + 0.7 * maxf(0.0, sin(_t * 2.2))
		draw_circle(c + Vector2(4, 6), 7.0, Color(Palette.TRUTH_CYAN, 0.25 * blink), true, -1.0, true)
		draw_circle(c + Vector2(4, 6), 3.5, Color(Palette.TRUTH_CYAN_HOT, blink), true, -1.0, true)
	else:
		var glow := 0.85 + 0.15 * sin(_t * 1.6)
		var top := c + Vector2(0, -62)
		var bottom := c + Vector2(0, 62)
		var ring := [c + Vector2(-38, -10), c + Vector2(-14, 4), c + Vector2(14, 4), c + Vector2(38, -10), c + Vector2(14, -22), c + Vector2(-14, -22)]
		var gold := Palette.STEWARD_GOLD
		for i: int in ring.size():
			var a: Vector2 = ring[i]
			var b: Vector2 = ring[(i + 1) % ring.size()]
			var shade := 0.55 + 0.45 * float(i % 3) / 2.0
			draw_colored_polygon(PackedVector2Array([top, a, b]), Color(gold.r * shade, gold.g * shade, gold.b * shade, 0.95))
			draw_colored_polygon(PackedVector2Array([bottom, b, a]), Color(gold.r * shade * 0.7, gold.g * shade * 0.7, gold.b * shade * 0.7, 0.95))
		draw_circle(c + Vector2(0, -6), 10.0 * glow, Color(Palette.STEWARD_GOLD_HOT, 0.8), true, -1.0, true)
		var outline := PackedVector2Array([top, ring[0], bottom, ring[3], top])
		draw_polyline(outline, Palette.STEWARD_GOLD_HOT, 2.0, true)
