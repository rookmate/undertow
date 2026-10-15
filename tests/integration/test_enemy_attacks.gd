extends TestCase
## Attacks that keep their word: what a machine warns you of is what it does. A Sterilizer's mist goes
## down where it showed you, and a wall cuts it off; a Warden swings only at what it can reach, and its
## committed swing misses if you step out of it; a Salvager takes nothing from beyond its ring or round
## a corner; a Lamplighter's hook finds nothing mid-roll, and one lamp letting go doesn't free you from
## another's.

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


func _at(g: Vector2) -> Vector2:
	return Iso.grid_to_world(g)


func test_stepping_out_of_the_drawn_mist_escapes_it() -> void:
	level.player.position = _at(Vector2(4.5, 8.5))
	var s := level.add_enemy(Sterilizer.new(), Vector2i(5, 8), Sterilizer.MAX_INTEGRITY) as Sterilizer
	var waited := 0
	while s.state != Enemy.State.WINDUP and waited < 120:
		await wait_physics_frames(1)
		waited += 1
	check_eq(s.state, Enemy.State.WINDUP, "it winds up at you")
	var shown := s.deploy_at
	check(Iso.ground_distance(shown, level.player.global_position) <= SterileCloud.RADIUS_TILES, "the mist it shows covers you as it begins")
	# Out of the drawn mist before it falls.
	level.player.position = _at(Vector2(1.5, 8.5))
	var before := level.player.integrity.value
	while s.state == Enemy.State.WINDUP:
		await wait_physics_frames(1)
	var clouds := level.fx_ground.get_children().filter(func(n: Node) -> bool: return n is SterileCloud)
	check(clouds.size() == 1 and (clouds[0] as SterileCloud).position.distance_to(shown) < 1.0, "it went down where it showed you")
	await wait_seconds(1.0)
	check_eq(level.player.integrity.value, before, "and you're not in it")


func test_a_wall_cuts_the_mist_off() -> void:
	var cloud := SterileCloud.new()
	cloud.setup(level, _at(Vector2(10.5, 2.9)))
	level.fx_ground.add_child(cloud)
	var beyond := _at(Vector2(10.5, 4.15))
	check(Iso.ground_distance(beyond, cloud.position) <= SterileCloud.RADIUS_TILES, "within its reach")
	check_false(cloud.covers(beyond), "but the wall is between")
	check(cloud.covers(_at(Vector2(10.5, 2.0))), "on its own side, it stings")


func test_a_warden_swings_only_at_what_it_can_reach() -> void:
	var w := level.add_enemy(Warden.new(), Vector2i(5, 2), Warden.MAX_INTEGRITY) as Warden
	w.set_physics_process(false)
	w.position = _at(Vector2(5.8, 2.95))
	level.player.position = _at(Vector2(6.2, 4.05))
	await wait_physics_frames(1)
	check(Iso.ground_distance(w.global_position, level.player.global_position) <= Warden.REACH, "within its reach")
	check(w.sees(level.player.global_position), "and it hears you round the corner")
	w.hunting = true
	w.call(&"_hunt", level.player, 1.0 / 60.0)
	check(w.state != Enemy.State.WINDUP, "but it doesn't swing through the wall")


func test_stepping_out_of_a_committed_swing_makes_it_miss() -> void:
	for dodge: bool in [false, true]:
		var w := level.add_enemy(Warden.new(), Vector2i(8, 8), Warden.MAX_INTEGRITY) as Warden
		level.player.position = w.position + _at(Vector2(1.0, 0.0))
		await wait_physics_frames(1)
		w.hunting = true
		w.set("_unseen_for", 0.0)
		w.call(&"_hunt", level.player, 1.0 / 60.0)
		check_eq(w.state, Enemy.State.WINDUP, "it winds up")
		var before := level.player.integrity.value
		# Past the point it commits, you go round its side.
		await wait_seconds(w.windup_seconds() * (Warden.COMMIT + 0.1))
		if dodge:
			level.player.position = w.global_position + _at(Vector2(0.0, -1.0))
		while w.state == Enemy.State.WINDUP:
			await wait_physics_frames(1)
		if dodge:
			check_eq(level.player.integrity.value, before, "out of its swing: it misses")
		else:
			check(level.player.integrity.value < before, "standing in it: it lands")
		w.queue_free()
		level.player.integrity.value = level.player.integrity.max_value
		await wait_seconds(1.0)


