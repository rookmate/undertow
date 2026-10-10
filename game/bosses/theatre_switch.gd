class_name TheatreSwitch
extends WeakPoint
## The theatre lamp's switch panel by the door: a manual override the night staff used when the Steward
## dimmed the lights. Throw it while the Surgeon is laying a line and it loses its guide.


func _draw() -> void:
	draw_shadow(12.0, 6.0)
	var flash := hit_flash()
	draw_rect(Rect2(-12, -64, 24, 34), Palette.WARD_WALL_SHADE.lerp(Palette.IVORY, flash))
	draw_rect(Rect2(-12, -30, 24, 30), Palette.WARD_WALL_SHADE.darkened(0.3))
	draw_line(Vector2(0, -54), Vector2(8, -40), Palette.IRON_DARK, 4.0, true)
	draw_circle(Vector2(0, -58), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
