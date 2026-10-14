class_name HandValve
extends WeakPoint
## The old hand valve on the basin's edge, from when crews ran the pumps (Greywater): a wheel on a pipe.
## Turn it while the Lung is filling a quarter and the line chokes.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	ArtCatalog.actor(self, "hand_valve", 61.0, Vector2.ZERO, hit_flash())
	draw_circle(Vector2(0, -46), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
