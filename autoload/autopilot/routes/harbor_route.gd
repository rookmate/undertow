extends AutopilotRoute
## Harbor Ward: on the city's ferry slip the Steward says it can't follow you in; off the slip its voice
## cuts out and there's nothing of it: no path, no map but your own scan, and muting changes nothing (the
## light, the map, what you can find); Noor's dashcam at her boat-house door and her Signal Jammer on
## the porch, the Wardfolk's radio log by
## the gate, the curfew patrol hunting you along Net Lane (fought off); through the border fence the Lattice starts again (the Steward back, its path); the depot's
## Reliquary. Before it, the Warden-Prime (the Steward's way: the barrier at your back, roll aside from its
## charge, at it while it's dazed), and Noor down in the plaza: carried, the curfew patrol after you, to the
## Wardfolk's boat. Both truths carried; on the Ark, Noor's home and the Commons stands. In a campaign, setting off for the Ward
## plays Noor going ahead at the dock first.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "steward_at_the_slip",
]
const THROUGH: Array[String] = [
	"the_voice_cuts_out", "no_lattice", "muting_changes_nothing", "dashcam_found", "jammer_found", "warden_hunted",
	"enemy_killed", "wardfolk_in_the_ward", "ward_mast_dark", "ward_radio_found",
	"the_lattice_again", "warden_prime_engaged", "warden_prime_called_the_charge", "warden_prime_dazed",
	"warden_prime_beaten", "barriers_opened", "noor_found_down", "carried_noor", "curfew_patrol_came",
	"noor_in_the_boat", "route_completed", "arrived_by_reliquary", "core_choice_shown", "harbor_cores_carried",
	"ark_reached", "noor_home", "commons_restored", "commons_standing", "mast_built", "commons_people",
	"wardfolk_talk",
]

## Set by a campaign: Noor goes ahead at the dock before this district (a prepared run has her gone).
var expect_departure: bool = false


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	if expect_departure:
		out.append("noor_went_ahead")
	return out


## Arriving after Act 2 (Mercy General and the Vellum, so the Defib Gauntlet), Noor gone ahead.
func prepare() -> void:
	super()
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)
	GameState.give_weapon(WeaponDefs.DEFIB)
	GameState.meet_companions()
	GameState.noor_leaves_for_ward()
	# Two people woken in Act 2, to live in the Commons.
	GameState.add_survivor("mercy_waiting_night_nurse")
	GameState.add_survivor("vellum_waiting_doorway")


