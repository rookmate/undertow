class_name HoistBrake
extends WeakPoint
## The Crane's hoist brake: a hand lever on a gantry leg, from before the cranes ran themselves. Throw it
## while the hoist is lifting and the load drops back onto the Crane's own trolley.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	ArtCatalog.actor(self, "hoist_brake", 65.0, Vector2.ZERO, hit_flash())
	draw_circle(Vector2(0, -24), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
