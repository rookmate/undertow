extends TestCase
## The ring must match port-city/11-ring-reference.png: gap at the upper right, band thickest opposite it.


func test_gap_is_at_the_upper_right() -> void:
	var gap_start := RingPainter.band_end_deg() - 360.0
	var gap_end := RingPainter.band_start_deg()
	var gap_mid := (gap_start + gap_end) * 0.5
	check(gap_mid > 20.0 and gap_mid < 70.0, "gap centred between 12 and 3 o'clock, got %.1f°" % gap_mid)
	check(gap_end - gap_start > 20.0 and gap_end - gap_start < 60.0, "gap is a notch, not a half ring")


func test_band_is_thickest_opposite_the_gap() -> void:
	var mid := RingPainter.band_thickness(0.5)
	check(mid > RingPainter.band_thickness(0.0), "thicker in the middle than at the start")
	check(mid > RingPainter.band_thickness(1.0), "thicker in the middle than at the end")
	var mid_angle := lerpf(RingPainter.band_start_deg(), RingPainter.band_end_deg(), 0.5)
	check(mid_angle > 200.0 and mid_angle < 250.0, "thickest point at lower left, got %.1f°" % mid_angle)


func test_clock_angles_map_to_screen() -> void:
	var up := Vector2.from_angle(RingPainter.clock_to_rad(0.0))
	check(up.y < -0.99, "0° points up")
	var right := Vector2.from_angle(RingPainter.clock_to_rad(90.0))
	check(right.x > 0.99, "90° points right")


func test_withholding_differs_from_idle_only_by_inlay_rotation() -> void:
	var ring := StewardRing.new()
	ring.state = StewardRing.State.IDLE
	var idle: RingPainter.Look = ring.call("_look")
	ring.state = StewardRing.State.WITHHOLDING
	var held: RingPainter.Look = ring.call("_look")
	check_eq(held.inlay_rotation_deg - idle.inlay_rotation_deg, StewardRing.WITHHOLD_DEG)
	check_eq(held.alpha, idle.alpha)
	check_eq(held.petal_fill, idle.petal_fill)
	check_eq(held.inner_segments, idle.inner_segments)
	ring.free()
