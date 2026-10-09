extends TestCase


func test_grid_world_round_trip() -> void:
	for g: Vector2 in [Vector2(0, 0), Vector2(3.5, 7.25), Vector2(-2, 5), Vector2(12.1, 0.3)]:
		var back := Iso.world_to_grid(Iso.grid_to_world(g))
		check(back.is_equal_approx(g), "%s -> %s" % [g, back])


func test_cell_centre_maps_back_to_its_cell() -> void:
	for c: Vector2i in [Vector2i(0, 0), Vector2i(12, 39), Vector2i(5, 9), Vector2i(23, 0)]:
		check_eq(Iso.world_to_cell(Iso.cell_center(c)), c)


func test_tile_proportions_match_the_camera() -> void:
	var d := Iso.cell_diamond(Vector2i.ZERO)
	check_near(d[1].x - d[3].x, float(Tunables.TILE_W), 0.001, "diamond width")
	check_near(d[2].y - d[0].y, float(Tunables.TILE_H), 0.001, "diamond height")
	check(Iso.SQUASH > 0.5 and Iso.SQUASH < 0.6, "≈56° tilt from vertical (image 10 measures 0.53–0.56)")


func test_up_right_walks_along_the_street() -> void:
	var g := Iso.input_to_ground(Vector2(1, -1).normalized())
	check(g.is_equal_approx(Vector2(0, -1)), "W+D walks grid -y, got %s" % g)
	var screen := Iso.ground_velocity(g, 1.0)
	check(screen.x > 0.0 and screen.y < 0.0, "which is up-right on screen")


func test_right_moves_straight_across_the_screen() -> void:
	var v := Iso.input_to_velocity(Vector2(1, 0), 1.0)
	check_near(v.y, 0.0, 0.0001)
	check(v.x > 0.0)


func test_ground_speed_is_the_same_in_every_direction() -> void:
	for input: Vector2 in [Vector2(1, 0), Vector2(0, -1), Vector2(1, 1).normalized(), Vector2(-0.3, 0.8).normalized()]:
		var v := Iso.input_to_velocity(input, 3.0)
		var tiles_per_second := Iso.world_to_grid(v).length()
		check_near(tiles_per_second, 3.0, 0.001, "input %s" % input)


func test_vertical_screen_speed_is_squashed() -> void:
	var across := Iso.input_to_velocity(Vector2(1, 0), 1.0).length()
	var up := Iso.input_to_velocity(Vector2(0, -1), 1.0).length()
	check_near(up / across, Iso.SQUASH, 0.001)


func test_analog_magnitude_is_kept_and_capped() -> void:
	check_near(Iso.input_to_ground(Vector2(0.5, 0)).length(), 0.5, 0.001)
	check_near(Iso.input_to_ground(Vector2(3, 0)).length(), 1.0, 0.001)
	check_eq(Iso.input_to_ground(Vector2.ZERO), Vector2.ZERO)


func test_ground_distance_between_neighbours_is_one_tile() -> void:
	check_near(Iso.ground_distance(Iso.cell_center(Vector2i(4, 4)), Iso.cell_center(Vector2i(5, 4))), 1.0, 0.0001)
	check_near(Iso.ground_distance(Iso.cell_center(Vector2i(4, 4)), Iso.cell_center(Vector2i(4, 7))), 3.0, 0.0001)
