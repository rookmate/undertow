extends AutopilotRoute
## Greywater: off the seawall through the kelp; up onto the causeway to wait out the first tide (the
## Steward calls the swell, and at high water its path keeps to high ground); north to the station apron;
## muted, the old pump room's brass plaque and the last shift's hand still at the valve; into the thick
## Marrow, where even listening the Steward draws no path, and the one waiting in it; over the bridge to
## the Lung (the Steward's way: out of the quarter that's filling, roll through the surge, hit it while
## it vents), then past the barrier to the Reliquary.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "path_three_tiles_ahead",
	"narration_heard", "kelp_slowed",
]
const THROUGH: Array[String] = [
	"steward_called_the_tide", "path_kept_to_high_ground", "plaque_found", "woke_the_last_shift",
	"no_path_in_the_marrow", "woke_in_the_marrow", "enemy_killed", "lung_engaged", "lung_called_a_flood",
	"lung_vented", "lung_beaten", "barriers_opened", "route_completed", "core_choice_shown",
	"greywater_cores_carried", "ark_reached", "pumphouse_restored", "pumphouse_standing",
]


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	return out


## Arriving after Act 1: the Riot Drone from the Tideworks, Noor and Teo met on the Ark.
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
	Controls.device = Controls.Device.PAD
	Narrator.line_spoken.connect(func(_id: String, _t: String) -> void:
		if not Autopilot.stale(gen):
			pass_check("narration_heard"), CONNECT_ONE_SHOT)
	var start_count := level.living_enemies().size()
	var tide := level.tide
	if not await Autopilot.wait(1.2, gen):
		return
	await Autopilot.snap("greywater_start")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	for cell: Vector2i in [Vector2i(5, 19), Vector2i(8, 15)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	check(level.footing(player.cell()) < 1.0, "kelp_slowed")
	await Autopilot.snap("greywater_kelp")
	if not long_run or tide == null:
		return
	# Past the Custodian scrubbing the low street, up onto the causeway, and wait for the tide to turn.
	for cell: Vector2i in [Vector2i(9, 12), Vector2i(14, 17), Vector2i(16, 17)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	if not await Autopilot.until(func() -> bool: return tide.phase == Tide.Phase.SWELL, 45.0, gen):
		return
	check(await Autopilot.until(func() -> bool: return Sound.voice_line == "tide_swell", 1.0, gen), "steward_called_the_tide")
	if not await Autopilot.until(func() -> bool: return tide.phase == Tide.Phase.HIGH, Tide.SWELL_SECONDS + 1.0, gen):
		return
	if not await Autopilot.wait(0.5, gen):
		return
	var shown := level.predicted_path.shown
	check(not shown.is_empty() and shown.all(func(c: Vector2i) -> bool: return not level.grid.floods(c)), "path_kept_to_high_ground")
	await Autopilot.snap("greywater_high_water")
	# North along the causeway to the apron, then the pump room (off the Lattice: muted).
	for cell: Vector2i in [Vector2i(16, 8), Vector2i(15, 5), Vector2i(11, 5)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.8, gen):
		return
	if not await Autopilot.advance_to(level, player, Vector2i(11, 4), 15.0, gen):
		return
	if not await Autopilot.use_at(level, player, Vector2i(12, 3), gen):
		return
	check(GameState.run.found_core_ids.has("greywater_truth_plaque"), "plaque_found")
	await Autopilot.snap("greywater_pump_room")
	if not await Autopilot.use_at(level, player, Vector2i(9, 3), gen):
		return
	check(GameState.run.survivor_ids.has("greywater_waiting_last_shift"), "woke_the_last_shift")
	# Into the thick Marrow: listening, the Steward is with you and still draws nothing.
	for cell: Vector2i in [Vector2i(11, 4), Vector2i(11, 5), Vector2i(24, 6), Vector2i(26, 8)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	Autopilot.tap(&"voice_toggle")
	var present := await Autopilot.until(func() -> bool: return Steward.assists().steward_present, 2.0, gen)
	if not await Autopilot.wait(0.6, gen):
		return
	check(present and level.grid.is_marrow(player.cell()) and level.predicted_path.shown.is_empty(), "no_path_in_the_marrow")
	await Autopilot.snap("greywater_marrow")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.6, gen):
		return
	if not await Autopilot.use_at(level, player, Vector2i(27, 10), gen):
		return
	check(GameState.run.survivor_ids.has("greywater_waiting_in_the_marrow"), "woke_in_the_marrow")
	Autopilot.tap(&"voice_toggle")
	# Over the bridge to the east island and the Lung.
	for cell: Vector2i in [Vector2i(27, 6), Vector2i(32, 5), Vector2i(35, 5)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	if level.living_enemies().size() < start_count:
		pass_check("enemy_killed")
	var lung := level.boss as Lung
	if lung == null:
		return
	check(await Autopilot.until(func() -> bool: return lung.is_engaged, 3.0, gen), "lung_engaged")
	await Autopilot.snap("greywater_lung")
	if not await _fight_lung(player, lung, gen):
		return
	check(not lung.is_alive(), "lung_beaten")
	await Autopilot.snap("greywater_lung_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	for cell: Vector2i in [Vector2i(38, 13), Vector2i(40, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	await Autopilot.snap("greywater_reliquary")
	Autopilot.tap(&"interact")


## The Steward's way with the Lung: out of the quarter it's filling, into the one across; roll through
## the surge's ring; hit it while it vents. Gives up after 110 s.
func _fight_lung(player: Operator, lung: Lung, gen: int) -> bool:
	var spent := 0.0
	var frame := 0
	while lung.is_alive() and spent < 110.0:
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Lung.LINES.values().has(Sound.voice_line):
			pass_check("lung_called_a_flood")
		if lung.phase == Lung.Phase.VENT:
			pass_check("lung_vented")
		var at := player.global_position
		if lung.is_vulnerable():
			Autopilot.fight(player, lung, frame)
			spent += await Autopilot.physics_step()
			continue
		Autopilot.release_attacks()
		var target := lung.global_position + Iso.ground_velocity(Iso.ground_dir_between(lung.global_position, at), 3.0)
		if lung.phase == Lung.Phase.FILL or lung.phase == Lung.Phase.FLOOD:
			target = lung.global_position + Iso.ground_velocity(-Lung.quarter_signs(lung.quarter).normalized(), 3.0)
		elif lung.phase == Lung.Phase.SURGE:
			var d := Iso.ground_distance(lung.global_position, at)
			if absf(d - lung.surge_radius()) < Lung.SURGE_WIDTH + 0.5 and player.dodge.can_start():
				# Roll in, through the ring.
				Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(at, lung.global_position)))
				Autopilot.tap(&"dodge")
				spent += await Autopilot.physics_step()
				continue
		if Iso.ground_distance(at, target) > 0.3:
			Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(at, target)))
		else:
			Autopilot.press_move(Vector2.ZERO)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	return true


## Carry the plaque and the Pump Core.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["greywater_truth_plaque", "greywater_power_pumps"], gen):
		return
	check(offered.size() == 4 and r.levels_completed.has("greywater") and r.cores_truth() == truth + 1 and r.cores_power() == power + 1, "greywater_cores_carried")
	on_to_the_ark(screen)


func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.buildings_restored.has("pumphouse"), "pumphouse_restored")
	check(facade_cells(ark, BuildingCell.Facade.PUMPHOUSE) > 0, "pumphouse_standing")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_greywater")
	if not await Autopilot.use_at(ark, ark.player, Vector2i(6, 11), gen):
		return false
	if not await Autopilot.wait(2.0, gen):
		return false
	await Autopilot.snap("ark_pumphouse")
	return true
