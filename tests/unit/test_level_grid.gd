extends TestCase
## The Vellum street map: playable, with its off-path area where the brief needs it.

const MAP := "res://data/levels/vellum_street.txt"

var grid: LevelGrid


func before_each() -> void:
	grid = LevelGrid.load_file(MAP)


func test_parses_with_comments_stripped() -> void:
	check(grid.size.x >= 20 and grid.size.y >= 40, "size %s" % grid.size)
	check_eq(grid.char_at(Vector2i(-1, 0)), " ", "outside the map is void")


func test_has_every_marker_the_district_needs() -> void:
	for ch: String in ["P", "R", "W"]:
		check_eq(grid.cells_with(ch).size(), 1, "exactly one %s" % ch)
	# The overflow stacks off the street, and Prem Vashti's office in the deep stacks.
	for ch: String in ["w", "T", "U"]:
		check_eq(grid.cells_with(ch).size(), 2, "two of %s" % ch)
	check_eq(grid.cells_with("k").size(), 3, "a Clerk in the plaza, two in the newsroom")
	check_eq(grid.cells_with("C").size(), 3, "checkpoints on the street, by the stair, by the Reliquary")
	check_eq(grid.cells_with("c").size(), 3, "three Custodians")
	check(grid.cells_with("L").size() >= 12, "the street is lamplit")


func test_the_newsroom_is_on_the_lattice_and_its_desks_stand_in_the_way() -> void:
	var desks := grid.cells_with(Tiles.NEWSROOM_DESK)
	check(desks.size() >= 12, "rows of desks (%d)" % desks.size())
	for d: Vector2i in desks:
		check(grid.is_solid(d), "a desk at %s is solid" % d)
	var floor_cells := grid.cells_with(Tiles.NEWSROOM_FLOOR)
	check(floor_cells.size() > 40, "a newsroom floor")
	for c: Vector2i in floor_cells:
		check_eq(grid.floor_at(c), LevelGrid.Floor.PARQUET)
		check(grid.is_indexed(c), "the newsroom at %s is on the Lattice" % c)
	var lit := grid.reachable_from(grid.first("P"), true)
	check(lit.has(Vector2i(25, 6)), "over the footbridge along the Lattice")
	check(lit.has(grid.first("R") + Vector2i(0, -1)), "and through the newsroom and the press hall to the Reliquary")


func test_reliquary_is_reachable_on_the_indexed_route() -> void:
	var start := grid.first("P")
	var lit := grid.reachable_from(start, true)
	var r := grid.first("R")
	var beside := false
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if lit.has(r + d):
			beside = true
	check(beside, "a lit cell next to the Reliquary is reachable from the start")


func test_off_path_area_is_unindexed_and_only_reachable_off_the_lattice() -> void:
	var start := grid.first("P")
	var on_foot := grid.reachable_from(start, false)
	var lit := grid.reachable_from(start, true)
	for ch: String in ["T", "U", "w"]:
		for c: Vector2i in grid.cells_with(ch):
			check_false(grid.is_indexed(c), "%s at %s is off the Lattice" % [ch, c])
			var reachable := false
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.ZERO]:
				if on_foot.has(c + d):
					reachable = true
			check(reachable, "%s at %s reachable on foot" % [ch, c])
			check_false(lit.has(c), "%s at %s not reachable through lit cells" % [ch, c])


func test_stairs_are_the_only_way_to_the_stacks() -> void:
	var stairs := grid.cells_with("S")
	check(stairs.size() >= 1)
	for s: Vector2i in stairs:
		check(grid.is_walkable(s))
		check_false(grid.is_indexed(s))


func test_occupied_cells_are_walkable_but_marked() -> void:
	var w := grid.first("W")
	check(grid.is_walkable(w))
	check(grid.is_occupied(w))
	check(grid.is_indexed(w), "the doorway Waiting stands on the lit street")


## Tall buildings may not stand in front of walkable ground: their prisms would hide it. A building
## covers the screen column above its footprint, i.e. cells behind it at (x - i, y - j) with
## |i - j| <= 1 and i + j up to its height in half-tiles.
func test_no_building_hides_walkable_ground() -> void:
	for id: String in LevelCatalog.LEVELS:
		_check_occlusion(LevelGrid.load_file(LevelCatalog.map_of(id)))
	_check_occlusion(LevelGrid.load_file("res://data/levels/ark.txt"))


