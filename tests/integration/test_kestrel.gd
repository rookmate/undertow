extends TestCase
## Kestrel Heights, where the believers lived: Lamplighters that light your way while the Steward
## listens and drag you back to the Lattice when you mute it, gates that won't open for you muted, a
## child's room the Lattice never saw, and the place hints that teach the voice.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load("res://game/level/kestrel_heights.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _lamplighters() -> Array[Lamplighter]:
	var out: Array[Lamplighter] = []
	for n: Node in level.world.get_children():
		if n is Lamplighter:
			out.append(n as Lamplighter)
	return out


func _gate() -> Array[SmartGate]:
	var out: Array[SmartGate] = []
	for n: Node in level.world.get_children():
		if n is SmartGate:
			out.append(n as SmartGate)
	return out


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func _nearest_indexed_distance(at: Vector2) -> float:
	var best := INF
	for c: Vector2i in level.grid.all_cells():
		if level.grid.is_indexed(c) and level.grid.is_walkable(c):
			best = minf(best, Iso.ground_distance(at, Iso.cell_center(c)))
	return best


func test_kestrel_is_a_real_district() -> void:
	check(level.grid.validate(false).is_empty(), "%s" % [level.grid.validate(false)])
	check_eq(level.look.wall, Palette.KESTREL_LIMESTONE, "pale stone, not the Vellum's brick")
	check_eq(_lamplighters().size(), level.grid.cells_with("X").size(), "every Lamplighter is there")
	check_eq(CoreChoice.offer("kestrel", GameState.run).size(), 3, "two power cores and one truth")
	GameState.find_core("kestrel_truth_childs_map")
	check_eq(CoreChoice.offer("kestrel", GameState.run).size(), 4, "and the child's map, if you found it")


func test_while_it_listens_lamplighters_light_the_way_and_are_not_targets() -> void:
	var lamp := _lamplighters()[0]
	check_false(lamp.is_in_group(&"enemies"), "not something your weapons aim at")
	check_false(lamp.hunting)
	check_false(level.hittable_enemies().has(lamp) or level.steward_targets().has(lamp))
	await _put(lamp.grid_cell() + Vector2i(3, 0))
	await wait_seconds(3.0)
	check_false(lamp.hooking, "it never takes hold while the Steward listens")
	check_eq(level.player.integrity.value, level.player.integrity.max_value, "and never hurts you")


## Swings the baton (tuned, then manual) at a lamp a tile in front of you; returns what it took.
func _swing_at(lamp: Lamplighter) -> float:
	var p := level.player
	# On a pad with the stick at rest, the player's own aim is where they face.
	Controls.device = Controls.Device.PAD
	p.set_physics_process(false)
	lamp.set_physics_process(false)
	lamp.global_position = p.global_position + Iso.ground_velocity(Vector2(1, 0), 1.0)
	p.face(Vector2(1, 0))
	var before := lamp.integrity.value
	var baton := p.weapons[0] as TrafficBaton
	for mode: Loadout.Mode in [Loadout.Mode.TUNED, Loadout.Mode.MANUAL]:
		baton.chosen_mode = mode
		baton.call(&"_swing", false)
		var raw := Vector2(1, 0).rotated(deg_to_rad(8.0))
		var drift := rad_to_deg(absf(p.assisted_aim(raw).angle_to(raw)))
		if not lamp.hunting:
			check(drift < 0.01, "and the Steward's aim doesn't bend toward it (%.2f°)" % drift)
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	return before - lamp.integrity.value


## Only this lamp nearby, so nothing else draws the aim.
func _alone_with(lamp: Lamplighter) -> void:
	for e: Enemy in level.living_enemies():
		if e != lamp:
			e.queue_free()
	await _put(lamp.grid_cell() + Vector2i(-1, 0))


func test_a_lamp_walking_with_you_cant_be_struck() -> void:
	var lamp := _lamplighters()[0]
	await _alone_with(lamp)
	check_eq(_swing_at(lamp), 0.0, "tuned or manual, the baton passes it by")
	check_false(lamp.hooking)


func test_muted_a_lamplighter_is_a_target_like_any_other() -> void:
	var lamp := _lamplighters()[0]
	await _alone_with(lamp)
	Steward.set_voice(false)
	await wait_frames(1)
	check(level.hittable_enemies().has(lamp))
	check(_swing_at(lamp) > 0.0, "muted, it hunts you, and you can hit it")


func test_muted_a_lamplighter_hooks_you_and_drags_you_toward_the_lattice() -> void:
	var lamp := _lamplighters()[0]
	# Stand on a lawn-side cell off the walk is impossible (lawns are solid), so stand just off the
	# Lattice on the child's gravel walk if it's in reach; otherwise on the walk itself.
	await _put(lamp.grid_cell() + Vector2i(0, 2))
	lamp.global_position = level.player.global_position + Iso.ground_velocity(Vector2(1, 0), 3.0)
	Steward.set_voice(false)
	await wait_frames(1)
	check(lamp.hunting and lamp.is_in_group(&"enemies"), "muted, it hunts")
	await wait_seconds(Lamplighter.WINDUP + 0.3)
	check(lamp.hooking, "it takes hold after its windup")
	check(level.player.is_pulled(), "and drags you")
	check(level.player.integrity.value < level.player.integrity.max_value, "the beam stings")
	lamp.take_hit(1.0, Vector2(1, 0), 0.0, 0.0)
	await wait_frames(1)
	check_false(lamp.hooking, "hitting it breaks its hold")
	check_false(level.player.is_pulled())


