extends TestCase
## The Editor (the Vellum's boss), in a test arena: its rollers sweep the hall with a gap to stand in
## (the Steward calls them and lights the gap), you can roll through one; it turns the Feed on you and
## throws its bales; it re-inks, open to blows; the bale stack knocked into the pulper while it pulps
## jams it.

var level: Level
var editor: Editor


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/editor_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	editor = level.boss as Editor


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func _rollers() -> PressRollers:
	for n: Node in level.fx_ground.get_children():
		if n is PressRollers:
			return n as PressRollers
	return null


func test_rollers_come_with_a_gap_to_move_to_and_the_steward_calls_them() -> void:
	check(editor != null and editor.weak_point is BaleStack, "the Editor, and the bale stack by the pulper")
	await _stand(Vector2i(7, 8))
	editor.call(&"_start_cycle")
	check_eq(editor.phase, Editor.Phase.ROLL_WARN)
	check_eq(editor.sweep, Editor.Sweep.DOWN, "first from the press toward the door")
	check_eq(Sound.voice_line, "editor_rollers", "the Steward calls it")
	var off := absf(editor.gap_start + Editor.GAP_CELLS * 0.5 - Iso.world_to_grid(level.player.global_position).x)
	check(off >= Editor.GAP_NEAR and off <= Editor.GAP_FAR, "a gap you have to move to, and can (%.1f tiles)" % off)
	check(_rollers() != null and _rollers().gap_lit(), "and lights it")


func test_the_roller_runs_you_over_outside_the_gap_and_not_in_it() -> void:
	await _stand(Vector2i(7, 8))
	editor.call(&"_start_cycle")
	editor.gap_start = 3
	editor.call(&"_enter_phase", Editor.Phase.ROLL)
	var before := level.player.integrity.value
	await wait_seconds(Editor.ROLL_SECONDS + 0.1)
	check(level.player.integrity.value < before, "run over")
	editor.call(&"_start_cycle")
	editor.gap_start = 7
	await _stand(Vector2i(7, 8))
	editor.call(&"_enter_phase", Editor.Phase.ROLL)
	before = level.player.integrity.value
	await wait_seconds(Editor.ROLL_SECONDS + 0.1)
	check_eq(level.player.integrity.value, before, "in the gap, it passes either side")


func test_across_the_hall_too_and_you_can_roll_through_it() -> void:
	await _stand(Vector2i(9, 6))
	editor.call(&"_start_cycle")
	editor.sweep = Editor.Sweep.ACROSS
	editor.across_dir = -1
	editor.gap_start = 9
	editor.call(&"_enter_phase", Editor.Phase.ROLL)
	var before := level.player.integrity.value
	await wait_seconds(Editor.ROLL_SECONDS + 0.1)
	check(level.player.integrity.value < before, "the cross roller runs you over too")
	await wait_seconds(0.5)
	editor.sweep = Editor.Sweep.ACROSS
	editor.across_dir = -1
	editor.gap_start = 9
	editor.call(&"_enter_phase", Editor.Phase.ROLL)
	before = level.player.integrity.value
	var x := Iso.world_to_grid(level.player.global_position).x
	var waited := 0
	while editor.roller_at() > x + Editor.ROLLER_HALF + 0.15 and waited < 200:
		await wait_physics_frames(1)
		waited += 1
	level.player.dodge.try_start(Vector2(0, 1))
	await wait_seconds(0.4)
	check_eq(level.player.integrity.value, before, "rolled through it")


func test_it_turns_the_feed_on_you_and_throws_its_bales() -> void:
	await _stand(Vector2i(7, 8))
	level.player.face(Iso.ground_dir_between(level.player.global_position, editor.global_position))
	var bales: Array[Projectile] = []
	level.world.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projectile and (n as Projectile).team == Projectile.Team.ENEMY:
			bales.append(n as Projectile))
	editor.call(&"_enter_phase", Editor.Phase.FEED_WARN)
	check_eq(Sound.voice_line, "editor_feed", "the Steward says look away")
	editor.call(&"_enter_phase", Editor.Phase.FEED)
	await wait_frames(3)
	check(level.feed_blind.is_blinding(), "looked at it: washed out")
	check_eq(bales.size(), Editor.BALES, "and the bales come")


func test_turned_from_its_feed_you_see_the_bales_coming() -> void:
	await _stand(Vector2i(7, 8))
	level.player.face(Iso.ground_dir_between(editor.global_position, level.player.global_position))
	editor.call(&"_enter_phase", Editor.Phase.FEED)
	await wait_frames(3)
	check_false(level.feed_blind.is_blinding(), "your back to it")


func test_it_is_armoured_until_it_reinks() -> void:
	await _stand(Vector2i(7, 8))
	var full := editor.integrity.value
	editor.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(editor.integrity.value, full, "armoured while it prints")
	editor.call(&"_enter_phase", Editor.Phase.INK)
	check_eq(Sound.voice_line, "editor_ink", "the Steward calls the opening")
	editor.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(editor.integrity.value, full - 40.0, "open while it re-inks")


func test_the_bale_stack_knocked_in_while_it_pulps_jams_it() -> void:
	await _stand(Vector2i(3, 3))
	editor.call(&"_start_cycle")
	editor.call(&"_enter_phase", Editor.Phase.PULP)
	check(editor.is_switching(), "pulping")
	editor.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(editor.phase, Editor.Phase.JAMMED, "it jams")
	check(editor.is_vulnerable())
	check_eq(editor.jams, 1)
	editor.call(&"_start_cycle")
	check_false(editor.is_switching(), "rolling, not pulping")
	editor.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(editor.jams, 1, "only while it pulps")
	check_false(editor.weak_point.steward_aims_at, "and the Steward never points you at it")


func test_with_never_warn_me_signed_the_rollers_come_unannounced_and_unlit() -> void:
	await _stand(Vector2i(7, 8))
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	Sound.hush()
	editor.call(&"_start_cycle")
	check(Sound.voice_line != "editor_rollers", "no call")
	check_false(_rollers().gap_lit(), "no gold in the gap")
	editor.call(&"_enter_phase", Editor.Phase.INK)
	check_eq(Sound.voice_line, "editor_ink", "an opening is a fact, still said")


func test_muted_the_track_shows_sooner_and_the_gap_is_unlit() -> void:
	await _stand(Vector2i(7, 8))
	Steward.set_voice(false)
	editor.call(&"_start_cycle")
	check_near(float(editor.get("_warn_for")), Editor.ROLL_WARN_SECONDS + Editor.EARLY_WARN, 0.001)
	check_false(_rollers().gap_lit(), "the Steward lights nothing muted")
