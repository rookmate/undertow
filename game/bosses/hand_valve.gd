class_name HandValve
extends WeakPoint
## The old hand valve on the basin's edge, from when crews ran the pumps (Greywater): a wheel on a pipe.
## Turn it while the Lung is filling a quarter and the line chokes.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	var flash := hit_flash()
	draw_rect(Rect2(-6, -38, 12, 38), Palette.IRON_DARK.lerp(Palette.IVORY, flash))
	draw_line(Vector2(-18, -10), Vector2(18, -10), Palette.IRON_DARK.lightened(0.15), 8.0, true)
	draw_arc(Vector2(0, -46), 15.0, 0.0, TAU, 20, Palette.RUST.lerp(Palette.IVORY, flash), 4.0, true)
	for k: int in 3:
		var a := TAU * k / 3.0 + 0.3
		draw_line(Vector2(0, -46), Vector2(0, -46) + Vector2(cos(a), sin(a)) * 14.0, Palette.RUST, 2.5, true)
	draw_circle(Vector2(0, -46), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
