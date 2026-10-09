extends TestCase
## Every weapon in both modes, against a staged Custodian in the real level, driven through the same
## input actions a player uses. Aim comes from facing (pad selected, stick centred).

var level: Level


func _setup_level(weapon_id: String, mode: Loadout.Mode) -> void:
	GameState.new_run()
	# Every weapon this test carries has been found.
	for id: String in WeaponDefs.PLAYABLE:
		GameState.give_weapon(id)
	var other := WeaponDefs.DEFIB if weapon_id != WeaponDefs.DEFIB else WeaponDefs.BATON
	var modes: Dictionary[String, String] = {weapon_id: Loadout.mode_key(mode), other: "tuned"}
	var ids: Array[String] = [weapon_id, other]
	GameState.set_loadout(ids, modes)
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_physics_frames(2)
	level.remove_all_enemies()
	Controls.device = Controls.Device.PAD
	Steward.voice_on = true


func _stage_custodian(tiles_ahead: int) -> Enemy:
	var cell := level.player.cell() + Vector2i(0, -tiles_ahead)
	var e := level.add_enemy(Custodian.new(), cell, Custodian.MAX_INTEGRITY)
	level.player.face(Vector2(0, -1))
	return e


func after_each() -> void:
	for action: StringName in [&"attack_primary", &"attack_secondary", &"move_up", &"dodge"]:
		Input.action_release(action)
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)


## Presses attack_primary in the pattern each weapon/mode needs, until the target dies or time runs out.
func _attack_until_dead(target: Enemy, pattern: String, seconds: float) -> bool:
	var frames := int(seconds * 60.0)
	for f: int in frames:
		if not is_instance_valid(target) or not target.is_alive():
			Input.action_release(&"attack_primary")
			return true
		level.player.face(Iso.ground_dir_between(level.player.global_position, target.global_position))
		match pattern:
			"hold":
				Input.action_press(&"attack_primary")
			"beat":
				if f % 18 < 2:
					Input.action_press(&"attack_primary")
				else:
					Input.action_release(&"attack_primary")
			"charge":
				# Hold ~0.65 s (the manual sweet spot), release, wait out the cooldown.
				if f % 120 < 39:
					Input.action_press(&"attack_primary")
				else:
					Input.action_release(&"attack_primary")
			"tap":
				if f % 80 < 2:
					Input.action_press(&"attack_primary")
				else:
					Input.action_release(&"attack_primary")
		await wait_physics_frames(1)
	Input.action_release(&"attack_primary")
	return not is_instance_valid(target) or not target.is_alive()


func _kills(weapon_id: String, mode: Loadout.Mode, pattern: String, tiles_ahead: int) -> void:
	await _setup_level(weapon_id, mode)
	var target := _stage_custodian(tiles_ahead)
	var killed := await _attack_until_dead(target, pattern, 8.0)
	check(killed, "%s (%s) kills a Custodian" % [weapon_id, Loadout.mode_key(mode)])
	check(level.player.is_alive(), "and the Operator is still standing")


func test_baton_tuned_kills() -> void:
	await _kills(WeaponDefs.BATON, Loadout.Mode.TUNED, "hold", 1)


func test_baton_manual_kills() -> void:
	await _kills(WeaponDefs.BATON, Loadout.Mode.MANUAL, "beat", 1)


func test_drone_tuned_kills() -> void:
	await _kills(WeaponDefs.RIOT_DRONE, Loadout.Mode.TUNED, "hold", 3)


func test_drone_manual_kills() -> void:
	await _kills(WeaponDefs.RIOT_DRONE, Loadout.Mode.MANUAL, "hold", 3)


func test_gauntlet_tuned_kills() -> void:
	await _kills(WeaponDefs.DEFIB, Loadout.Mode.TUNED, "tap", 1)


func test_gauntlet_manual_kills() -> void:
	await _kills(WeaponDefs.DEFIB, Loadout.Mode.MANUAL, "charge", 1)


