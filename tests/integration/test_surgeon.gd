extends TestCase
## The Surgeon (Mercy General's boss), in a test arena: it marks a line through you and cuts along it,
## floods the theatre with mist all but close to the table, sutures (open to blows); the Steward calls
## each move; the lamp switch thrown while it marks stalls it.

var level: Level
var surgeon: Surgeon


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/surgeon_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	surgeon = level.boss as Surgeon


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
	# Past the Steward's introduction, as if cut short: the fight starts at once.
	Sound.hush()
	await wait_physics_frames(1)


func test_it_marks_a_line_through_you_and_cuts_along_it() -> void:
	check(surgeon != null and surgeon.weak_point is TheatreSwitch, "the Surgeon, and the lamp switch by the door")
	await _stand(Vector2i(10, 4))
	await wait_frames(2)
	check(surgeon.is_engaged)
	check_eq(surgeon.phase, Surgeon.Phase.MARK)
	check_eq(Sound.voice_line, "surgeon_incision", "the Steward calls the incision")
	check(surgeon.on_line(level.player.global_position), "the line runs through you")
	var before := level.player.integrity.value
	await wait_seconds(Surgeon.MARK_SECONDS + Surgeon.CUT_SECONDS + 0.1)
	check(level.player.integrity.value < before, "stay on it and the beam cuts you")


func test_off_the_line_the_cut_misses() -> void:
	await _stand(Vector2i(10, 4))
	await wait_frames(2)
	await wait_seconds(Surgeon.MARK_SECONDS * 0.7)
	# It has committed to the line: step off it, sideways.
	level.player.position = Iso.cell_center(Vector2i(10, 7))
	await wait_physics_frames(2)
	check_false(surgeon.on_line(level.player.global_position), "off the line")
	var before := level.player.integrity.value
	await wait_seconds(Surgeon.MARK_SECONDS * 0.3 + Surgeon.CUT_SECONDS + 0.1)
	check_eq(level.player.integrity.value, before, "and the beam passes you by")


func test_the_mist_spares_you_close_to_the_table() -> void:
	# Standing still, physics on (a sting's short grace has to run out like it does in play).
	level.player.position = Iso.cell_center(Vector2i(8, 4))
	await wait_physics_frames(2)
	Sound.hush()
	await wait_physics_frames(1)
	surgeon.call(&"_enter_phase", Surgeon.Phase.MIST)
	var near := level.player.integrity.value
	check_false(surgeon.in_mist(level.player.global_position), "beside the table: clear")
	await wait_seconds(1.0)
	check_eq(level.player.integrity.value, near, "the mist doesn't reach you by the table")
	level.player.position = Iso.cell_center(Vector2i(12, 4))
	await wait_physics_frames(2)
	surgeon.call(&"_enter_phase", Surgeon.Phase.MIST)
	check(surgeon.in_mist(level.player.global_position), "out in the room")
	var far := level.player.integrity.value
	await wait_seconds(1.0)
	check(level.player.integrity.value <= far - Surgeon.MIST_DAMAGE * 2.0, "it stings, tick after tick")


## The mist fills the theatre, no further: back off past its reach and it can't touch you.
func test_the_mist_stays_in_the_theatre() -> void:
	level.player.position = Iso.cell_center(Vector2i(14, 1))
	await wait_physics_frames(2)
	check(Iso.ground_distance(surgeon.global_position, level.player.global_position) > Surgeon.MIST_REACH, "beyond its reach")
	surgeon.call(&"_enter_phase", Surgeon.Phase.MIST)
	check_false(surgeon.in_mist(level.player.global_position), "not in the mist")
	var before := level.player.integrity.value
	await wait_seconds(1.0)
	check_eq(level.player.integrity.value, before, "and it doesn't sting")


## Downed in the theatre and back at a checkpoint in Mercy General: the fight goes on, the mist stays put.
func test_back_at_a_checkpoint_the_mist_cant_reach_you() -> void:
	var mercy := (load("res://game/level/mercy_general.tscn") as PackedScene).instantiate() as Level
	add_child(mercy)
	await wait_frames(3)
	var boss := mercy.boss as Surgeon
	# Only the Surgeon and its switch: nothing else in the hospital to hurt you meanwhile.
	for e: Enemy in mercy.living_enemies():
		if e != boss and e != boss.weak_point:
			e.queue_free()
	mercy.player.position = boss.global_position + Iso.ground_velocity(Vector2(0, 1), 3.0)
	await wait_physics_frames(3)
	check(boss.is_engaged, "engaged")
	mercy.respawn_player()
	await wait_physics_frames(2)
	boss.call(&"_enter_phase", Surgeon.Phase.MIST)
	var before := mercy.player.integrity.value
	await wait_seconds(1.0)
	check_eq(mercy.player.integrity.value, before, "back at %s, out of the mist" % mercy.checkpoint_cell)
	mercy.queue_free()
	await wait_frames(2)


func test_it_is_armoured_until_it_sutures() -> void:
	await _stand(Vector2i(10, 4))
	await wait_frames(2)
	var full := surgeon.integrity.value
	surgeon.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(surgeon.integrity.value, full, "armoured while it works")
	surgeon.call(&"_enter_phase", Surgeon.Phase.SUTURE)
	check_eq(Sound.voice_line, "surgeon_suture", "the Steward calls the opening")
	surgeon.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(surgeon.integrity.value, full - 40.0, "open while it bends over the table")


func test_the_lamp_switch_thrown_while_it_marks_stalls_it() -> void:
	await _stand(Vector2i(3, 6))
	await wait_frames(2)
	check(surgeon.is_engaged and surgeon.is_switching(), "marking a line")
	surgeon.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(surgeon.phase, Surgeon.Phase.STALLED, "its guide goes dark")
	check(surgeon.is_vulnerable())
	check_eq(surgeon.stalls, 1)
	surgeon.call(&"_enter_phase", Surgeon.Phase.CUT)
	surgeon.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(surgeon.stalls, 1, "only while it's marking")
	check_false(surgeon.weak_point.steward_aims_at, "and the Steward never points you at it")


func test_with_never_warn_me_signed_it_cuts_in_silence() -> void:
	await _stand(Vector2i(10, 4))
	await wait_frames(2)
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	Sound.hush()
	surgeon.call(&"_enter_phase", Surgeon.Phase.MARK)
	check(Sound.voice_line != "surgeon_incision", "no call: it lays the line and says nothing")
	surgeon.call(&"_enter_phase", Surgeon.Phase.SUTURE)
	check_eq(Sound.voice_line, "surgeon_suture", "an opening is a fact, still said")
