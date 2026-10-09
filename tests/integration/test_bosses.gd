extends TestCase
## Bosses: armoured but for their openings, two solutions (the Steward calls the pattern; or a weakness
## it never mentions), and the way on opens when they fall. Against the Conductor in a test arena.

var level: Level
var conductor: Conductor


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/conductor_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	conductor = level.boss as Conductor


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	level.player.set_physics_process(false)
	await wait_physics_frames(2)


func _lane_of(cell: Vector2i) -> ShuntLane:
	for l: ShuntLane in conductor.lanes:
		if l.has_cell(cell):
			return l
	return null


func test_the_arena_is_built_from_the_map() -> void:
	check(conductor != null, "the Conductor stands on its cell")
	check_eq(conductor.lanes.size(), 3)
	check_eq(conductor.lanes.map(func(l: ShuntLane) -> String: return l.side), ["left", "middle", "right"])
	check(conductor.weak_point is SignalBox and not conductor.weak_point.steward_aims_at, "the signal box is there, and the Steward won't aim at it")
	check_eq(get_tree().get_nodes_in_group(&"boss_barriers").filter(func(n: Node) -> bool: return level.is_ancestor_of(n)).size(), 2)
	check_false(conductor.is_engaged, "it waits until you come")


func test_it_clears_the_lane_you_stand_on_and_the_steward_calls_it() -> void:
	await _stand(Vector2i(5, 4))
	await wait_frames(2)
	check(conductor.is_engaged, "close enough, and it starts")
	check_eq(conductor.phase, Conductor.Phase.WARN)
	var lane := _lane_of(Vector2i(5, 4))
	check_eq(conductor.get("_lane"), lane, "the lane you're on first")
	check_eq(Sound.voice_line, "conductor_" + lane.side, "the Steward calls it, aloud")
	var before := level.player.integrity.value
	await wait_seconds(Conductor.WARN_SECONDS + ShuntLane.CARRIAGE_SECONDS + 0.2)
	check(level.player.integrity.value < before, "and if you stay on it, the carriage hits you")


func test_muted_the_lights_warn_earlier_and_nothing_is_called() -> void:
	Steward.set_voice(false)
	await _stand(Vector2i(5, 4))
	await wait_frames(2)
	check_near(conductor.get("_warn_for"), Conductor.WARN_SECONDS + Conductor.EARLY_FLICKER, 0.001, "you watch the lights yourself, and they flicker sooner")
	check_eq(Sound.voice_line, "", "the Steward is silent")


func test_it_is_armoured_until_it_vents() -> void:
	await _stand(Vector2i(5, 7))
	await wait_frames(2)
	var full := conductor.integrity.value
	conductor.take_hit(50.0, Vector2(0, -1), 0.0, 0.0)
	check_eq(conductor.integrity.value, full, "blows ring off its armour")
	check(Sound.heard(&"armour_clang") > 0)
	conductor.call(&"_enter_phase", Conductor.Phase.VENT)
	conductor.take_hit(50.0, Vector2(0, -1), 0.0, 0.0)
	check_eq(conductor.integrity.value, full - 50.0, "venting, it's open")


func test_the_signal_box_stalls_it_while_switching() -> void:
	await _stand(Vector2i(4, 7))
	await wait_frames(2)
	check(conductor.is_switching())
	conductor.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(conductor.phase, Conductor.Phase.STALLED, "it stalls")
	check(conductor.is_vulnerable(), "and is open for a long moment")
	check_eq(conductor.stalls, 1)
	conductor.call(&"_enter_phase", Conductor.Phase.WARN)
	conductor.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(conductor.stalls, 1, "once a cycle")
	conductor.call(&"_start_cycle")
	conductor.call(&"_enter_phase", Conductor.Phase.GAP)
	conductor.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(conductor.stalls, 1, "and only while the points are moving")


func test_tuned_aim_never_picks_the_signal_box() -> void:
	await _stand(Vector2i(3, 8))
	level.player.face(Vector2(1, 0))
	var baton := level.player.weapons[0]
	check(Iso.ground_distance(level.player.global_position, conductor.weak_point.global_position) < 1.6, "the box is right there")
	check_eq(baton.tuned_direction(3.0), level.player.aim_ground(), "the Steward's aim ignores it")


## Against the player's own aim, not the assisted one: eight degrees beside the box stays eight degrees
## beside it (an ordinary machine in the same place would pull it in).
func test_aim_assist_never_bends_toward_the_signal_box() -> void:
	await _stand(Vector2i(3, 8))
	var p := level.player
	var box := conductor.weak_point
	var to_box := Iso.world_to_grid(box.global_position) - Iso.world_to_grid(p.global_position)
	var raw := to_box.normalized().rotated(deg_to_rad(8.0))
	check(Steward.assists().aim_assist > 0.0, "aim assist is on")
	check_near(rad_to_deg(absf(p.assisted_aim(raw).angle_to(to_box))), 8.0, 0.01, "no pull toward the box")
	var stand_in := level.add_enemy(Custodian.new(), box.grid_cell(), 10.0)
	stand_in.global_position = box.global_position
	await wait_frames(1)
	check(rad_to_deg(absf(p.assisted_aim(raw).angle_to(to_box))) < 7.0, "while a machine there would pull it")
	stand_in.queue_free()


func test_taking_it_apart_opens_the_way_and_pays() -> void:
	await _stand(Vector2i(5, 7))
	await wait_frames(2)
	var scrap := GameState.run.scrap
	conductor.call(&"_enter_phase", Conductor.Phase.VENT)
	conductor.take_hit(Conductor.MAX_INTEGRITY, Vector2(0, -1), 0.0, 0.0)
	check_false(conductor.is_alive())
	await wait_frames(2)
	for n: Node in get_tree().get_nodes_in_group(&"boss_barriers"):
		if level.is_ancestor_of(n):
			check((n as BossBarrier).open, "the buffer stops are gone")
	check_eq(GameState.run.scrap, scrap + conductor.scrap_value, "and it gives up its parts")
	check_false(level.living_enemies().has(conductor.weak_point), "its signal box is just a cabinet now")
