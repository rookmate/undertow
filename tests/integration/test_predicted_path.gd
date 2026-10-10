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
	await _place(_cell_of(ContentIds.LOG_UNINDEXED_SLIP) + Vector2i(0, 1))
	check(level.predicted_path.shown.is_empty(), "the Steward can't route you in the stacks")
	await _place(_cell_of("vellum_truth_vashti_office") + Vector2i(-1, 0))
	check(level.predicted_path.shown.is_empty(), "nor in the deep stacks")


## Where the map puts the thing with this id.
func _cell_of(id: String) -> Vector2i:
	for c: Vector2i in level.grid.entity_ids:
		if level.grid.entity_ids[c] == id:
			return c
	fail("no %s on the map" % id)
	return Vector2i(-1, -1)


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
	var caches := _find(TruthCache)
	var slips := _find(UnindexedLog)
	check_eq(caches.size(), 2, "the stacks' cache and Prem Vashti's")
	check_eq(slips.size(), 2)
	var finds: Array[Interactable] = []
	finds.append_array(caches)
	finds.append_array(slips)
	for it: Interactable in finds:
		check_false(it.is_present(), "%s hidden" % it.get_script().resource_path.get_file())
	await _place(_cell_of(ContentIds.CORE_TRUTH_STACKS) + Vector2i(-1, 0))
	_stacks_cache().interact(level.player)
	check(GameState.run.found_core_ids.is_empty(), "can't take what isn't there")


func _stacks_cache() -> TruthCache:
	for it: Interactable in _find(TruthCache):
		if (it as TruthCache).core_id == ContentIds.CORE_TRUTH_STACKS:
			return it as TruthCache
	return null


func test_muted_operator_finds_what_it_left_out() -> void:
	Steward.voice_on = false
	await wait_frames(2)
	var cache := _stacks_cache()
	var slip: UnindexedLog = null
	for it: Interactable in _find(UnindexedLog):
		if (it as UnindexedLog).log_id == ContentIds.LOG_UNINDEXED_SLIP:
			slip = it as UnindexedLog
	check(cache.is_present() and slip.is_present())
	await _place(_cell_of(ContentIds.CORE_TRUTH_STACKS) + Vector2i(-1, 0))
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


func test_never_more_than_three_painted_and_never_underfoot_while_walking() -> void:
	var start := Iso.world_to_grid(level.player.global_position)
	for k: int in 90:
		# Walk up the street (below the stalled tram) in small steps, including positions near cell corners.
		level.player.position = Iso.grid_to_world(start + Vector2(0.37 * sin(k * 0.5), -k * 0.08))
		await wait_frames(1)
		var painted := level.predicted_path.painted_cells()
		check(painted.size() <= Tunables.PATH_TILES_AHEAD, "frame %d: %d tiles painted" % [k, painted.size()])
		check_false(painted.has(level.player.cell()), "frame %d: a tile under the feet" % k)


func test_corner_of_a_cell_still_excludes_it() -> void:
	# 0.05 tiles from a cell corner is ~0.64 tiles from its centre: still the cell underfoot.
	level.player.position = Iso.grid_to_world(Vector2(13.05, 34.05))
	await wait_frames(3)
	check_false(level.predicted_path.shown.has(level.player.cell()))
	check_false(level.predicted_path.painted_cells().has(level.player.cell()))


func test_muting_removes_the_tiles_at_once() -> void:
	check(level.predicted_path.painted_cells().size() > 0)
	Steward.set_voice(false)
	await wait_frames(1)
	check(level.predicted_path.painted_cells().is_empty(), "the gilt dies with the voice")
	Steward.set_voice(true)


func test_standing_in_a_lamp_cells_open_corner_keeps_the_path() -> void:
	var lamp := Vector2i(15, 32)
	check_eq(level.grid.char_at(lamp), "L")
	level.player.position = Iso.grid_to_world(Vector2(lamp.x + 0.15, lamp.y + 0.15))
	await wait_frames(3)
	check_eq(level.player.cell(), lamp)
	check_eq(level.predicted_path.shown.size(), Tunables.PATH_TILES_AHEAD, "still lit, still routed")
	check_false(level.predicted_path.shown.has(lamp))
