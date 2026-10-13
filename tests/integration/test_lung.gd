extends TestCase
## The Lung (Greywater's boss), in a test arena: it floods the basin a quarter at a time, the quarter
## you're in first (the Steward calls each), sends a surge out you roll through, vents (open to blows);
## the old hand valve turned while it fills chokes it.

var level: Level
var lung: Lung


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/lung_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	lung = level.boss as Lung


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)
	# Past the Steward's introduction, as if cut short: the fight starts at once.
	Sound.hush()
	await wait_physics_frames(1)


func test_it_floods_the_quarter_youre_in_first_and_the_steward_calls_it() -> void:
	check(lung != null and lung.weak_point is HandValve, "the Lung, and the old hand valve")
	await _stand(Vector2i(11, 3))
	lung.call(&"_start_cycle")
	check_eq(lung.phase, Lung.Phase.FILL)
	check_eq(lung.quarter, lung.quarter_of(level.player.global_position), "your quarter first")
	check_eq(Sound.voice_line, Lung.LINES[lung.quarter], "and the Steward calls it")
	var before := level.player.integrity.value
	await wait_seconds(Lung.FILL_SECONDS + 0.6)
	check(level.player.integrity.value < before, "stay and the water takes you")


func test_out_of_the_filling_quarter_youre_dry() -> void:
	await _stand(Vector2i(11, 3))
	lung.call(&"_start_cycle")
	var q := lung.quarter
	await _stand(Vector2i(5, 8))
	check(lung.quarter_of(level.player.global_position) != q, "another quarter")
	var before := level.player.integrity.value
	await wait_seconds(Lung.FILL_SECONDS + 0.6)
	check_eq(level.player.integrity.value, before, "and the water passes you by")


## What's drawn is what floods: just inside every edge and corner of each quarter's square is wet, just
## outside is dry.
func test_the_flood_is_exactly_the_square_drawn() -> void:
	var at := Iso.world_to_grid(lung.global_position)
	for q: Lung.Quarter in [Lung.Quarter.LEFT, Lung.Quarter.RIGHT, Lung.Quarter.NEAR, Lung.Quarter.FAR]:
		lung.quarter = q
		var r := Lung.flood_rect(q)
		var sg := Lung.quarter_signs(q)
		var inside := r.grow(-0.05)
		for corner: Vector2 in [inside.position, Vector2(inside.end.x, inside.position.y), inside.end, Vector2(inside.position.x, inside.end.y)]:
			check(lung.in_flood(Iso.grid_to_world(at + corner)), "%s: %s is wet" % [q, corner])
		var far := sg * (Lung.FLOOD_TILES + 0.05)
		for p: Vector2 in [far, Vector2(far.x, sg.y * 1.0), Vector2(sg.x * 1.0, far.y)]:
			check_false(lung.in_flood(Iso.grid_to_world(at + p)), "%s: %s is dry" % [q, p])
		check_false(lung.in_flood(Iso.grid_to_world(at - sg * 1.0)), "%s: the quarter across is dry" % q)


## The surge's ring hits you where you stand, unless you roll through it.
func test_the_surge_hits_unless_you_roll_through_it() -> void:
	await _stand(Vector2i(11, 5))
	var r := Iso.ground_distance(lung.global_position, level.player.global_position)
	lung.call(&"_enter_phase", Lung.Phase.SURGE)
	var before := level.player.integrity.value
	await wait_seconds(Lung.SURGE_SECONDS + 0.1)
	check(level.player.integrity.value < before, "the ring caught you (%.1f tiles out)" % r)
	await wait_seconds(0.5)
	lung.call(&"_enter_phase", Lung.Phase.SURGE)
	before = level.player.integrity.value
	var waited := 0
	while lung.surge_radius() < r - Lung.SURGE_WIDTH - 0.1 and waited < 200:
		await wait_physics_frames(1)
		waited += 1
	level.player.dodge.try_start(Vector2(-1, 0))
	await wait_seconds(0.4)
	check_eq(level.player.integrity.value, before, "rolled through it")


func test_it_is_armoured_until_it_vents() -> void:
	await _stand(Vector2i(11, 5))
	var full := lung.integrity.value
	lung.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.integrity.value, full, "armoured while it pumps")
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	check_eq(Sound.voice_line, "lung_vent", "the Steward calls the opening")
	lung.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.integrity.value, full - 40.0, "open while it vents")


