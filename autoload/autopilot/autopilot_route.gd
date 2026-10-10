class_name AutopilotRoute
extends RefCounted
## How the autopilot plays one district, from its loadout to the Ark after it: the checks it makes, the
## way through, the cores it carries out of the Reliquary, and what it does with the Ark building the
## Reliquary restores. Scenarios string routes together (one for a prepared run, all of them for the
## campaign). In a campaign every check is tagged with its district ("loop:route_completed"), so one
## district can't pass another's.
##
## Adding a district means adding its route here (for_district) and in autoload/autopilot/routes/; a
## unit test fails while a district in LevelCatalog has none.

const ROUTES: Dictionary[String, String] = {
	"kestrel": "res://autoload/autopilot/routes/kestrel_route.gd",
	"loop": "res://autoload/autopilot/routes/loop_route.gd",
	"tideworks": "res://autoload/autopilot/routes/tideworks_route.gd",
	"mercy": "res://autoload/autopilot/routes/mercy_route.gd",
	"greywater": "res://autoload/autopilot/routes/greywater_route.gd",
	"vellum": "res://autoload/autopilot/routes/vellum_route.gd",
}

## The district this route plays.
var id: String = ""
## Prefix for this route's checks: "" alone, "<id>:" in a campaign.
var tag: String = ""
## Long runs play the whole district through; short ones only its opening.
var long_run: bool = true


## The route for a district, or null if there is none (or its script doesn't load).
static func for_district(district: String) -> AutopilotRoute:
	if not ROUTES.has(district):
		return null
	var script := load(ROUTES[district]) as GDScript
	if script == null or not script.can_instantiate():
		return null
	var route := script.new() as AutopilotRoute
	route.id = district
	return route


## This route's checks, untagged. Subclasses list theirs.
func checks() -> Array[String]:
	return []


func tagged_checks() -> Array[String]:
	var out: Array[String] = []
	for c: String in checks():
		out.append(tag + c)
	return out


func check(condition: bool, check_id: String) -> void:
	Autopilot.check(condition, tag + check_id)


func pass_check(check_id: String) -> void:
	Autopilot.pass_check(tag + check_id)


func expect(check_id: String) -> void:
	Autopilot.expect(tag + check_id)


## A prepared run: the run as it would be arriving here, without playing the districts before it. The
## districts before are done; subclasses add what those districts give (a found weapon).
func prepare() -> void:
	GameState.new_run()
	for before: String in _districts_before(id):
		GameState.complete_level(before)
	GameState.set_location("loadout:" + id)


static func _districts_before(district: String) -> Array[String]:
	var out: Array[String] = []
	for before: Variant in LevelCatalog.LEVELS.get(district, {}).get("after", []):
		for earlier: String in _districts_before(str(before)):
			if not out.has(earlier):
				out.append(earlier)
		if not out.has(str(before)):
			out.append(str(before))
	return out


## The loadout: with one weapon found it's the Baton, and off you go; with two, run the Baton by hand
## (the way a player clicking the slot's toggle would, if an earlier district hasn't left it manual
## already: the choice is the run's) and take both.
func loadout(screen: Node, gen: int) -> void:
	pass_check("loadout_shown")
	if not await Autopilot.wait(1.5, gen):
		return
	await Autopilot.snap(id + "_loadout")
	var depart := screen.get("_depart") as Button
	var picked: Array[String] = screen.get("picked")
	if Loadout.slots_for(GameState.run.weapons_owned) == 1:
		check(picked == [WeaponDefs.BATON], "loadout_one_weapon")
		depart.grab_focus()
		Autopilot.tap(&"ui_accept")
		return
	var modes: Dictionary = screen.get("modes")
	if not picked.is_empty() and modes.get(picked[0]) != Loadout.Mode.MANUAL:
		screen.call("_on_mode_toggled", 0)
	if not await Autopilot.wait(1.0, gen):
		return
	await Autopilot.snap(id + "_loadout_manual_baton")
	expect("loadout_applied")
	depart.grab_focus()
	Autopilot.tap(&"ui_accept")


## Plays the district from its start to opening its Reliquary.
func drive(_level: Level, _gen: int) -> void:
	pass


## The Reliquary's cards. Subclasses pick theirs and check what they carried, using pick_cores().
func choose(_screen: Node, _gen: int) -> void:
	pass


## The Ark after this district. Returns true once everything there is done (a campaign goes on from it).
func at_ark(_ark: ArkLevel, gen: int) -> bool:
	return await Autopilot.wait(0.0, gen)


# --- Helpers for routes ---------------------------------------------------------------------------
## Takes these cards and confirms. Returns false if the scene changed meanwhile.
func pick_cores(screen: Node, cores: Array[String], gen: int) -> bool:
	pass_check("core_choice_shown")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap(id + "_core_choice")
	for core: String in cores:
		screen.call("_toggle", core)
	if not await Autopilot.wait(0.8, gen):
		return false
	await Autopilot.snap(id + "_core_choice_picked")
	var confirm := screen.get("_confirm") as Button
	confirm.grab_focus()
	Autopilot.tap(&"ui_accept")
	return await Autopilot.wait(1.0, gen)


## After the cores are carried, the same button goes on to the Ark.
func on_to_the_ark(screen: Node) -> void:
	expect("ark_reached")
	var confirm := screen.get("_confirm") as Button
	confirm.grab_focus()
	Autopilot.tap(&"ui_accept")


## How many of the Ark's cells show a building's facade.
static func facade_cells(ark: ArkLevel, facade: BuildingCell.Facade) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == facade:
			n += 1
	return n