func test_tuned_baton_finds_a_target_the_player_isnt_facing() -> void:
	await _setup_level(WeaponDefs.BATON, Loadout.Mode.TUNED)
	var target := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(1, 0), Custodian.MAX_INTEGRITY)
	level.player.face(Vector2(-1, 0))
	Input.action_press(&"attack_primary")
	await wait_physics_frames(4)
	Input.action_release(&"attack_primary")
	check(target.integrity.value < Custodian.MAX_INTEGRITY, "tuned swing turned to find the Custodian behind")


func test_manual_baton_only_hits_where_aimed() -> void:
	await _setup_level(WeaponDefs.BATON, Loadout.Mode.MANUAL)
	var target := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(1, 0), Custodian.MAX_INTEGRITY)
	level.player.face(Vector2(-1, 0))
	Input.action_press(&"attack_primary")
	await wait_physics_frames(4)
	Input.action_release(&"attack_primary")
	check_eq(target.integrity.value, Custodian.MAX_INTEGRITY, "manual swing went where it was aimed")


func test_manual_drone_overheats_and_tuned_never_does() -> void:
	await _setup_level(WeaponDefs.RIOT_DRONE, Loadout.Mode.MANUAL)
	var drone := level.player.weapons[0] as RiotDrone
	Input.action_press(&"attack_primary")
	var overheated := false
	for f: int in 300:
		await wait_physics_frames(1)
		overheated = overheated or drone.is_overheated()
	check(overheated, "five seconds of held manual fire overheats")
	Input.action_release(&"attack_primary")
	await after_each()
	await _setup_level(WeaponDefs.RIOT_DRONE, Loadout.Mode.TUNED)
	var tuned := level.player.weapons[0] as RiotDrone
	Input.action_press(&"attack_primary")
	var ever_locked := false
	for f: int in 300:
		await wait_physics_frames(1)
		ever_locked = ever_locked or tuned.is_overheated()
	Input.action_release(&"attack_primary")
	check_false(ever_locked, "the Steward manages the heat")


func test_manual_gauntlet_overload_bites_the_operator() -> void:
	await _setup_level(WeaponDefs.DEFIB, Loadout.Mode.MANUAL)
	Input.action_press(&"attack_primary")
	await wait_physics_frames(90)
	Input.action_release(&"attack_primary")
	check(level.player.integrity.value < Operator.MAX_INTEGRITY, "held past the window, the gauntlet shocked its wearer")


func test_muted_steward_makes_tuned_weapons_manual_and_hits_harder() -> void:
	await _setup_level(WeaponDefs.BATON, Loadout.Mode.TUNED)
	var baton := level.player.weapons[0]
	check(baton.is_tuned())
	Steward.voice_on = false
	check_false(baton.is_tuned(), "no Steward, no tuning")
	level.player.take_hit(10.0, level.player.global_position + Vector2(50, 0))
	check_near(level.player.integrity.value, Operator.MAX_INTEGRITY - 14.0, 0.01, "muted: ×1.4 damage")
	Steward.voice_on = true


func test_dodge_invulnerability_avoids_damage() -> void:
	await _setup_level(WeaponDefs.BATON, Loadout.Mode.TUNED)
	level.player.dodge.try_start(Vector2(0, -1))
	var landed := level.player.take_hit(10.0, level.player.global_position + Vector2(50, 0))
	check_false(landed, "rolled through it")
	check_eq(level.player.integrity.value, Operator.MAX_INTEGRITY)


func test_downed_operator_respawns_at_the_checkpoint() -> void:
	await _setup_level(WeaponDefs.BATON, Loadout.Mode.TUNED)
	level.player.self_damage(500.0)
	check_false(level.player.is_alive(), "downed")
	await wait_seconds(Operator.DOWNED_SECONDS + 0.2)
	check(level.player.is_alive(), "back up")
	check_eq(level.player.integrity.value, Operator.MAX_INTEGRITY)
	check_eq(level.player.cell(), level.checkpoint_cell)
