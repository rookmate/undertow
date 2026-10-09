extends TestCase
## The voice toggle in the real level, through the real input action: everything the brief's voice table
## lists changes, and changes back.

var level: Level


func before_each() -> void:
	GameState.new_run()
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, false)
	Engine.time_scale = 1.0
	level.queue_free()
	await wait_frames(2)


func _press_voice() -> void:
	var down := InputEventAction.new()
	down.action = &"voice_toggle"
	down.pressed = true
	Input.parse_input_event(down)
	await wait_frames(2)
	var up := InputEventAction.new()
	up.action = &"voice_toggle"
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)


func _lamps() -> Array[LampPost]:
	var out: Array[LampPost] = []
	for n: Node in get_tree().get_nodes_in_group(&"lattice_lamps"):
		if level.is_ancestor_of(n):
			out.append(n as LampPost)
	return out


func test_voice_key_mutes_and_unmutes() -> void:
	await _press_voice()
	check_false(Steward.voice_on)
	check_false(GameState.run.voice_on, "remembered in the run")
	check_eq(GameState.run.voice_toggle_count, 1)
	await _press_voice()
	check(Steward.voice_on)
	check_eq(GameState.run.voice_toggle_count, 2)


func test_muting_switches_every_system_and_unmuting_restores_them() -> void:
	await _press_voice()
	await wait_seconds(1.6)
	for lamp: LampPost in _lamps():
		check_false(lamp.lit, "lamp dark")
	for b: Node in get_tree().get_nodes_in_group(&"gilt"):
		check_false((b as BuildingCell).gilt_lit, "gilt dead")
		break
	check_near(level.lighting.grade_amount(), 1.0, 0.01, "cold grade")
	check(level.player.carried_light_on(), "only what you carry is lit")
	check(level.predicted_path.shown.is_empty(), "no path")
	check_eq(level.hud.minimap.mode(), Assists.MapMode.HAND_SCAN)
	check(level.hud.minimap.charted_label().begins_with("HAND SCAN"))
	check_false(level.player.weapons[0].is_tuned(), "weapons manual")
	var muted_talk: Array[String] = []
	var listener := func(_id: String, t: String) -> void: muted_talk.append(t)
	Narrator.line_spoken.connect(listener)
	Narrator.speak_text("test", "should not be heard")
	check(muted_talk.is_empty(), "narration silent")
	await _press_voice()
	await wait_seconds(1.6)
	for lamp: LampPost in _lamps():
		check(lamp.lit, "lamp back")
	check_near(level.lighting.grade_amount(), 0.0, 0.01)
	check_false(level.player.carried_light_on())
	check_eq(level.predicted_path.shown.size(), Tunables.PATH_TILES_AHEAD)
	check_eq(level.hud.minimap.charted_label(), "STEWARD MAP · 100% CHARTED")
	check(level.player.weapons[0].is_tuned() or level.player.weapons[0].chosen_mode == Loadout.Mode.MANUAL)
	check_false(muted_talk.is_empty(), "it speaks when it comes back")
	Narrator.line_spoken.disconnect(listener)


func test_voice_time_counts_level_play_only() -> void:
	await wait_seconds(1.0)
	await _press_voice()
	await wait_seconds(1.0)
	var r := GameState.run
	check_near(r.voice_on_ratio(), 0.5, 0.08, "about half and half")
	var before := r.voice_tracked_seconds()
	get_tree().paused = true
	await wait_seconds(0.5)
	get_tree().paused = false
	check_near(r.voice_tracked_seconds(), before, 0.05, "paused time doesn't count")


func _stage_windup() -> Custodian:
	var c := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(0, -1), Custodian.MAX_INTEGRITY) as Custodian
	await wait_physics_frames(30)
	return c


func test_threat_warnings_only_with_the_voice_on_and_no_override() -> void:
	var c := await _stage_windup()
	check(level.hud.view.active_threats().has(c), "the Steward calls out the windup")
	c.queue_free()
	await wait_frames(2)
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	var c2 := await _stage_windup()
	check_false(level.hud.view.active_threats().has(c2), "the override silences it")
	c2.queue_free()
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, false)
	await wait_frames(2)
	Steward.set_voice(false)
	var c3 := await _stage_windup()
	check_false(level.hud.view.active_threats().has(c3), "muted: no warnings")


func test_dodging_a_windup_slows_time_only_with_the_voice_on() -> void:
	var c := level.add_enemy(Custodian.new(), level.player.cell() + Vector2i(0, -1), Custodian.MAX_INTEGRITY) as Custodian
	c.state = Enemy.State.WINDUP
	level.player.dodge.try_start(Vector2(1, 0))
	level.player.dodged.emit(Vector2(1, 0))
	check(Engine.time_scale < 1.0, "slow-mo on a close dodge")
	await wait_seconds(Assists.BASE_SLOWMO_SECONDS * 3.0)
	check_eq(Engine.time_scale, 1.0, "and it ends")
	Steward.set_voice(false)
	level.player.dodged.emit(Vector2(1, 0))
	check_eq(Engine.time_scale, 1.0, "muted: no slow-mo")


func test_hand_scan_charts_what_you_walk_past() -> void:
	var before := level.exploration.charted_ratio()
	check(before > 0.0 and before < 0.2, "a little around the start")
	level.player.position = Iso.cell_center(Vector2i(12, 24))
	await wait_frames(3)
	check(level.exploration.charted_ratio() > before)


func test_the_hand_scan_hears_only_about_cells_it_had_not_seen() -> void:
	var heard: Array[Vector2i] = []
	var collect := func(cells: Array[Vector2i]) -> void: heard.append_array(cells)
	level.exploration.discovered.connect(collect)
	var seen_before := level.exploration.explored.duplicate()
	level.player.position = Iso.cell_center(Vector2i(12, 24))
	await wait_frames(3)
	check_false(heard.is_empty(), "walking somewhere new reveals cells")
	for c: Vector2i in heard:
		check_false(seen_before.has(c), "%s was already charted" % c)
	check_eq(heard.size(), level.exploration.explored.size() - seen_before.size(), "each new cell reported once")
	heard.clear()
	level.player.position = Iso.cell_center(level.grid.start_cell())
	await wait_frames(3)
	level.player.position = Iso.cell_center(Vector2i(12, 24))
	await wait_frames(3)
	check(heard.is_empty(), "walking back over charted ground reveals nothing: %s" % [heard])
	level.exploration.discovered.disconnect(collect)
