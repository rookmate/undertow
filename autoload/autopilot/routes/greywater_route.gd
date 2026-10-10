extends AutopilotRoute
## Greywater: off the seawall through the kelp; up onto the causeway to wait out the first tide (the
## Steward calls the swell, and at high water its path keeps to high ground); north to the station apron;
## muted, the old pump room's brass plaque and the last shift's hand still at the valve; into the thick
## Marrow, where even listening the Steward draws no path, and the one waiting in it; over the bridge to
## the Reliquary on the east island.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "path_three_tiles_ahead",
	"narration_heard", "kelp_slowed",
]
const THROUGH: Array[String] = [
	"steward_called_the_tide", "path_kept_to_high_ground", "plaque_found", "woke_the_last_shift",
	"no_path_in_the_marrow", "woke_in_the_marrow", "enemy_killed", "route_completed", "core_choice_shown",
	"greywater_cores_carried", "ark_reached", "pumphouse_restored",
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
	# Up onto the causeway, and wait for the tide to turn.
	for cell: Vector2i in [Vector2i(14, 17), Vector2i(16, 17)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
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
	# Over the bridge to the east island and the Reliquary.
	for cell: Vector2i in [Vector2i(27, 6), Vector2i(32, 5), Vector2i(36, 6), Vector2i(38, 12), Vector2i(40, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	if level.living_enemies().size() < start_count:
		pass_check("enemy_killed")
	pass_check("route_completed")
	await Autopilot.snap("greywater_reliquary")
	Autopilot.tap(&"interact")


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


func at_ark(_ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.buildings_restored.has("pumphouse"), "pumphouse_restored")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_greywater")
	return true