func test_the_hand_valve_turned_while_it_fills_chokes_it() -> void:
	await _stand(Vector2i(3, 8))
	lung.call(&"_start_cycle")
	check(lung.is_switching(), "filling")
	lung.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.phase, Lung.Phase.STALLED, "it chokes")
	check(lung.is_vulnerable())
	check_eq(lung.stalls, 1)
	lung.call(&"_enter_phase", Lung.Phase.FLOOD)
	lung.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.stalls, 1, "only while it's filling")
	check_false(lung.weak_point.steward_aims_at, "and the Steward never points you at it")


func test_with_never_warn_me_signed_it_floods_in_silence() -> void:
	await _stand(Vector2i(11, 3))
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	Sound.hush()
	lung.call(&"_start_cycle")
	check_false(Lung.LINES.values().has(Sound.voice_line), "no call")
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	check_eq(Sound.voice_line, "lung_vent", "an opening is a fact, still said")


## Stages (DECISIONS 179, 180): a blow stops at two thirds; it pauses (it can't be hurt; the Steward
## says the tide's in), then the outer basin is deep water and it fills faster.
func test_at_two_thirds_the_tide_comes_up() -> void:
	await _stand(Vector2i(11, 3))
	check_eq(lung.stage_count(), 3)
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	lung.take_hit(Lung.MAX_INTEGRITY, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.stage, 2, "stage 2")
	check_near(lung.integrity.ratio(), 2.0 / 3.0, 0.001, "the blow stopped at two thirds")
	check(lung.in_transition(), "a pause between stages")
	var before := lung.integrity.value
	lung.take_hit(50.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.integrity.value, before, "it can't be hurt while it changes")
	check(await wait_until(func() -> bool: return Narrator.last_line_id == "lung_rise", Boss.STAGE_CALL_WAIT + 0.5), "the Steward says what's changed")
	check(lung.in_transition(), "still in its pause")
	check(await wait_until(func() -> bool: return not lung.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "then the pause ends")
	check_eq(lung.phase, Lung.Phase.FILL, "then it fights again")
	check(lung.fill_seconds() < Lung.STAGE_FILL[0], "filling faster")
	check(lung.deep_tiles() > 0.0, "the tide up")
	var hp := level.player.integrity.value
	level.player.position = lung.global_position + Iso.ground_velocity(Vector2(-1, 0), lung.deep_tiles() + 0.8)
	await wait_seconds(Lung.DEEP_TICK * 2.0 + 0.1)
	check(level.player.integrity.value < hp, "out in the deep water, it wears you down")
	hp = level.player.integrity.value
	level.player.position = lung.global_position + Iso.ground_velocity(Vector2(-1, 0), 2.0)
	await wait_seconds(Lung.DEEP_TICK * 2.0)
	check(level.player.integrity.value >= hp or lung.in_flood(level.player.global_position), "in the shallows, it doesn't")


## At one third the Marrow is in: no calls (the Steward can't see it), and its floods don't follow you.
func test_at_one_third_the_marrow_rolls_in() -> void:
	await _stand(Vector2i(11, 3))
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	lung.take_hit(Lung.MAX_INTEGRITY, Vector2(1, 0), 0.0, 0.0)
	check(await wait_until(func() -> bool: return not lung.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "stage 2 under way")
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	lung.take_hit(Lung.MAX_INTEGRITY, Vector2(1, 0), 0.0, 0.0)
	check_eq(lung.stage, 3, "stage 3")
	check_near(lung.integrity.ratio(), 1.0 / 3.0, 0.001)
	check(await wait_until(func() -> bool: return Narrator.last_line_id == "lung_marrow", Boss.STAGE_CALL_WAIT + 0.5), "the Steward loses you")
	check(await wait_until(func() -> bool: return not lung.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5), "then the pause ends")
	check(lung.in_the_marrow())
	var calls := 0
	for k: int in 6:
		Narrator.last_line_id = ""
		lung.call(&"_enter_phase", Lung.Phase.FILL)
		if Lung.LINES.values().has(Narrator.last_line_id):
			calls += 1
	check_eq(calls, 0, "no calls in the Marrow")
	lung.call(&"_enter_phase", Lung.Phase.VENT)
	lung.take_hit(Lung.MAX_INTEGRITY, Vector2(1, 0), 0.0, 0.0)
	check_false(lung.is_alive(), "the last stage: down")

