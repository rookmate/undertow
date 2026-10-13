extends AutopilotRoute
## The Vellum: the street (walls, the path, the voice table muted and back), its whole route to the
## Reliquary with a detour into the overflow stacks (muted: the slip, the truth core, two of the
## Waiting); over the footbridge to the newsroom, where a Clerk turns the Feed on you (looked at, it
## washes the world out; turned from, it doesn't); muted, down the stair to the deep stacks and Prem
## Vashti's office (her last note, a tube carrier nobody opened, one of the Waiting); the Editor in the
## press hall (the Steward's way: into the gap it lights before each roller, your back to the Feed, at
## it while it re-inks), then past the barrier to the Reliquary. Both of her notes carried, then the Ark
## with its Archive restored: replay them, talk to Noor, and the dock's map and the run summary.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "walls_block",
	"path_three_tiles_ahead", "voice_muted_by_key", "muted_lamps_dark", "muted_hand_lamp_on",
	"muted_cold_grade", "muted_path_and_map", "muted_assists_off", "voice_restored_lamps",
	"voice_restored", "subtitles_keep_the_voice", "narration_heard", "dodge_performed", "enemy_killed",
]
const THROUGH: Array[String] = [
	"threat_warning_shown", "slowmo_on_dodge", "stacks_reached", "stacks_hidden_while_listening",
	"steward_blind_in_stacks", "found_unindexed_log", "found_truth_core",
	"woke_survivor_in_stacks", "woke_survivor_in_doorway", "path_over_the_bridge", "newsroom_on_the_lattice",
	"feed_blinded", "turned_from_the_feed", "woke_in_the_audit_office", "found_the_tube_carrier",
	"found_vashti_last_note", "editor_engaged", "editor_called_the_rollers", "stood_in_the_gap",
	"kept_its_back_to_the_feed", "editor_inked", "editor_beaten", "barriers_opened", "route_completed",
	"arrived_by_reliquary",
	"playstyle_profiled", "core_choice_shown", "five_cards_with_both_vashti_notes", "cores_carried",
	"level_completed_archive_restored", "saved_after_choice", "ark_reached",
	"archive_restored_on_the_ark", "noor_and_teo_present", "survivors_on_the_ark", "archive_replayed",
	"trust_changed", "conversation_waiting", "conversation_offered", "conversation_answered", "loop_map_shown",
	"endings_offered_with_rewrite_locked",
]


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	return out