func test_the_drag_goes_toward_the_lattice_from_off_it() -> void:
	var lamp := _lamplighters()[0]
	var off := Vector2i(6, 14)
	check_false(level.grid.is_indexed(off), "the garden walk is off the Lattice")
	await _put(off)
	lamp.global_position = Iso.cell_center(Vector2i(10, 14))
	Steward.set_voice(false)
	await wait_seconds(Lamplighter.WINDUP + 0.2)
	var before := _nearest_indexed_distance(level.player.global_position)
	await wait_seconds(0.8)
	check(_nearest_indexed_distance(level.player.global_position) < before, "pulled back toward the lit walk")
	Steward.set_voice(true)
	await wait_frames(1)
	check_false(level.player.is_pulled(), "bringing the Steward back releases you")


func test_gates_shut_when_muted_but_never_on_you() -> void:
	var gates := _gate()
	check_eq(gates.size(), 2)
	check(gates.all(func(g: SmartGate) -> bool: return g.open), "open while it listens")
	await _put(gates[0].cell)
	Steward.set_voice(false)
	await wait_seconds(SmartGate.CLOSE_DELAY + 0.4)
	check(gates[0].open, "it waits while you're in the way")
	check_false(gates[1].open, "the other leaf has shut")
	await _put(Vector2i(24, 14))
	await wait_seconds(0.3)
	check_false(gates[0].open, "and the first shuts once you're clear")
	var heard := Sound.heard(&"gate_shut")
	check(heard >= 2, "with a clang")
	Steward.set_voice(true)
	await wait_frames(2)
	check(gates.all(func(g: SmartGate) -> bool: return g.open), "and they open for it again")


func test_the_childs_room_is_where_the_lattice_never_looked() -> void:
	var t := level.grid.first("T")
	check_eq(level.grid.floor_at(t), LevelGrid.Floor.TIMBER, "the map lies on her floorboards")
	check_false(level.grid.is_indexed(t), "the room is off the Lattice")
	var route := level.grid.reachable_from(level.grid.start_cell(), false)
	check(route.has(t + Vector2i(0, 1)), "but you can walk there")
	await _put(t + Vector2i(0, 1))
	await wait_seconds(Level.COVERAGE_GRACE + 0.3)
	check(Steward.assists().signal_lost, "and the Steward loses you inside")


func test_place_hints_teach_the_voice_where_it_matters() -> void:
	var hints: LevelHints = null
	for c: Node in level.get_children():
		if c is LevelHints:
			hints = c
	await _put(Vector2i(9, 15))
	await wait_frames(2)
	check(hints.place_hint.contains("MUTE THE STEWARD"), "by the hedge gap: %s" % hints.place_hint)
	check(hints.place_hint.begins_with(Controls.prompt(&"voice_toggle")), "with the key to press")
	Steward.set_voice(false)
	await wait_frames(2)
	check_eq(hints.place_hint, "", "muted, that hint has done its job")
	await _put(Vector2i(28, 19))
	await wait_frames(2)
	check(hints.place_hint.contains("GATES WON'T OPEN"), "by the shut gate: %s" % hints.place_hint)


func test_machines_give_up_scrap() -> void:
	var before := GameState.run.scrap
	var e := level.add_enemy(Custodian.new(), level.grid.start_cell() + Vector2i(2, 0), Custodian.MAX_INTEGRITY)
	e.take_hit(1000.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(GameState.run.scrap, before + 1, "a Custodian is worth a part")


## A place hint sits between the Steward's subtitles and the weapon cards, over neither: with two
## weapons carried and the longest hint in the game.
func test_a_place_hint_clears_the_weapon_cards_and_the_subtitles() -> void:
	var hints: LevelHints = null
	for c: Node in level.get_children():
		if c is LevelHints:
			hints = c
	var label: Label = hints.get("_hint")
	var longest := ""
	for id: String in LevelCatalog.LEVELS:
		var g := LevelGrid.load_file(LevelCatalog.map_of(id))
		for c: Vector2i in g.hints:
			if g.hints[c].length() > longest.length():
				longest = g.hints[c]
	label.text = longest
	await wait_frames(2)
	var view := level.get_viewport().get_visible_rect().size
	var hint := label.get_global_rect()
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	var text_w := font.get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# The line it draws, at the top of its box.
	var text := Rect2(Vector2(hint.get_center().x - text_w * 0.5, hint.position.y), Vector2(text_w, font.get_height(font_size)))
	var cards := Rect2(Vector2(HudView.MARGIN, view.y - HudView.MARGIN - HudView.CHIP_H), Vector2(2.0 * HudView.CHIP_W + 14.0, HudView.CHIP_H))
	check_false(text.intersects(cards), "the hint %s clears the cards %s" % [text, cards])
	check(text.position.y >= view.y - 190.0 + 20.0, "and sits below the subtitles' last line (%s)" % text)
	check(text.end.y <= cards.position.y, "above the cards")

