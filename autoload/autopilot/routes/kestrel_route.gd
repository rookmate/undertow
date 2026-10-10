extends AutopilotRoute
## Kestrel Heights, the switchback climb: terrace 1's Custodians, through the gate while it listens, mute
## at the hedge, let a Lamplighter take hold and put it down, the child's map, wake the gardener (muted),
## the Steward back, the Reliquary. Then the Ark, bare, and the Loop open on the dock's map.

const OPENING: Array[String] = [
	"loadout_shown", "loadout_one_weapon", "level_reached", "player_spawned", "path_three_tiles_ahead",
	"lamplighters_light_the_way", "narration_heard", "enemy_killed",
]
const THROUGH: Array[String] = [
	"dodge_performed", "gate_open_while_listening", "muted_at_the_hedge", "gate_shut_behind",
	"lamplighter_hooked", "lamplighter_beaten", "childs_map_found", "gardener_woken", "voice_restored",
	"route_completed", "core_choice_shown", "kestrel_cores_carried", "ark_reached", "ark_bare",
	"loop_map_shown", "the_loop_open_on_map",
]


func checks() -> Array[String]:
	var out := OPENING.duplicate()
	if long_run:
		out.append_array(THROUGH)
	return out


func drive(level: Level, gen: int) -> void:
	pass_check("level_reached")
	var player := level.player
	pass_check("player_spawned")
	Controls.device = Controls.Device.PAD
	player.dodged.connect(func(_d: Vector2) -> void: pass_check("dodge_performed"), CONNECT_ONE_SHOT)
	Narrator.line_spoken.connect(func(_id: String, _t: String) -> void:
		if not Autopilot.stale(gen):
			pass_check("narration_heard"), CONNECT_ONE_SHOT)
	var start_count := level.living_enemies().size()
	if not await Autopilot.wait(1.2, gen):
		return
	await Autopilot.snap("kestrel_start")
	check(level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, "path_three_tiles_ahead")
	check(_lamplighters(level).all(func(l: Lamplighter) -> bool: return not l.hunting and not l.is_hittable()), "lamplighters_light_the_way")
	for cell: Vector2i in [Vector2i(12, 23), Vector2i(20, 23), Vector2i(27, 23), Vector2i(28, 20), Vector2i(28, 18)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
		if level.living_enemies().size() < start_count:
			pass_check("enemy_killed")
	if level.living_enemies().size() < start_count:
		pass_check("enemy_killed")
	await Autopilot.snap("kestrel_terrace_1")
	if not long_run:
		return
	check(_gates(level).all(func(g: SmartGate) -> bool: return g.open), "gate_open_while_listening")
	for cell: Vector2i in [Vector2i(28, 16), Vector2i(28, 15), Vector2i(24, 14), Vector2i(18, 14), Vector2i(12, 14), Vector2i(10, 14)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	await Autopilot.snap("kestrel_hedge_hint")
	Autopilot.tap(&"voice_toggle")
	check(await Autopilot.until(func() -> bool: return not Steward.voice_on, 1.0, gen), "muted_at_the_hedge")
	check(await Autopilot.until(func() -> bool: return _gates(level).all(func(g: SmartGate) -> bool: return not g.open), 3.0, gen), "gate_shut_behind")
	# Muted, a Lamplighter comes for you: let it take hold, then put it down.
	check(await Autopilot.until(func() -> bool: return _lamplighters(level).any(func(l: Lamplighter) -> bool: return l.hooking), 8.0, gen), "lamplighter_hooked")
	await Autopilot.snap("kestrel_hooked")
	var lamp: Lamplighter = null
	for l: Lamplighter in _lamplighters(level):
		if l.hooking or (lamp == null and l.is_alive()):
			lamp = l
	var frame := 0
	var spent := 0.0
	while lamp != null and lamp.is_alive() and spent < 15.0:
		if Autopilot.stale(gen):
			return
		frame += 1
		Autopilot.fight(player, lamp, frame)
		spent += await Autopilot.physics_step()
	Autopilot.release_all()
	check(lamp != null and not lamp.is_alive(), "lamplighter_beaten")
	for cell: Vector2i in [Vector2i(10, 14), Vector2i(8, 15), Vector2i(6, 15), Vector2i(5, 14)]:
		if not await Autopilot.advance_to(level, player, cell, 20.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(3, 12), gen):
		return
	check(GameState.run.found_core_ids.has("kestrel_truth_childs_map"), "childs_map_found")
	await Autopilot.snap("kestrel_childs_room")
	for cell: Vector2i in [Vector2i(5, 14), Vector2i(8, 15), Vector2i(10, 14), Vector2i(10, 12), Vector2i(10, 9), Vector2i(10, 6), Vector2i(15, 5)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	if not await Autopilot.use_at(level, player, Vector2i(18, 5), gen):
		return
	check(GameState.run.survivor_ids.has("kestrel_waiting_gardener"), "gardener_woken")
	await Autopilot.snap("kestrel_gardener")
	Autopilot.tap(&"voice_toggle")
	check(await Autopilot.until(func() -> bool: return Steward.voice_on and level.predicted_path.shown.size() == Tunables.PATH_TILES_AHEAD, 3.0, gen), "voice_restored")
	for cell: Vector2i in [Vector2i(22, 5), Vector2i(26, 5), Vector2i(28, 4)]:
		if not await Autopilot.advance_to(level, player, cell, 25.0, gen):
			return
	pass_check("route_completed")
	await Autopilot.snap("kestrel_reliquary")
	Autopilot.tap(&"interact")


## Carry the child's map and the Day core.
func choose(screen: Node, gen: int) -> void:
	var offered: Array[String] = screen.get("offered")
	var r := GameState.run
	var power := r.cores_power()
	var truth := r.cores_truth()
	if not await pick_cores(screen, ["kestrel_truth_childs_map", "kestrel_power_day"], gen):
		return
	check(offered.size() == 4 and r.cores_truth() == truth + 1 and r.cores_power() == power + 1 and r.levels_completed.has("kestrel"), "kestrel_cores_carried")
	await Autopilot.snap("kestrel_core_choice_done")
	on_to_the_ark(screen)


## After Kestrel Heights the Ark is bare (nothing restored yet); the dock's map shows the Loop open.
func at_ark(ark: ArkLevel, gen: int) -> bool:
	pass_check("ark_reached")
	check(facade_cells(ark, BuildingCell.Facade.ARCHIVE) == 0 and GameState.run.buildings_restored.is_empty() and ark.noor == null and ark.teo == null, "ark_bare")
	if not await Autopilot.wait(1.5, gen):
		return false
	await Autopilot.snap("ark_bare")
	if not await Autopilot.open_city_map(ark, gen):
		return false
	check(ark.city_map != null, "loop_map_shown")
	check(CityMap.state_of(GameState.run, "loop") == "open" and CityMap.state_of(GameState.run, "kestrel") == "done" and CityMap.state_of(GameState.run, "vellum") == "locked", "the_loop_open_on_map")
	await Autopilot.snap("loop_map_after_kestrel")
	return true


func _lamplighters(level: Level) -> Array[Lamplighter]:
	var out: Array[Lamplighter] = []
	for n: Node in level.world.get_children():
		if n is Lamplighter:
			out.append(n as Lamplighter)
	return out


func _gates(level: Level) -> Array[SmartGate]:
	var out: Array[SmartGate] = []
	for n: Node in level.world.get_children():
		if n is SmartGate:
			out.append(n as SmartGate)
	return out
