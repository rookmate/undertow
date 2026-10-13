extends TestCase
## Greywater: the tide floods the low streets (the Steward warns at the swell and routes its path over
## high ground; high water slows and stings you), kelp slows you, the thick Marrow hides the path even
## with the voice on, and the old manual pump room is off the Lattice. The Pumphouse calms the tide.

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks"]:
		GameState.complete_level(district)
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://game/level/greywater.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func test_greywater_is_a_real_district() -> void:
	check(level.grid.validate(false).is_empty() and level.grid.content_problems().is_empty(), "%s" % [level.grid.validate(false)])
	check_eq(level.look.wall, Palette.PUMP_CONCRETE)
	check(LevelCatalog.is_open(GameState.run, "greywater"), "open once Act 1 is done")
	check_eq(LevelCatalog.restores("greywater"), "pumphouse")
	check_eq(CoreChoice.offer("greywater", GameState.run).size(), 3)
	check(level.tide != null and level.tide.cells.size() > 100, "the low streets flood")
	check_false(level.tide.floods(level.grid.start_cell()), "the seawall stays dry")


## Low water, the swell (the Steward warns), high water, the ebb.
func test_the_tide_turns_and_the_steward_warns_you() -> void:
	var tide := level.tide
	check_eq(tide.phase, Tide.Phase.LOW)
	tide.enter(Tide.Phase.SWELL)
	check_eq(Sound.voice_line, "tide_swell", "the Steward calls the turn")
	await wait_seconds(Tide.SWELL_SECONDS + 0.1)
	check_eq(tide.phase, Tide.Phase.HIGH, "then the water's up")
	await wait_seconds(Tide.HIGH_SECONDS + 0.1)
	check_eq(tide.phase, Tide.Phase.EBB)
	await wait_seconds(Tide.EBB_SECONDS + 0.1)
	check_eq(tide.phase, Tide.Phase.LOW, "and back")
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	Sound.hush()
	tide.enter(Tide.Phase.SWELL)
	check(Sound.voice_line != "tide_swell", "'never warn me' signed: it watches the water come and says nothing")


func test_high_water_slows_and_stings_you_on_the_low_streets() -> void:
	var low := Vector2i(8, 9)
	check(level.grid.floods(low))
	await _put(low)
	level.tide.enter(Tide.Phase.HIGH)
	check_eq(level.footing(low), Tide.WADE, "wading")
	var before := level.player.integrity.value
	await wait_seconds(2.2)
	check(level.player.integrity.value <= before - Tide.STING * 2.0, "the cold stings, every second")
	var dry := Vector2i(16, 12)
	check_false(level.grid.floods(dry), "the causeway")
	await _put(dry)
	before = level.player.integrity.value
	await wait_seconds(2.2)
	check_eq(level.player.integrity.value, before, "high ground stays dry")
	check_eq(level.footing(dry), 1.0)


## While the tide's up the Steward's path keeps to high ground.
func test_the_path_keeps_to_high_ground_while_the_tide_is_up() -> void:
	await _put(Vector2i(10, 20))
	await wait_frames(2)
	level.tide.enter(Tide.Phase.HIGH)
	var shown := level.predictor.predict(level.player.global_position)
	check_false(shown.is_empty(), "there's still a way")
	for c: Vector2i in shown:
		check_false(level.grid.floods(c), "%s is above the water" % c)
	level.tide.enter(Tide.Phase.LOW)
	var low_water := level.predictor.predict(level.player.global_position)
	check(low_water.any(func(c: Vector2i) -> bool: return level.grid.floods(c)), "at low water it goes the short way, through the streets")


func test_kelp_slows_you() -> void:
	var kelp := Vector2i(8, 15)
	check_eq(level.grid.floor_at(kelp), LevelGrid.Floor.KELP)
	check_near(level.footing(kelp), Level.KELP_FOOTING, 0.001)


## The thick Marrow: on the Lattice (the Steward is with you) but it can't see through it.
func test_the_marrow_hides_the_path_even_with_the_voice_on() -> void:
	var inside := Vector2i(27, 10)
	check(level.grid.is_marrow(inside) and level.grid.is_indexed(inside))
	await _put(inside)
	await wait_seconds(0.3)
	check(Steward.assists().steward_present, "it's with you")
	check(level.predictor.predict(level.player.global_position).is_empty(), "but it draws no path in the fog")


