class_name WeaponIcon
extends Control
## Painted icons for the reclaimed city tools: chipped municipal paint, a half-peeled asset tag.

var weapon_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var key: String = {
		WeaponDefs.BATON: "baton", WeaponDefs.RIOT_DRONE: "drone",
		WeaponDefs.DEFIB: "gauntlet", WeaponDefs.SIGNAL_JAMMER: "jammer",
	}.get(weapon_id, "")
	if key != "":
		ArtCatalog.fit(self, key, Rect2(size * 0.1, size * 0.8))
	else:
		draw_string(UiFonts.heading(), size * 0.5 + Vector2(-10, 16), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Palette.GREY_DEEP)
