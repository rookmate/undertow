extends TestCase


func test_edges_follow_physical_support_across_chunk_joins() -> void:
	var grid := LevelGrid.parse("....v#\n....~ \n")
	check_false(TerrainEdges.exposed(grid, Vector2i(3, 0), Vector2i.RIGHT), "no wall at the four-cell chunk join")
	check_false(grid.is_walkable(Vector2i(4, 0)), "fixture has a solid lawn")
	check_false(TerrainEdges.exposed(grid, Vector2i(4, 0), Vector2i.RIGHT), "lawn and building share physical support")
	check(TerrainEdges.exposed(grid, Vector2i(5, 0), Vector2i.DOWN), "building has a foundation over void")
	check(TerrainEdges.exposed(grid, Vector2i(3, 1), Vector2i.RIGHT), "water exposes a quay edge")
	check_false(TerrainEdges.exposed(grid, Vector2i(4, 1), Vector2i.RIGHT), "water has no stone wall")
	check(TerrainEdges.exposed(grid, Vector2i(0, 0), Vector2i.LEFT), "map bounds expose an edge")
	check(grid.is_walkable(Vector2i(3, 1)), "presentation leaves navigation intact")
