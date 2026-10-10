class_name TideWater
extends Node2D
## The tide drawn over Greywater's low streets: standing water that rises with the swell, covers the
## streets at high water and drains with the ebb; at low water only the wet sheen and the kelp show.

var tide: Tide
var _t: float = 0.0


func setup(owner_tide: Tide) -> void:
	tide = owner_tide
	z_index = -11


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if tide == null:
		return
	var level := tide.water_level()
	if level <= 0.01:
		return
	for c: Vector2i in tide.cells:
		draw_colored_polygon(Iso.cell_diamond(c), Color(Palette.WATER_DEEP, 0.75 * level))
		if (c.x * 3 + c.y * 5) % 4 == 0:
			var p := Iso.cell_center(c) + Vector2(sin(_t * 1.3 + c.x) * 12.0, 0.0)
			draw_line(p + Vector2(-18, 0), p + Vector2(18, 0), Color(Palette.WATER_SHEEN, 0.5 * level), 2.0, true)
