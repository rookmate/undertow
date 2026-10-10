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
	# Past the Steward's introduction, as if cut short: the fight starts at once.
	Sound.hush()
	await wait_physics_frames(1)


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


## Finding, losing and getting back a weapon leaves the one in your hand alone, and the Steward goes on
## noticing what you fire. All through real presses: Interact at a find, the drone's trigger (real
## shots), a Salvager that comes for the drone by itself, beaten, and the drone fired again.
func test_finds_and_snatches_keep_the_weapon_in_hand_and_the_steward_watching() -> void:
	var modes: Dictionary[String, String] = {WeaponDefs.BATON: "tuned", WeaponDefs.RIOT_DRONE: "manual"}
	GameState.set_loadout([WeaponDefs.BATON] as Array[String], modes)
	await _open("res://game/level/tideworks.tscn")
	level.remove_all_enemies()
	Controls.device = Controls.Device.PAD
	var p := level.player
	var at := Vector2i(10, 12)
	p.position = Iso.cell_center(at)
	var find := WeaponFind.new()
	find.setup(level, at + Vector2i(1, 0), WeaponDefs.RIOT_DRONE)
	level.world.add_child(find)
	await wait_physics_frames(3)
	var heard: Array[StringName] = []
	var listen := func(id: String, _t: String) -> void:
		for l: LineSelector.Line in Narrator.selector.all_lines():
			if l.id == id:
				heard.append(l.event)
	Narrator.line_spoken.connect(listen)
	# The district's own entry line comes first; then the Steward is free to remark on what you do.
	var waited := 0
	while not heard.has(&"level_enter") and waited < 240:
		await wait_physics_frames(1)
		waited += 1
	var baton := p.weapons[0] as TrafficBaton
	await _press(&"attack_primary", 1)
	check(float(baton.get(&"_since_swing")) < TrafficBaton.SWING_SECONDS, "a swing under way")
	await _press(&"interact", 1)
	check(GameState.run.weapons_owned.has(WeaponDefs.RIOT_DRONE) and p.weapons.size() == 2, "the drone, taken off the find with Interact")
	check(is_same(p.weapons[0], baton), "the baton is the same baton")
	check(float(baton.get(&"_since_swing")) < TrafficBaton.SWING_SECONDS, "still mid-swing")
	check_eq(Sound.voice_line, "find_riot_drone", "the Steward has a view on the find")
	# Its next remark waits for the gap it keeps between lines.
	await wait_seconds(Narrator.MIN_GAP + 0.1)
	var profile := GameState.run.playstyle_profile
	var risk := profile.risk
	var shots := _shots()
	await _press(&"attack_secondary", 12)
	check(_shots() > shots, "the drone fires")
	check(profile.risk > risk, "the Steward sees it fired by hand")
	check(heard.has(&"weapon_manual"), "and says so: %s" % [heard])
	var drone := p.weapons[1]
	var thief := level.add_enemy(Salvager.new(), at + Vector2i(0, 2), Salvager.MAX_INTEGRITY) as Salvager
	waited = 0
	while p.weapons.size() == 2 and waited < 300:
		await wait_physics_frames(1)
		waited += 1
	check_eq(p.weapons.size(), 1, "a Salvager comes for the drone and takes it")
	check(is_same(p.weapons[0], baton) and not is_instance_valid(drone), "the drone, never the baton")
	thief.take_hit(1000.0, Vector2(1, 0), 0.0, 0.0)
	check(p.weapons.size() == 2 and p.weapons[1].weapon_id == WeaponDefs.RIOT_DRONE, "beaten, it drops it back")
	check(is_same(p.weapons[0], baton))
	await wait_seconds(StewardWatch.MODE_REPORT_EVERY + 0.1)
	risk = profile.risk
	shots = _shots()
	await _press(&"attack_secondary", 12)
	check(_shots() > shots and profile.risk > risk, "fired again, and still noticed")
	Narrator.line_spoken.disconnect(listen)
	Controls.device = Controls.Device.KEYBOARD_MOUSE


## Holds an action for some physics frames, then lets go.
func _press(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await wait_physics_frames(frames)
	Input.action_release(action)
	await wait_physics_frames(1)


## The Operator's shots in the air.
func _shots() -> int:
	var n := 0
	for c: Node in level.world.get_children():
		if c is Projectile and (c as Projectile).team == Projectile.Team.PLAYER:
			n += 1
	return n


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
