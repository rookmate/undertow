class_name SignalBox
extends WeakPoint
## The Loop junction's signal box: the lineside cabinet the Conductor switches its points through.


func _draw() -> void:
	draw_shadow(16.0, 8.0)
	var flash := hit_flash()
	draw_rect(Rect2(-12, -46, 24, 46), Palette.IRON_DARK.lerp(Palette.IVORY, flash))
	draw_rect(Rect2(-12, -46, 24, 6), Palette.IRON_VERDIGRIS)
	draw_circle(Vector2(0, -32), 4.0, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
