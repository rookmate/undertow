extends TestCase
## The Tideworks: the Riot Drone found in the Wardens' depot, Salvagers that snatch your second weapon
## (never your only one), and the last Crane (both its solutions), against the real district and a
## test arena.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	if is_instance_valid(level):
		level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _open(path: String) -> void:
	level = (load(path) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	level.player.set_physics_process(false)
	await wait_physics_frames(2)


func _salvager_at(cell: Vector2i) -> Salvager:
	var s := level.add_enemy(Salvager.new(), cell, Salvager.MAX_INTEGRITY) as Salvager
	return s


func test_the_tideworks_is_a_real_district() -> void:
	await _open("res://game/level/tideworks.tscn")
	check(level.grid.validate(false).is_empty() and level.grid.content_problems().is_empty())
	check_eq(level.look.wall, Palette.RUST, "rust, not brick")
	check(level.boss is Crane and level.boss.weak_point is HoistBrake, "the last crane, and its brake")
	check_eq(CoreChoice.offer("tideworks", GameState.run).size(), 3)


func test_the_riot_drone_is_found_in_the_depot_and_goes_straight_to_hand() -> void:
	await _open("res://game/level/tideworks.tscn")
	check_eq(level.player.weapons.size(), 1, "only the baton coming in")
	var find: WeaponFind = null
	for n: Node in level.world.get_children():
		if n is WeaponFind:
			find = n
	check(find != null and find.weapon_id == WeaponDefs.RIOT_DRONE)
	find.interact(level.player)
	check(GameState.run.weapons_owned.has(WeaponDefs.RIOT_DRONE), "it's yours from now on")
	check_eq(level.player.weapons.size(), 2, "and in your second hand")
	check_eq(level.player.weapons[1].weapon_id, WeaponDefs.RIOT_DRONE)
	check_false(find.is_present(), "the rack is empty")
	check_eq(Sound.voice_line, "find_riot_drone", "the Steward has a view on it")


func test_a_salvager_snatches_your_second_weapon_and_drops_it_when_beaten() -> void:
	await _open("res://game/level/tideworks.tscn")
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)
	level.player.add_weapon(WeaponDefs.RIOT_DRONE, Loadout.Mode.TUNED)
	await _stand(Vector2i(10, 12))
	var s := _salvager_at(Vector2i(11, 12))
	s.call(&"_snatch", level.player)
	check_eq(level.player.weapons.size(), 1, "it took one")
	check_eq(level.player.weapons[0].weapon_id, WeaponDefs.BATON, "your second, never the baton in your hand")
	check_eq(s.loot.get("id"), WeaponDefs.RIOT_DRONE)
	s.take_hit(1000.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(level.player.weapons.size(), 2, "beaten, it drops it back to you")
	check(GameState.run.weapons_owned.has(WeaponDefs.RIOT_DRONE), "it was never lost")


func test_with_one_weapon_a_salvager_takes_scrap_not_your_only_weapon() -> void:
	await _open("res://game/level/tideworks.tscn")
	GameState.add_scrap(10)
	await _stand(Vector2i(10, 12))
	var s := _salvager_at(Vector2i(11, 12))
	s.call(&"_snatch", level.player)
	check_eq(level.player.weapons.size(), 1, "never your only weapon")
	check_eq(GameState.run.scrap, 10 - Salvager.SCRAP_TAKEN, "it lifts some parts instead")
	s.take_hit(1000.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(GameState.run.scrap, 10 + s.scrap_value, "and gives them back, and its own")


func test_the_crane_drops_where_you_stand_and_the_steward_calls_it() -> void:
	await _open("res://tests/fixtures/crane_arena.tscn")
	var crane := level.boss as Crane
	await _stand(Vector2i(9, 7))
	await wait_frames(2)
	check(crane.is_engaged, "close enough, it starts")
	check_eq(crane.phase, Crane.Phase.LIFT)
	await wait_seconds(Crane.LIFT_SECONDS + 0.05)
	check_eq(crane.phase, Crane.Phase.AIM)
	check_eq(Sound.voice_line, "crane_drop", "the Steward calls the drop")
	var before := level.player.integrity.value
	await wait_seconds(Crane.AIM_SECONDS + Crane.DROP_SECONDS + 0.2)
	check(level.player.integrity.value < before, "stay under it and it lands on you")


func test_the_crane_is_armoured_until_it_rests() -> void:
	await _open("res://tests/fixtures/crane_arena.tscn")
	var crane := level.boss as Crane
	await _stand(Vector2i(9, 7))
	await wait_frames(2)
	var full := crane.integrity.value
	crane.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(crane.integrity.value, full, "armoured while working")
	crane.call(&"_enter_phase", Crane.Phase.REST)
	crane.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(crane.integrity.value, full - 40.0, "open with its cab down")


func test_throwing_the_brake_while_it_lifts_stalls_it() -> void:
	await _open("res://tests/fixtures/crane_arena.tscn")
	var crane := level.boss as Crane
	await _stand(Vector2i(3, 8))
	await wait_frames(2)
	check(crane.is_switching(), "lifting")
	crane.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(crane.phase, Crane.Phase.STALLED, "the load drops back on its trolley")
	check(crane.is_vulnerable())
	check_eq(crane.stalls, 1)
	crane.call(&"_enter_phase", Crane.Phase.SWING)
	crane.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(crane.stalls, 1, "only while it's lifting")
	check_false(crane.weak_point.steward_aims_at, "and the Steward never points you at it")


func test_the_swing_misses_you_inside_its_ring() -> void:
	await _open("res://tests/fixtures/crane_arena.tscn")
	var crane := level.boss as Crane
	await _stand(Vector2i(8, 6))
	await wait_frames(2)
	check(Iso.ground_distance(level.player.global_position, crane.global_position) < Crane.SWING_INNER, "tucked in by the tower")
	crane.call(&"_enter_phase", Crane.Phase.SWING)
	var before := level.player.integrity.value
	await wait_seconds(Crane.SWING_SECONDS + 0.1)
	check_eq(level.player.integrity.value, before, "the load swings past outside you")
