class_name HangingContainer
extends Node2D
## A shipping container frozen mid-lift over the quay: cables up into the dark, a shadow on the ground
## below, a slow sway in the wind. Nothing holds it but the crane's last instruction.

const HEIGHT := 210.0

var cell: Vector2i
var look: DistrictLook = DistrictLook.new()
var _t: float = 0.0
var _colour: Color


func setup(at: Vector2i, district_look: DistrictLook) -> void:
	cell = at
	look = district_look
	position = Iso.cell_center(at)
	z_index = 2
	var shades: Array[Color] = [Palette.CONTAINER_TEAL, Palette.CONTAINER_RED, Palette.CONTAINER_GREY, Palette.RUST]
	_colour = shades[absi(hash(at)) % shades.size()]
	_t = float(absi(hash(at)) % 100) / 10.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var sway := sin(_t * 0.6) * 6.0
	draw_colored_polygon(Fx.ground_ellipse(0.75, 20, false), Color(Palette.NEAR_BLACK, 0.35))
	var base := Vector2(sway, -HEIGHT)
	for x: float in [-48.0, 48.0]:
		ArtCatalog.link(self, "pipe", base + Vector2(x, -56), Vector2(x * 0.5, -HEIGHT - 260), 2.0)
	ArtCatalog.paint(self, "container", Rect2(base + Vector2(-52, -76), Vector2(104, 102)), _colour.lightened(0.55))
