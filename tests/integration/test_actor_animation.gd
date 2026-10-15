extends TestCase

class Walker extends Enemy:
	var intent: Vector2 = Vector2.ZERO
	func _think(_delta: float) -> Vector2:
		return intent


func test_enemy_gait_tracks_travel_and_stops_during_stun() -> void:
	var enemy := Walker.new()
	enemy.setup(null, Vector2i(2, 2), 100.0)
	add_child(enemy)
	enemy.intent = Iso.ground_velocity(Vector2.RIGHT, 2.0)
	await wait_physics_frames(12)
	check(enemy.gait.phase > 0.0, "actual enemy locomotion advances its feet")
	enemy.take_hit(1.0, Vector2.LEFT, 1.0, 1.0)
	var phase := enemy.gait.phase
	await wait_physics_frames(15)
	check_near(enemy.gait.phase, phase, 0.001, "stun and knockback never walk")
	check_near(enemy.gait.weight, 0.0, 0.001)
	enemy.free()


func test_tripod_has_two_planted_contacts_and_one_passing_foot() -> void:
	var gait := StrideCycle.new()
	gait.configure(1.1, 9.0, 3)
	gait.weight = 1.0
	var travel := Iso.grid_to_world(Vector2.RIGHT * 0.02)
	for phase: float in [0.08, 0.41, 0.75]:
		gait.phase = phase
		var before: Array[Vector2] = []
		for i: int in 3:
			before.append(gait.foot_index(i))
		gait.advance(travel, true, 1.0 / 60.0)
		var planted := 0
		for i: int in 3:
			if (gait.foot_index(i) + travel).distance_to(before[i]) < 0.001:
				planted += 1
		check_eq(planted, 2, "tripod keeps two supports while the third leg passes")


func test_attack_pose_reaches_release_at_the_gameplay_deadline() -> void:
	var enemy := Warden.new()
	enemy.state = Enemy.State.WINDUP
	enemy.set("_state_time", enemy.windup_seconds() * 0.7)
	check_near(enemy.attack_pose(), -1.0, 0.001, "baton is drawn back")
	enemy.set("_state_time", enemy.windup_seconds())
	check_near(enemy.attack_pose(), 1.0, 0.001, "stroke reaches impact at damage time")
	enemy.state = Enemy.State.RECOVER
	enemy.set("_state_time", 0.0)
	check_near(enemy.attack_pose(), 1.0, 0.001, "recovery starts at the same pose")
	enemy.set("_state_time", 0.35)
	check_near(enemy.attack_pose(), 0.0, 0.001)
	enemy.free()


func test_crane_prepares_the_swing_without_teleporting_its_load() -> void:
	var crane := Crane.new()
	crane.setup(null, Vector2i.ZERO, Crane.MAX_INTEGRITY)
	add_child(crane)
	crane.set_physics_process(false)
	crane.load_at = crane.global_position + Iso.grid_to_world(Vector2(-3, 1))
	crane.load_height = 0.0
	var before := crane.load_at
	crane.call("_enter_phase", Crane.Phase.SWING_WARN)
	crane.call("_fight", 0.01)
	check(crane.load_at.distance_to(before) < 1.0, "warning begins at the previous drop")
	check(crane.load_height < 1.0, "load rises instead of jumping 60 pixels")
	crane.call("_fight", Crane.SWING_WARN_SECONDS - 0.01)
	check_eq(crane.phase, Crane.Phase.SWING)
	before = crane.load_at
	crane.call("_fight", 0.01)
	check(crane.load_at.distance_to(before) < 30.0, "swing starts from its prepared location")
	crane.call("_enter_phase", Crane.Phase.REST)
	crane.call("_fight", 0.01)
	check(crane.load_height > 55.0, "rest lowers the load continuously")
	crane.free()


func test_warden_baton_travels_toward_its_target_at_release() -> void:
	var gait := StrideCycle.new()
	for view: String in ["front", "back"]:
		var prefix := "rig_warden_%s_" % view
		var arm := ArtCatalog.frame(prefix + "arm")
		var target := Iso.grid_to_world(Vector2.RIGHT if view == "front" else Vector2.UP).normalized()
		var endpoints: Array[Vector2] = []
		for attack: float in [-1.0, 1.0]:
			var end := PaintedBiped.arm_end(prefix, Vector2.ZERO, Vector2.ZERO, gait, 90.0, attack)
			endpoints.append(PaintedParts.attachment(prefix + "arm", arm.anchors["weapon"], Vector2.ZERO, end, 90.0 * 0.36))
		for side: float in [-1.0, 1.0]:
			var stroke := (endpoints[1] - endpoints[0]) * Vector2(side, 1)
			check(stroke.dot(target * Vector2(side, 1)) > 20.0, view + " baton advances toward the target, including mirrored views")


func test_lung_breathing_pauses_with_the_scene() -> void:
	var lung := Lung.new()
	lung.process_mode = Node.PROCESS_MODE_PAUSABLE
	lung.setup(null, Vector2i.ZERO, Lung.MAX_INTEGRITY)
	add_child(lung)
	await wait_physics_frames(3)
	var phase: float = lung.get("_breath_phase")
	get_tree().paused = true
	await get_tree().create_timer(0.05, true).timeout
	check_near(lung.get("_breath_phase"), phase, 0.001)
	get_tree().paused = false
	await wait_physics_frames(3)
	check(float(lung.get("_breath_phase")) > phase, "breathing resumes from its paused phase")
	lung.free()
