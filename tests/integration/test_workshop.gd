extends TestCase
## The Workshop: scrap buys a level at a time for each weapon's tuned and manual modes, each level hits
## harder in that mode only, and it stands on the Ark once the Tideworks is done.


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if not Steward.voice_on:
		Steward.set_voice(true)
	await wait_frames(1)


func test_upgrades_cost_scrap_a_level_at_a_time() -> void:
	var r := GameState.run
	check(GameState.buy_upgrade(WeaponDefs.BATON, "tuned") != "", "no scrap, no upgrade")
	GameState.add_scrap(20)
	check_eq(GameState.buy_upgrade(WeaponDefs.BATON, "tuned"), "")
	check_eq(r.scrap, 20 - Upgrades.COSTS[0])
	check_eq(Upgrades.level(r, WeaponDefs.BATON, "tuned"), 1)
	check_eq(GameState.buy_upgrade(WeaponDefs.BATON, "tuned"), "")
	check_eq(r.scrap, 20 - Upgrades.COSTS[0] - Upgrades.COSTS[1])
	check(GameState.buy_upgrade(WeaponDefs.BATON, "tuned") != "", "two levels at most")
	check_eq(Upgrades.level(r, WeaponDefs.BATON, "manual"), 0, "the manual mode is its own")
	check(GameState.buy_upgrade(WeaponDefs.RIOT_DRONE, "tuned") != "", "not before it's found")
	var back := RunState.from_dict(r.to_dict())
	check_eq(Upgrades.level(back, WeaponDefs.BATON, "tuned"), 2, "upgrades are saved")


func test_an_upgraded_mode_hits_harder_only_in_that_mode() -> void:
	var level := (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	var baton := level.player.weapons[0]
	check_near(baton.damage_scale(), 1.0, 0.0001)
	GameState.add_scrap(6)
	GameState.buy_upgrade(WeaponDefs.BATON, Loadout.mode_key(baton.mode()))
	check_near(baton.damage_scale(), 1.0 + Upgrades.DAMAGE_PER_LEVEL, 0.0001, "the mode it's running in hits harder")
	var e := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(0, -1), Custodian.MAX_INTEGRITY)
	e.set_physics_process(false)
	level.player.face(Vector2(0, -1))
	baton.call(&"_swing", false)
	var dealt := Custodian.MAX_INTEGRITY - e.integrity.value
	var expected: float = (TrafficBaton.TUNED_DAMAGE[0] if baton.is_tuned() else TrafficBaton.MANUAL_DAMAGE[0]) * baton.damage_scale()
	check_near(dealt, expected, 0.01, "and lands that much harder")
	Steward.set_voice(false)
	check_near(baton.damage_scale(), 1.0 if Loadout.mode_key(baton.chosen_mode) == "tuned" else 1.0 + Upgrades.DAMAGE_PER_LEVEL, 0.0001, "muted, a tuned upgrade waits for the Steward")
	level.queue_free()
	await wait_frames(2)


func test_the_workshop_stands_once_the_tideworks_is_done() -> void:
	var bare := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(bare)
	await wait_frames(2)
	check_eq(_count(bare, BuildingCell.Facade.WORKSHOP), 0, "no Workshop before the Tideworks")
	bare.queue_free()
	await wait_frames(1)
	GameState.restore_building("workshop")
	GameState.add_scrap(10)
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(2)
	check(_count(ark, BuildingCell.Facade.WORKSHOP) > 0, "the Workshop stands")
	var screen := ark.open_workshop()
	await wait_frames(2)
	check(Modals.is_top(screen) and get_tree().paused)
	check_eq((screen.get("_rows") as Dictionary).size(), 2, "the baton, tuned and manual (only what's been found)")
	screen.buy(WeaponDefs.BATON, "manual")
	check_eq(Upgrades.level(GameState.run, WeaponDefs.BATON, "manual"), 1)
	check_eq(Sound.voice_line, "workshop_manual", "the Steward has a view on doing it yourself")
	check(SaveService.has_save(), "saved")
	screen.close()
	ark.queue_free()
	await wait_frames(2)


## "Stop praising me" holds at the Workshop's own counter: buying what the Steward runs gets no praise,
## said or shown; buying what you run still gets its plain remark. Pressed through the screen's rows.
func test_stop_praising_me_holds_at_the_workshop() -> void:
	GameState.restore_building("workshop")
	GameState.add_scrap(20)
	GameState.set_override(Overrides.NO_PRAISE, true)
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(2)
	var screen := ark.open_workshop()
	await wait_frames(2)
	var rows: Dictionary = screen.get("_rows")
	var reply: Label = screen.get("_reply")
	Sound.hush()
	var voices := Sound.heard(&"voice")
	(rows[Upgrades.key(WeaponDefs.BATON, "tuned")] as Button).pressed.emit()
	check_eq(Upgrades.level(GameState.run, WeaponDefs.BATON, "tuned"), 1, "bought")
	check_eq(Sound.heard(&"voice"), voices, "and not praised aloud")
	check_eq(reply.text, "", "nor in writing")
	(rows[Upgrades.key(WeaponDefs.BATON, "manual")] as Button).pressed.emit()
	check_eq(Sound.voice_line, "workshop_manual", "a plain remark is still said")
	check_eq(reply.text, VoiceLines.fixed("workshop_manual"))
	screen.close()
	ark.queue_free()
	await wait_frames(2)


func _count(ark: ArkLevel, facade: BuildingCell.Facade) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == facade:
			n += 1
	return n


## With every tool found (four of them, two rows each) the list scrolls: the last row is reachable by
## focus and nothing covers the way back.
func test_with_every_tool_found_the_list_scrolls_and_the_way_back_stays_clear() -> void:
	GameState.restore_building("workshop")
	for id: String in WeaponDefs.PLAYABLE:
		GameState.give_weapon(id)
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(2)
	var screen := ark.open_workshop()
	await wait_frames(2)
	var rows: Dictionary = screen.get("_rows")
	check_eq(rows.size(), WeaponDefs.PLAYABLE.size() * 2, "every tool, both modes")
	var scroll := screen.get_node("List") as ScrollContainer
	var back := screen.get("_back") as Button
	check(scroll.get_global_rect().end.y <= back.get_global_rect().position.y, "the list stops above the way back")
	var last: Button = rows.values()[rows.size() - 1]
	last.grab_focus()
	await wait_frames(3)
	check(scroll.scroll_vertical > 0, "focus scrolled the list to the last row")
	check(scroll.get_global_rect().encloses(last.get_global_rect()), "which is in view")
	screen.close()
	ark.queue_free()
	await wait_frames(2)
