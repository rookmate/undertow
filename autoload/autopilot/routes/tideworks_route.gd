extends AutopilotRoute
## The Tideworks: the side yard first (the Riot Drone off the depot's rack; muted, the union hall's
## strike ledger), then on the quay the container wound clear by hand while the Steward's Custodians come
## (the hold) and down the freighter's hatch into its hold (the descent: the one waiting there, the night
## shift's hand count), then the quay's Salvagers, the pier, the last Crane (the Steward's way), and the
## Reliquary on the pier head. Then the Ark's Workshop: buy an upgrade with the scrap.

const ROUTE: Array[String] = [
	"loadout_shown", "loadout_one_weapon", "level_reached", "player_spawned", "riot_drone_found",
	"strike_records_found", "hold_started", "hold_brought_them_out", "container_wound_clear", "went_down",
	"dark_below", "woke_in_the_hold", "hand_count_found", "climbed_back_up", "enemy_killed", "crane_engaged", "crane_called_a_drop", "crane_rested",
	"crane_beaten", "barriers_opened", "route_completed", "core_choice_shown", "tideworks_cores_carried",
	"ark_reached", "noor_and_teo_arrive", "workshop_restored", "workshop_standing", "upgrade_bought",
	"noor_and_teo_stay",
]


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
	await Autopilot.snap("tideworks_start")
	for cell: Vector2i in [Vector2i(8, 11), Vector2i(10, 9), Vector2i(10, 7), Vector2i(11, 6), Vector2i(11, 5)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(11, 4), gen):
		return
	check(GameState.run.weapons_owned.has(WeaponDefs.RIOT_DRONE) and player.weapons.size() == 2, "riot_drone_found")
	await Autopilot.snap("tideworks_depot")
	Autopilot.tap(&"voice_toggle")
	for cell: Vector2i in [Vector2i(11, 6), Vector2i(9, 7), Vector2i(8, 5), Vector2i(7, 4), Vector2i(5, 4)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(3, 4), gen):
		return
	check(GameState.run.found_core_ids.has("tideworks_truth_strike_records"), "strike_records_found")
	await Autopilot.snap("tideworks_union_hall")
	Autopilot.tap(&"voice_toggle")
	for cell: Vector2i in [Vector2i(7, 4), Vector2i(8, 6), Vector2i(10, 8), Vector2i(10, 11)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	# The quay's hand winch (the hold) winds the container clear of the freighter's hatch.
	if not await run_hold(level, player, Vector2i(10, 12), gen):
		return
	check(level.passage("tideworks_hold_down") != null and level.passage("tideworks_hold_down").can_interact(), "container_wound_clear")
	var hold := func() -> bool:
		if not await Autopilot.use_at(level, player, Vector2i(12, 33), gen):
			return false
		check(GameState.run.survivor_ids.has("tideworks_waiting_in_the_hold"), "woke_in_the_hold")
		for cell: Vector2i in [Vector2i(20, 33), Vector2i(27, 32)]:
			if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
				return false
		if not await Autopilot.use_at(level, player, Vector2i(30, 30), gen):
			return false
		check(GameState.run.found_core_ids.has("tideworks_truth_hand_count"), "hand_count_found")
		return true
	if not await descend(level, player, Vector2i(13, 13), [Vector2i(7, 27), Vector2i(14, 26), Vector2i(14, 30), Vector2i(14, 33)],
			hold, [Vector2i(27, 32), Vector2i(20, 33), Vector2i(14, 30), Vector2i(14, 26), Vector2i(7, 26)], Vector2i(6, 26), gen):
		return
	for cell: Vector2i in [Vector2i(12, 10), Vector2i(19, 11), Vector2i(26, 11), Vector2i(30, 11), Vector2i(33, 11), Vector2i(36, 11)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if level.living_enemies().filter(func(e: Enemy) -> bool: return e.is_threat).size() < start_count:
		pass_check("enemy_killed")
	var crane := level.boss as Crane
	if crane == null:
		return
	check(await Autopilot.until(func() -> bool: return crane.is_engaged, 3.0, gen), "crane_engaged")
	await Autopilot.snap("tideworks_crane")
	if not await _fight_crane(player, crane, gen):
		return
	check(boss_down(player), "crane_beaten")
	await Autopilot.snap("tideworks_crane_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	for cell: Vector2i in [Vector2i(39, 7), Vector2i(39, 5), Vector2i(40, 3)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	Autopilot.tap(&"interact")


## The Steward's way with the Crane: out from under the drop, in by the tower for the swing, hit it while
## its cab is down. Gives up after 100 s.
func _fight_crane(player: Operator, crane: Crane, gen: int) -> bool:
	var spent := 0.0
	var frame := 0
	while spent < 100.0:
		# A fight restarted after the Operator went down: the fresh boss.
		crane = boss_now(crane, player) as Crane
		if crane == null or not crane.is_alive():
			break
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Sound.voice_line == "crane_drop":
			pass_check("crane_called_a_drop")
		if crane.phase == Crane.Phase.REST:
			pass_check("crane_rested")
		var at := player.global_position
		var to_tower := Iso.ground_dir_between(at, crane.global_position)
		var d := Iso.ground_distance(at, crane.global_position)
		if crane.is_vulnerable():
			Autopilot.fight(player, crane, frame)
		elif crane.phase == Crane.Phase.SWING_WARN or crane.phase == Crane.Phase.SWING:
			Autopilot.release_attacks()
			Autopilot.press_move(Autopilot.input_for_ground(to_tower) if d > 1.6 else Vector2.ZERO)
		elif crane.phase == Crane.Phase.AIM or crane.phase == Crane.Phase.DROP:
			Autopilot.release_attacks()
			var mark: Vector2 = crane.get("_mark")
			# It aims at you until most of the way through; after that the mark's fixed.
			var fixed: bool = crane.phase == Crane.Phase.DROP or float(crane.get("_phase_time")) >= float(crane.get("_aim_for")) * 0.7
			var under := Iso.ground_distance(at, mark) < Crane.DROP_RADIUS + 0.6
			if under and fixed and player.dodge.can_start():
				# Roll out from under the load.
				var away := Iso.ground_dir_between(mark, at)
				Autopilot.press_move(Autopilot.input_for_ground(away if away != Vector2.ZERO else Vector2(1, 0)))
				Autopilot.tap(&"dodge")
			elif not fixed:
				# Keep moving round the tower while it aims, so the mark trails behind you.
				var round_it := Vector2(-to_tower.y, to_tower.x)
				var want := round_it if d > 2.4 and d < 3.8 else (to_tower if d >= 3.8 else -to_tower)
				Autopilot.press_move(Autopilot.input_for_ground(want))
			elif under:
				Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(mark, at)))
			else:
				Autopilot.press_move(Vector2.ZERO)
		else:
			Autopilot.release_attacks()
			Autopilot.press_move(Autopilot.input_for_ground(to_tower) if d > 3.0 else Vector2.ZERO)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	return true


## Carry the strike ledger and the Crane core.
func choose(screen: Node, gen: int) -> void:
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["tideworks_truth_strike_records", "tideworks_power_cranes"], gen):
		return
	check(r.levels_completed.has("tideworks") and r.cores_truth() == truth + 1 and r.cores_power() == power + 1, "tideworks_cores_carried")
	on_to_the_ark(screen)


