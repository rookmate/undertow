class_name HoistBrake
extends WeakPoint
## The Crane's hoist brake: a hand lever on a gantry leg, from before the cranes ran themselves. Throw it
## while the hoist is lifting and the load drops back onto the Crane's own trolley.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	var flash := hit_flash()
	draw_rect(Rect2(-8, -40, 16, 40), Palette.IRON_DARK.lerp(Palette.IVORY, flash))
	draw_line(Vector2(0, -36), Vector2(16, -60), Palette.RUST, 4.0, true)
	draw_circle(Vector2(16, -60), 5.0, Palette.RUST.lightened(0.2), true, -1.0, true)
	draw_circle(Vector2(0, -24), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