## Arriving from the Tideworks: the Riot Drone found there and Noor and Teo met on the Ark after it;
## nothing else handed over.
func prepare() -> void:
	super()
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)
	GameState.meet_companions()


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	var ids: Array[String] = []
	for w: Weapon in player.weapons:
		ids.append(w.weapon_id)
	check(ids == [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE] and player.weapons[0].chosen_mode == Loadout.Mode.MANUAL, "loadout_applied")
	# Aim with the right stick from here on, like a controller player.
	Controls.device = Controls.Device.PAD
	player.dodged.connect(func(_d: Vector2) -> void: pass_check("dodge_performed"), CONNECT_ONE_SHOT)
	Narrator.line_spoken.connect(func(_id: String, _t: String) -> void:
		if not Autopilot.stale(gen):
			pass_check("narration_heard"), CONNECT_ONE_SHOT)
	var start_count := level.living_enemies().size()
	if not await Autopilot.wait(1.2, gen):
		return
	await Autopilot.snap("level_start")
	if not await Autopilot.hold_ground(Vector2(-1, 0), 1.0, gen):
		return
	check(level.grid.is_walkable(player.cell()) and player.cell().x >= 9, "walls_block")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	await Autopilot.snap("path")
	if not await _toggle_voice_and_check(level, player, gen):
		return
	var route: Array[Vector2i] = [Vector2i(12, 37), Vector2i(13, 33), Vector2i(14, 30), Vector2i(13, 26), Vector2i(12, 21), Vector2i(11, 15), Vector2i(9, 10)]
	if long_run:
		level.slow_mo.started.connect(func(_s: float) -> void: pass_check("slowmo_on_dodge"), CONNECT_ONE_SHOT)
		_watch_threats(level, gen)
	var shot_fight := false
	for i: int in route.size():
		if not await Autopilot.advance_to(level, player, route[i], 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
		if not shot_fight and level.living_enemies().size() < start_count:
			shot_fight = true
			await Autopilot.snap("level_after_fight")
		if long_run and i == 1:
			if not await _visit_stacks(level, player, gen):
				return
	if not long_run:
		return
	await Autopilot.snap("level_plaza")
	# Over the footbridge: the Steward's path leads on, into the newsroom.
	for cell: Vector2i in [Vector2i(14, 7), Vector2i(19, 6)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.wait(0.6, gen):
		return
	var ahead := level.predicted_path.shown
	check(not ahead.is_empty() and ahead[ahead.size() - 1].x > player.cell().x, "path_over_the_bridge")
	await Autopilot.snap("vellum_bridge")
	if not await Autopilot.advance_to(level, player, Vector2i(25, 6), 25.0, gen):
		return
	check(level.grid.floor_at(player.cell()) == LevelGrid.Floor.PARQUET and level.grid.is_indexed(player.cell()) and not Steward.assists().signal_lost, "newsroom_on_the_lattice")
	await Autopilot.snap("vellum_newsroom")
	if not await _face_the_feed(level, player, gen):
		return
	# Through the newsroom to the stair down, muted: the deep stacks and Prem Vashti's office.
	for cell: Vector2i in [Vector2i(27, 6), Vector2i(27, 13)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.8, gen):
		return
	for cell: Vector2i in [Vector2i(27, 14), Vector2i(27, 15), Vector2i(28, 15)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(28, 19), gen):
		return
	check(GameState.run.survivor_ids.has("vellum_waiting_audit_office"), "woke_in_the_audit_office")
	await Autopilot.snap("vellum_vashti_office")
	if not await Autopilot.use_at(level, player, Vector2i(30, 19), gen):
		return
	check(GameState.run.logs_unlocked.has("log_vellum_tube_carrier"), "found_the_tube_carrier")
	if not await Autopilot.use_at(level, player, Vector2i(32, 19), gen):
		return
	check(GameState.run.found_core_ids.has("vellum_truth_vashti_office"), "found_vashti_last_note")
	await Autopilot.snap("vellum_vashti_note")
	for cell: Vector2i in [Vector2i(28, 19), Vector2i(28, 15), Vector2i(27, 15), Vector2i(27, 13)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.6, gen):
		return
	# Into the press hall and the Editor.
	for cell: Vector2i in [Vector2i(27, 11), Vector2i(33, 11), Vector2i(34, 9), Vector2i(36, 9)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	var editor := level.boss as Editor
	if editor == null:
		return
	check(await Autopilot.until(func() -> bool: return editor.is_engaged, 3.0, gen), "editor_engaged")
	await Autopilot.snap("vellum_editor")
	if not await _fight_editor(level, player, editor, gen):
		return
	check(boss_down(player), "editor_beaten")
	await Autopilot.snap("vellum_editor_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	for cell: Vector2i in [Vector2i(40, 13), Vector2i(40, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(level.grid.first("R"))) <= 1.5, "arrived_by_reliquary")
	var p := GameState.run.playstyle_profile
	check(p.risk + p.caution > 0.0, "playstyle_profiled")
	await Autopilot.snap("vellum_reliquary")
	Autopilot.tap(&"interact")


## The Steward's way with the Editor: into the gap it lights before each roller; your back to its screen
## when it turns the Feed on; at it while it re-inks. Gives up after 120 s.
func _fight_editor(level: Level, player: Operator, editor: Editor, gen: int) -> bool:
	var flashes: Array[bool] = []
	level.feed_flashed.connect(func(caught: bool) -> void: flashes.append(caught))
	var spent := 0.0
	var frame := 0
	var snapped_rollers := false
	while spent < 120.0:
		# A fight restarted after the Operator went down: the fresh boss.
		editor = boss_now(editor, player) as Editor
		if editor == null or not editor.is_alive():
			break
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Sound.voice_line == "editor_rollers":
			pass_check("editor_called_the_rollers")
		if editor.phase == Editor.Phase.INK:
			pass_check("editor_inked")
		var at := player.global_position
		if editor.phase == Editor.Phase.ROLL and editor.in_gap(Iso.world_to_grid(at)):
			pass_check("stood_in_the_gap")
			if not snapped_rollers and editor.roller_at() > Iso.world_to_grid(at).y - 1.5:
				snapped_rollers = true
				await Autopilot.snap("vellum_editor_rollers")
		if editor.is_vulnerable():
			Autopilot.fight(player, editor, frame)
			spent += await Autopilot.physics_step()
			continue
		Autopilot.release_attacks()
		var away := Iso.ground_dir_between(editor.global_position, at)
		var target := editor.global_position + Iso.ground_velocity(away, 2.6)
		match editor.phase:
			Editor.Phase.ROLL_WARN, Editor.Phase.ROLL:
				target = Iso.cell_center(_gap_cell(level, editor, player.cell()))
			Editor.Phase.FEED_WARN, Editor.Phase.FEED:
				# Your back to its screen: walk away from it.
				target = at + Iso.ground_velocity(away, 2.0)
		if Iso.ground_distance(at, target) > 0.25:
			Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(at, target)))
		else:
			Autopilot.press_move(Vector2.ZERO)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	check(flashes.has(false), "kept_its_back_to_the_feed")
	return true


## The nearest open cell in the rollers' gap, clear of the press and the pulper.
func _gap_cell(level: Level, editor: Editor, from: Vector2i) -> Vector2i:
	var best := from
	var best_d := INF
	var h := editor.hall()
	for y: int in range(int(h.position.y), int(h.end.y)):
		for x: int in range(int(h.position.x), int(h.end.x)):
			var c := Vector2i(x, y)
			if not editor.in_gap(Vector2(c) + Vector2(0.5, 0.5)) or not level.grid.is_walkable(c):
				continue
			if Vector2(c).distance_to(Vector2(editor.grid_cell())) < 2.0 or (editor.weak_point != null and c == editor.weak_point.grid_cell()):
				continue
			var d := Vector2(c).distance_to(Vector2(from))
			if d < best_d:
				best = c
				best_d = d
	return best


## In the newsroom a Clerk turns the Feed on you. Look at it and the world washes out; then, knowing,
## turn your back on its next one (the way the autopilot does from here on), and nothing happens.
## Stands its ground meanwhile, rolling from its bales.
func _face_the_feed(level: Level, player: Operator, gen: int) -> bool:
	var flashes: Array[bool] = []
	level.feed_flashed.connect(func(caught: bool) -> void: flashes.append(caught))
	var clerk: Clerk = null
	for e: Enemy in level.living_enemies():
		if e is Clerk and (clerk == null or Iso.ground_distance(player.global_position, e.global_position) < Iso.ground_distance(player.global_position, clerk.global_position)):
			clerk = e
	if clerk == null:
		return true
	Autopilot.turn_from_feed = false
	var spent := 0.0
	while not flashes.has(true) and spent < 10.0 and clerk.is_alive():
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		_stand_facing(player, clerk)
		spent += await Autopilot.physics_step()
	Autopilot.press_move(Vector2.ZERO)
	check(flashes.has(true) and level.feed_blind.is_blinding(), "feed_blinded")
	if not await Autopilot.wait(0.3, gen):
		return false
	await Autopilot.snap("vellum_feed_blind")
	Autopilot.turn_from_feed = true
	var before := flashes.size()
	spent = 0.0
	while flashes.size() == before and spent < 10.0 and clerk.is_alive():
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		if Autopilot.feed_coming(level, player) != null:
			Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(clerk.global_position, player.global_position)))
		else:
			_stand_facing(player, clerk)
		spent += await Autopilot.physics_step()
	Autopilot.press_move(Vector2.ZERO)
	check(flashes.size() > before and not flashes[flashes.size() - 1], "turned_from_the_feed")
	return true


