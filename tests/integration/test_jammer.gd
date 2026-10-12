extends TestCase
## The Signal Jammer (Harbor Ward): it jams machines. Tuned, the Steward points it at the nearest machine
## (a short stun); manual, a charged wave all round you (the longer you hold, the wider and longer). A
## Warden it catches loses you. Its pulse trips a boss's weak point from range.

var level: Level


func _setup(path: String, mode: Loadout.Mode) -> void:
	GameState.new_run()
	for id: String in WeaponDefs.PLAYABLE:
		GameState.give_weapon(id)
	var ids: Array[String] = [WeaponDefs.SIGNAL_JAMMER, WeaponDefs.BATON]
	var modes: Dictionary[String, String] = {WeaponDefs.SIGNAL_JAMMER: Loadout.mode_key(mode), WeaponDefs.BATON: "tuned"}
	GameState.set_loadout(ids, modes)
	Steward.set_voice(true)
	Steward.set_coverage(true)
	level = (load(path) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_physics_frames(3)
	Controls.device = Controls.Device.PAD


func after_each() -> void:
	Input.action_release(&"attack_primary")
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)


func _press_for(frames: int) -> void:
	Input.action_press(&"attack_primary")
	await wait_physics_frames(frames)
	Input.action_release(&"attack_primary")
	await wait_physics_frames(2)


func test_it_is_a_real_tool_now() -> void:
	check(WeaponDefs.is_playable(WeaponDefs.SIGNAL_JAMMER))
	check_eq(WeaponDefs.display_name(WeaponDefs.SIGNAL_JAMMER), "Signal Jammer")
	check(WeaponDefs.asset_tag(WeaponDefs.SIGNAL_JAMMER).begins_with("NO ASSET TAG"), "the one tool that isn't the city's")


func test_tuned_it_stuns_the_nearest_machine() -> void:
	await _setup("res://game/level/vellum_street.tscn", Loadout.Mode.TUNED)
	level.remove_all_enemies()
	var c := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(2, 0), Custodian.MAX_INTEGRITY)
	level.player.face(Vector2(0, -1))
	await _press_for(4)
	await wait_physics_frames(roundi(SignalJammer.TUNED_DELAY * 60.0) + 2)
	check(c.integrity.value < Custodian.MAX_INTEGRITY, "the Steward pointed it at the Custodian beside you")
	check_eq(c.state, Enemy.State.STUNNED, "and it stopped dead")


func test_manual_the_longer_you_hold_the_wider_the_wave() -> void:
	await _setup("res://game/level/vellum_street.tscn", Loadout.Mode.MANUAL)
	level.remove_all_enemies()
	var far := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(0, -3), Custodian.MAX_INTEGRITY)
	far.set_physics_process(false)
	await _press_for(6)
	check_eq(far.integrity.value, Custodian.MAX_INTEGRITY, "a quick wave doesn't reach three tiles")
	await wait_physics_frames(roundi(SignalJammer.MANUAL_COOLDOWN * 60.0) + 2)
	await _press_for(roundi(SignalJammer.CHARGE_FULL * 60.0) + 2)
	check(far.integrity.value < Custodian.MAX_INTEGRITY, "a full one does")


func test_a_warden_it_catches_loses_you() -> void:
	await _setup("res://tests/fixtures/warden_arena.tscn", Loadout.Mode.MANUAL)
	var warden: Warden = null
	for e: Enemy in level.living_enemies():
		if e is Warden:
			warden = e
	level.player.position = Iso.cell_center(Vector2i(6, 3))
	await wait_physics_frames(10)
	check(warden.hunting, "it has you")
	await _press_for(roundi(SignalJammer.CHARGE_FULL * 60.0) + 2)
	check_false(warden.hunting, "jammed: it's lost you")
	check_eq(warden.state, Enemy.State.STUNNED)


func test_its_pulse_trips_a_weak_point_from_range() -> void:
	await _setup("res://tests/fixtures/lung_arena.tscn", Loadout.Mode.MANUAL)
	var lung := level.boss as Lung
	level.player.position = lung.weak_point.global_position + Iso.ground_velocity(Vector2(1, 0), 2.5)
	await wait_physics_frames(3)
	Sound.hush()
	await wait_physics_frames(2)
	# Charged first, released while it fills (the fill is shorter than a full charge).
	Input.action_press(&"attack_primary")
	await wait_physics_frames(roundi(SignalJammer.CHARGE_FULL * 60.0) + 2)
	lung.call(&"_start_cycle")
	check(lung.is_switching(), "filling")
	Input.action_release(&"attack_primary")
	await wait_physics_frames(3)
	check_eq(lung.stalls, 1, "the wave tripped the hand valve, two and a half tiles off")
