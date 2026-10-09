extends TestCase


func _step(d: Dodge, seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.00001:
		d.update(1.0 / 120.0)
		t += 1.0 / 120.0


func test_needs_a_direction() -> void:
	var d := Dodge.new()
	check_false(d.try_start(Vector2.ZERO))
	check_false(d.is_rolling())


func test_roll_lasts_duration_and_is_invulnerable_first() -> void:
	var d := Dodge.new()
	check(d.try_start(Vector2(0, -1)))
	check(d.is_rolling())
	check(d.is_invulnerable())
	_step(d, Dodge.INVULNERABLE + 0.01)
	check(d.is_rolling(), "still rolling after the invulnerable window")
	check_false(d.is_invulnerable(), "invulnerability ends before the roll does")
	_step(d, Dodge.DURATION - Dodge.INVULNERABLE)
	check_false(d.is_rolling())
	check_eq(d.velocity(), Vector2.ZERO)


func test_cooldown_blocks_a_second_roll() -> void:
	var d := Dodge.new()
	d.try_start(Vector2(1, 0))
	_step(d, Dodge.DURATION + 0.05)
	check_false(d.try_start(Vector2(1, 0)), "can't roll again during cooldown")
	_step(d, Dodge.COOLDOWN)
	check(d.try_start(Vector2(1, 0)), "can roll after cooldown")


func test_roll_covers_about_two_tiles() -> void:
	var d := Dodge.new()
	d.try_start(Vector2(0, -1))
	var travelled := Vector2.ZERO
	while d.is_rolling():
		travelled += d.velocity() / 120.0
		d.update(1.0 / 120.0)
	var tiles := Iso.world_to_grid(travelled).length()
	check(tiles > 1.4 and tiles < 2.6, "roll distance %.2f tiles" % tiles)
	check(Iso.world_to_grid(travelled).y < 0.0, "rolled the way it was pointed")