## Turn to look at the Clerk (a nudge toward it), then stand; roll sideways out of a bale's line.
func _stand_facing(player: Operator, clerk: Clerk) -> void:
	var to := Iso.ground_dir_between(player.global_position, clerk.global_position)
	if clerk.state == Enemy.State.WINDUP and not clerk.flash_next and clerk.windup_progress() > 0.8 and player.dodge.can_start():
		Autopilot.press_move(Autopilot.input_for_ground(Vector2(-to.y, to.x)))
		Autopilot.tap(&"dodge")
	elif player.facing_ground.dot(to) < 0.95:
		Autopilot.press_move(Autopilot.input_for_ground(to))
	else:
		Autopilot.press_move(Vector2.ZERO)


## Mutes the Steward with the voice key and checks everything the brief's voice table says changes,
## then turns it back on.
func _toggle_voice_and_check(level: Level, player: Operator, gen: int) -> bool:
	var toggles := GameState.run.voice_toggle_count
	Autopilot.tap(&"voice_toggle")
	var all_lamps := func(lit: bool) -> bool:
		for n: Node in Autopilot.get_tree().get_nodes_in_group(&"lattice_lamps"):
			if (n as LampPost).lit != lit:
				return false
		return true
	check(await Autopilot.until(func() -> bool: return not Steward.voice_on and GameState.run.voice_toggle_count == toggles + 1, 1.0, gen), "voice_muted_by_key")
	check(await Autopilot.until(func() -> bool: return all_lamps.call(false), 3.0, gen), "muted_lamps_dark")
	check(player.carried_light_on(), "muted_hand_lamp_on")
	check(await Autopilot.until(func() -> bool: return level.lighting.grade_amount() > 0.95, 3.0, gen), "muted_cold_grade")
	var a := Steward.assists()
	check(level.predicted_path.shown.is_empty() and level.hud.minimap.mode() == Assists.MapMode.HAND_SCAN, "muted_path_and_map")
	check(not a.threat_warnings and a.aim_assist == 0.0 and a.dodge_slowmo_seconds == 0.0 and not player.weapons[1].is_tuned() and a.damage_taken_mult > 1.0, "muted_assists_off")
	await Autopilot.snap("muted_street")
	Autopilot.tap(&"voice_toggle")
	check(await Autopilot.until(func() -> bool: return Steward.voice_on and all_lamps.call(true), 3.0, gen), "voice_restored_lamps")
	check(await Autopilot.until(func() -> bool: return level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD and level.hud.subtitles.is_speaking(), 3.0, gen), "voice_restored")
	await Autopilot.snap("voice_restored")
	return await _voice_keeps_time(level, gen)


