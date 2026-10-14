class_name TheatreSwitch
extends WeakPoint
## The theatre lamp's switch panel by the door: a manual override the night staff used when the Steward
## dimmed the lights. Throw it while the Surgeon is laying a line and it loses its guide.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	ArtCatalog.actor(self, "theatre_switch", 64.0, Vector2.ZERO, hit_flash())
	draw_circle(Vector2(0, -58), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
