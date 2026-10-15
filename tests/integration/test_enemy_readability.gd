extends TestCase
## Reading the machines: their shadows and warnings lie on the ground under every body; a Clerk's bale
## leaves from the hand you see throw it; a hover drone's claw reaches toward what it's after; a
## Lamplighter holding you in its beam keeps facing you.

var level: Level


class HoverProbe extends Node2D:
	var aim: Vector2 = Vector2(0, 1)
	var tips: Array[Vector2] = []

	func _draw() -> void:
		tips = PaintedHover.paint(self, "salvager", Vector2(1, 0), 64.0, Vector2.ZERO, 0.0, 1.0, false, aim)


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load("res://tests/fixtures/contact_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)


func _marks_of(e: Enemy) -> Array[Node]:
	return level.fx_ground.get_children().filter(func(n: Node) -> bool: return n is GroundMarks and (n as GroundMarks).enemy == e)


func test_shadows_and_warnings_lie_on_the_ground_under_every_body() -> void:
	var kinds: Array[Script] = [Custodian, Clerk, Salvager, Sterilizer, Warden, Lamplighter]
	for kind: Script in kinds:
		var e := level.add_enemy(kind.new() as Enemy, Vector2i(8, 8), 1000.0)
		await wait_frames(2)
		var marks := _marks_of(e)
		check_eq(marks.size(), 1, "%s puts its marks in the ground layer" % kind.get_global_name())
		e.position += Iso.grid_to_world(Vector2(1, 0))
		await wait_frames(2)
		if marks.size() == 1:
			# A frame behind at most, while it walks.
			check((marks[0] as Node2D).global_position.distance_to(e.global_position) < 6.0, "and they follow it")
		e.queue_free()
		await wait_frames(2)
		check(marks.size() == 1 and not is_instance_valid(marks[0]), "and go with it")


func _bales() -> Array[Node]:
	return level.world.get_children().filter(func(n: Node) -> bool: return n is Projectile)


## Thrown, the bale appears at the hand of the stroke that throws it, facing either way, whether or not
## a frame has been drawn since it turned.
func test_a_clerks_bale_leaves_from_its_hand() -> void:
	for side: int in [-1, 1]:
		level.player.position = Iso.cell_center(Vector2i(9, 8)) + Iso.grid_to_world(Vector2(side * 4, 0))
		var clerk := level.add_enemy(Clerk.new(), Vector2i(9, 8), Clerk.MAX_INTEGRITY) as Clerk
		clerk.set_physics_process(false)
		clerk.hide()
		await wait_physics_frames(1)
		clerk.face_player()
		clerk.call(&"_throw")
		var bales := _bales()
		check_eq(bales.size(), 1, "a bale")
		if bales.size() == 1:
			var bale := bales[0] as Projectile
			var drawn := bale.global_position + Vector2(0, -bale.height)
			var hand := clerk.global_position + clerk.hand_at_release()
			check(drawn.distance_to(hand) < 2.0, "facing %d: it appears at the hand (%.1f px off)" % [side, drawn.distance_to(hand)])
			bale.queue_free()
		clerk.queue_free()
		await wait_physics_frames(1)


## By a wall's end, a throw the warning line showed clear still goes clear: it doesn't leave from a hand
## that would put the corner in the way.
func test_a_clear_throw_by_a_corner_still_reaches_you() -> void:
	level.player.position = Iso.grid_to_world(Vector2(9.4, 4.5))
	var clerk := level.add_enemy(Clerk.new(), Vector2i(5, 4), Clerk.MAX_INTEGRITY) as Clerk
	clerk.set_physics_process(false)
	clerk.position = Iso.grid_to_world(Vector2(5.4, 4.2))
	await wait_physics_frames(1)
	check(level.grid.line_clear(clerk.global_position, level.player.global_position), "the warning line is clear")
	clerk.face_player()
	var before := level.player.integrity.value
	clerk.call(&"_throw")
	await wait_seconds(1.5)
	check(level.player.integrity.value < before, "and the bale reaches you")


func test_a_hover_drones_claw_reaches_toward_its_target() -> void:
	var up := HoverProbe.new()
	up.aim = Vector2(0, -1)
	var down := HoverProbe.new()
	add_child(up)
	add_child(down)
	await wait_frames(2)
	check(up.tips.size() == 1 and down.tips.size() == 1, "a claw each")
	if up.tips.size() == 1 and down.tips.size() == 1:
		check(up.tips[0].y < down.tips[0].y - 10.0, "after something above it, it reaches up (%.1f vs %.1f)" % [up.tips[0].y, down.tips[0].y])
	up.queue_free()
	down.queue_free()


func test_a_lamp_holding_you_keeps_facing_you() -> void:
	Steward.set_voice(false)
	await wait_frames(2)
	var lamp := level.add_enemy(Lamplighter.new(), Vector2i(8, 8), Lamplighter.MAX_INTEGRITY) as Lamplighter
	lamp.set_physics_process(false)
	level.player.position = lamp.position + Iso.grid_to_world(Vector2(2, 0))
	await wait_frames(2)
	lamp.face_player()
	lamp.call(&"_hook", level.player)
	check(lamp.hooking, "it has you")
	# You go round behind it.
	level.player.position = lamp.position + Iso.grid_to_world(Vector2(-2, 0))
	lamp.call(&"_think", 1.0 / 60.0)
	var to_you := Iso.ground_dir_between(lamp.global_position, level.player.global_position)
	check(lamp.visual_facing().dot(to_you) > 0.9, "and it turns to keep you in its beam")