## At the dock: Noor's turn begins. She tells you about the bridge and goes ahead.
func on_departure(ark: ArkLevel, gen: int) -> void:
	if not await Autopilot.until(func() -> bool: return ark.city_map != null and ark.city_map.departure != null, 3.0, gen):
		return
	if not await Autopilot.wait(1.5, gen):
		return
	check(GameState.run.noor_away and not GameState.run.companion_here(RunState.WHO_NOOR), "noor_went_ahead")
	await Autopilot.snap("harbor_noor_goes_ahead")
	Autopilot.tap(&"ui_accept")


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	var ids: Array[String] = []
	for w: Weapon in player.weapons:
		ids.append(w.weapon_id)
	check(ids.size() == 2 and ids[0] == WeaponDefs.BATON and player.weapons[0].chosen_mode == Loadout.Mode.MANUAL, "loadout_applied")
	Controls.device = Controls.Device.PAD
	var said := await Autopilot.until(func() -> bool: return Narrator.last_line_id == "HARBOR_ENTER_N1", 3.0, gen)
	check(said and Steward.assists().steward_present, "steward_at_the_slip")
	await Autopilot.snap("harbor_slip")
	if not long_run:
		return
	_watch_wardens(level, gen)
	# Off the slip: its voice cuts out, mid-word if it was still talking.
	if not await Autopilot.advance_to(level, player, Vector2i(6, 32), 20.0, gen):
		return
	check(await Autopilot.until(func() -> bool: return not Steward.covered and Sound.voice_line == "", 2.0, gen), "the_voice_cuts_out")
	if not await Autopilot.wait(0.6, gen):
		return
	var map := level.hud.minimap
	check(level.predicted_path.shown.is_empty() and map.mode() == Assists.MapMode.HAND_SCAN and map.charted_label().contains("NO LATTICE"), "no_lattice")
	await Autopilot.snap("harbor_boardwalk")
	if not await _muting_changes_nothing(level, gen):
		return
	# Up the first pier to Net Lane, and Noor's door at its west end.
	for cell: Vector2i in [Vector2i(7, 30), Vector2i(7, 22), Vector2i(7, 19)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(5, 18), gen):
		return
	check(GameState.run.found_core_ids.has("harbor_truth_dashcam"), "dashcam_found")
	await Autopilot.snap("harbor_noors_door")
	if not await Autopilot.use_at(level, player, Vector2i(5, 21), gen):
		return
	check(GameState.run.weapons_owned.has(WeaponDefs.SIGNAL_JAMMER), "jammer_found")
	# East along the lane: a word with the Wardfolk by their doors, and their radio log by the gate under
	# the Ward's own mast, dark.
	if not await Autopilot.use_at(level, player, Vector2i(10, 19), gen):
		return
	var folk: ArkFigure = null
	for n: Node in level.world.get_children():
		if n is ArkFigure and (n as ArkFigure).who == ArkFigure.Who.WARDFOLK and (folk == null or (n as ArkFigure).spoken_line() != ""):
			folk = n
	check(folk != null and folk.spoken_line() != "" and folk.spoken_line() == CommonsPeople.wardfolk_line(folk.wardfolk_index, GameState.run, true), "wardfolk_in_the_ward")
	await Autopilot.snap("harbor_wardfolk")
	var masts := level.world.get_children().filter(func(n: Node) -> bool: return n is BuildingCell and (n as BuildingCell).roof_mast and (n as BuildingCell).mast_dark)
	check(masts.size() == 1, "ward_mast_dark")
	for cell: Vector2i in [Vector2i(12, 19), Vector2i(24, 19)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(30, 18), gen):
		return
	check(GameState.run.logs_unlocked.has("log_ward_radio"), "ward_radio_found")
	# Through the gate: the Lattice again.
	for cell: Vector2i in [Vector2i(33, 19), Vector2i(36, 19)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	var back := await Autopilot.until(func() -> bool: return Steward.covered and not level.predicted_path.shown.is_empty(), 2.0, gen)
	check(back and Steward.assists().steward_present, "the_lattice_again")
	await Autopilot.snap("harbor_border")
	var prime := level.boss as WardenPrime
	if prime == null:
		return
	check(await Autopilot.until(func() -> bool: return prime.is_engaged, 3.0, gen), "warden_prime_engaged")
	await Autopilot.snap("harbor_warden_prime")
	if not await _fight_prime(player, prime, gen):
		return
	check(not prime.is_alive(), "warden_prime_beaten")
	await Autopilot.snap("harbor_warden_prime_down")
	check(await Autopilot.until(Autopilot.barriers_open, 2.0, gen), "barriers_opened")
	# Noor, down in the plaza's far corner: carry her to the Wardfolk's boat.
	if not await Autopilot.use_at(level, player, Vector2i(43, 24), gen):
		return
	var choice := level.noor_choice
	check(choice != null, "noor_found_down")
	if choice == null:
		return
	await Autopilot.snap("harbor_noor_down")
	(choice.get("_carry") as Button).grab_focus()
	Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(0.6, gen):
		return
	check(player.carrying, "carried_noor")
	var patrol := level.living_enemies().filter(func(e: Enemy) -> bool: return e is Warden and (e as Warden).hunting).size()
	check(patrol >= 2, "curfew_patrol_came")
	await Autopilot.snap("harbor_carrying_noor")
	for cell: Vector2i in [Vector2i(43, 19), Vector2i(43, 15), Vector2i(43, 12)]:
		if not await Autopilot.advance_to(level, player, cell, 30.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(43, 11), gen):
		return
	check(not player.carrying and GameState.run.noor_present and not GameState.run.noor_away, "noor_in_the_boat")
	await Autopilot.snap("harbor_noor_in_the_boat")
	for cell: Vector2i in [Vector2i(40, 13)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(level.grid.first("R"))) <= 1.5, "arrived_by_reliquary")
	await Autopilot.snap("harbor_reliquary")
	Autopilot.tap(&"interact")


## The curfew patrol: a Warden that has you, hunting; one fought off.
func _watch_wardens(level: Level, gen: int) -> void:
	var start := level.living_enemies().size()
	var photographed := false
	while not Autopilot.stale(gen):
		for e: Enemy in level.living_enemies():
			if e is Warden and (e as Warden).hunting:
				pass_check("warden_hunted")
				if not photographed:
					photographed = true
					await Autopilot.snap("harbor_warden_hunting")
		if level.living_enemies().size() < start:
			pass_check("enemy_killed")
		await Autopilot.physics_step()


