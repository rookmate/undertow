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


func _count(ark: ArkLevel, facade: BuildingCell.Facade) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == facade:
			n += 1
	return n