## The Steward's voice keeps its own clock, on the real audio path when the run has one (the gate's
## windowed runs): mid-line, open the pause menu for a second; the recording plays on, and its subtitle
## with it, never ending before the voice does. Measured against the run's own unscaled clock: real time
## live, the movie's time when recording.
func _voice_keeps_time(level: Level, gen: int) -> bool:
	var subs := level.hud.subtitles
	var line := VoiceLines.log_line("log_0522_feed_adjustment")
	Narrator.speak_text(line, VoiceLines.all()[line], LineSelector.FACT)
	if not await Autopilot.wait(0.5, gen):
		return false
	var voice_before := Sound.voice_left()
	var text_before: float = subs.get("_left")
	var at := Autopilot.run_seconds()
	Autopilot.tap(&"pause")
	if not await Autopilot.wait(1.0, gen):
		return false
	var paused := Autopilot.get_tree().paused
	var real := Autopilot.run_seconds() - at
	var voice_ran := voice_before - Sound.voice_left()
	var text_ran := text_before - float(subs.get("_left"))
	var covers := float(subs.get("_left")) >= Sound.voice_left() + Subtitles.FADE - 0.05
	Autopilot.tap(&"pause")
	print("[autopilot] voice clock: %.2f s run time, voice %.2f s, text %.2f s (audible: %s)" % [real, voice_ran, text_ran, Sound.audible])
	check(paused and Sound.voice_line == line and absf(voice_ran - real) < 0.2 and absf(text_ran - real) < 0.2 and covers, "subtitles_keep_the_voice")
	return await Autopilot.wait(0.5, gen)


