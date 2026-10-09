extends TestCase
## The Steward's predicted path in the real level: three tiles ahead, never underfoot, only where the
## Lattice reaches, re-routing as the Operator strays, absent off the Lattice and when muted.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.voice_on = true
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	Steward.voice_on = true
	level.queue_free()
	await wait_frames(2)


func _place(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_frames(2)


func _check_path(shown: Array[Vector2i], where: String) -> void:
	check_eq(shown.size(), Tunables.PATH_TILES_AHEAD, "%s: exactly three tiles" % where)
	var p := level.player.global_position
	for i: int in shown.size():
		var c := shown[i]
		check(level.grid.is_indexed(c), "%s: tile %s is on the Lattice" % [where, c])
		check(Iso.ground_distance(p, Iso.cell_center(c)) >= PathPredictor.UNDERFOOT_TILES, "%s: tile %s is not underfoot" % [where, c])
		if i > 0:
			var step := c - shown[i - 1]
			check(absi(step.x) + absi(step.y) == 1, "%s: tiles meet edge to edge (%s → %s)" % [where, shown[i - 1], c])


func test_three_tiles_ahead_at_the_start() -> void:
	var shown := level.predicted_path.shown
	_check_path(shown, "start")
	check(Iso.world_to_grid(Iso.cell_center(shown[2])).y < Iso.world_to_grid(level.player.global_position).y, "they lead up the street")


func test_path_reroutes_when_the_operator_strays() -> void:
	await _place(Vector2i(10, 33))
	var left := level.predicted_path.shown.duplicate()
	_check_path(left, "left of the tram")
	await _place(Vector2i(14, 33))
	var right := level.predicted_path.shown.duplicate()
	_check_path(right, "right of the tram")
	check(left != right, "a different route from a different place")
	for c: Vector2i in left:
		check(c.x <= 10, "from the left side it routes down the left (%s)" % c)
	for c: Vector2i in right:
		check(c.x >= 13, "from the right side it routes down the right (%s)" % c)


func test_no_path_off_the_lattice() -> void:
	await _place(level.grid.first("U") + Vector2i(0, 1))
	check(level.predicted_path.shown.is_empty(), "the Steward can't route you in the stacks")


func test_no_path_when_muted() -> void:
	Steward.voice_on = false
	await wait_frames(2)
	check(level.predicted_path.shown.is_empty())


func test_path_ends_at_the_reliquary() -> void:
	var goal := level.predictor.goal
	check(goal.x >= 0, "the Steward has a destination")
	await _place(goal + Vector2i(0, 2))
	var shown := level.predicted_path.shown
	check(shown.size() <= 2, "near the end there are fewer tiles left (%d)" % shown.size())
	if not shown.is_empty():
		check_eq(shown[shown.size() - 1], goal, "the last tile is the Reliquary's door")


func test_the_route_never_leaves_the_lattice() -> void:
	var route := level.predictor.nav.path(level.grid.first("P"), level.predictor.goal)
	check(route.size() > 20, "a real route up the street")
	for c: Vector2i in route:
		check(level.grid.is_indexed(c), "%s indexed" % c)


func _find(script_type: GDScript) -> Array[Interactable]:
	var out: Array[Interactable] = []
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n.get_script() == script_type and level.is_ancestor_of(n):
			out.append(n as Interactable)
	return out


func test_off_path_finds_are_hidden_while_the_steward_listens() -> void:
	var cache := _find(TruthCache)[0] as TruthCache
	var slip := _find(UnindexedLog)[0] as UnindexedLog
	check_false(cache.is_present(), "truth cache hidden")
	check_false(slip.is_present(), "unindexed log hidden")
	await _place(level.grid.first("T") + Vector2i(-1, 0))
	cache.interact(level.player)
	check(GameState.run.found_core_ids.is_empty(), "can't take what isn't there")


func test_muted_operator_finds_what_it_left_out() -> void:
	Steward.voice_on = false
	await wait_frames(2)
	var cache := _find(TruthCache)[0] as TruthCache
	var slip := _find(UnindexedLog)[0] as UnindexedLog
	check(cache.is_present() and slip.is_present())
	await _place(level.grid.first("T") + Vector2i(-1, 0))
	check(level.player.interact_target() == cache, "the cache is in reach")
	Input.action_press(&"interact")
	await wait_physics_frames(3)
	Input.action_release(&"interact")
	check(GameState.run.found_core_ids.has(ContentIds.CORE_TRUTH_STACKS), "truth core found")
	slip.interact(level.player)
	check(GameState.run.logs_unlocked.has(ContentIds.LOG_UNINDEXED_SLIP), "slip filed")


func test_the_waiting_wake_only_when_muted() -> void:
	var doorway: TheWaiting = null
	for it: Interactable in _find(TheWaiting):
		if not it.off_path:
			doorway = it as TheWaiting
	check(doorway != null)
	check(doorway.is_present(), "the doorway Waiting stands on the lit street")
	check_false(doorway.can_interact(), "the Steward says leave them")
	check(doorway.blocked_reason() != "", "and says so")
	doorway.interact(level.player)
	check_eq(GameState.run.survivors_found(), 0)
	Steward.voice_on = false
	check(doorway.can_interact())
	doorway.interact(level.player)
	check_eq(GameState.run.survivors_found(), 1, "woken and counted")
	check_false(doorway.can_interact(), "only once")


func test_stacks_resident_is_in_reach_when_muted() -> void:
	Steward.voice_on = false
	await _place(Vector2i(18, 30))
	var target := level.player.interact_target()
	var names := []
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := n as Interactable
		names.append("%s present=%s can=%s d=%.2f" % [it.get_script().resource_path.get_file(), it.is_present(), it.can_interact(), Iso.ground_distance(level.player.global_position, it.global_position)])
	check(target is TheWaiting, "the stacks resident is the interact target; saw %s" % [names])


func test_tiles_hold_steady_while_the_operator_jitters_at_a_cell_edge() -> void:
	await _place(Vector2i(9, 37))
	var edge := Iso.grid_to_world(Vector2(9.5, 37.0))
	var seen: Dictionary[Vector2i, bool] = {}
	for k: int in 30:
		level.player.position = edge + Vector2(0, 2.0 if k % 2 == 0 else -2.0)
		await wait_frames(1)
		for c: Vector2i in level.predicted_path.shown:
			seen[c] = true
	check(seen.size() <= Tunables.PATH_TILES_AHEAD + 1, "a stable prediction, not two alternating routes (saw %d cells)" % seen.size())
