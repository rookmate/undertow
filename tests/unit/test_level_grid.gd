extends TestCase
## The Vellum street map: playable, with its off-path area where the brief needs it.

const MAP := "res://data/levels/vellum_street.txt"

var grid: LevelGrid


func before_each() -> void:
	grid = LevelGrid.load_file(MAP)


func test_parses_with_comments_stripped() -> void:
	check(grid.size.x >= 20 and grid.size.y >= 40, "size %s" % grid.size)
	check_eq(grid.char_at(Vector2i(-1, 0)), " ", "outside the map is void")


func test_has_every_marker_the_slice_needs() -> void:
	for ch: String in ["P", "R", "W", "w", "T", "U", "k", "C"]:
		check_eq(grid.cells_with(ch).size(), 1, "exactly one %s" % ch)
	check_eq(grid.cells_with("c").size(), 3, "three Custodians")
	check(grid.cells_with("L").size() >= 12, "the street is lamplit")


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
	for ch: String in ["T", "U"]:
		var c := grid.first(ch)
		check_false(grid.is_indexed(c), "%s is off the Lattice" % ch)
		var reachable := false
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP, Vector2i.ZERO]:
			if on_foot.has(c + d):
				reachable = true
		check(reachable, "%s reachable on foot" % ch)
		check_false(lit.has(c), "%s not reachable through lit cells" % ch)
	var waiting := grid.first("w")
	check_false(grid.is_indexed(waiting), "the off-path Waiting is unindexed")


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
	_check_occlusion(grid)
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
