class_name WeaponFind
extends Interactable
## A reclaimed city tool lying where it was left: the Riot Drone in the Warden depot built to watch the
## Tideworks strikers, the Defib Gauntlet on a crash cart in Mercy General's resus bay. Take it and it's
## yours from then on (the loadout offers it), and in your second hand straight away if it's free. Its
## id comes from the map ('@' line): the weapon it is.

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
	Narrator.say_fixed("find_" + weapon_id)
	queue_redraw()


func _process(_delta: float) -> void:
	visible = is_present()


func _draw() -> void:
	draw_colored_polygon(Fx.ground_ellipse(0.4, 18, false), Color(Palette.NEAR_BLACK, 0.4))
	if weapon_id == WeaponDefs.DEFIB:
		ArtCatalog.paint(self, "crash_cart", Rect2(-20, -65, 40, 65))
		ArtCatalog.fit(self, "gauntlet", Rect2(-15, -73, 30, 24))
	elif weapon_id == WeaponDefs.SIGNAL_JAMMER:
		ArtCatalog.paint(self, "crate", Rect2(-20, -29, 40, 39))
		ArtCatalog.fit(self, "jammer", Rect2(-14, -62, 28, 38))
	else:
		ArtCatalog.paint(self, "rack", Rect2(-20, -40, 40, 44))
		ArtCatalog.fit(self, "drone", Rect2(-30, -64, 60, 32))
