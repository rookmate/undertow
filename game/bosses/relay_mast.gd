class_name RelayMast
extends WeakPoint
## The border's Lattice relay: the mast that links the Wardens, their Prime among them (Harbor Ward).
## Strike it while the Warden-Prime sweeps and it loses its link. Steward hardware: its lamp is gold.


func _draw() -> void:
	draw_shadow(14.0, 7.0)
	ArtCatalog.actor(self, "relay_mast", 138.0, Vector2.ZERO, hit_flash())
	draw_circle(Vector2(0, -124), 3.5, Palette.STEWARD_GOLD_HOT if not tell_on() else Palette.HUMAN_CREAM, true, -1.0, true)
