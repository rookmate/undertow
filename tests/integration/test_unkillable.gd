extends TestCase
## The autopilot's Operator can't go down (DECISIONS 178): damage lands, but at 1 Integrity it stays up and
## says it would have gone down. Anyone else's goes down as ever.

var level: Level


func before_each() -> void:
	GameState.new_run()
	level = (load("res://tests/fixtures/warden_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	level.queue_free()
	await wait_frames(2)


func test_held_up_at_one_and_noted() -> void:
	var p := level.player
	p.cannot_go_down = true
	var noted := [0]
	var downs := [0]
	p.would_have_gone_down.connect(func() -> void: noted[0] += 1)
	p.downed.connect(func() -> void: downs[0] += 1)
	p.self_damage(10000.0)
	check(p.is_alive(), "still up")
	check_eq(p.integrity.value, 1.0, "at 1 Integrity")
	check_eq(noted[0], 1, "noted")
	check_eq(downs[0], 0, "never down")
	await wait_physics_frames(30)
	check(p.take_hit(500.0, p.global_position + Vector2(40, 0)), "it still takes the hit")
	check(p.is_alive() and noted[0] == 2, "and still stays up")


func test_otherwise_down_as_ever() -> void:
	var p := level.player
	check_false(p.cannot_go_down, "off by default")
	p.self_damage(10000.0)
	check_false(p.is_alive(), "down")