func _watch_threats(level: Level, gen: int) -> void:
	while not Autopilot.stale(gen):
		if not level.hud.view.active_threats().is_empty():
			pass_check("threat_warning_shown")
			await Autopilot.snap("threat_warning")
			return
		await Autopilot.physics_step()


## Off the path: down the stair into the overflow stacks. Nothing there while the Steward listens;
## muted, read the slip, take the truth core, wake the resident there and the one in the doorway.
func _visit_stacks(level: Level, player: Operator, gen: int) -> bool:
	for cell: Vector2i in [Vector2i(15, 27), Vector2i(15, 26), Vector2i(16, 26), Vector2i(17, 26), Vector2i(18, 28)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return false
	pass_check("stacks_reached")
	var cache: TruthCache = null
	for n: Node in Autopilot.get_tree().get_nodes_in_group(&"interactables"):
		if n is TruthCache:
			cache = n
	check(level.predicted_path.shown.is_empty() and cache != null and not cache.is_present(), "stacks_hidden_while_listening")
	# Off the Lattice the voice is still on, but the Steward can't see the Operator.
	check(await Autopilot.until(func() -> bool: return Steward.voice_on and Steward.assists().signal_lost and level.hud.minimap.charted_label().ends_with("SIGNAL LOST"), 2.0, gen), "steward_blind_in_stacks")
	await Autopilot.snap("stacks_listening")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(1.2, gen):
		return false
	await Autopilot.snap("stacks_muted")
	if not await Autopilot.use_at(level, player, Vector2i(18, 28), gen):
		return false
	check(GameState.run.logs_unlocked.has(ContentIds.LOG_UNINDEXED_SLIP), "found_unindexed_log")
	if not await Autopilot.use_at(level, player, Vector2i(19, 24), gen):
		return false
	check(GameState.run.found_core_ids.has(ContentIds.CORE_TRUTH_STACKS), "found_truth_core")
	await Autopilot.snap("stacks_truth_core")
	if not await Autopilot.use_at(level, player, Vector2i(18, 30), gen):
		return false
	check(GameState.run.survivor_ids.has(ContentIds.SURVIVOR_STACKS), "woke_survivor_in_stacks")
	await Autopilot.snap("stacks_woken")
	for cell: Vector2i in [Vector2i(17, 26), Vector2i(16, 26), Vector2i(15, 26)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return false
	if not await Autopilot.use_at(level, player, Vector2i(10, 25), gen):
		return false
	check(GameState.run.survivor_ids.has(ContentIds.SURVIVOR_DOORWAY), "woke_survivor_in_doorway")
	Autopilot.tap(&"voice_toggle")
	return await Autopilot.wait(0.5, gen)


## Carry both of Prem Vashti's notes (her thread), leaving the power cores.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	check(offered.size() == 5 and offered.has(ContentIds.CORE_TRUTH_STACKS) and offered.has("vellum_truth_vashti_office"), "five_cards_with_both_vashti_notes")
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, [ContentIds.CORE_TRUTH_STACKS, "vellum_truth_vashti_office"], gen):
		return
	check(r.cores_power() == power and r.cores_truth() == truth + 2 and r.found_core_ids.is_empty(), "cores_carried")
	check(r.levels_completed.has(ContentIds.LEVEL_VELLUM) and r.buildings_restored.has("archive") and r.logs_unlocked.has("log_vashti_audit_note") and r.logs_unlocked.has("log_vashti_last_note"), "level_completed_archive_restored")
	check(SaveService.has_save(), "saved_after_choice")
	await Autopilot.snap("vellum_core_choice_done")
	on_to_the_ark(screen)


## The Ark: the restored Archive, Noor and Teo, the survivors; replay Prem Vashti's notes, talk her over
## with Noor and Teo (and say nothing), take the skiff.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	var player := ark.player
	var figures: Dictionary[String, int] = {}
	for n: Node in ark.world.get_children():
		if n is ArkFigure:
			var key := (n as ArkFigure).display_name()
			figures[key] = int(figures.get(key, 0)) + 1
	check(facade_cells(ark, BuildingCell.Facade.ARCHIVE) > 0, "archive_restored_on_the_ark")
	check(figures.get("NOOR", 0) == 1 and figures.get("TEO", 0) == 1, "noor_and_teo_present")
	check(int(figures.get("SURVIVOR", 0)) == GameState.run.survivors_found(), "survivors_on_the_ark")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark")
	if not await Autopilot.advance_to(ark, player, Vector2i(10, 7), 20.0, gen):
		return false
	Autopilot.tap(&"interact")
	if not await Autopilot.wait(0.8, gen):
		return false
	var screen := ark.archive_screen
	if screen == null:
		return false
	await Autopilot.snap("archive")
	var noor_before := GameState.run.noor_trust
	var teo_before := GameState.run.teo_trust
	for log_id: String in ["log_vashti_audit_note", "log_vashti_last_note"]:
		screen.select(log_id)
		screen.call("_on_replay")
		var lines := (ContentDb.memory_log(log_id).get("record", []) as Array).size()
		if not await Autopilot.wait(lines * ArchiveScreen.LINE_SECONDS + 1.2, gen):
			return false
		await Autopilot.snap("archive_" + log_id)
	check(GameState.run.logs_replayed.has("log_vashti_audit_note") and GameState.run.logs_replayed.has("log_vashti_last_note"), "archive_replayed")
	check(GameState.run.noor_trust != noor_before or GameState.run.teo_trust != teo_before, "trust_changed")
	Autopilot.tap(&"ui_cancel")
	if not await Autopilot.wait(0.8, gen):
		return false
	if not await talk_it_over(ark, "none", gen):
		return false
	if not await Autopilot.open_city_map(ark, gen):
		return false
	check(ark.city_map != null, "loop_map_shown")
	await Autopilot.snap("loop_map")
	if not await Autopilot.wait(1.5, gen):
		return false
	var summary: RunSummary = ark.city_map.open_summary() if ark.city_map != null else null
	if not await Autopilot.wait(1.0, gen):
		return false
	await Autopilot.snap("run_summary")
	# Rewrite stays locked for both runs that get here: a prepared run carries two truth cores, short of
	# what it asks, and the campaign listens far more than the balanced share it asks for.
	var endings := EndingRules.evaluate(GameState.run)
	for c: EndingRules.Condition in endings.checklist:
		print("[autopilot] rewrite: %s: %s (%s)" % [c.label, "met" if c.met else "not met", c.detail])
	check(endings.reboot and endings.unplug and not endings.rewrite and endings.checklist.size() == 3, "endings_offered_with_rewrite_locked")
	if not await Autopilot.wait(1.0, gen):
		return false
	DebugOverlay.toggle()
	if not await Autopilot.wait(0.5, gen):
		return false
	await Autopilot.snap("debug_overlay_final")
	DebugOverlay.toggle()
	# Back to the map (a campaign sets off from it).
	if is_instance_valid(summary):
		summary.close()
	return await Autopilot.wait(0.5, gen)
