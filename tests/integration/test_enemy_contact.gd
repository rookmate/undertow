extends TestCase
## Bodies meeting: the Steward's machines stop against the Operator as the Operator stops against them;
## a roll passes through either way; their bodies are their ground footprints and still fit a one-tile
## passage; a Custodian's lunge ends at you, not through you; a cornered machine backs out round the wall.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load("res://tests/fixtures/contact_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	level.queue_free()
	await wait_frames(2)


func _keep_alive() -> void:
	level.player.integrity.value = level.player.integrity.max_value


func _gap(e: Enemy) -> float:
	return Iso.ground_distance(level.player.global_position, e.global_position)


func test_a_machine_stops_against_you() -> void:
	level.player.position = Iso.cell_center(Vector2i(4, 8))
	var c := level.add_enemy(Custodian.new(), Vector2i(7, 8), Custodian.MAX_INTEGRITY)
	var closest := INF
	var lunged := false
	for i: int in 60 * 5:
		_keep_alive()
		closest = minf(closest, _gap(c))
		lunged = lunged or c.state == Enemy.State.ATTACK
		await wait_physics_frames(1)
	check(lunged, "it came for you and lunged")
	check(closest >= c.radius_tiles + 0.2, "its body never entered yours (closest %.2f tiles)" % closest)


func test_knocked_back_into_you_it_stops_at_you() -> void:
	level.player.position = Iso.cell_center(Vector2i(4, 8))
	var c := level.add_enemy(Custodian.new(), Vector2i(6, 8), Custodian.MAX_INTEGRITY)
	await wait_physics_frames(2)
	# Struck hard from beyond it, toward you.
	c.take_hit(1.0, Iso.ground_dir_between(c.global_position, level.player.global_position), 4.0, 1.0)
	var closest := INF
	for i: int in 40:
		closest = minf(closest, _gap(c))
		await wait_physics_frames(1)
	check(closest >= c.radius_tiles + 0.2, "it stops against you (closest %.2f tiles)" % closest)


func test_a_roll_passes_through_a_machine() -> void:
	level.player.position = Iso.cell_center(Vector2i(4, 8))
	var c := level.add_enemy(Custodian.new(), Vector2i(5, 8), Custodian.MAX_INTEGRITY)
	c.set_physics_process(false)
	await wait_physics_frames(2)
	var start := Iso.world_to_grid(level.player.global_position).x
	var past := Iso.world_to_grid(c.global_position).x
	check(level.player.dodge.try_start(Vector2(1, 0)), "a roll")
	await wait_physics_frames(roundi(Dodge.DURATION * 60.0) + 6)
	var end := Iso.world_to_grid(level.player.global_position).x
	check(end > past + 0.3, "through it and out the far side (%.2f -> %.2f, it at %.2f)" % [start, end, past])


## Every regular machine's footprint goes through a passage one tile wide, end to end.
func test_every_body_fits_a_one_tile_passage() -> void:
	level.player.position = Iso.cell_center(Vector2i(2, 9))
	var kinds: Array[Script] = [Custodian, Clerk, Salvager, Sterilizer, Warden, Lamplighter]
	for kind: Script in kinds:
		var e := level.add_enemy(kind.new() as Enemy, Vector2i(18, 4), 1000.0)
		e.set_physics_process(false)
		await wait_physics_frames(1)
		var goal := Iso.cell_center(Vector2i(3, 4))
		var t := 0
		while t < 60 * 12 and Iso.ground_distance(e.global_position, goal) > 0.5:
			e.velocity = e.steer_to(goal, 1.0 / 60.0, 3.0)
			e.move_and_slide()
			await wait_physics_frames(1)
			t += 1
		check(Iso.ground_distance(e.global_position, goal) <= 0.5, "%s gets through the passage" % kind.get_global_name())
		e.queue_free()
		await wait_physics_frames(1)


## Lunging from close by, it stops at you and the blow lands; it doesn't come out behind you.
func test_a_close_lunge_ends_at_you() -> void:
	level.player.position = Iso.cell_center(Vector2i(8, 8))
	await wait_physics_frames(2)
	var c := level.add_enemy(Custodian.new(), Vector2i(8, 8), Custodian.MAX_INTEGRITY)
	c.position = level.player.position + Iso.grid_to_world(Vector2(0.75, 0))
	await wait_physics_frames(2)
	var from := c.global_position - level.player.global_position
	var before := level.player.integrity.value
	var lunged := false
	for i: int in 60 * 3:
		lunged = lunged or c.state == Enemy.State.ATTACK
		if lunged and c.state == Enemy.State.RECOVER:
			break
		await wait_physics_frames(1)
	check(lunged, "it lunged")
	check(level.player.integrity.value < before, "the blow landed")
	var now := c.global_position - level.player.global_position
	check(Iso.world_to_grid(now).dot(Iso.world_to_grid(from)) > 0.0, "still on its own side of you")
	check(_gap(c) >= c.radius_tiles + 0.2, "and not inside you (%.2f tiles)" % _gap(c))


