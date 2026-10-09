extends TestCase
## Hit geometry: swept projectile segments, lines of sight, and mouse aim at chest height.


## The reviewer's example: both endpoints outside the hit circle, the segment between them inside it.
func test_a_grazing_shot_hits_even_when_both_ends_miss() -> void:
	var a := Vector2(-0.125, 0.55)
	var b := Vector2(0.125, 0.55)
	check(a.length() > 0.56 and b.length() > 0.56, "both endpoints are outside")
	var t := CombatMath.segment_hit(a, b, Vector2.ZERO, 0.56)
	check(t >= 0.0 and t <= 1.0, "the swept segment touches the circle (t=%.3f)" % t)


func test_segment_hit_order_and_misses() -> void:
	check_near(CombatMath.segment_hit(Vector2(-2, 0), Vector2(2, 0), Vector2.ZERO, 0.5), 0.375, 0.0001, "enters at x=-0.5")
	check_eq(CombatMath.segment_hit(Vector2(-2, 1), Vector2(2, 1), Vector2.ZERO, 0.5), -1.0, "passes above")
	check_eq(CombatMath.segment_hit(Vector2(1, 0), Vector2(2, 0), Vector2.ZERO, 0.5), -1.0, "moving away")
	check_eq(CombatMath.segment_hit(Vector2(0.1, 0), Vector2(2, 0), Vector2.ZERO, 0.5), 0.0, "starts inside")


func test_a_segment_through_a_wall_corner_is_blocked_even_from_open_cells() -> void:
	var grid := LevelGrid.load_file("res://data/levels/vellum_street.txt")
	var kiosk := grid.first("K")
	var from := Vector2(kiosk.x - 0.5, kiosk.y + 0.5)
	var to := Vector2(kiosk.x + 1.5, kiosk.y + 0.5)
	check(grid.is_walkable(Vector2i(floori(from.x), floori(from.y))) and grid.is_walkable(Vector2i(floori(to.x), floori(to.y))), "both ends open")
	check(grid.first_block(from, to) >= 0.0, "the kiosk is in the way")
	check(grid.first_block(from, from + Vector2(0, -1)) < 0.0, "a clear line along the street")


## A shot moving tick by tick at any speed stops at the kiosk's face: never skipped, never early.
func test_ticks_of_any_length_stop_at_the_wall() -> void:
	var grid := LevelGrid.load_file("res://data/levels/vellum_street.txt")
	var kiosk := grid.first("K")
	var start := Vector2(kiosk.x - 1.5, kiosk.y + 0.5)
	for step: float in [0.05, 0.25, 0.3, 1.0, 2.5]:
		var pos := start
		var stopped_at := Vector2.INF
		for i: int in 200:
			var to := pos + Vector2(step, 0)
			var t := grid.first_block(pos, to)
			if t >= 0.0:
				stopped_at = pos.lerp(to, t)
				break
			pos = to
		check_near(stopped_at.x, float(kiosk.x), 0.0001, "ticks of %.2f tiles stop at the kiosk face" % step)


func test_blocking_counts_the_cells_at_both_ends() -> void:
	var grid := LevelGrid.load_file("res://data/levels/vellum_street.txt")
	var kiosk := grid.first("K")
	var inside := Vector2(kiosk.x + 0.5, kiosk.y + 0.5)
	check_eq(grid.first_block(inside, inside + Vector2(0.1, 0)), 0.0, "a segment inside the kiosk is blocked from the start")
	check_near(grid.first_block(Vector2(kiosk.x - 0.2, kiosk.y + 0.5), Vector2(kiosk.x + 0.2, kiosk.y + 0.5)), 0.5, 0.0001, "ending inside it")
	check_near(grid.first_block(Vector2(kiosk.x - 0.2, kiosk.y + 0.5), Vector2(kiosk.x + 0.5, kiosk.y + 0.5)), 0.2 / 0.7, 0.0001, "entering it")


func test_a_corner_between_two_walls_does_not_let_a_shot_through() -> void:
	var grid := LevelGrid.parse("....\n.#..\n..#.\n....")
	# From the open cell (1,2) to the open cell (2,1): the only way is through the corner both walls share.
	check(grid.first_block(Vector2(1.5, 2.5), Vector2(2.5, 1.5)) >= 0.0, "the shared corner is closed")
	check(grid.first_block(Vector2(0.5, 3.5), Vector2(3.5, 3.5)) < 0.0, "an open row is clear")


func test_mouse_aim_points_where_the_cursor_points() -> void:
	var origin := Iso.cell_center(Vector2i(10, 30))
	var target := Iso.cell_center(Vector2i(13, 30))
	var cursor_on_chest := target + Vector2(0, -Projectile.CHEST_HEIGHT)
	var aim := Operator.cursor_aim(origin, cursor_on_chest)
	var truth := Iso.ground_dir_between(origin, target)
	check(absf(rad_to_deg(aim.angle_to(truth))) < 1.0, "aiming at the chest flies at the body (off by %.1f°)" % rad_to_deg(aim.angle_to(truth)))