## Not even on its edge, beside dry ground, in any phase of the tide (at high water the route has to
## start from the dry cell next door, and still draws nothing while you're in the fog).
func test_no_path_from_anywhere_in_the_marrow_whatever_the_tide() -> void:
	var edge: Array[Vector2i] = []
	for c: Vector2i in level.grid.all_cells():
		if not level.grid.is_marrow(c) or not level.grid.is_walkable(c):
			continue
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			if level.grid.is_walkable(c + d) and not level.grid.is_marrow(c + d) and not edge.has(c):
				edge.append(c)
	check(edge.has(Vector2i(25, 7)), "the Marrow's edge by the seawall")
	for phase: Tide.Phase in [Tide.Phase.LOW, Tide.Phase.SWELL, Tide.Phase.HIGH, Tide.Phase.EBB]:
		level.tide.enter(phase)
		await wait_physics_frames(1)
		for c: Vector2i in edge:
			check(level.predictor.predict(Iso.cell_center(c)).is_empty(), "%s at %s: no path in the fog" % [Tide.Phase.keys()[phase], c])


func test_the_pump_room_is_off_the_lattice() -> void:
	check_eq(level.grid.floor_at(Vector2i(11, 3)), LevelGrid.Floor.GRATING)
	check_false(level.grid.is_indexed(Vector2i(11, 3)))


## Three movements (design/deeper-districts.md): the pumps run by hand on the apron drain the sump; the
## pump room's stair goes down into the galleries, off the Lattice and dark, where the plaque is now.
func test_the_pumps_open_the_way_down_to_the_plaque() -> void:
	var hold: Hold = null
	for n: Node in level.world.get_children():
		if n is Hold:
			hold = n
	check(hold != null and hold.hold_id == "greywater_pumps", "Pumping Station 2's hand crank")
	check(level.grid.cells_with(Tiles.HOLD_SPAWN).size() >= 2, "doors the Steward's machines come out of")
	var stair := level.passage("greywater_sump_down")
	check(stair != null and not stair.can_interact() and stair.blocked_reason().contains("pumps"), "the stair's under water")
	check(level.descent_finds_left() >= 2, "what's below glows up through it: the plaque and someone waiting")
	var plaque := level.grid.first("T")
	check_eq(level.grid.entity_id(plaque), "greywater_truth_plaque")
	check_eq(level.grid.floor_at(plaque + Vector2i(0, 1)), LevelGrid.Floor.CULVERT, "the plaque is down in the sump")
	check_false(level.grid.is_indexed(plaque + Vector2i(0, 1)), "off the Lattice")
	check_false(level.grid.reachable_from(level.grid.start_cell()).has(plaque + Vector2i(0, 1)), "no walking there: only the stair")
	GameState.complete_hold("greywater_pumps")
	check(stair.can_interact(), "the pumps run: the stair's open")


## With the Pumphouse rebuilt on the Ark, high water is shorter and doesn't sting; it still slows you.
func test_the_pumphouse_calms_the_tide() -> void:
	GameState.restore_building("pumphouse")
	check(Tide.pumped())
	check_eq(level.tide.high_seconds(), Tide.PUMPED_HIGH_SECONDS)
	await _put(Vector2i(8, 9))
	level.tide.enter(Tide.Phase.HIGH)
	var before := level.player.integrity.value
	await wait_seconds(2.2)
	check_eq(level.player.integrity.value, before, "no sting")
	check_eq(level.footing(Vector2i(8, 9)), Tide.WADE, "still wading")


## The Pumphouse stands on the Ark once Greywater is done; looking in, the Steward has its say.
func test_the_pumphouse_stands_on_the_ark() -> void:
	level.queue_free()
	await wait_frames(1)
	GameState.restore_building("pumphouse")
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(2)
	var cells := 0
	var door: ArkFixture = null
	for n: Node in level.world.get_children():
		if n is BuildingCell and (n as BuildingCell).facade == BuildingCell.Facade.PUMPHOUSE:
			cells += 1
		if n is ArkFixture and (n as ArkFixture).kind == ArkFixture.Kind.PUMPHOUSE_DOOR:
			door = n
	check(cells > 0 and door != null, "the Pumphouse stands, with its door")
	Sound.hush()
	door.interact(level.player)
	check_eq(Sound.voice_line, "pumphouse_note", "people run the pumps again, and the Steward says so")

