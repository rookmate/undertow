class_name WeaponFind
extends Interactable
## A reclaimed city tool lying where it was left: the Riot Drone in the Warden depot built to watch the
## Tideworks strikers. Take it and it's yours from then on (the loadout offers it), and in your second
## hand straight away. Its id comes from the map ('@' line): the weapon it is.

var weapon_id: String = ""
var cell: Vector2i


func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	weapon_id = id
	cell = at
	position = Iso.cell_center(at)


func is_present() -> bool:
	return super.is_present() and not GameState.run.weapons_owned.has(weapon_id)


func prompt_verb() -> String:
	return "TAKE THE " + WeaponDefs.display_name(weapon_id).to_upper()


func interact(player: Operator) -> void:
	if not can_interact():
		return
	GameState.give_weapon(weapon_id)
	player.add_weapon(weapon_id, Loadout.chosen_mode(GameState.run, weapon_id))
	Sound.play(&"core_take", global_position)
	var line := "find_" + weapon_id
	if VoiceLines.fixed(line) != "":
		Narrator.speak_text(line, VoiceLines.fixed(line))
	queue_redraw()


func _process(_delta: float) -> void:
	visible = is_present()


func _draw() -> void:
	# A Warden's drone on a rack, chipped municipal paint, its asset tag half peeled.
	draw_colored_polygon(PackedVector2Array([Vector2(-26, 0), Vector2(0, 13), Vector2(26, 0), Vector2(0, -13)]), Color(Palette.NEAR_BLACK, 0.4))
	draw_rect(Rect2(-18, -34, 36, 6), Palette.IRON_DARK)
	draw_circle(Vector2(0, -44), 13.0, Palette.GREY_COLD.darkened(0.3), true, -1.0, true)
	for x: float in [-22.0, 22.0]:
		draw_line(Vector2(0, -44), Vector2(x, -50), Palette.IRON_DARK, 3.0, true)
		draw_circle(Vector2(x, -50), 6.0, Palette.IRON_DARK, false, 2.0, true)
	draw_rect(Rect2(4, -40, 10, 5), Palette.PAPER)
