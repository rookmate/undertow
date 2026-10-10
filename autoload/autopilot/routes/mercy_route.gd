extends AutopilotRoute
## Mercy General: up the corridor from the ambulance yard; the Defib Gauntlet off its crash cart in the
## resus bay; ward A's seal holds while the Steward listens and says why; muted, crank it open and wake
## someone in their bed; through ward B to the night nurses' station off the Lattice (the triage sheets,
## the night nurse at her desk); the Steward back, along the upper corridor to the theatre and the
## Surgeon (the Steward's way: off each line it lays, in close by the table in the mist, hit it while it
## sutures), then through the barrier to the records vault's Reliquary.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "path_three_tiles_ahead",
	"narration_heard", "enemy_killed",
]
const THROUGH: Array[String] = [
	"gauntlet_found", "seal_held", "seal_cranked", "woke_in_ward", "night_sheets_found",
	"night_nurse_woken", "sterilizer_misted", "surgeon_engaged", "surgeon_called_an_incision",
	"surgeon_sutured", "surgeon_beaten", "barriers_opened", "route_completed", "core_choice_shown",
	"mercy_cores_carried", "ark_reached", "clinic_restored",
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
	_watch_for_mist(level, gen)
	if not await Autopilot.wait(1.2, gen):
		return
	await Autopilot.snap("mercy_start")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	for cell: Vector2i in [Vector2i(7, 20), Vector2i(7, 15), Vector2i(7, 12)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	if not long_run:
		return
	if not await Autopilot.use_at(level, player, Vector2i(4, 12), gen):
		return
	check(GameState.run.weapons_owned.has(WeaponDefs.DEFIB), "gauntlet_found")
	await Autopilot.snap("mercy_resus_bay")
	# Ward A: the seal holds while the Steward listens, and it says why.
	var seal_a := _seal_at(level, Vector2i(9, 9))
	if not await Autopilot.use_at(level, player, Vector2i(8, 9), gen):
		return
	check(seal_a != null and seal_a.sealed and Sound.voice_line == "ward_sealed", "seal_held")
	await Autopilot.snap("mercy_seal_held")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.8, gen):
		return
	Autopilot.tap(&"interact")
	if not await Autopilot.wait(1.0, gen):
		return
	check(seal_a != null and not seal_a.sealed, "seal_cranked")
	await Autopilot.snap("mercy_seal_cranked")
	for cell: Vector2i in [Vector2i(10, 9)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(12, 9), gen):
		return
	check(GameState.run.survivor_ids.has("mercy_waiting_ward_a_window"), "woke_in_ward")
	await Autopilot.snap("mercy_ward_a")
	# Ward B, and through its far door to the night nurses' station.
	for cell: Vector2i in [Vector2i(10, 9), Vector2i(8, 9), Vector2i(8, 13)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(8, 14), gen):
		return
	for cell: Vector2i in [Vector2i(10, 14), Vector2i(14, 14), Vector2i(19, 15)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(20, 15), gen):
		return
	for cell: Vector2i in [Vector2i(22, 15)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(23, 15), gen):
		return
	check(GameState.run.found_core_ids.has("mercy_truth_night_sheets"), "night_sheets_found")
	await Autopilot.snap("mercy_night_station")
	if not await Autopilot.use_at(level, player, Vector2i(25, 16), gen):
		return
	check(GameState.run.survivor_ids.has("mercy_waiting_night_nurse"), "night_nurse_woken")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.6, gen):
		return
	# Back out, up the corridor to the theatre.
	for cell: Vector2i in [Vector2i(22, 15), Vector2i(20, 15), Vector2i(11, 14), Vector2i(8, 14), Vector2i(7, 7), Vector2i(10, 4), Vector2i(20, 4), Vector2i(28, 4), Vector2i(31, 5)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	var surgeon := level.boss as Surgeon
	if surgeon == null:
		return
	check(await Autopilot.until(func() -> bool: return surgeon.is_engaged, 3.0, gen), "surgeon_engaged")
	await Autopilot.snap("mercy_surgeon")
	if not await _fight_surgeon(player, surgeon, gen):
		return
	check(not surgeon.is_alive(), "surgeon_beaten")
	await Autopilot.snap("mercy_surgeon_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	for cell: Vector2i in [Vector2i(35, 12), Vector2i(35, 15), Vector2i(35, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	await Autopilot.snap("mercy_reliquary")
	Autopilot.tap(&"interact")


## The Steward's way with the Surgeon: step off each line it lays; in the mist, in close by the table;
## hit it while it sutures. Gives up after 100 s.
func _fight_surgeon(player: Operator, surgeon: Surgeon, gen: int) -> bool:
	var spent := 0.0
	var frame := 0
	while surgeon.is_alive() and spent < 100.0:
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Sound.voice_line == "surgeon_incision":
			pass_check("surgeon_called_an_incision")
		if surgeon.phase == Surgeon.Phase.SUTURE:
			pass_check("surgeon_sutured")
		var at := player.global_position
		var target := at
		if surgeon.is_vulnerable():
			Autopilot.fight(player, surgeon, frame)
			spent += await Autopilot.physics_step()
			continue
		Autopilot.release_attacks()
		var away := Iso.ground_dir_between(surgeon.global_position, at)
		if surgeon.phase == Surgeon.Phase.MARK or surgeon.phase == Surgeon.Phase.CUT:
			# Sideways off the line, a couple of tiles from the table.
			var rel := Iso.world_to_grid(at) - Iso.world_to_grid(surgeon.global_position)
			var d := surgeon.cut_dir
			var side := Vector2(-d.y, d.x) * (1.0 if rel.cross(d) <= 0.0 else -1.0)
			target = surgeon.global_position + Iso.ground_velocity(side, 2.6)
		elif surgeon.phase == Surgeon.Phase.MIST_WARN or surgeon.phase == Surgeon.Phase.MIST:
			target = surgeon.global_position + Iso.ground_velocity(away, 1.45)
		else:
			target = surgeon.global_position + Iso.ground_velocity(away, 2.4)
		if Iso.ground_distance(at, target) > 0.25:
			Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(at, target)))
		else:
			Autopilot.press_move(Vector2.ZERO)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	return true


func _seal_at(level: Level, cell: Vector2i) -> WardSeal:
	for n: Node in level.world.get_children():
		if n is WardSeal and (n as WardSeal).cell == cell:
			return n as WardSeal
	return null


## A Sterilizer lets its mist go at some point on the way.
func _watch_for_mist(level: Level, gen: int) -> void:
	while not Autopilot.stale(gen):
		for n: Node in level.fx_ground.get_children():
			if n is SterileCloud:
				pass_check("sterilizer_misted")
				await Autopilot.snap("mercy_mist")
				return
		await Autopilot.physics_step()


## Carry the night nurses' sheets and the Bed Core.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["mercy_truth_night_sheets", "mercy_power_beds"], gen):
		return
	check(offered.size() == 4 and r.levels_completed.has("mercy") and r.cores_truth() == truth + 1 and r.cores_power() == power + 1, "mercy_cores_carried")
	on_to_the_ark(screen)


func at_ark(_ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.buildings_restored.has("clinic"), "clinic_restored")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_mercy")
	return true
