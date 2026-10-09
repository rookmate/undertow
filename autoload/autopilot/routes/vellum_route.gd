extends AutopilotRoute
## The Vellum: the street (walls, the path, the voice table muted and back), its whole route to the
## Reliquary with a detour into the overflow stacks (muted: the slip, the truth core, the Defib Gauntlet
## on the old quay, two of the Waiting), the core choice, then the Ark with its Archive restored: replay
## two memories, talk to Noor, and the dock's map and the run summary.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "walls_block",
	"path_three_tiles_ahead", "voice_muted_by_key", "muted_lamps_dark", "muted_hand_lamp_on",
	"muted_cold_grade", "muted_path_and_map", "muted_assists_off", "voice_restored_lamps",
	"voice_restored", "subtitles_keep_the_voice", "narration_heard", "dodge_performed", "enemy_killed",
]
const THROUGH: Array[String] = [
	"threat_warning_shown", "slowmo_on_dodge", "stacks_reached", "stacks_hidden_while_listening",
	"steward_blind_in_stacks", "found_unindexed_log", "found_truth_core", "gauntlet_found",
	"woke_survivor_in_stacks", "woke_survivor_in_doorway", "route_completed", "arrived_by_reliquary",
	"playstyle_profiled", "core_choice_shown", "four_cards_with_the_found_core", "cores_carried",
	"level_completed_archive_restored", "saved_after_choice", "ark_reached",
	"archive_restored_on_the_ark", "noor_and_teo_present", "survivors_on_the_ark", "archive_replayed",
	"trust_changed", "loop_map_shown", "endings_offered_with_rewrite_locked",
]


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	return out


## Arriving from the Tideworks: the Riot Drone found there, nothing else handed over.
func prepare() -> void:
	super()
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)


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
	var route: Array[Vector2i] = [Vector2i(12, 37), Vector2i(13, 33), Vector2i(14, 30), Vector2i(13, 26), Vector2i(12, 21), Vector2i(11, 15), Vector2i(9, 10), Vector2i(5, 9)]
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
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(5, 9)) <= 1.5, "arrived_by_reliquary")
	var p := GameState.run.playstyle_profile
	check(p.risk + p.caution > 0.0, "playstyle_profiled")
	if not await Autopilot.advance_to(level, player, Vector2i(4, 8), 15.0, gen):
		return
	Autopilot.tap(&"interact")
	await Autopilot.snap("level_plaza")


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
## windowed runs): mid-line, open the pause menu for a second; the recording plays on in real time, and
## its subtitle with it, never ending before the voice does.
func _voice_keeps_time(level: Level, gen: int) -> bool:
	var subs := level.hud.subtitles
	var line := VoiceLines.log_line("log_0522_feed_adjustment")
	Narrator.speak_text(line, VoiceLines.all()[line], LineSelector.FACT)
	if not await Autopilot.wait(0.5, gen):
		return false
	var voice_before := Sound.voice_left()
	var text_before: float = subs.get("_left")
	var at := Time.get_ticks_msec()
	Autopilot.tap(&"pause")
	if not await Autopilot.wait(1.0, gen):
		return false
	var paused := Autopilot.get_tree().paused
	var real := (Time.get_ticks_msec() - at) / 1000.0
	var voice_ran := voice_before - Sound.voice_left()
	var text_ran := text_before - float(subs.get("_left"))
	var covers := float(subs.get("_left")) >= Sound.voice_left() + Subtitles.FADE - 0.05
	Autopilot.tap(&"pause")
	print("[autopilot] voice clock: %.2f s real, voice %.2f s, text %.2f s (audible: %s)" % [real, voice_ran, text_ran, Sound.audible])
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
## muted, read the slip, take the truth core, wake the resident there, take the Gauntlet off the crash
## cart up the old quay, and wake the one in the doorway.
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
	for cell: Vector2i in [Vector2i(17, 26), Vector2i(17, 24)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return false
	if not await Autopilot.use_at(level, player, Vector2i(17, 22), gen):
		return false
	check(GameState.run.weapons_owned.has(WeaponDefs.DEFIB), "gauntlet_found")
	await Autopilot.snap("old_quay_gauntlet")
	for cell: Vector2i in [Vector2i(17, 26), Vector2i(16, 26), Vector2i(15, 26)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return false
	if not await Autopilot.use_at(level, player, Vector2i(10, 25), gen):
		return false
	check(GameState.run.survivor_ids.has(ContentIds.SURVIVOR_DOORWAY), "woke_survivor_in_doorway")
	Autopilot.tap(&"voice_toggle")
	return await Autopilot.wait(0.5, gen)


## Carry the off-path truth core and the Lattice power core.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	check(offered.size() == 4 and offered.has(ContentIds.CORE_TRUTH_STACKS), "four_cards_with_the_found_core")
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, [ContentIds.CORE_TRUTH_STACKS, "vellum_power_lattice"], gen):
		return
	check(r.cores_power() == power + 1 and r.cores_truth() == truth + 1 and r.found_core_ids.is_empty(), "cores_carried")
	check(r.levels_completed.has(ContentIds.LEVEL_VELLUM) and r.buildings_restored.has("archive") and r.logs_unlocked.has("log_vashti_audit_note"), "level_completed_archive_restored")
	check(SaveService.has_save(), "saved_after_choice")
	await Autopilot.snap("vellum_core_choice_done")
	on_to_the_ark(screen)


## The Ark: the restored Archive, Noor and Teo, the survivors; replay two memories, talk, take the skiff.
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
	for log_id: String in ["log_0311_morning_feed", "log_vashti_audit_note"]:
		screen.select(log_id)
		screen.call("_on_replay")
		var lines := (ContentDb.memory_log(log_id).get("record", []) as Array).size()
		if not await Autopilot.wait(lines * ArchiveScreen.LINE_SECONDS + 1.2, gen):
			return false
		await Autopilot.snap("archive_" + log_id)
	check(GameState.run.logs_replayed.has("log_0311_morning_feed") and GameState.run.logs_replayed.has("log_vashti_audit_note"), "archive_replayed")
	check(GameState.run.noor_trust != noor_before or GameState.run.teo_trust != teo_before, "trust_changed")
	Autopilot.tap(&"ui_cancel")
	if not await Autopilot.wait(0.8, gen):
		return false
	if not await Autopilot.use_at(ark, player, Vector2i(12, 9), gen):
		return false
	await Autopilot.snap("ark_noor")
	if not await Autopilot.open_city_map(ark, gen):
		return false
	check(ark.city_map != null, "loop_map_shown")
	await Autopilot.snap("loop_map")
	if not await Autopilot.wait(1.5, gen):
		return false
	if ark.city_map != null:
		ark.city_map.open_summary()
	if not await Autopilot.wait(1.0, gen):
		return false
	await Autopilot.snap("run_summary")
	# Act 1 and the Vellum hold four truth cores at most, one short of what Rewrite asks: it's still locked
	# (a prepared run, with none, and the campaign alike).
	var endings := EndingRules.evaluate(GameState.run)
	check(endings.reboot and endings.unplug and not endings.rewrite and endings.checklist.size() == 3, "endings_offered_with_rewrite_locked")
	if not await Autopilot.wait(1.0, gen):
		return false
	DebugOverlay.toggle()
	if not await Autopilot.wait(0.5, gen):
		return false
	await Autopilot.snap("debug_overlay_final")
	DebugOverlay.toggle()
	return true
