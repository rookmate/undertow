extends AutopilotScenario
## The run as a player plays it, one run throughout: New Game, Kestrel Heights, the Ark, the Loop (an
## order signed in the Signal Room and kept from then on), the Ark; then save and return to the title and
## Continue; the Tideworks (an upgrade bought at the Workshop; Noor and Teo arrive), the Ark; Mercy
## General (the Defib Gauntlet, the sealed wards, the Surgeon), the Ark and its Clinic; Greywater (the
## tide, the Marrow), the Ark; the Vellum to the Archive; then Act 3: Noor goes ahead at the dock, and
## Harbor Ward; Teo has his say at the dock, and the Spire; then down into the Council Chamber on the
## Ark, the final choice (Rewrite if the run has earned it, otherwise Reboot), its epilogue and the
## credits, and the title after: the finished run kept, not continued. Each district's checks are
## tagged with it ("loop:route_completed").

const DISTRICTS: Array[String] = ["kestrel", "loop", "tideworks", "mercy", "greywater", "vellum", "harbor", "spire"]
## Signed in the Loop's Signal Room and kept to the end: it mustn't stop any later check (no slowed
## time, no path would), and its effect is plain to check (no aim assist).
const ORDER := Overrides.LET_ME_AIM

var routes: Array[AutopilotRoute] = []
## The district being played (index into routes).
var _at: int = 0
## Back on the title after the Loop's Ark: Continue rather than New Game.
var _left_for_title: bool = false
var _continued: bool = false
var _progress_before: Dictionary = {}
## Districts whose route didn't load (the run is refused).
var _missing: PackedStringArray = []
## The ending picked in the Council Chamber, and whether its epilogue has played (the next title is
## the one after it).
var _ending: String = ""
var _ended: bool = false


func _init() -> void:
	for id: String in DISTRICTS:
		var route := AutopilotRoute.for_district(id)
		if route == null:
			_missing.append(id)
			continue
		route.tag = id + ":"
		routes.append(route)
	if _missing.is_empty():
		routes[1].set(&"order_to_sign", ORDER)
		for route: AutopilotRoute in routes:
			if route.id == "harbor":
				route.set(&"expect_departure", true)
			if route.id == "spire":
				route.set(&"expect_teo_turn", true)


func problem() -> String:
	return "" if _missing.is_empty() else "no autopilot route loads for %s" % ", ".join(_missing)


func expected() -> Array[String]:
	var out := super()
	out.append_array(["campaign_saved_and_continued", "dressing_used", "campaign_done", "chamber_entered",
		"ending_chosen", "epilogue_played", "title_after_ending", "run_kept_not_continued"])
	for i: int in range(2, DISTRICTS.size()):
		out.append("order_carried_to_" + DISTRICTS[i])
	for route: AutopilotRoute in routes:
		route.long_run = true
		out.append_array(route.tagged_checks())
	return out


func on_title(title: Node, _gen: int) -> void:
	if _ended:
		Autopilot.pass_check("title_after_ending")
		Autopilot.check((title.get("_continue") as Button).disabled and SaveService.has_save() and GameState.run.ending == _ending, "run_kept_not_continued")
		Autopilot.pass_check("campaign_done")
		Autopilot.finish_now()
		return
	if not _left_for_title:
		Autopilot.tap(&"ui_accept")
		return
	var cont := title.get("_continue") as Button
	cont.grab_focus()
	Autopilot.tap(&"ui_accept")


func on_loadout(screen: Node, gen: int) -> void:
	routes[_at].loadout(screen, gen)


func on_level(level: Level, gen: int) -> void:
	var route := routes[_at]
	Autopilot.check(level.level_id == route.id, "campaign_in_order_%d" % _at)
	if _at >= 2:
		var a := Steward.assists()
		Autopilot.check(GameState.has_override(ORDER) and a.aim_overridden and a.aim_assist == 0.0, "order_carried_to_" + route.id)
	if GameState.run.dressings > 0:
		_dress_wounds(level, gen)
	route.drive(level, gen)


