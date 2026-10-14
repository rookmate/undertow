class_name WardBoat
extends Interactable
## The Wardfolk's boat on the depot slipway at the border. Carrying Noor, set her down in it: she comes
## home to the Ark with you.

var cell: Vector2i


func setup(owner_level: Level, at: Vector2i) -> void:
	level = owner_level
	cell = at
	position = Iso.cell_center(at)


func can_interact() -> bool:
	return level != null and level.player != null and level.player.carrying


func blocked_reason() -> String:
	return "" if can_interact() else "The Wardfolk's boat. Someone's coming back for it."


func prompt_verb() -> String:
	return "SET NOOR DOWN IN THE BOAT"


func interact(player: Operator) -> void:
	if not can_interact():
		return
	player.set_carrying(false)
	GameState.noor_comes_home()
	Narrator.say_fixed("noor_home")
	Sound.play(&"dressing", global_position)


func _draw() -> void:
	draw_colored_polygon(Fx.ground_ellipse(0.85, 20, false), Color(Palette.NEAR_BLACK, 0.4))
	ArtCatalog.paint(self, "boat", Rect2(-60, -64, 120, 86))
	ArtCatalog.paint(self, "lantern_housing", Rect2(14, -60, 12, 24))
	draw_circle(Vector2(20, -45), 3.0, Palette.WARD_CYAN_HOT, true, -1.0, true)
