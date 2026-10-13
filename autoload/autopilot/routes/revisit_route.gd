extends AutopilotRoute
## Back to Mercy General (DECISIONS 187): done once without going down to the morgue, its night sheets
## carried out. The Surgeon stays beaten and its barriers open; one of its truths carried, so its
## Custodians come two to a post, and every machine gives up twice the parts. The generator cranked
## (the hold) and down the morgue lift: the ledger found there goes straight to the Archive, no core
## choice. Home by the Reliquary, which doesn't open again; on the Ark, the ledger's in the Archive and
## the city map says Mercy's harder now.

const ROUTE: Array[String] = [
	"loadout_shown", "loadout_applied", "level_reached", "a_revisit", "boss_stays_beaten", "barriers_stay_open", "more_of_them", "pays_double",
	"hold_started", "hold_brought_them_out", "generator_cranked", "went_down", "dark_below",
	"filed_to_the_archive", "no_core_choice_waiting", "climbed_back_up", "reliquary_takes_you_home",
	"ark_reached", "ledger_in_the_archive", "map_says_harder",
]
const SHEETS := "mercy_truth_night_sheets"
const LEDGER := "mercy_truth_morgue_ledger"


func checks() -> Array[String]:
	return ROUTE.duplicate()


## Mercy done once: the night sheets and a power core carried, the rest left; the morgue never found.
func prepare() -> void:
	super()
	GameState.give_weapon(WeaponDefs.RIOT_DRONE)
	GameState.give_weapon(WeaponDefs.DEFIB)
	GameState.meet_companions()
	GameState.file_truth(SHEETS)
	GameState.take_core("mercy_power_beds", false)
	var left: Array[String] = ["mercy_power_dispatch", "mercy_truth_0417"]
	GameState.leave_cores(left)
	GameState.complete_level("mercy")
	GameState.restore_building(LevelCatalog.restores("mercy"))
	GameState.set_location("loadout:mercy")


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	var ids: Array[String] = []
	for w: Weapon in player.weapons:
		ids.append(w.weapon_id)
	check(ids.size() == 2 and ids[0] == WeaponDefs.BATON and player.weapons[0].chosen_mode == Loadout.Mode.MANUAL, "loadout_applied")
	Controls.device = Controls.Device.PAD
	check(level.revisit and level.hardening == 1, "a_revisit")
	check(level.boss == null, "boss_stays_beaten")
	check(Autopilot.barriers_open() and level.world.get_children().filter(func(n: Node) -> bool: return n is BossBarrier).is_empty(), "barriers_stay_open")
	var custodians := level.living_enemies().filter(func(e: Enemy) -> bool: return e is Custodian).size()
	check(custodians >= 2 * level.grid.cells_with("c").size(), "more_of_them")
	var doubled := level.living_enemies().all(func(e: Enemy) -> bool: return e.scrap_value >= Hardening.REVISIT_SCRAP and e.scrap_value % Hardening.REVISIT_SCRAP == 0)
	check(doubled and not level.living_enemies().is_empty(), "pays_double")
	if not await Autopilot.wait(1.0, gen):
		return
	await Autopilot.snap("revisit_start")
	for cell: Vector2i in [Vector2i(7, 20), Vector2i(11, 19)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await run_hold(level, player, Vector2i(12, 19), gen):
		return
	check(level.passage("mercy_morgue_down") != null and level.passage("mercy_morgue_down").can_interact(), "generator_cranked")
	var morgue := func() -> bool:
		for cell: Vector2i in [Vector2i(16, 38), Vector2i(26, 37)]:
			if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
				return false
		if not await Autopilot.use_at(level, player, Vector2i(29, 34), gen):
			return false
		var r := GameState.run
		check(r.truth_core_ids.has(LEDGER) and r.logs_unlocked.has(str(ContentDb.core(LEDGER).get("log", ""))), "filed_to_the_archive")
		check(r.found_core_ids.is_empty(), "no_core_choice_waiting")
		await Autopilot.snap("revisit_filed")
		return true
	if not await descend(level, player, Vector2i(9, 24), [Vector2i(7, 31), Vector2i(14, 31), Vector2i(18, 33), Vector2i(18, 36), Vector2i(12, 38)],
			morgue, [Vector2i(24, 37), Vector2i(18, 35), Vector2i(18, 31), Vector2i(8, 30)], Vector2i(5, 30), gen):
		return
	# Up the corridor and through the theatre, its barrier open, to the Reliquary: the way home.
	for cell: Vector2i in [Vector2i(8, 23), Vector2i(7, 15), Vector2i(7, 7), Vector2i(10, 4), Vector2i(20, 4), Vector2i(28, 4), Vector2i(33, 8), Vector2i(35, 12), Vector2i(35, 15)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	var reliquary: Reliquary = null
	for n: Node in level.world.get_children():
		if n is Reliquary:
			reliquary = n
	check(reliquary != null and reliquary.prompt_verb() == "BACK TO THE ARK", "reliquary_takes_you_home")
	await Autopilot.snap("revisit_reliquary")
	if not await Autopilot.use_at(level, player, Vector2i(35, 16), gen):
		return


func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(GameState.run.logs_unlocked.has(str(ContentDb.core(LEDGER).get("log", ""))) and GameState.run.truth_core_ids.has(LEDGER), "ledger_in_the_archive")
	if not await Autopilot.wait(1.0, gen):
		return false
	if not await Autopilot.open_city_map(ark, gen):
		return false
	var map := ark.city_map
	if map == null:
		return false
	map.choose("mercy")
	var detail := (map.get("_detail") as Label).text
	check(detail.contains(Hardening.describe(2)) and map.chosen == "mercy", "map_says_harder")
	await Autopilot.snap("revisit_city_map")
	Autopilot.finish_now()
	return true
