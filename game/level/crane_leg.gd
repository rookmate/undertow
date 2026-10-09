class_name CraneLeg
extends Node2D
## A leg of a gantry crane: a tall lattice of rusted steel, a gold light-trace climbing it (ten years of
## the Steward laid over the docks: the gilt).

const HEIGHT := 260.0

var cell: Vector2i
var look: DistrictLook = DistrictLook.new()
var _gilt: Emissive


func setup(at: Vector2i, district_look: DistrictLook) -> void:
	cell = at
	look = district_look
	position = Iso.cell_center(at)
	add_to_group(&"gilt")
	var ops := DrawOps.new()
	ops.line(Vector2(6, -20), Vector2(6, -HEIGHT + 20), Palette.STEWARD_GOLD_HOT, 1.5)
	_gilt = Emissive.new()
	_gilt.layers = [ops]
	add_child(_gilt)


## Muted, the gilt dies with the rest of the Steward's light (LightingState drives every "gilt" node).
var gilt_lit: bool = true:
	set(value):
		gilt_lit = value
		if _gilt != null:
			_gilt.visible = value


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(0, 8), Vector2(16, 0), Vector2(0, -8)]), Color(Palette.NEAR_BLACK, 0.45))
	for x: float in [-15.0, 15.0]:
		draw_line(Vector2(x, 0), Vector2(x * 0.6, -HEIGHT), look.wall_shade, 8.0, true)
	var y := -18.0
	var flip := false
	while y > -HEIGHT + 20.0:
		var a := Vector2(-15.0 * (1.0 + y / HEIGHT * 0.4), y)
		var b := Vector2(15.0 * (1.0 + (y - 22.0) / HEIGHT * 0.4), y - 22.0)
		draw_line(a if not flip else Vector2(-a.x, a.y), b if not flip else Vector2(-b.x, b.y), look.wall, 3.0, true)
		y -= 22.0
		flip = not flip
