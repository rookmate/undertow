extends TestCase
## Boss stages (DECISIONS 179, 183), in the test arenas: at its thresholds each boss stops (it can't be
## hurt) and then fights its next stage. The Conductor runs express (two lanes, the Steward calls the
## clear one); the Surgeon cuts in a cross and its mist creeps closer; the Crane lifts two loads at once,
## then goes over along a line it shows you first.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _arena(fixture: String) -> Boss:
	level = (load("res://tests/fixtures/%s.tscn" % fixture) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	return level.boss


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	level.player.set_physics_process(false)
	await wait_physics_frames(2)
	Sound.hush()
	await wait_physics_frames(1)


## Opens it and takes it down to its next threshold; waits out the transition.
func _to_next_stage(b: Boss, open_phase: int) -> void:
	b.call(&"_enter_phase", open_phase)
	b.take_hit(b.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	check(b.in_transition(), "%s: a pause between stages" % b.boss_name)
	check(await wait_until(func() -> bool: return not b.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "%s: then the pause ends" % b.boss_name)


func test_the_conductor_runs_express() -> void:
	var c := await _arena("conductor_arena") as Conductor
	await _stand(Vector2i(5, 4))
	check_eq(c.stage_count(), 2)
	await _to_next_stage(c, Conductor.Phase.VENT)
	check_eq(c.stage, 2)
	check_near(c.integrity.ratio(), 0.5, 0.001, "stopped at half")
	check_eq(c.phase, Conductor.Phase.WARN, "running again")
	check_eq(c.running_lanes().size(), 2, "two lanes at once")
	check(c.clear_lane() != null and not c.running_lanes().has(c.clear_lane()), "and one clear")
	check(c.running_lanes().any(func(l: ShuntLane) -> bool: return l.has_cell(level.player.cell())), "yours among them")
	check_eq(Sound.voice_line, "conductor_clear_" + c.clear_lane().side, "the Steward calls the clear one")
	check(c.running_lanes().all(func(l: ShuntLane) -> bool: return l.speed > 1.0), "express: faster carriages")


func test_the_surgeon_cuts_in_a_cross() -> void:
	var s := await _arena("surgeon_arena") as Surgeon
	await _stand(Vector2i(10, 4))
	check_eq(s.stage_count(), 2)
	var before_safe := s.mist_safe()
	await _to_next_stage(s, Surgeon.Phase.SUTURE)
	check_eq(s.stage, 2)
	check(s.crossed(), "triage")
	check(s.mist_safe() < before_safe, "the mist creeps in closer")
	var across := Vector2(-s.cut_dir.y, s.cut_dir.x)
	var spot := s.global_position + Iso.ground_velocity(across, 3.0)
	check(s.on_line(spot), "the second line, across the first")


func test_the_crane_lifts_two_loads_then_goes_over() -> void:
	var c := await _arena("crane_arena") as Crane
	await _stand(Vector2i(6, 9))
	check_eq(c.stage_count(), 3)
	await _to_next_stage(c, Crane.Phase.REST)
	check_eq(c.stage, 2)
	await wait_seconds(Crane.LIFT_SECONDS + 0.2)
	check_eq(c.phase, Crane.Phase.AIM)
	check(Iso.ground_distance(c.second_mark(), c.get("_mark")) > Crane.DROP_RADIUS, "a second load beside the first")
	# On to stage 3: it goes over along a line toward you, shown first.
	c.call(&"_enter_phase", Crane.Phase.REST)
	c.take_hit(c.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	check_eq(c.stage, 3)
	check(c.on_fall_line(level.player.global_position), "the line runs through you")
	var hp := level.player.integrity.value
	level.player.set_physics_process(true)
	check(await wait_until(func() -> bool: return not c.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "its pause ends")
	check(c.fallen, "down across the pier")
	check(level.player.integrity.value < hp, "stay on the line and it lands on you")


func test_the_editor_leaves_wet_ink_then_runs_backwards() -> void:
	var e := await _arena("editor_arena") as Editor
	await _stand(Vector2i(7, 8))
	check_eq(e.stage_count(), 3)
	await _to_next_stage(e, Editor.Phase.INK)
	check_eq(e.stage, 2)
	await wait_seconds(Editor.ROLL_WARN_SECONDS + Editor.ROLL_SECONDS + 0.4)
	check(not e.ink_pools.is_empty(), "the headlines left wet behind the roller")
	var pool: Vector2i = e.ink_pools.keys()[0]
	# Clear of any blow the rollers dealt while it ran (no grace left over, no knockback to carry you
	# off the ink), and standing still in it.
	level.player.set_physics_process(false)
	level.player.set("_grace", 0.0)
	level.player.set("_knock", Vector2.ZERO)
	level.player.position = Iso.cell_center(pool)
	var hp := level.player.integrity.value
	await wait_seconds(Editor.INK_POOL_TICK + 0.2)
	check(level.player.integrity.value < hp, "standing in it stings")
	var forward := e.run_span()
	e.call(&"_enter_phase", Editor.Phase.INK)
	e.take_hit(e.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	check_eq(e.stage, 3)
	check(await wait_until(func() -> bool: return not e.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "its pause ends")
	check(e.backwards(), "its presses run backwards")
	var back := e.run_span()
	check(signf(back.y - back.x) != signf(forward.y - forward.x) or e.sweep != Editor.Sweep.DOWN, "the rollers come back the other way")


func test_the_warden_prime_calls_them_in_then_goes_blind() -> void:
	GameState.noor_leaves_for_ward()
	var w := await _arena("warden_prime_arena") as WardenPrime
	await _stand(Vector2i(8, 10))
	check_eq(w.stage_count(), 3)
	var wardens := level.living_enemies().filter(func(e: Enemy) -> bool: return e is Warden).size()
	await _to_next_stage(w, WardenPrime.Phase.DAZED)
	check_eq(w.stage, 2)
	check(level.living_enemies().filter(func(e: Enemy) -> bool: return e is Warden).size() > wardens, "it called Wardens in")
	check(w.sweep_seconds() < WardenPrime.SWEEP_SECONDS, "its light sweeps faster")
	w.call(&"_enter_phase", WardenPrime.Phase.DAZED)
	w.take_hit(w.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	check_eq(w.stage, 3)
	check(await wait_until(func() -> bool: return not w.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "its pause ends")
	check(w.blind(), "the mast's gone")
	check_eq(w.phase, WardenPrime.Phase.CHARGE_WARN, "it comes at you")
	check(w.weak_point == null or not is_instance_valid(w.weak_point) or not w.weak_point.is_hittable(), "no stalling it now")
	w.call(&"_enter_phase", WardenPrime.Phase.DAZED)
	w.take_hit(w.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	await wait_physics_frames(3)
	check_eq(level.living_enemies().filter(func(e: Enemy) -> bool: return e is Warden).size(), wardens, "the ones it called drop with it")


## A new stage's word waits for the call the Steward is still saying (it doesn't cut it off), and the
## pause between stages counts from then.
func test_a_new_stage_waits_for_the_call_being_said() -> void:
	var c := await _arena("conductor_arena") as Conductor
	await _stand(Vector2i(5, 4))
	c.call(&"_enter_phase", Conductor.Phase.VENT)
	c.call_out("conductor_vent")
	await wait_physics_frames(2)
	check_eq(Sound.voice_line, "conductor_vent")
	c.take_hit(c.integrity.max_value, Vector2(1, 0), 0.0, 0.0)
	check_eq(c.stage, 2)
	await wait_physics_frames(3)
	check_eq(Sound.voice_line, "conductor_vent", "its vent call isn't cut off")
	await wait_seconds(Sound.voice_left() + 0.3)
	check_eq(Sound.voice_line, "conductor_express", "then its word on the express")
	check(c.in_transition(), "still between stages")
	await wait_seconds(Boss.STAGE_TRANSITION + 0.2)
	check_false(c.in_transition(), "the pause runs from its word")


## The Lung's deep water stings only where it's drawn: beyond its band you're out of it.
func test_the_lungs_deep_water_is_only_where_its_drawn() -> void:
	var l := await _arena("lung_arena") as Lung
	await _stand(Vector2i(6, 6))
	await _to_next_stage(l, Lung.Phase.VENT)
	check(l.deep_tiles() > 0.0, "the tide's in")
	var east := Vector2(1, 0)
	var at := func(tiles: float) -> Vector2: return l.global_position + Iso.ground_velocity(east, tiles)
	check(l.in_deep(at.call((l.deep_tiles() + Lung.DEEP_OUTER) * 0.5)), "in the band: deep")
	check_false(l.in_deep(at.call(l.deep_tiles() - 0.5)), "inside it: not")
	check_false(l.in_deep(at.call(Lung.DEEP_OUTER + 1.0)), "past where it's drawn: not")


## From its second stage the second load hangs on its own cable through its fall (it doesn't vanish as it
## lets go), and where it lands, away from the first, it hurts.
func test_the_cranes_second_load_falls_where_its_shown() -> void:
	var c := await _arena("crane_arena") as Crane
	await _stand(Vector2i(6, 9))
	await _to_next_stage(c, Crane.Phase.REST)
	check_eq(c.stage, 2)
	# Its first lift in the new stage, from its very first frame: the second load comes up beside the first,
	# not from anywhere else.
	check_eq(c.phase, Crane.Phase.LIFT)
	check(c.second_load_shown(), "lifting: both loads")
	check_near(Iso.ground_distance(c.second_load_at(), c.load_at), Crane.SECOND_LOAD, 0.05, "the second beside the first")
	# Aiming, marked from its first frame: at you, and the second beside it.
	c.call(&"_enter_phase", Crane.Phase.AIM)
	check(Iso.ground_distance(c.get("_mark"), c.call(&"_reach", level.player.global_position)) < 0.01, "the first mark on you, as near as the jib reaches")
	check_near(Iso.ground_distance(c.second_mark(), c.get("_mark")), Crane.SECOND_LOAD, 0.05, "the second mark beside it")
	check(await wait_until(func() -> bool: return float(c.get("_phase_time")) >= float(c.get("_aim_for")) * 0.75, 3.0), "its marks are set")
	check(c.second_load_shown(), "aimed: both loads hang")
	var second := c.second_mark()
	check(Iso.ground_distance(second, c.get("_mark")) > Crane.DROP_RADIUS, "the second clear of the first")
	level.player.position = second
	var hp := level.player.integrity.value
	check(await wait_until(func() -> bool: return c.phase == Crane.Phase.DROP, 3.0), "it lets go")
	check(c.second_load_shown(), "falling: the second load is still there")
	check(await wait_until(func() -> bool: return bool(c.get("_struck")), 1.0), "and lands")
	check(level.player.integrity.value < hp, "under the second load, it hurts")

