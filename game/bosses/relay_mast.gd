class_name RelayMast
extends WeakPoint
## The border's Lattice relay: the mast that links the Wardens, their Prime among them (Harbor Ward).
## Strike it while the Warden-Prime sweeps and it loses its link. Steward hardware: its lamp is gold.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	var flash := hit_flash()
	draw_line(Vector2(0, 0), Vector2(0, -120), Palette.IRON_DARK.lerp(Palette.IVORY, flash), 6.0)
	for k: int in 3:
		var y := -60.0 - k * 22.0
		draw_line(Vector2(-14, y), Vector2(14, y), Palette.IRON_DARK, 3.0)
	draw_line(Vector2(0, -120), Vector2(-16, -138), Palette.GREY_COLD, 2.0, true)
	draw_line(Vector2(0, -120), Vector2(16, -138), Palette.GREY_COLD, 2.0, true)
	draw_circle(Vector2(0, -124), 5.0, Palette.STEWARD_GOLD_HOT if not tell_on() else Palette.HUMAN_CREAM, true, -1.0, true)