## With the Clinic's dressings in the pack, put one on when badly hurt, below half (the way a player
## would: not for a scratch).
func _dress_wounds(level: Level, gen: int) -> void:
	var p := level.player
	while not Autopilot.stale(gen) and is_instance_valid(p):
		if p.is_alive() and p.integrity.value < p.integrity.max_value * 0.5 and GameState.run.dressings > 0:
			var before := GameState.run.dressings
			var hurt := p.integrity.value
			Autopilot.tap(&"use_item")
			if await Autopilot.wait(0.3, gen) and GameState.run.dressings < before:
				print("[autopilot] dressing on at %d integrity, now %d" % [roundi(hurt), roundi(p.integrity.value)])
				Autopilot.pass_check("dressing_used")
		await Autopilot.wait(0.25, gen)


func on_core_choice(screen: Node, gen: int) -> void:
	routes[_at].choose(screen, gen)


func on_ark(ark: ArkLevel, gen: int) -> void:
	if _left_for_title and not _continued:
		_continued = true
		Autopilot.check(_progress(GameState.run) == _progress_before, "campaign_saved_and_continued")
		await _travel(ark, gen)
		return
	if not await routes[_at].at_ark(ark, gen):
		return
	if routes[_at].id == "loop":
		await _save_and_quit(ark, gen)
	elif _at == routes.size() - 1:
		await _the_end(ark, gen)
	else:
		await _travel(ark, gen)


## Every district done: down into the Council Chamber and the final choice, the way a player would.
func _the_end(ark: ArkLevel, gen: int) -> void:
	if not await Autopilot.use_at(ark, ark.player, Vector2i(14, 9), gen):
		return
	var choice := ark.final_choice
	Autopilot.check(choice != null, "chamber_entered")
	if choice == null:
		return
	if not await Autopilot.wait(1.5, gen):
		return
	await Autopilot.snap("campaign_council_chamber")
	_ending = Endings.REWRITE if choice.offered.has(Endings.REWRITE) else Endings.REBOOT
	print("[autopilot] the campaign's ending: %s" % _ending)
	choice.door(_ending).grab_focus()
	await Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(0.8, gen):
		return
	(choice.get("_yes") as Button).grab_focus()
	Autopilot.tap(&"ui_accept")


func on_epilogue(screen: Epilogue, gen: int) -> void:
	Autopilot.check(GameState.run.ending == _ending and screen.ending == _ending, "ending_chosen")
	Autopilot.pass_check("epilogue_played")
	_ended = true
	if await Autopilot.wait(2.0, gen):
		await Autopilot.snap("campaign_epilogue")


## Down to the dock, the map, the next district, the skiff.
func _travel(ark: ArkLevel, gen: int) -> void:
	if ark.city_map == null and not await Autopilot.open_city_map(ark, gen):
		return
	_at += 1
	var next := routes[_at].id
	ark.city_map.choose(next)
	(ark.city_map.get("_go") as Button).grab_focus()
	Autopilot.tap(&"ui_accept")
	await routes[_at].on_departure(ark, gen)


## The pause menu's "save and return to title", as a player would: what the run carries must come back.
func _save_and_quit(ark: ArkLevel, gen: int) -> void:
	Autopilot.tap(&"pause")
	if not await Autopilot.wait(0.6, gen):
		return
	var quit: Button = null
	for b: Node in ark.find_children("*", "Button", true, false):
		if (b as Button).text == "SAVE AND RETURN TO TITLE":
			quit = b
	if quit == null:
		return
	_progress_before = _progress(GameState.run)
	_left_for_title = true
	quit.grab_focus()
	Autopilot.tap(&"ui_accept")


## What a run has gained so far: everything a save must bring back.
static func _progress(run: RunState) -> Dictionary:
	return {
		"levels": run.levels_completed.duplicate(), "power": run.power_core_ids.duplicate(),
		"truth": run.truth_core_ids.duplicate(), "survivors": run.survivor_ids.duplicate(),
		"orders": run.active_overrides.duplicate(), "weapons": run.weapons_owned.duplicate(),
		"scrap": run.scrap, "upgrades": run.upgrades.duplicate(), "buildings": run.buildings_restored.duplicate(),
		"logs": run.logs_unlocked.duplicate(), "noor": run.noor_trust, "teo": run.teo_trust,
		"profile": run.playstyle_profile.to_dict(), "location": run.location,
	}
