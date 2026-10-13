extends TestCase
## Holds and descents (design/deeper-districts.md), in a test arena: a hold runs while you stay by its
## crank and pauses when you don't, its waves come out meanwhile, and done it opens the way down for the
## rest of the run; downed, it starts over and what it brought out goes. The way down is shut until then,
## and says why. Down there, off the Lattice, it's dark but for your lamp.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	await _open()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _open() -> void:
	level = (load("res://tests/fixtures/hold_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func _hold() -> Hold:
	for n: Node in level.world.get_children():
		if n is Hold:
			return n
	return null


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func test_the_words_are_all_there() -> void:
	check(Holds.problems().is_empty(), "%s" % [Holds.problems()])


func test_it_runs_while_you_stay_and_pauses_when_you_dont() -> void:
	var hold := _hold()
	check(hold != null and hold.can_interact(), "a crank to turn")
	check_eq(hold.prompt_verb(), "TURN THE WHEEL")
	await _put(Vector2i(6, 4))
	hold.interact(level.player)
	check(hold.running and hold.turning(), "turning")
	await wait_seconds(1.0)
	var ran := hold.progress
	check(ran > 0.8, "it runs while you're by it (%.2f)" % ran)
	await _put(Vector2i(13, 7))
	await wait_seconds(1.0)
	check_near(hold.progress, ran, 0.05, "walk off and it waits")
	check(level.running_hold() == hold, "the HUD shows it running")


func test_its_waves_come_out_and_done_it_opens_the_way_down() -> void:
	var hold := _hold()
	var down := level.passage("fixture_shaft_down")
	check(down != null and not down.can_interact(), "the way down is shut")
	check_eq(down.blocked_reason(), "Shut fast.", "and says so")
	var before := level.living_enemies().size()
	await _put(Vector2i(6, 4))
	hold.interact(level.player)
	await wait_seconds(Holds.seconds("fixture_hold") + 0.3)
	check(hold.done and not hold.running, "done")
	check_eq(level.living_enemies().size() - before, 2, "its two waves came out")
	check(GameState.run.holds_done.has("fixture_hold"), "for the rest of the run")
	check(RunState.from_dict(GameState.run.to_dict()).holds_done.has("fixture_hold"), "saved")
	check(down.can_interact(), "the way down is open")


func test_downed_it_starts_over() -> void:
	var hold := _hold()
	await _put(Vector2i(6, 4))
	hold.interact(level.player)
	await wait_seconds(Holds.seconds("fixture_hold") * 0.5)
	check(hold.brought_out().size() > 0, "its first wave is out")
	var before := level.living_enemies().size()
	level.player.self_damage(10000.0)
	await wait_seconds(Operator.DOWNED_SECONDS + 0.2)
	check_false(hold.running, "it stopped")
	check_eq(hold.progress, 0.0, "back to nothing")
	check(hold.brought_out().is_empty(), "what it brought out is gone")
	check(level.living_enemies().size() < before)
	check(hold.can_interact(), "to start again")


func test_down_there_its_dark_but_for_your_lamp() -> void:
	GameState.complete_hold("fixture_hold")
	var down := level.passage("fixture_shaft_down")
	await _put(Vector2i(3, 5))
	check(down.can_interact())
	down.interact(level.player)
	await wait_seconds(0.8)
	check(level.in_descent(), "down")
	check(level.grid.floor_at(level.player.cell()) == LevelGrid.Floor.CULVERT)
	check_false(level.grid.is_indexed(level.player.cell()), "off the Lattice")
	await wait_seconds(DescentDark.FADE_SECONDS + 0.2)
	check(level.descent_dark.amount > 0.99, "dark")
	check(level.player.carried_light_on(), "your lamp on, voice on or not")
	for layer: Node in level.get_children():
		if layer is CanvasLayer and (layer as CanvasLayer).layer < 0:
			check_false((layer as CanvasLayer).visible, "no sky down there")
	check_eq(Sound.layer_target(&"underground"), 1.0, "the walls close in")
	check(Sound.layer_target(&"rain") < 0.5, "the rain is far above")
	var up := level.passage("fixture_shaft_up")
	up.interact(level.player)
	await wait_seconds(0.8)
	check_false(level.in_descent(), "back up")
	await wait_seconds(DescentDark.FADE_SECONDS + 0.2)
	check(level.descent_dark.amount < 0.01, "and the dark lifts")
	check_false(level.player.carried_light_on(), "the Steward's light again, voice on")


func test_a_done_hold_stays_done() -> void:
	GameState.complete_hold("fixture_hold")
	level.queue_free()
	await wait_frames(2)
	await _open()
	check(_hold().done and not _hold().can_interact(), "done on the way back")
	check(level.passage("fixture_shaft_down").can_interact())


## Every district's hold (data/holds.json, the test arena's aside) is placed once, in one district, with
## the pair of ladders it opens in the same map and something still to find below.
func test_every_hold_is_placed_with_its_way_down() -> void:
	var placed: Dictionary[String, String] = {}
	for id: String in LevelCatalog.LEVELS:
		var g := LevelGrid.load_file(LevelCatalog.map_of(id))
		for c: Vector2i in g.cells_with(Tiles.CRANK):
			var hold := g.entity_id(c)
			check(Holds.has(hold), "%s: %s is a hold" % [id, hold])
			check_false(placed.has(hold), "%s placed once" % hold)
			placed[hold] = id
			var ladders: Array[String] = []
			for l: Vector2i in g.cells_with(Tiles.LADDER):
				ladders.append(g.entity_id(l))
			var way := Holds.opens(hold)
			check(ladders.has(way + "_down") and ladders.has(way + "_up"), "%s: both ends of %s" % [id, way])
			var below := 0
			for k: Vector2i in g.cells_with("T") + g.cells_with("w") + g.cells_with("U"):
				if g.floor_at(k) == LevelGrid.Floor.CULVERT:
					below += 1
			check(below > 0, "%s: something to find down there" % id)
	for hold: String in ["greywater_pumps", "loop_points", "tideworks_winch", "mercy_generator", "vellum_paper_lift", "harbor_mast"]:
		check(placed.has(hold), "%s is in its district" % hold)

