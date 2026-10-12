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
	draw_colored_polygon(PackedVector2Array([Vector2(-56, 0), Vector2(0, 26), Vector2(56, 0), Vector2(0, -26)]), Color(Palette.NEAR_BLACK, 0.4))
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -10), Vector2(10, 22), Vector2(60, -4), Vector2(-6, -34)]), Palette.BOATHOUSE)
	draw_colored_polygon(PackedVector2Array([Vector2(-48, -14), Vector2(8, 12), Vector2(48, -8), Vector2(-4, -28)]), Palette.PIER_PLANK)
	draw_line(Vector2(-6, -34), Vector2(-6, -84), Palette.IRON_DARK, 3.0)
	draw_rect(Rect2(-2, -86, 10, 12), Palette.WARD_CYAN_HOT)
