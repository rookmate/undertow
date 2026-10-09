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
	# Its shadow on the wet quay.
	draw_colored_polygon(PackedVector2Array([Vector2(-48, 0), Vector2(0, 24), Vector2(48, 0), Vector2(0, -24)]), Color(Palette.NEAR_BLACK, 0.35))
	var base := Vector2(sway, -HEIGHT)
	var w := 52.0
	var h := 50.0
	var front := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, 26), base + Vector2(0, 26 - h), base + Vector2(-w, -h)])
	var side := PackedVector2Array([base + Vector2(0, 26), base + Vector2(w, 0), base + Vector2(w, -h), base + Vector2(0, 26 - h)])
	var top := PackedVector2Array([base + Vector2(-w, -h), base + Vector2(0, 26 - h), base + Vector2(w, -h), base + Vector2(0, -26 - h)])
	draw_colored_polygon(front, _colour.darkened(0.2))
	draw_colored_polygon(side, _colour)
	draw_colored_polygon(top, _colour.lightened(0.1))
	for k: int in 6:
		var u := (k + 0.5) / 6.0
		draw_line(front[0].lerp(front[1], u), front[3].lerp(front[2], u), Color(Palette.NEAR_BLACK, 0.25), 1.5)
	for c: Vector2 in [top[0], top[2]]:
		draw_line(c, Vector2(c.x * 0.5, -HEIGHT - 260.0), Palette.IRON_DARK, 1.5, true)
