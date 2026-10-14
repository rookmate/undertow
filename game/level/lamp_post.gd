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
var look: DistrictLook = DistrictLook.for_district("vellum")


func setup(cell: Vector2i, district_look: DistrictLook = null) -> void:
	position = Iso.cell_center(cell)
	if district_look != null:
		look = district_look
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	if look.lamp_texture != null:
		var housing := DrawOps.new()
		# Source aperture center maps to (0, -POST_HEIGHT); the stepped foot extends to y=8.
		housing.textured_poly(PackedVector2Array([Vector2(-21, 8), Vector2(22, 8), Vector2(22, -193), Vector2(-21, -193)]),
			PackedVector2Array([Vector2.DOWN, Vector2.ONE, Vector2.RIGHT, Vector2.ZERO]), look.lamp_texture)
		housing.add_layer(self, &"PaintedHousing")
	WetReflections.add(self, Vector2.ZERO, POST_HEIGHT, Palette.STEWARD_GOLD, func() -> bool: return lit)


func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2.ZERO, 16.0, 8.0), Color(Palette.NEAR_BLACK, 0.5))
	draw_circle(Vector2(0, -POST_HEIGHT), 14.0, Palette.BLACK_MIRROR, true, -1.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