## Act 1 done: Noor and Teo arrive off the dock. The Workshop stands: spend scrap on the Riot Drone's
## tuning.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(ark.arriving and ark.noor != null and ark.teo != null, "noor_and_teo_arrive")
	check(GameState.run.buildings_restored.has("workshop"), "workshop_restored")
	check(facade_cells(ark, BuildingCell.Facade.WORKSHOP) > 0, "workshop_standing")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_tideworks")
	if not await Autopilot.use_at(ark, ark.player, Vector2i(6, 9), gen):
		return false
	var shop := ark.workshop_screen
	if shop == null:
		return false
	await Autopilot.snap("workshop")
	var scrap := GameState.run.scrap
	var level := Upgrades.level(GameState.run, WeaponDefs.RIOT_DRONE, "tuned")
	shop.buy(WeaponDefs.RIOT_DRONE, "tuned")
	check(GameState.run.scrap == scrap - Upgrades.COSTS[level] and Upgrades.level(GameState.run, WeaponDefs.RIOT_DRONE, "tuned") == level + 1, "upgrade_bought")
	if not await Autopilot.wait(2.5, gen):
		return false
	await Autopilot.snap("workshop_bought")
	shop.close()
	check(await Autopilot.until(func() -> bool: return not ark.arriving, 30.0, gen) and GameState.run.companions_met, "noor_and_teo_stay")
	await Autopilot.snap("ark_noor_and_teo")
	return await Autopilot.wait(0.5, gen)