func _check_occlusion(g: LevelGrid) -> void:
	var rows_hidden := ceili((BuildingCell.STORY * BuildingCell.STORIES + BuildingCell.PARAPET) / Iso.HALF_H)
	for c: Vector2i in g.all_cells():
		if not g.is_building(c):
			continue
		for i: int in range(0, rows_hidden + 1):
			for j: int in range(0, rows_hidden + 1):
				if i + j == 0 or i + j > rows_hidden or absi(i - j) > 1:
					continue
				var behind := c - Vector2i(i, j)
				if g.is_walkable(behind):
					fail("building %s hides walkable cell %s" % [c, behind])
					return


## "The Steward may advise here and may not act": the Ark has no Lattice cells at all.
func test_the_ark_has_no_lattice() -> void:
	var ark := LevelGrid.load_file("res://data/levels/ark.txt")
	check(ark.start_cell().x >= 0, "the Ark has a start")
	for c: Vector2i in ark.all_cells():
		check_false(ark.is_indexed(c), "%s on the Ark is indexed" % c)
	check(ark.reachable_from(ark.start_cell()).has(ark.first("a") + Vector2i(1, 0)), "the Archive door is reachable from the dock")


func test_every_placed_thing_has_a_unique_id_from_the_map() -> void:
	check(grid.validate(false).is_empty(), "the Vellum validates: %s" % [grid.validate(false)])
	# The slice's own where they always were (saved runs know them), and Prem Vashti's office's.
	var placed: Dictionary[String, String] = {
		"W": ContentIds.SURVIVOR_DOORWAY,
		"w": ContentIds.SURVIVOR_STACKS + " vellum_waiting_audit_office",
		"T": ContentIds.CORE_TRUTH_STACKS + " vellum_truth_vashti_office",
		"U": ContentIds.LOG_UNINDEXED_SLIP + " log_vellum_tube_carrier",
	}
	for ch: String in placed:
		var ids: Array[String] = []
		for c: Vector2i in grid.cells_with(ch):
			ids.append(grid.entity_id(c))
		ids.sort()
		var expected: Array[String] = []
		for id: String in placed[ch].split(" "):
			expected.append(id)
		expected.sort()
		check_eq(ids, expected, "every %s has its id" % ch)
	check_eq(grid.entity_id(Vector2i(9, 25)), ContentIds.SURVIVOR_DOORWAY)
	check_eq(grid.entity_id(Vector2i(18, 31)), ContentIds.SURVIVOR_STACKS)
	check_eq(grid.entity_id(Vector2i(20, 24)), ContentIds.CORE_TRUTH_STACKS)
	check_eq(grid.entity_id(Vector2i(18, 27)), ContentIds.LOG_UNINDEXED_SLIP)


func test_map_ids_point_at_real_content() -> void:
	for c: Vector2i in grid.cells_with("T"):
		check(ContentDb.is_truth(grid.entity_id(c)), "the cache at %s holds a known truth core" % c)
	for c: Vector2i in grid.cells_with("U"):
		check_eq(str(ContentDb.memory_log(grid.entity_id(c)).get("kind")), "unindexed", "the slip at %s is an unindexed log" % c)


## A placed thing stands on the ground around it: what's drawn, what floods, the Marrow and the Lattice
## all read the same terrain. Off-path finds stay off the Lattice whatever they stand on.
func test_placed_things_stand_on_the_ground_around_them() -> void:
	var grey := LevelGrid.load_file(LevelCatalog.map_of("greywater"))
	for c: Vector2i in [Vector2i(9, 10), Vector2i(23, 17)]:
		check("cO".contains(grey.char_at(c)), "a spawn at %s" % c)
		check_eq(grey.floor_at(c), LevelGrid.Floor.LOW_STREET, "on the low street")
		check(grey.floods(c), "%s floods like the low street round it, after its machine has moved on" % c)
	var w := Vector2i(28, 10)
	check_eq(grey.char_at(w), "W")
	check(grey.is_marrow(w), "the Waiting in the Marrow stand in it")
	var loop := LevelGrid.load_file(LevelCatalog.map_of("loop"))
	var t := Vector2i(24, 18)
	check_eq(loop.char_at(t), "T")
	check_eq(loop.floor_at(t), LevelGrid.Floor.CAB, "the cache sits on the cab's floor")
	check_false(loop.is_indexed(t), "and stays off the Lattice")


## Every solid thing is a building, tall (it stops sight, swings and shots) or low (it doesn't): exactly
## one, so a new prop can't come in unclassified.
func test_every_solid_thing_is_tall_or_low() -> void:
	for ch: String in LevelGrid.SOLID:
		var building: bool = LevelGrid.FLOOR_OF.get(ch, LevelGrid.Floor.VOID) == LevelGrid.Floor.BUILDING
		var kinds := int(building) + int(LevelGrid.TALL.contains(ch)) + int(LevelGrid.LOW.contains(ch))
		check_eq(kinds, 1, "'%s' is exactly one of building, tall, low" % ch)
	var mercy := LevelGrid.load_file(LevelCatalog.map_of("mercy"))
	check(mercy.blocks_line(mercy.first(Tiles.AMBULANCE)), "an ambulance stops a shot")
	check_false(mercy.blocks_line(mercy.first(Tiles.PARTITION)), "a partition cut to waist height doesn't")
	var grey := LevelGrid.load_file(LevelCatalog.map_of("greywater"))
	check(grey.blocks_line(grey.first(Tiles.TURBINE)), "a turbine's pylon does")