func test_a_salvager_takes_nothing_from_beyond_its_ring_or_round_a_corner() -> void:
	GameState.run.scrap = 10
	var sv := level.add_enemy(Salvager.new(), Vector2i(8, 8), Salvager.MAX_INTEGRITY) as Salvager
	sv.set_physics_process(false)
	await wait_physics_frames(1)
	level.player.position = sv.position + _at(Vector2(Salvager.catch_reach() + 0.15, 0.0))
	sv.call(&"_snatch", level.player)
	check(sv.loot.is_empty(), "beyond the ring it draws: nothing")
	sv.position = _at(Vector2(5.8, 2.95))
	level.player.position = _at(Vector2(6.2, 4.05))
	sv.call(&"_snatch", level.player)
	check(sv.loot.is_empty(), "round a corner: nothing")
	sv.position = _at(Vector2(8.5, 8.5))
	level.player.position = sv.position + _at(Vector2(Salvager.SNATCH_REACH, 0.0))
	sv.call(&"_snatch", level.player)
	check_false(sv.loot.is_empty(), "inside its ring and in sight: it takes")


func test_a_roll_evades_the_hook_and_lamps_keep_their_own_pulls() -> void:
	Steward.set_voice(false)
	await wait_physics_frames(2)
	var a := level.add_enemy(Lamplighter.new(), Vector2i(8, 8), Lamplighter.MAX_INTEGRITY) as Lamplighter
	var b := level.add_enemy(Lamplighter.new(), Vector2i(10, 8), Lamplighter.MAX_INTEGRITY) as Lamplighter
	a.set_physics_process(false)
	b.set_physics_process(false)
	level.player.position = Iso.cell_center(Vector2i(9, 9))
	await wait_physics_frames(2)
	var evaded: Array[bool] = []
	level.player.evaded.connect(func() -> void: evaded.append(true), CONNECT_ONE_SHOT)
	check(level.player.dodge.try_start(Vector2(0, 1)), "a roll")
	a.call(&"_hook", level.player)
	check(not evaded.is_empty() and not level.player.is_pulled() and not a.hooking, "mid-roll the beam takes no hold")
	await wait_seconds(Dodge.COOLDOWN + 0.2)
	a.call(&"_hook", level.player)
	b.call(&"_hook", level.player)
	check(level.player.is_pulled(), "two lamps have you")
	a.call(&"_release")
	check(level.player.is_pulled(), "one letting go doesn't free you from the other")
	b.call(&"_release")
	check_false(level.player.is_pulled(), "the last one letting go does")
	Steward.set_voice(true)


## The ring a Warden draws is its baton's reach: some of you inside it, the blow lands; all of you
## outside, it doesn't. And at that reach the painted baton is at your chest, whichever way it faces.
func test_a_wardens_ring_is_its_reach_and_its_baton_meets_you() -> void:
	var w := level.add_enemy(Warden.new(), Vector2i(8, 8), Warden.MAX_INTEGRITY) as Warden
	w.set_physics_process(false)
	await wait_physics_frames(1)
	var edge := Warden.STRIKE_REACH + Operator.RADIUS_TILES
	for d: float in [edge - 0.05, edge + 0.05]:
		level.player.position = w.position + _at(Vector2(d, 0.0))
		w.face_player()
		w.set("_strike_dir", w.facing_ground)
		var lands: bool = w.call(&"_strike_lands", level.player)
		check_eq(lands, d < edge, "%.2f tiles away: %s" % [d, "lands" if d < edge else "misses"])
	for dir: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var baton := PaintedBiped.weapon_at("warden", w.gait, dir, 90.0, 1.0)
		var chest := _at(dir * edge) + Vector2(0, -Projectile.CHEST_HEIGHT)
		check(baton.distance_to(chest) <= 50.0, "facing %s the baton lands at your chest (%.0f px off)" % [dir, baton.distance_to(chest)])

