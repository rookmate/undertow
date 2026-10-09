class_name LampPost
extends Node2D
## A Lattice lamp: every streetlamp installed after the Compact is a speaker, a microphone and a
## camera. With the voice on its lens burns gold and lights the street; muted, it goes dark.

const POST_HEIGHT := 150.0

var lit: bool = true:
	set(value):
		lit = value
		if _light != null:
			_light.enabled = lit
		if _lens != null:
			_lens.set_layer_enabled(0, lit)
		queue_redraw()

var _light: PointLight2D
var _lens: Emissive


func setup(cell: Vector2i) -> void:
	position = Iso.cell_center(cell)
	add_to_group(&"lattice_lamps")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial()
	_light.color = Palette.STEWARD_GOLD
	_light.energy = 2.3
	_light.texture_scale = 2.7
	_light.scale = Vector2(1.0, Iso.SQUASH)
	_light.position = Vector2(0, 6)
	add_child(_light)
	var head := Vector2(0, -POST_HEIGHT)
	var glow := DrawOps.new()
	glow.circle(head, 30.0, Color(Palette.STEWARD_GOLD, 0.12))
	glow.circle(head, 15.0, Palette.STEWARD_GOLD_HOT)
	glow.circle(head, 7.0, Color(Palette.HUMAN_CREAM.r * 2.0, Palette.HUMAN_CREAM.g * 2.0, Palette.HUMAN_CREAM.b * 2.0))
	_lens = Emissive.new()
	_lens.layers = [glow]
	add_child(_lens)
	WetReflections.add(self, Vector2.ZERO, POST_HEIGHT, Palette.STEWARD_GOLD, func() -> bool: return lit)


func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2.ZERO, 16.0, 8.0), Color(Palette.NEAR_BLACK, 0.5))
	draw_rect(Rect2(-7, -14, 14, 14), Palette.IRON_DARK)
	draw_line(Vector2(0, -12), Vector2(0, -POST_HEIGHT + 18.0), Palette.IRON_DARK, 5.0, true)
	draw_line(Vector2(0, -60), Vector2(0, -POST_HEIGHT + 18.0), Palette.IRON_VERDIGRIS, 1.5, true)
	draw_arc(Vector2(10, -POST_HEIGHT + 22.0), 10.0, PI, TAU * 0.95, 10, Palette.IRON_DARK, 3.0, true)
	var head := Vector2(0, -POST_HEIGHT)
	if not lit:
		draw_circle(head, 14.0, Palette.BLACK_MIRROR, true, -1.0, true)
		draw_arc(head, 14.0, 0.0, TAU, 20, Palette.GREY_DEEP, 2.0, true)
	draw_arc(head, 16.0, PI * 1.05, TAU * 0.98, 14, Palette.IRON_DARK, 4.0, true)
	draw_line(head + Vector2(-12, -14), head + Vector2(12, -14), Palette.IRON_DARK, 4.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
