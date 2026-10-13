extends AutopilotRoute
## The Loop, train to train over the drop: the first carriage's Custodians, the driver's cab (muted), the
## gantries; on platform B the points thrown by hand while the Steward's Custodians come (the hold), and
## down the service hatch into the tunnels (the descent: the one waiting there, the crew's log); the
## second train, then the Conductor (the Steward's way: off the called
## lane, hit it while it vents) and the Reliquary past the buffer stops. Then the Ark's Signal Room:
## sign an order and hear the Steward's answer.

const ROUTE: Array[String] = [
	"loadout_shown", "loadout_one_weapon", "level_reached", "player_spawned", "path_three_tiles_ahead",
	"enemy_killed", "cab_truth_found", "hold_started", "hold_brought_them_out", "points_thrown", "went_down",
	"dark_below", "woke_in_the_tunnels", "crew_log_found", "climbed_back_up", "conductor_engaged", "conductor_called_a_lane", "conductor_vented",
	"conductor_beaten", "barriers_opened", "route_completed", "core_choice_shown", "loop_cores_carried",
	"ark_reached", "signal_room_restored", "signal_room_standing", "override_signed",
	"steward_answered_the_order",
]

## The order signed in the Signal Room (a campaign signs one it can keep for the rest of the run).
var order_to_sign: String = Overrides.NO_SLOWMO


## Always the whole route, whatever the run's length.
func checks() -> Array[String]:
	return ROUTE.duplicate()


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	Controls.device = Controls.Device.PAD
	var start_count := level.living_enemies().size()
	if not await Autopilot.wait(1.2, gen):
		return
	await Autopilot.snap("loop_start")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	for cell: Vector2i in [Vector2i(8, 16), Vector2i(14, 16), Vector2i(19, 16), Vector2i(22, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if level.living_enemies().size() < start_count:
		pass_check("enemy_killed")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.6, gen):
		return
	if not await Autopilot.use_at(level, player, Vector2i(23, 18), gen):
		return
	check(GameState.run.found_core_ids.has("loop_truth_no_manual"), "cab_truth_found")
	await Autopilot.snap("loop_cab")
	Autopilot.tap(&"voice_toggle")
	for cell: Vector2i in [Vector2i(20, 16), Vector2i(20, 15), Vector2i(20, 12), Vector2i(20, 9)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	# Platform B: the points thrown by hand (the hold) opens the service hatch.
	if not await run_hold(level, player, Vector2i(23, 9), gen):
		return
	check(level.passage("loop_tunnels_down") != null and level.passage("loop_tunnels_down").can_interact(), "points_thrown")
	var tunnels := func() -> bool:
		if not await Autopilot.use_at(level, player, Vector2i(18, 34), gen):
			return false
		check(GameState.run.survivor_ids.has("loop_waiting_in_the_tunnels"), "woke_in_the_tunnels")
		for cell: Vector2i in [Vector2i(25, 33), Vector2i(31, 32)]:
			if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
				return false
		if not await Autopilot.use_at(level, player, Vector2i(34, 30), gen):
			return false
		check(GameState.run.found_core_ids.has("loop_truth_service_log"), "crew_log_found")
		return true
	if not await descend(level, player, Vector2i(26, 10), [Vector2i(12, 27), Vector2i(20, 26), Vector2i(22, 30), Vector2i(20, 33)],
			tunnels, [Vector2i(31, 32), Vector2i(25, 33), Vector2i(22, 30), Vector2i(20, 26), Vector2i(12, 26)], Vector2i(11, 26), gen):
		return
	for cell: Vector2i in [Vector2i(26, 8), Vector2i(30, 8), Vector2i(37, 8), Vector2i(39, 7), Vector2i(39, 5), Vector2i(39, 4)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if level.living_enemies().size() < start_count:
		pass_check("enemy_killed")
	var boss := level.boss as Conductor
	if boss == null:
		return
	check(await Autopilot.until(func() -> bool: return boss.is_engaged, 3.0, gen), "conductor_engaged")
	await Autopilot.snap("loop_conductor")
	if not await _fight_conductor(player, boss, gen):
		return
	check(boss_down(player), "conductor_beaten")
	await Autopilot.snap("loop_conductor_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	for cell: Vector2i in [Vector2i(36, 3), Vector2i(30, 3), Vector2i(27, 3), Vector2i(25, 3)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	Autopilot.tap(&"interact")


## The Steward's solution: keep off the lane it calls, wait out the runs, close in and hit it while it
## vents. Gives up after 90 s.
func _fight_conductor(player: Operator, boss: Conductor, gen: int) -> bool:
	var spent := 0.0
	var frame := 0
	var lane_rows: Array[int] = [2, 3, 4]
	while spent < 90.0:
		# A fight restarted after the Operator went down: the fresh boss.
		boss = boss_now(boss, player) as Conductor
		if boss == null or not boss.is_alive():
			break
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Sound.voice_line.begins_with("conductor_"):
			pass_check("conductor_called_a_lane")
		if boss.phase == Conductor.Phase.VENT:
			pass_check("conductor_vented")
		var row := player.cell().y
		var danger: ShuntLane = boss.get("_lane") if boss.phase == Conductor.Phase.WARN or boss.phase == Conductor.Phase.RUN else null
		if boss.is_vulnerable():
			Autopilot.fight(player, boss, frame)
		elif danger != null and danger.has_cell(player.cell()):
			# Step to the next lane over, away from the one that's about to run.
			var safe := row - 1 if row > 2 else row + 1
			for r: int in lane_rows:
				if not danger.has_cell(Vector2i(player.cell().x, r)) and absi(r - row) == 1:
					safe = r
			Autopilot.release_attacks()
			Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(player.global_position, Iso.cell_center(Vector2i(clampi(player.cell().x, 36, 41), safe)))))
		else:
			Autopilot.release_attacks()
			var hold := Vector2i(clampi(player.cell().x, 39, 41), row if lane_rows.has(row) else 3)
			if Iso.ground_distance(player.global_position, Iso.cell_center(hold)) > 0.3:
				Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(player.global_position, Iso.cell_center(hold))))
			else:
				Autopilot.press_move(Vector2.ZERO)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	return true


## Carry the procurement order and the Route core.
func choose(screen: Node, gen: int) -> void:
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["loop_truth_no_manual", "loop_power_routes"], gen):
		return
	check(r.levels_completed.has("loop") and r.cores_truth() == truth + 1 and r.cores_power() == power + 1, "loop_cores_carried")
	on_to_the_ark(screen)


## The Signal Room stands: sign the order, and the Steward answers it aloud.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.buildings_restored.has("signal_room"), "signal_room_restored")
	check(facade_cells(ark, BuildingCell.Facade.SIGNAL_ROOM) > 0, "signal_room_standing")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_loop")
	if not await Autopilot.use_at(ark, ark.player, Vector2i(12, 5), gen):
		return false
	var orders := ark.overrides_screen
	if orders == null:
		return false
	await Autopilot.snap("signal_room")
	orders.toggle(order_to_sign)
	check(GameState.has_override(order_to_sign), "override_signed")
	check(Sound.voice_line == Overrides.reply_line(order_to_sign, true), "steward_answered_the_order")
	if not await Autopilot.wait(2.5, gen):
		return false
	await Autopilot.snap("signal_room_signed")
	orders.close()
	return await Autopilot.wait(0.5, gen)
