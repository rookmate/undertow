extends TestCase


func test_muted_damage_is_multiplied() -> void:
	check_near(CombatMath.damage_taken(10.0, true), 10.0)
	check_near(CombatMath.damage_taken(10.0, false), 10.0 * Tunables.MUTED_DAMAGE_TAKEN_MULT)
	check_near(Tunables.MUTED_DAMAGE_TAKEN_MULT, 1.4, 0.0001, "HUD mock: DMG TAKEN ×1.4")


func test_arc_respects_range_and_angle() -> void:
	var o := Iso.cell_center(Vector2i(10, 10))
	var ahead := Iso.cell_center(Vector2i(10, 9))
	var behind := Iso.cell_center(Vector2i(10, 11))
	var far := Iso.cell_center(Vector2i(10, 6))
	var up := Vector2(0, -1)
	check(CombatMath.in_arc(o, up, ahead, 1.5, 90.0))
	check_false(CombatMath.in_arc(o, up, behind, 1.5, 90.0), "behind is outside the arc")
	check_false(CombatMath.in_arc(o, up, far, 1.5, 90.0), "out of range")
	check(CombatMath.in_arc(o, up, Iso.cell_center(Vector2i(10, 8)), 1.5, 90.0, 0.6), "a big target's radius extends reach")


func test_nearest_picks_the_closest_in_reach() -> void:
	var a := Node2D.new()
	var b := Node2D.new()
	add_child(a)
	add_child(b)
	a.global_position = Iso.cell_center(Vector2i(5, 3))
	b.global_position = Iso.cell_center(Vector2i(5, 7))
	var origin := Iso.cell_center(Vector2i(5, 5))
	var candidates: Array[Node2D] = [b, a]
	check(CombatMath.nearest(origin, candidates, 10.0) != null)
	check(CombatMath.nearest(origin, candidates, 1.0) == null, "nothing in reach")
	a.global_position = Iso.cell_center(Vector2i(5, 4))
	check(CombatMath.nearest(origin, candidates, 10.0) == a)
	a.free()
	b.free()


func test_aim_assist_bends_toward_a_target_in_the_cone_only() -> void:
	var t := Node2D.new()
	add_child(t)
	var origin := Iso.cell_center(Vector2i(10, 10))
	t.global_position = Iso.grid_to_world(Vector2(10.5 + 0.8, 10.5 - 4.0))
	var candidates: Array[Node2D] = [t]
	var aim := Vector2(0, -1)
	var bent := CombatMath.assist_aim(aim, origin, candidates, 8.0, 24.0, 0.5)
	check(bent.x > 0.0 and bent.angle_to(aim) != 0.0, "bent toward the target, got %s" % bent)
	check_near(bent.length(), 1.0, 0.0001)
	var none := CombatMath.assist_aim(aim, origin, candidates, 8.0, 24.0, 0.0)
	check(none.is_equal_approx(aim), "zero strength leaves aim alone")
	t.global_position = Iso.cell_center(Vector2i(14, 10))
	check(CombatMath.assist_aim(aim, origin, candidates, 8.0, 24.0, 0.5).is_equal_approx(aim), "outside the cone: unchanged")
	t.free()


func test_integrity_takes_heals_and_clamps() -> void:
	var i := Integrity.new(50.0)
	check_near(i.take(20.0), 20.0)
	check_near(i.ratio(), 0.6)
	i.heal(100.0)
	check_near(i.value, 50.0, 0.0001, "heal clamps to max")
	check_near(i.take(80.0), 50.0, 0.0001, "can't take more than is left")
	check(i.is_depleted())
	i.heal(10.0)
	check(i.is_depleted(), "no healing back from zero; reset() does that")
	i.reset()
	check_near(i.value, 50.0)
