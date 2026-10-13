extends TestCase
## Revisits (DECISIONS 175, 176, 187): back in a district you've done, its boss stays beaten and its
## barriers open; its machines harden by the truths you've carried out of it, and only those; they give
## up twice the parts; a truth found there goes straight to the Archive; what a Reliquary offered and you
## left is gone; the Reliquary is the way home; the city map takes you back anywhere but the Spire.

const SHEETS := "mercy_truth_night_sheets"
const LEDGER := "mercy_truth_morgue_ledger"

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks"]:
		GameState.complete_level(district)
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _open_mercy() -> void:
	if level != null:
		level.queue_free()
		await wait_frames(2)
	level = (load("res://game/level/mercy_general.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


## Mercy done, with `truths` of its truths carried out.
func _done_with(truths: Array[String]) -> void:
	for id: String in truths:
		GameState.file_truth(id)
	GameState.complete_level("mercy")


func _custodians() -> Array[Enemy]:
	return level.living_enemies().filter(func(e: Enemy) -> bool: return e is Custodian)


func _cache(core_id: String) -> TruthCache:
	for n: Node in level.world.get_children():
		if n is TruthCache and (n as TruthCache).core_id == core_id:
			return n
	return null


func test_a_districts_truths_are_its_reliquarys_and_its_maps() -> void:
	var truths := LevelCatalog.truths_of("mercy")
	for id: String in ["mercy_truth_0417", SHEETS, LEDGER]:
		check(truths.has(id), "Mercy holds %s" % id)
	for id: String in truths:
		check(ContentDb.is_truth(id), "%s is a truth" % id)
	check_false(truths.has("vellum_truth_0522"), "not another district's")


func test_hardening_counts_only_that_districts_truths() -> void:
	for id: String in ["vellum_truth_0522", "vellum_truth_vashti_office", "loop_truth_long_night"]:
		GameState.take_core(id, true)
	check_eq(Hardening.step(GameState.run, "mercy"), 0, "the run's truths from elsewhere don't count")
	var want := 0
	for id: String in ["mercy_truth_0417", SHEETS, LEDGER]:
		GameState.take_core(id, true)
		want += 1
		check_eq(Hardening.step(GameState.run, "mercy"), want, "one step for each of its truths carried out")
	check(Hardening.step(GameState.run, "mercy") <= Hardening.ELITE_FROM, "and no further than the elites")


func test_a_first_visit_is_as_built() -> void:
	GameState.file_truth(SHEETS)
	await _open_mercy()
	check_false(level.revisit, "not done yet: a first visit")
	check_eq(level.hardening, 0)
	check(level.boss != null, "its boss is there to beat")
	for e: Enemy in level.living_enemies():
		check_eq(e.windup_scale, 1.0)
		check_false(e.elite)


func test_back_in_a_district_its_boss_stays_beaten_and_it_pays_double() -> void:
	await _open_mercy()
	var first := _custodians().size()
	var scrap: Dictionary[String, int] = {}
	for e: Enemy in level.living_enemies():
		scrap[e.get_class() + (e.get_script() as Script).resource_path] = e.scrap_value
	var sheets: Array[String] = [SHEETS]
	_done_with(sheets)
	await _open_mercy()
	check(level.revisit, "a revisit")
	check_eq(level.hardening, 1, "one of its truths carried out")
	check(level.boss == null, "the Surgeon stays beaten")
	check(level.world.get_children().filter(func(n: Node) -> bool: return n is BossBarrier).is_empty(), "its barriers stay open")
	check(_custodians().size() > first, "more Custodians than the first time (%d, from %d)" % [_custodians().size(), first])
	check(_custodians().size() >= 2 * level.grid.cells_with("c").size(), "one more beside each one placed")
	for e: Enemy in level.living_enemies():
		var key := e.get_class() + (e.get_script() as Script).resource_path
		if scrap.has(key):
			check_eq(e.scrap_value, scrap[key] * Hardening.REVISIT_SCRAP, "%s gives up twice the parts" % key.get_file())
		check_eq(e.windup_scale, 1.0, "no quicker at one truth")


func test_two_truths_quicker_three_elite() -> void:
	var two: Array[String] = [SHEETS, "mercy_truth_0417"]
	_done_with(two)
	await _open_mercy()
	check_eq(level.hardening, 2)
	var c := _custodians()[0]
	check_eq(c.windup_seconds(), Custodian.WINDUP * Hardening.WINDUP_SCALE, "a fifth quicker to strike")
	check(c.windup_seconds() >= 0.4, "still long enough to read")
	check_false(c.elite, "not elite yet")
	GameState.file_truth(LEDGER)
	await _open_mercy()
	check_eq(level.hardening, 3)
	for e: Enemy in level.living_enemies():
		check(e.elite and e.get_node_or_null("EliteMark") != null, "%s elite, and marked" % e.get_class())
	var elite := _custodians()[0]
	check_eq(elite.integrity.max_value, Custodian.MAX_INTEGRITY * Hardening.ELITE_INTEGRITY)
	check_eq(elite.integrity.value, elite.integrity.max_value, "at full strength")


func test_a_revisits_truth_goes_straight_to_the_archive() -> void:
	var sheets: Array[String] = [SHEETS]
	_done_with(sheets)
	await _open_mercy()
	Steward.set_voice(false)
	await wait_frames(2)
	check(_cache(SHEETS).taken, "what you carried out isn't there again")
	var ledger := _cache(LEDGER)
	check(ledger != null and ledger.can_interact(), "the ledger, never found, is")
	ledger.interact(level.player)
	var r := GameState.run
	check(r.truth_core_ids.has(LEDGER), "carried")
	check(r.logs_unlocked.has(str(ContentDb.core(LEDGER).get("log", ""))), "its log filed in the Archive")
	check(r.found_core_ids.is_empty(), "nothing waiting for a core choice")
	check_eq(ledger.spoken_line(), "FILED TO THE ARCHIVE")
	await wait_seconds(TruthCache.FILED_SECONDS + 0.2)
	check_eq(ledger.spoken_line(), "", "said for a moment")


func test_what_you_left_at_the_reliquary_is_gone() -> void:
	var offered := CoreChoice.offer("mercy", GameState.run)
	GameState.find_core(SHEETS)
	offered = CoreChoice.offer("mercy", GameState.run)
	var picks: Array[String] = ["mercy_power_beds", "mercy_power_dispatch"]
	check_eq(CoreChoice.apply("mercy", offered, picks), "")
	var r := GameState.run
	for id: String in ["mercy_truth_0417", SHEETS]:
		check(r.cores_left.has(id), "%s left behind" % id)
	for id: String in picks:
		check_false(r.cores_left.has(id), "%s carried" % id)
	var back := RunState.from_dict(r.to_dict())
	check_eq(back.cores_left, r.cores_left, "and that's saved")
	await _open_mercy()
	Steward.set_voice(false)
	await wait_frames(2)
	check(_cache(SHEETS).taken and not _cache(SHEETS).can_interact(), "the sheets you left aren't there to take")


func test_the_reliquary_is_the_way_home() -> void:
	var sheets: Array[String] = [SHEETS]
	_done_with(sheets)
	await _open_mercy()
	var reliquary: Reliquary = null
	for n: Node in level.world.get_children():
		if n is Reliquary:
			reliquary = n
	check(reliquary != null and reliquary.can_interact(), "you can use it")
	check_eq(reliquary.prompt_verb(), "BACK TO THE ARK", "it doesn't open again: it takes you home")


func test_the_city_map_goes_back_anywhere_but_the_spire() -> void:
	for id: String in ["mercy", "vellum", "greywater", "harbor", "spire"]:
		GameState.complete_level(id)
	for id: String in ["kestrel", "loop", "tideworks", "mercy", "vellum", "greywater", "harbor"]:
		check(LevelCatalog.can_revisit(GameState.run, id), "%s can be gone back to" % id)
	check_false(LevelCatalog.can_revisit(GameState.run, "spire"), "the Spire is where the run ends")
	GameState.new_run()
	check_false(LevelCatalog.can_revisit(GameState.run, "kestrel"), "not before it's done")
	var map := CityMap.new()
	add_child(map)
	await wait_frames(2)
	map.choose("kestrel")
	check_eq(map.chosen, "kestrel", "the first district, open")
	GameState.complete_level("kestrel")
	map.choose("kestrel")
	check_eq(map.chosen, "kestrel", "and done, still")
	check((map.get("_detail") as Label).text.contains("back"), "the skiff takes you back")
	check(map.turn_before("kestrel") == null)
	map.queue_free()


func test_going_back_to_the_ward_plays_no_departure() -> void:
	GameState.meet_companions()
	var map := CityMap.new()
	add_child(map)
	await wait_frames(2)
	var first := map.turn_before("harbor")
	check(first != null, "the first time, Noor goes ahead")
	if first != null:
		first.free()
	GameState.complete_level("harbor")
	check(map.turn_before("harbor") == null, "going back is only going back")
	map.queue_free()


## Every district done: the Loop map doesn't say the skiff isn't ready; it offers the way back.
func test_with_everything_done_the_skiff_still_goes_back() -> void:
	for id: String in LevelCatalog.LEVELS:
		GameState.complete_level(id)
	var map := CityMap.new()
	add_child(map)
	await wait_frames(2)
	check_eq(map.chosen, "kestrel", "the first district you can go back to")
	check_false((map.get("_go") as Button).disabled, "the skiff can take you")
	check_false((map.get("_detail") as Label).text.contains("ISN'T READY"))
	Modals.pop(map)
	map.queue_free()


## Two of its truths carried out: a Custodian strikes when its shorter telegraph runs out, not when the
## old one would have.
func test_a_quicker_windup_strikes_sooner() -> void:
	var between := (Custodian.WINDUP + Custodian.WINDUP * Hardening.WINDUP_SCALE) * 0.5
	await _open_mercy()
	var c := _custodians()[0]
	c.call(&"_enter", Enemy.State.WINDUP)
	await wait_seconds(between)
	check_eq(c.state, Enemy.State.WINDUP, "as built, still winding up")
	var two: Array[String] = [SHEETS, "mercy_truth_0417"]
	_done_with(two)
	await _open_mercy()
	c = _custodians()[0]
	c.call(&"_enter", Enemy.State.WINDUP)
	await wait_seconds(between)
	check(c.state != Enemy.State.WINDUP, "quicker: it's struck already")


## Three of its truths carried out: an elite Warden is faster hunting you and walking its beat.
func test_an_elite_warden_keeps_its_speed() -> void:
	var three: Array[String] = [SHEETS, "mercy_truth_0417", LEDGER]
	_done_with(three)
	await _open_mercy()
	# You're well away (it can't see you or reach you); it hunts toward where it last saw you.
	level.player.position = Iso.cell_center(level.grid.first("R"))
	var w := level.add_enemy(Warden.new(), level.grid.start_cell() + Vector2i(1, 0), Warden.MAX_INTEGRITY) as Warden
	check(w.elite, "elite")
	w.hunting = true
	w.last_seen = Iso.cell_center(level.grid.start_cell() + Vector2i(1, -3))
	await wait_physics_frames(5)
	check_near(w.speed_tiles, Warden.HUNT_SPEED * Hardening.ELITE_SPEED, 0.001, "hunting")
	w.hunting = false
	await wait_physics_frames(5)
	check_near(w.speed_tiles, Warden.PATROL_SPEED * Hardening.ELITE_SPEED, 0.001, "on its beat")