func test_validation_catches_broken_maps() -> void:
	var no_start := LevelGrid.parse("#####\n#..R#\n#####")
	check(no_start.validate(false).size() > 0, "no start")
	var unknown := LevelGrid.parse("#####\n#P?.#\n#.R.#\n#####")
	check(unknown.validate(false).size() > 0, "unknown character reported")
	check(unknown.is_solid(Vector2i(2, 1)), "and treated as solid, not invisible floor")
	var no_id := LevelGrid.parse("#####\n#P.W#\n#.R.#\n#####")
	check(no_id.validate(false).size() > 0, "a resident without an id")
	var dup := LevelGrid.parse("@ 3,1 same\n@ 1,2 same\n#####\n#P.W#\n#WR.#\n#####")
	check(dup.validate(false).size() > 0, "two things sharing an id")
	var bad_line := LevelGrid.parse("@ nonsense\n#####\n#P.R#\n#####")
	check(bad_line.validate(false).size() > 0, "a malformed id line")
	var ok := LevelGrid.parse("@ 3,1 someone\n#####\n#P.W#\n#.R.#\n#####")
	check(ok.validate(false).is_empty(), "a good little map passes: %s" % [ok.validate(false)])


func test_shipped_districts_pass_the_boot_check() -> void:
	check_eq(LevelCatalog.check_all(), PackedStringArray(), "every district's map and content agree")


func test_maps_must_name_real_content_of_the_right_kind() -> void:
	var wrong := LevelGrid.parse("@ 2,1 vellum_power_feed\n@ 3,1 log_0311_morning_feed\n#####\n#.TU#\n#####")
	var problems := wrong.content_problems()
	check_eq(problems.size(), 2, "a power core in a truth cache, a Steward log on a slip: %s" % [problems])
	var unknown := LevelGrid.parse("@ 2,1 no_such_core\n#####\n#.T.#\n#####")
	check_eq(unknown.content_problems().size(), 1, "an unknown core")


func test_ids_are_unique_across_districts_and_every_district_has_a_reliquary() -> void:
	var map := "@ 2,1 the_same_person\n#####\n#PW.#\n#.R.#\n#####"
	var grids: Dictionary[String, LevelGrid] = {"vellum": LevelGrid.parse(map), "elsewhere": LevelGrid.parse(map)}
	var problems := "\n".join(LevelCatalog.check(grids))
	check(problems.contains("the_same_person is placed in both"), "a person can't live in two districts: %s" % problems)
	check(problems.contains("elsewhere: This Reliquary is broken"), "a district with no Reliquary content is caught")


## A map can rename its own characters to named tiles: in this one '.' is hospital tile and '=' a glass
## partition, not cobble and railing. Everything else reads the tiles, never the map's letters.
func test_a_map_can_have_its_own_legend() -> void:
	var own := LevelGrid.parse("% . hospital_tile\n% = partition\n#####\n#P..#\n#=.R#\n#####")
	check(own.parse_errors.is_empty(), "%s" % [own.parse_errors])
	check_eq(own.char_at(Vector2i(2, 1)), Tiles.HOSPITAL_TILE, "the map's '.' is hospital tile here")
	check_eq(own.floor_at(Vector2i(2, 1)), LevelGrid.Floor.TILE)
	check(own.is_indexed(Vector2i(2, 1)), "on the Lattice")
	check(own.is_solid(Vector2i(1, 2)), "the partition stands in the way")
	check_eq(own.char_at(Vector2i(1, 1)), "P", "letters it doesn't rename keep their usual meaning")
	check(own.validate(false).is_empty(), "%s" % [own.validate(false)])
	var plain := LevelGrid.parse("#####\n#P..#\n#=.R#\n#####")
	check_eq(plain.floor_at(Vector2i(2, 1)), LevelGrid.Floor.COBBLE, "and other maps are unaffected")


func test_a_bad_legend_line_is_reported() -> void:
	var own := LevelGrid.parse("% . teleporter\n% ab hospital_tile\n%\n#####\n#P.R#\n#####")
	check_eq(own.parse_errors.size(), 3, "%s" % [own.parse_errors])
	check_false(own.validate(false).is_empty(), "and the map won't load")