## The Steward's way with the Warden-Prime: wait for it with the barrier at your back; out of its light;
## as its charge comes, roll aside, and it runs on into the barrier, dazed; at it while it's dazed.
## Gives up after 120 s.
func _fight_prime(player: Operator, prime: WardenPrime, gen: int) -> bool:
	var anchor := Iso.cell_center(Vector2i(40, 16))
	var spent := 0.0
	var frame := 0
	while prime.is_alive() and spent < 120.0:
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if Sound.voice_line == "warden_prime_charge":
			pass_check("warden_prime_called_the_charge")
		if prime.phase == WardenPrime.Phase.DAZED:
			pass_check("warden_prime_dazed")
		var at := player.global_position
		if prime.is_vulnerable():
			Autopilot.fight(player, prime, frame)
			spent += await Autopilot.physics_step()
			continue
		Autopilot.release_attacks()
		var target := anchor
		match prime.phase:
			WardenPrime.Phase.SWEEP, WardenPrime.Phase.VOLLEY:
				if prime.in_light(at) or prime.phase == WardenPrime.Phase.VOLLEY:
					var side := Vector2(-prime.beam_dir.y, prime.beam_dir.x)
					target = at + Iso.ground_velocity(side, 1.5)
			WardenPrime.Phase.CHARGE_WARN, WardenPrime.Phase.CHARGE:
				var near := Iso.ground_distance(at, prime.global_position) < 3.0
				var late := prime.phase == WardenPrime.Phase.CHARGE or float(prime.get("_phase_time")) > WardenPrime.CHARGE_WARN_SECONDS * 0.85
				if late and (near or prime.phase == WardenPrime.Phase.CHARGE_WARN) and player.dodge.can_start():
					Autopilot.press_move(Autopilot.input_for_ground(Vector2(-prime.charge_dir.y, prime.charge_dir.x)))
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


## In the Ward the Steward has no say: mute it and the light, the map and what's there to find stay as
## they were. Then back on, as you were.
func _muting_changes_nothing(level: Level, gen: int) -> bool:
	var cache: TruthCache = null
	for n: Node in Autopilot.get_tree().get_nodes_in_group(&"interactables"):
		if n is TruthCache and level.is_ancestor_of(n):
			cache = n
	var grade := level.lighting.grade_amount()
	var label := level.hud.minimap.charted_label()
	var present := cache != null and cache.is_present()
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(1.6, gen):
		return false
	var same := not Steward.voice_on and absf(level.lighting.grade_amount() - grade) < 0.01 \
		and level.hud.minimap.charted_label() == label and cache != null and cache.is_present() == present and present
	await Autopilot.snap("harbor_muted")
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(1.6, gen):
		return false
	check(same and Steward.voice_on and absf(level.lighting.grade_amount() - grade) < 0.01, "muting_changes_nothing")
	return true


## Carry both truths: Noor's dashcam and the Council's order.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	var r := GameState.run
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["harbor_truth_dashcam", "harbor_truth_council_order"], gen):
		return
	check(offered.size() == 4 and r.levels_completed.has("harbor") and r.cores_truth() == truth + 2, "harbor_cores_carried")
	on_to_the_ark(screen)


## Home with her: Noor's back on the Ark, and the Commons stands, her Mast on its roof; its people carry
## their own lights, and the Wardfolk who came over talk about her.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(not GameState.run.noor_away and GameState.run.noor_present and ark.noor != null, "noor_home")
	check(GameState.run.buildings_restored.has("commons"), "commons_restored")
	check(facade_cells(ark, BuildingCell.Facade.COMMONS) > 0, "commons_standing")
	var masts := ark.world.get_children().filter(func(n: Node) -> bool: return n is BuildingCell and (n as BuildingCell).roof_mast)
	check(GameState.run.buildings_restored.has(GameState.MAST) and masts.size() == 1, "mast_built")
	var people := ark.world.get_children().filter(func(n: Node) -> bool: return n is ArkFigure and (n as ArkFigure).who == ArkFigure.Who.SURVIVOR)
	check(ark.wardfolk.size() == 2 and people.all(func(f: ArkFigure) -> bool: return f.lit), "commons_people")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_harbor")
	if ark.wardfolk.is_empty():
		return true
	# Over to the Commons: one of the Wardfolk has something to say about Noor.
	var w := ark.wardfolk[ark.wardfolk.size() - 1]
	if not await Autopilot.use_at(ark, ark.player, Vector2i(Iso.world_to_grid(w.position).floor()) + Vector2i(0, 1), gen):
		return false
	check(w.spoken_line() != "" and w.spoken_line() == CommonsPeople.wardfolk_line(w.wardfolk_index, GameState.run), "wardfolk_talk")
	await Autopilot.snap("ark_commons_people")
	return true
