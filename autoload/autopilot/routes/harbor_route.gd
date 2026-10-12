extends AutopilotRoute
## Harbor Ward: on the city's ferry slip the Steward says it can't follow you in; off the slip its voice
## cuts out and there's nothing of it: no path, no map but your own scan, and muting changes nothing (the
## light, the map, what you can find); Noor's dashcam at her boat-house door and her Signal Jammer on
## the porch, the Wardfolk's radio log by
## the gate, the curfew patrol hunting you along Net Lane (fought off); through the border fence the Lattice starts again (the Steward back, its path); the depot's
## Reliquary. Both truths carried; on the Ark, Noor's still away. In a campaign, setting off for the Ward
## plays Noor going ahead at the dock first.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "steward_at_the_slip",
]
const THROUGH: Array[String] = [
	"the_voice_cuts_out", "no_lattice", "muting_changes_nothing", "dashcam_found", "jammer_found", "warden_hunted",
	"enemy_killed", "ward_radio_found",
	"the_lattice_again", "route_completed", "arrived_by_reliquary", "core_choice_shown", "harbor_cores_carried",
	"ark_reached", "noor_still_away",
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
	# East along the lane: the Wardfolk's radio log by the gate.
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
	for cell: Vector2i in [Vector2i(39, 16), Vector2i(40, 13)]:
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


## Home without her: Noor's still in the Ward.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.noor_away and ark.noor == null, "noor_still_away")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_harbor")
	return true