## Backed into a corner with you close, a Clerk gets out along a wall instead of pressing into the
## corner; a Salvager with your weapon gets away the same way.
func test_a_cornered_machine_backs_out_round_the_wall() -> void:
	level.player.position = Iso.cell_center(Vector2i(2, 2)) + Iso.grid_to_world(Vector2(0.3, 0.3))
	var clerk := level.add_enemy(Clerk.new(), Vector2i(1, 1), Clerk.MAX_INTEGRITY) as Clerk
	clerk.set("_since_attack", -100.0)
	clerk.state = Enemy.State.CHASE
	await wait_physics_frames(2)
	var start := _gap(clerk)
	var corner := clerk.global_position
	for i: int in 60 * 2:
		_keep_alive()
		await wait_physics_frames(1)
	var moved := Iso.ground_distance(corner, clerk.global_position)
	check(moved > 2.0 and _gap(clerk) > start, "the Clerk got out of the corner (moved %.2f; %.2f -> %.2f from you)" % [moved, start, _gap(clerk)])
	clerk.queue_free()
	await wait_physics_frames(1)
	var salvager := level.add_enemy(Salvager.new(), Vector2i(1, 1), Salvager.MAX_INTEGRITY) as Salvager
	salvager.loot = {"scrap": 1}
	await wait_physics_frames(2)
	start = _gap(salvager)
	corner = salvager.global_position
	for i: int in 60 * 2:
		_keep_alive()
		await wait_physics_frames(1)
	moved = Iso.ground_distance(corner, salvager.global_position)
	check(moved > 3.0 and _gap(salvager) > start + 1.0, "the Salvager got away with it (moved %.2f; %.2f -> %.2f from you)" % [moved, start, _gap(salvager)])


## Lunging at you as you walk into it, late: the blow isn't spent on the moment you were still out of
## reach; it lands when you meet.
func test_walking_into_a_lunge_late_still_meets_it() -> void:
	level.player.position = Iso.cell_center(Vector2i(4, 8))
	var c := level.add_enemy(Custodian.new(), Vector2i(4, 8), Custodian.MAX_INTEGRITY)
	c.position = level.player.position + Iso.grid_to_world(Vector2(1.9, 0))
	await wait_physics_frames(1)
	c.face_player()
	c.state = Enemy.State.WINDUP
	c.set("_state_time", c.windup_seconds() - 0.01)
	var before := level.player.integrity.value
	for i: int in 30:
		# You walk toward it at a walking pace.
		if c.state == Enemy.State.ATTACK or c.state == Enemy.State.WINDUP:
			level.player.position += Iso.ground_velocity(Vector2(1, 0), 3.2) / 60.0
		await wait_physics_frames(1)
	check(level.player.integrity.value < before, "the blow landed when you met it")


## A dead end whose only way out bends back past you: a Salvager with your weapon finds it.
func test_a_dead_end_with_a_bend_doesnt_trap_it() -> void:
	level.queue_free()
	await wait_frames(1)
	level = (load("res://tests/fixtures/retreat_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	level.player.position = Iso.grid_to_world(Vector2(6.5, 2.5))
	var sv := level.add_enemy(Salvager.new(), Vector2i(2, 2), Salvager.MAX_INTEGRITY) as Salvager
	sv.position = Iso.grid_to_world(Vector2(2.4, 2.5))
	sv.loot = {"scrap": 1}
	var start := _gap(sv)
	for i: int in 60 * 6:
		_keep_alive()
		await wait_physics_frames(1)
	check(_gap(sv) > 5.0, "round the bend and away (%.2f -> %.2f from you)" % [start, _gap(sv)])


## Stopped short by another machine in its way, its lunge doesn't hit you from where it meant to be:
## held where it set off (blocked from its first step), most of the way through its lunge, with you
## inside its old reach from there but beyond what its brushes reach along the ground it covered.
func test_a_lunge_stopped_short_doesnt_hit_from_afar() -> void:
	var c := level.add_enemy(Custodian.new(), Vector2i(6, 8), Custodian.MAX_INTEGRITY) as Custodian
	c.set_physics_process(false)
	await wait_physics_frames(1)
	level.player.position = c.position + Iso.grid_to_world(Vector2(1.45, 0.0))
	await wait_physics_frames(1)
	c.face_player()
	c.state = Enemy.State.ATTACK
	c.set("_struck", false)
	c.set("_lunge_from", c.global_position)
	c.set("_lunge_dir", c.facing_ground)
	c.set("_state_time", Custodian.LUNGE * 0.7)
	check(CombatMath.in_arc(c.global_position, c.facing_ground, level.player.global_position, Custodian.REACH + 0.25, 130.0, Operator.RADIUS_TILES), "you're inside the reach it set off with")
	var before := level.player.integrity.value
	c.call(&"_think", 1.0 / 60.0)
	check_eq(level.player.integrity.value, before, "but it got nowhere, so the blow doesn't reach you")
	# Where it has got to you, it lands.
	c.position = level.player.position - Iso.grid_to_world(Vector2(0.7, 0.0))
	c.call(&"_think", 1.0 / 60.0)
	check(level.player.integrity.value < before, "where it has reached you, it lands")
