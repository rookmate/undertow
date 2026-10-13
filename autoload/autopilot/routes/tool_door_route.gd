extends AutopilotRoute
## Back to Kestrel Heights with the Signal Jammer (DECISIONS 187, 188): done once, its two truths
## carried out, so it's two steps harder. The Jammer in the loadout; the Steward lock on the gate at the
## foot of the funicular stop jammed open, and muted, down the gravel path to the gatehouse: the
## gatekeeper's list goes straight to the Archive.

const ROUTE: Array[String] = [
	"loadout_shown", "jammer_in_the_loadout", "level_reached", "a_revisit", "lock_jammed",
	"steward_had_its_word", "gate_list_filed",
]
const GATE_LIST := "kestrel_truth_gate_list"


func checks() -> Array[String]:
	return ROUTE.duplicate()


## Kestrel done, both its truths carried; the Ward done too, so the Jammer's on the Ark.
func prepare() -> void:
	super()
	for district: String in ["loop", "tideworks", "mercy", "vellum", "harbor"]:
		GameState.complete_level(district)
	for core: String in ["kestrel_truth_evacuation", "kestrel_truth_childs_map"]:
		GameState.file_truth(core)
	GameState.complete_level("kestrel")
	for w: String in [WeaponDefs.RIOT_DRONE, WeaponDefs.DEFIB, WeaponDefs.SIGNAL_JAMMER]:
		GameState.give_weapon(w)
	GameState.meet_companions()
	GameState.set_location("loadout:kestrel")


func loadout(screen: Node, gen: int) -> void:
	pass_check("loadout_shown")
	if not await Autopilot.wait(1.0, gen):
		return
	var picked: Array[String] = screen.get("picked")
	if not picked.has(WeaponDefs.SIGNAL_JAMMER):
		screen.call("_on_card_pressed", WeaponDefs.SIGNAL_JAMMER)
	picked = screen.get("picked")
	check(picked.has(WeaponDefs.SIGNAL_JAMMER), "jammer_in_the_loadout")
	await Autopilot.snap("tool_door_loadout")
	(screen.get("_depart") as Button).grab_focus()
	Autopilot.tap(&"ui_accept")


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	Controls.device = Controls.Device.PAD
	check(level.revisit and level.hardening == 2, "a_revisit")
	if not await Autopilot.wait(1.0, gen):
		return
	if not await Autopilot.advance_to(level, player, Vector2i(6, 24), 25.0, gen):
		return
	var door: ToolDoor = null
	for n: Node in level.world.get_children():
		if n is ToolDoor:
			door = n
	await Autopilot.snap("tool_door_shut")
	var heard: Array[String] = []
	Narrator.line_spoken.connect(func(line_id: String, _text: String) -> void: heard.append(line_id))
	if not await Autopilot.use_at(level, player, Vector2i(6, 25), gen):
		return
	check(door != null and door.is_open(), "lock_jammed")
	check(heard.has("kestrel_gate_jammed"), "steward_had_its_word")
	await Autopilot.snap("tool_door_open")
	# Muted: what's behind it is off the Lattice.
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(0.8, gen):
		return
	for cell: Vector2i in [Vector2i(6, 27), Vector2i(6, 29), Vector2i(7, 31)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(8, 31), gen):
		return
	var r := GameState.run
	check(r.truth_core_ids.has(GATE_LIST) and r.logs_unlocked.has(str(ContentDb.core(GATE_LIST).get("log", ""))) and r.found_core_ids.is_empty(), "gate_list_filed")
	await Autopilot.snap("tool_door_filed")
	Autopilot.finish_now()
