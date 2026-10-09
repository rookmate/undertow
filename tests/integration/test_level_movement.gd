extends TestCase
## Loads the real level scene and drives the Operator with the same actions a player would press.

var level: Level


func before_each() -> void:
	GameState.new_run()
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_physics_frames(2)
	# Movement only: no Custodians bumping into the Operator.
	level.remove_all_enemies()


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"dodge"]:
		Input.action_release(action)
	level.queue_free()
	await wait_frames(2)


func test_operator_spawns_on_the_start_cell() -> void:
	check_eq(level.player.cell(), level.grid.first("P"))


func test_up_right_walks_up_the_street() -> void:
	var start := Iso.world_to_grid(level.player.global_position)
	Input.action_press(&"move_up", 0.7071)
	Input.action_press(&"move_right", 0.7071)
	await wait_physics_frames(60)
	Input.action_release(&"move_up")
	Input.action_release(&"move_right")
	var moved := Iso.world_to_grid(level.player.global_position) - start
	check(moved.y < -2.5, "about 3 tiles up the street in a second, moved %s" % moved)
	check(absf(moved.x) < 0.2, "without drifting across it, moved %s" % moved)


func test_buildings_block_the_operator() -> void:
	Input.action_press(&"move_left", 0.7071)
	Input.action_press(&"move_up", 0.7071)
	await wait_physics_frames(150)
	Input.action_release(&"move_left")
	Input.action_release(&"move_up")
	var cell := level.player.cell()
	check(level.grid.is_walkable(cell), "stayed on walkable ground, at %s" % cell)
	check(cell.x >= 9, "stopped at the pavement edge, at %s" % cell)


func test_dodge_rolls_further_than_walking() -> void:
	var start := Iso.world_to_grid(level.player.global_position)
	Input.action_press(&"move_up", 0.7071)
	Input.action_press(&"move_right", 0.7071)
	await wait_physics_frames(1)
	Input.action_press(&"dodge")
	# An action pressed during a physics frame reaches _physics_process a tick or two later.
	await wait_physics_frames(3)
	Input.action_release(&"dodge")
	check(level.player.dodge.is_rolling(), "roll started")
	check(level.player.is_invulnerable(), "invulnerable at the start of the roll")
	await wait_physics_frames(16)
	Input.action_release(&"move_up")
	Input.action_release(&"move_right")
	var moved := (Iso.world_to_grid(level.player.global_position) - start).length()
	check(moved > 1.6, "a roll plus a step covers more than walking would, moved %.2f" % moved)
