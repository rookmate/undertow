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
