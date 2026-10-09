extends TestCase
## Combat against the real level geometry: nothing through walls, shots stop at corners, knockback
## respects collision.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	var ids: Array[String] = [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE]
	var modes: Dictionary[String, String] = {WeaponDefs.BATON: "tuned", WeaponDefs.RIOT_DRONE: "tuned"}
	GameState.set_loadout(ids, modes)
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	Controls.device = Controls.Device.PAD
	await wait_frames(3)


func after_each() -> void:
	Input.action_release(&"attack_primary")
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	level.queue_free()
	await wait_frames(2)


func _put_player(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func test_the_baton_cannot_strike_through_the_kiosk() -> void:
	var kiosk := level.grid.first("K")
	await _put_player(kiosk + Vector2i(0, 1))
	var behind := level.add_enemy(Custodian.new(), kiosk + Vector2i(0, -1), Custodian.MAX_INTEGRITY)
	behind.set_physics_process(false)
	level.player.face(Vector2(0, -1))
	Input.action_press(&"attack_primary")
	await wait_physics_frames(30)
	Input.action_release(&"attack_primary")
	check_eq(behind.integrity.value, Custodian.MAX_INTEGRITY, "the kiosk stands between them")


func _fire(team: Projectile.Team, from_cell: Vector2i, speed: float) -> Projectile:
	var p := Projectile.new()
	p.team = team
	p.level = level
	p.direction = Vector2(1, 0)
	p.speed_tiles = speed
	p.damage = 5.0
	p.max_tiles = 9.0
	p.position = Iso.cell_center(from_cell)
	level.world.add_child(p)
	return p


func _spent(p: Variant) -> bool:
	return not is_instance_valid(p) or not (p as Node).is_inside_tree() or (p as Node).is_queued_for_deletion()


## The Drone's real speed, the Clerk's bale and an absurdly fast one: none crosses the kiosk.
func test_shots_at_every_speed_stop_at_the_kiosk() -> void:
	var kiosk := level.grid.first("K")
	for speed: float in [RiotDrone.SHOT_SPEED, 150.0]:
		var target := level.add_enemy(Custodian.new(), kiosk + Vector2i(2, 0), Custodian.MAX_INTEGRITY)
		target.set_physics_process(false)
		var p := _fire(Projectile.Team.PLAYER, kiosk + Vector2i(-1, 0), speed)
		await wait_physics_frames(ceili(4.0 / speed * 60.0) + 3)
		check(_spent(p), "the %.0f tiles/s pellet is spent" % speed)
		check_eq(target.integrity.value, Custodian.MAX_INTEGRITY, "nothing behind the kiosk was hit at %.0f tiles/s" % speed)
		level.remove_all_enemies()
	await _put_player(kiosk + Vector2i(2, 0))
	level.player.set_physics_process(false)
	var before := level.player.integrity.value
	var bale := _fire(Projectile.Team.ENEMY, kiosk + Vector2i(-1, 0), Clerk.BALE_SPEED)
	await wait_physics_frames(ceili(4.0 / Clerk.BALE_SPEED * 60.0) + 3)
	check(_spent(bale), "the bale is spent")
	check_eq(level.player.integrity.value, before, "the bale didn't reach the Operator behind the kiosk")
	level.player.set_physics_process(true)


func test_an_open_shot_still_lands() -> void:
	var kiosk := level.grid.first("K")
	var row := kiosk + Vector2i(0, 2)
	var target := level.add_enemy(Custodian.new(), row + Vector2i(3, 0), Custodian.MAX_INTEGRITY)
	target.set_physics_process(false)
	check(level.grid.first_block(Vector2(row) + Vector2(0.5, 0.5), Vector2(row) + Vector2(3.5, 0.5)) < 0.0, "nothing in the way")
	_fire(Projectile.Team.PLAYER, row, RiotDrone.SHOT_SPEED)
	await wait_physics_frames(20)
	check(target.integrity.value < Custodian.MAX_INTEGRITY, "the pellet hit")


func test_tuned_drone_ignores_a_nearer_enemy_it_cannot_reach() -> void:
	var kiosk := level.grid.first("K")
	await _put_player(kiosk + Vector2i(0, 1))
	# Two tiles away behind the kiosk, versus three-plus tiles away in the open.
	var hidden := level.add_enemy(Custodian.new(), kiosk + Vector2i(0, -1), Custodian.MAX_INTEGRITY)
	var open := level.add_enemy(Custodian.new(), kiosk + Vector2i(-3, 2), Custodian.MAX_INTEGRITY)
	hidden.set_physics_process(false)
	open.set_physics_process(false)
	var drone := level.player.weapons[1]
	var dir := drone.tuned_direction(RiotDrone.TUNED_RANGE)
	var to_open := Iso.ground_dir_between(level.player.global_position, open.global_position)
	check(absf(dir.angle_to(to_open)) < 0.05, "aims at the reachable enemy, not the one behind the kiosk")


func test_knockback_does_not_push_the_operator_into_a_wall() -> void:
	# Against the left building band, hit from the street side.
	await _put_player(Vector2i(9, 37))
	for k: int in 6:
		level.player.take_hit(1.0, level.player.global_position + Iso.ground_velocity(Vector2(1, 0), 1.0))
		await wait_physics_frames(25)
	# Lamp posts only block the middle of their cell, so standing in a lamp cell's corner is fine; the
	# building band (x <= 8) and anything that isn't ground are not.
	var cell := level.player.cell()
	var f := level.grid.floor_at(cell)
	check(cell.x >= 9 and not level.grid.is_building(cell) and f != LevelGrid.Floor.WATER and f != LevelGrid.Floor.VOID, "pushed against the wall, not into it (at %s)" % cell)
