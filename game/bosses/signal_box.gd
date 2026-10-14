class_name SignalBox
extends WeakPoint
## The Loop junction's signal box: the lineside cabinet the Conductor switches its points through.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	ArtCatalog.actor(self, "signal_box", 46.0, Vector2.ZERO, hit_flash())
	draw_circle(Vector2(0, -32), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
