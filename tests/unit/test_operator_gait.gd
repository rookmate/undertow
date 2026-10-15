extends TestCase


func test_feet_exchange_contact_and_passing_poses() -> void:
	var gait := StrideCycle.new()
	gait.weight = 1.0
	var near_contact := gait.foot(false)
	var far_contact := gait.foot(true)
	check(near_contact.distance_to(far_contact) > 40, "opposite legs visibly lead")
	gait.phase = 0.5
	check_eq(gait.foot(false), far_contact)
	check_eq(gait.foot(true), near_contact)
	gait.phase = 0.25
	check_near(gait.foot(false).length(), 0.0, 0.001, "supporting foot passes beneath the body")
	check(gait.foot(true).y < -8, "other foot lifts during its pass")
	gait.phase = 0.75
	check_near(gait.foot(true).length(), 0.0, 0.001)
	check(gait.foot(false).y < -8)


func test_contact_stays_planted_and_distance_controls_cadence() -> void:
	for dir: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2(1, -1).normalized(), Vector2(1, 1).normalized()]:
		var gait := StrideCycle.new()
		gait.direction = dir
		gait.weight = 1.0
		gait.phase = 0.1
		var before := gait.foot(false)
		var travel := Iso.grid_to_world(dir * 0.1)
		gait.advance(travel, true, 0.03)
		check((gait.foot(false) + travel).distance_to(before) < 0.001, "stance foot stays on the ground in every direction")
	var fast := StrideCycle.new()
	var slow := StrideCycle.new()
	fast.advance(Iso.grid_to_world(Vector2(0.4, 0)), true, 0.125)
	slow.advance(Iso.grid_to_world(Vector2(0.4, 0)), true, 0.5)
	check_near(fast.phase, slow.phase, 0.001, "equal travel means equal stride regardless of time")


func test_idle_and_external_motion_do_not_advance_the_stride() -> void:
	var gait := StrideCycle.new()
	gait.phase = 0.23
	gait.weight = 1.0
	gait.advance(Vector2.ZERO, true, 0.2)
	check_near(gait.phase, 0.23)
	check_near(gait.weight, 0.0, 0.001, "blocked motion returns to rest")
	gait.advance(Vector2(30, 20), false, 0.2)
	check_near(gait.phase, 0.23, 0.001, "knockback, pulls and rolls cannot advance the walk")


func test_turns_preserve_the_planted_world_contact() -> void:
	for turn: Vector2 in [Vector2.LEFT, Vector2.DOWN, Vector2(1, -1).normalized()]:
		var gait := StrideCycle.new()
		gait.weight = 1.0
		gait.direction = Vector2.RIGHT
		var contact := gait.foot(false)
		var travel := Iso.grid_to_world(turn * 0.05)
		gait.advance(travel, true, 1.0 / 60.0)
		check((gait.foot(false) + travel).distance_to(contact) < 0.001, "turn keeps the planted contact rather than snapping it")
		for i: int in 40:
			gait.advance(travel, true, 1.0 / 60.0)
		var reference := StrideCycle.new()
		reference.phase = gait.phase
		reference.direction = turn
		reference.weight = 1.0
		check(gait.foot(false).distance_to(reference.foot(false)) < 4.0, "turn offset settles during subsequent steps")
		gait.advance(Vector2.ZERO, false, 0.2)
		check_near(gait.foot(false).length(), 0.0, 0.001, "stopping clears the turn offset")


func test_roll_and_downed_take_priority_over_walking() -> void:
	var body := OperatorBody.new()
	var roll := Dodge.new()
	roll.try_start(Vector2.RIGHT)
	body.update_pose(Vector2.RIGHT, Vector2(12, 6), roll, 0.1)
	check_near(body.gait.phase, 0.0)
	body.downed = true
	body.update_pose(Vector2.RIGHT, Vector2(12, 6), Dodge.new(), 0.1)
	check_near(body.gait.phase, 0.0)
	body.free()


func test_arms_counter_the_same_side_foot_in_each_painted_view() -> void:
	var gait := StrideCycle.new()
	gait.weight = 1.0
	for direction: String in ["front", "back"]:
		var anchors := ArtCatalog.frame("rig_%s_torso" % direction).anchors
		for side: float in [-1.0, 1.0]:
			var shoulder_x: float = (anchors["near_shoulder"].x - anchors["hip"].x) * side
			for travel: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1), Vector2(-1, -1)]:
				gait.direction = travel.normalized()
				for phase: float in [0.0, 0.5]:
					gait.phase = phase
					var angle := OperatorRig.arm_swing(gait, direction)
					var arm_travel := (Vector2(5, 63).rotated(angle) - Vector2(5, 63)).x * side
					var same_side_foot := gait.foot(shoulder_x > 0.0)
					if is_zero_approx(same_side_foot.x):
						check_near(arm_travel, 0.0, 0.001, "vertical travel has no sideways arm swing")
					else:
						check(arm_travel * same_side_foot.x < 0.0, "%s view at mirror %.0f travelling %s counters its physical leg" % [direction, side, travel])


func test_late_turn_does_not_discard_the_offset_at_landing() -> void:
	var gait := StrideCycle.new()
	gait.weight = 1.0
	gait.phase = 0.94
	var travel := Iso.grid_to_world(Vector2.LEFT * 0.05)
	for i: int in 5:
		var before := gait.foot(false)
		gait.advance(travel, true, 1.0 / 60.0)
		check((gait.foot(false) + travel).distance_to(before) < 20.0, "lifted foot remains continuous through the turn and landing")
