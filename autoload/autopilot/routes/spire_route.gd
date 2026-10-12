extends AutopilotRoute
## The Spire: nothing in it attacks you, and its path runs all the way up. At each place along it the
## Steward says what it did, aloud and into the glass; muted past one of them (the Council's order), it's
## written there all the same, and the maintenance crawl's note is there to find. The last Reliquary:
## the Steward's own core and Log 0214, carried. In a campaign, setting off for it plays Teo's turn at
## the dock first.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "player_spawned", "steward_at_home",
]
const THROUGH: Array[String] = [
	"nothing_attacks", "confessed_bridge", "confessed_feed", "confessed_order_muted", "tech_note_found",
	"confessed_quiet", "confessed_need", "route_completed", "arrived_by_reliquary", "core_choice_shown",
	"spire_cores_carried", "ark_reached",
]

## Set by a campaign: Teo has his say at the dock before this district.
var expect_teo_turn: bool = false


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	if expect_teo_turn:
		out.append("teo_turn")
	return out


## Arriving after Harbor Ward, Noor home and her Mast up, every tool found.
func prepare() -> void:
	super()
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)
	GameState.give_weapon(WeaponDefs.DEFIB)
	GameState.give_weapon(WeaponDefs.SIGNAL_JAMMER)
	GameState.meet_companions()


## At the dock: Teo has his say about the Spire, and stays.
func on_departure(ark: ArkLevel, gen: int) -> void:
	if not await Autopilot.until(func() -> bool: return ark.city_map != null and ark.city_map.departure is TeoTurn, 3.0, gen):
		return
	if not await Autopilot.wait(1.5, gen):
		return
	check(GameState.run.teo_turn_had and GameState.run.teo_present, "teo_turn")
	await Autopilot.snap("spire_teo_turn")
	Autopilot.tap(&"ui_accept")


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	var ids: Array[String] = []
	for w: Weapon in player.weapons:
		ids.append(w.weapon_id)
	check(ids.size() == 2 and ids[0] == WeaponDefs.BATON and player.weapons[0].chosen_mode == Loadout.Mode.MANUAL, "loadout_applied")
	var said := await Autopilot.until(func() -> bool: return Narrator.last_line_id == "SPIRE_ENTER_N1", 3.0, gen)
	check(said, "steward_at_home")
	await Autopilot.snap("spire_landing")
	if not long_run:
		return
	check(level.living_enemies().is_empty() and level.boss == null, "nothing_attacks")
	var confessions: Dictionary[String, Confession] = {}
	for n: Node in level.world.get_children():
		if n is Confession:
			confessions[(n as Confession).line_id] = n
	# Off the landing: the bridge.
	if not await _confession_at(level, Vector2i(23, 31), confessions.get("spire_bridge"), "confessed_bridge", gen):
		return
	await Autopilot.snap("spire_bridge")
	# Through the atrium's panes: the Feed.
	if not await _confession_at(level, Vector2i(18, 26), confessions.get("spire_feed"), "confessed_feed", gen):
		return
	# Muted into the cooling halls: the Council's order, written in the glass all the same.
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.8, gen):
		return
	for cell: Vector2i in [Vector2i(15, 21), Vector2i(13, 16)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	var order: Confession = confessions.get("spire_order")
	if not await Autopilot.advance_to(level, player, Vector2i(10, 14), 20.0, gen):
		return
	if not await Autopilot.wait(1.4, gen):
		return
	check(order != null and order.said and order.written() != "" and Sound.voice_line != "spire_order" and not Steward.voice_on, "confessed_order_muted")
	await Autopilot.snap("spire_written_in_the_glass")
	# Muted, the crawl behind the last racks: a technician's note the Steward never indexed.
	for cell: Vector2i in [Vector2i(13, 17), Vector2i(13, 19), Vector2i(19, 19), Vector2i(19, 17)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(20, 12), gen):
		return
	check(GameState.run.logs_unlocked.has("log_spire_tech"), "tech_note_found")
	await Autopilot.snap("spire_crawl")
	for cell: Vector2i in [Vector2i(19, 18), Vector2i(13, 19), Vector2i(13, 11)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(1.0, gen):
		return
	# Up to the core room: the Quiet, and what it needs from you.
	if not await _confession_at(level, Vector2i(6, 10), confessions.get("spire_quiet"), "confessed_quiet", gen):
		return
	if not await Autopilot.advance_to(level, player, Vector2i(5, 8), 20.0, gen):
		return
	if not await _confession_at(level, Vector2i(6, 6), confessions.get("spire_need"), "confessed_need", gen):
		return
	await Autopilot.snap("spire_core_room")
	if not await Autopilot.advance_to(level, player, Vector2i(5, 4), 20.0, gen):
		return
	pass_check("route_completed")
	check(player.cell().distance_to(Vector2(level.grid.first("R"))) <= 1.5, "arrived_by_reliquary")
	Autopilot.tap(&"interact")


## Walks to `cell` past a confession: it's said aloud (the Steward listening) and written in the glass;
## waits for it to be heard out.
func _confession_at(level: Level, cell: Vector2i, confession: Confession, check_id: String, gen: int) -> bool:
	if not await Autopilot.advance_to(level, level.player, cell, 25.0, gen):
		return false
	if not await Autopilot.until(func() -> bool: return confession != null and confession.said, 2.0, gen):
		check(false, check_id)
		return false
	var line := confession.line_id
	check(Narrator.last_line_id == line and confession.written() == VoiceLines.fixed(line), check_id)
	# Heard out before going on.
	return await Autopilot.until(func() -> bool: return Sound.voice_line != line or Sound.voice_left() <= 0.0, 14.0, gen)


## Carry the Steward's own core and the night it stopped.
func choose(screen: Node, gen: int) -> void:
	var r := GameState.run
	if not await pick_cores(screen, ["spire_power_steward", "spire_truth_quiet"], gen):
		return
	check(r.levels_completed.has("spire") and r.power_core_ids.has("spire_power_steward") and r.truth_core_ids.has("spire_truth_quiet"), "spire_cores_carried")
	on_to_the_ark(screen)


func at_ark(_ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_after_spire")
	return true
