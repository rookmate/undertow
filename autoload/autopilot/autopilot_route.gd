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
	"harbor": "res://autoload/autopilot/routes/harbor_route.gd",
	"spire": "res://autoload/autopilot/routes/spire_route.gd",
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
	var def: Dictionary = LevelCatalog.LEVELS.get(district, {})
	# Of the districts it needs some of, the first ones listed.
	var needed: Array = (def.get("after", []) as Array).duplicate()
	needed.append_array((def.get("after_any", []) as Array).slice(0, int(def.get("after_count", 0))))
	for before: Variant in needed:
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


## At the dock, after choosing this district on the map: anything that happens before setting off (Noor
## going ahead to the Ward). A campaign calls it; most districts have nothing.
func on_departure(_ark: ArkLevel, gen: int) -> void:
	await Autopilot.wait(0.0, gen)


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
## The boss a fight loop works against: the same one, or, after the Operator went down and the fight
## restarted (DECISIONS 177), the fresh one the level built in its place. Null if there's none.
static func boss_now(old: Variant, player: Operator) -> Boss:
	# Untyped: after a restart `old` is a freed object, which a typed argument refuses.
	if is_instance_valid(old):
		return old as Boss
	if player == null or player.level == null or not is_instance_valid(player.level.boss):
		return null
	return player.level.boss


## A hold: start its crank from `stand`, stay by it and fight off what the Steward sends out until it's
## done (checks "hold_started", "hold_brought_them_out"). Returns whether it's done.
func run_hold(level: Level, player: Operator, stand: Vector2i, gen: int) -> bool:
	if not await Autopilot.use_at(level, player, stand, gen):
		return false
	var hold: Hold = null
	for n: Node in level.world.get_children():
		if n is Hold and Iso.ground_distance((n as Hold).global_position, player.global_position) < 2.0:
			hold = n
	check(hold != null and hold.running, "hold_started")
	if hold == null:
		return false
	var crank := hold.global_position + Iso.ground_velocity(Iso.ground_dir_between(hold.global_position, player.global_position), 1.0)
	var spent := 0.0
	var frame := 0
	var photographed := false
	while not hold.done and spent < 150.0:
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		if not hold.brought_out().is_empty():
			pass_check("hold_brought_them_out")
			if not photographed:
				photographed = true
				await Autopilot.snap(id + "_hold")
		# Fight what's come within reach, but never far from the crank: it only runs while you're by it.
		var threat := Autopilot.nearest_threat(level, player, 3.0)
		if threat != null and Iso.ground_distance(threat.global_position, crank) < Hold.RADIUS + 1.0:
			Autopilot.fight(player, threat, frame)
		else:
			Autopilot.release_attacks()
			var at := player.global_position
			if Iso.ground_distance(at, crank) > 0.6:
				Autopilot.press_move(Autopilot.input_for_ground(Iso.ground_dir_between(at, crank)))
			else:
				Autopilot.press_move(Vector2.ZERO)
		spent += await Autopilot.physics_step()
	# Done: see off the ones it brought out before going on (they don't give up).
	var clearing := 0.0
	while hold.done and clearing < 40.0 and not hold.brought_out().is_empty():
		if Autopilot.stale(gen):
			Autopilot.release_all()
			return false
		frame += 1
		var left := hold.brought_out()
		left.sort_custom(func(a: Enemy, b: Enemy) -> bool: return Iso.ground_distance(a.global_position, player.global_position) < Iso.ground_distance(b.global_position, player.global_position))
		Autopilot.fight(player, left[0], frame)
		clearing += await Autopilot.physics_step()
	Autopilot.release_all()
	return hold.done


## Down a passage (`ladder_stand` beside its top), through the waypoints, back up by the ladder beside
## `up_stand`: muted, as everything down there is unindexed. `visit` runs at the far end of the outward
## leg. Checks "went_down", "dark_below", "climbed_back_up".
func descend(level: Level, player: Operator, ladder_stand: Vector2i, out: Array[Vector2i], visit: Callable, back: Array[Vector2i], up_stand: Vector2i, gen: int) -> bool:
	if Steward.voice_on:
		Autopilot.tap(&"voice_toggle")
		if not await Autopilot.wait(0.8, gen):
			return false
	if not await Autopilot.use_at(level, player, ladder_stand, gen):
		return false
	check(level.in_descent(), "went_down")
	if not await Autopilot.wait(1.0, gen):
		return false
	check(level.descent_dark != null and level.descent_dark.amount > 0.9 and player.carried_light_on(), "dark_below")
	await Autopilot.snap(id + "_descent")
	for cell: Vector2i in out:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return false
	if not await visit.call():
		return false
	for cell: Vector2i in back:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return false
	if not await Autopilot.use_at(level, player, up_stand, gen):
		return false
	if not await Autopilot.wait(0.6, gen):
		return false
	check(not level.in_descent(), "climbed_back_up")
	Autopilot.tap(&"voice_toggle")
	return await Autopilot.wait(0.8, gen)


## The district's boss is down (or already gone).
static func boss_down(player: Operator) -> bool:
	if player == null or player.level == null:
		return false
	var b: Boss = player.level.boss
	return not is_instance_valid(b) or not b.is_alive()


## Talks this district over with Noor and Teo on the Ark (the first time you talk to Noor after it),
## answering `side` ("noor", "teo" or "none", Conversations.SIDES) the way a player would; checks their
## trust moved by what that answer says, once, and that nothing more is waiting.
func talk_it_over(ark: ArkLevel, side: String, gen: int) -> bool:
	var r := GameState.run
	check(r.pending_conversation() == id, "conversation_waiting")
	if not await Autopilot.use_at(ark, ark.player, ark.grid.first("N") + Vector2i(1, 0), gen):
		return false
	var screen := ark.conversation_screen
	check(screen != null and screen.district == id, "conversation_offered")
	if screen == null:
		return false
	if not await Autopilot.wait(2.0, gen):
		return false
	await Autopilot.snap(id + "_conversation")
	# DECISIONS 137: siding with one is +2 for them and -1 for the other; saying nothing moves neither.
	var moves: Dictionary[String, Vector2i] = {"noor": Vector2i(2, -1), "teo": Vector2i(-1, 2), "none": Vector2i.ZERO}
	var noor := clampi(r.noor_trust + moves[side].x, Tunables.TRUST_MIN, Tunables.TRUST_MAX)
	var teo := clampi(r.teo_trust + moves[side].y, Tunables.TRUST_MIN, Tunables.TRUST_MAX)
	var buttons: Dictionary = screen.get("_choices")
	(buttons[side] as Button).grab_focus()
	Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(2.0, gen):
		return false
	await Autopilot.snap(id + "_conversation_answered")
	check(screen.answered == side and r.conversations_had.has(id) and r.noor_trust == noor and r.teo_trust == teo and r.pending_conversation() == "", "conversation_answered")
	Autopilot.tap(&"ui_cancel")
	return await Autopilot.wait(0.8, gen)


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
