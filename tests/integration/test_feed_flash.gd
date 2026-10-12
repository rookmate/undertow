extends TestCase
## The Feed's flash (the Vellum's Clerks): looked at, it washes the world out for a moment; turned from,
## rolled through, or behind something tall, nothing. A Clerk takes turns, a bale then the Feed. Never a
## strobe, and never over the HUD's subtitles.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	level.queue_free()
	await wait_frames(2)


func _stand(cell: Vector2i, facing: Vector2) -> void:
	level.player.position = Iso.cell_center(cell)
	level.player.face(facing)
	await wait_physics_frames(2)


func test_it_catches_only_what_you_look_at() -> void:
	var at := Iso.cell_center(Vector2i(13, 36))
	var ahead := Iso.cell_center(Vector2i(13, 31))
	check(FeedBlind.catches(at, Vector2(0, -1), ahead, Clerk.FLASH_REACH), "straight ahead")
	check(FeedBlind.catches(at, Vector2(1, -1).normalized(), ahead, Clerk.FLASH_REACH), "45° off")
	check_false(FeedBlind.catches(at, Vector2(1, 0), ahead, Clerk.FLASH_REACH), "90° off: the corner of your eye")
	check_false(FeedBlind.catches(at, Vector2(0, 1), ahead, Clerk.FLASH_REACH), "your back to it")
	check_false(FeedBlind.catches(at, Vector2(0, -1), Iso.cell_center(Vector2i(13, 26)), Clerk.FLASH_REACH), "too far to see")


func test_looked_at_it_washes_the_world_out_and_clears() -> void:
	await _stand(Vector2i(13, 36), Vector2(0, -1))
	var caught: Array[bool] = []
	level.feed_flashed.connect(func(c: bool) -> void: caught.append(c))
	check(level.flash_feed(Iso.cell_center(Vector2i(13, 31)), Clerk.FLASH_REACH, Clerk.BLIND_SECONDS), "caught")
	check(caught.size() == 1 and caught[0], "and says so")
	await wait_frames(2)
	var first := level.feed_blind.amount()
	check(first > 0.0 and first < FeedBlind.PEAK, "it rises (%.2f after a frame), never a hard cut to white" % first)
	await wait_frames(ceili(FeedBlind.RISE * 60.0) + 2)
	check_near(level.feed_blind.amount(), FeedBlind.PEAK, 0.001, "white, for a moment")
	await wait_frames(ceili(Clerk.BLIND_SECONDS * 60.0) + 10)
	check_false(level.feed_blind.is_blinding(), "a moment, then it clears")
	check_eq(level.feed_blind.amount(), 0.0)


func test_turned_from_rolled_through_or_behind_the_kiosk_it_misses() -> void:
	var source := Iso.cell_center(Vector2i(13, 31))
	await _stand(Vector2i(13, 36), Vector2(0, 1))
	check_false(level.flash_feed(source, Clerk.FLASH_REACH, Clerk.BLIND_SECONDS), "back turned")
	await _stand(Vector2i(13, 36), Vector2(0, -1))
	check(level.player.dodge.try_start(Vector2(1, 0)), "a roll")
	check(level.player.is_invulnerable())
	check_false(level.flash_feed(source, Clerk.FLASH_REACH, Clerk.BLIND_SECONDS), "mid-roll")
	await wait_physics_frames(60)
	var kiosk := level.grid.first("K")
	await _stand(kiosk + Vector2i(0, 1), Vector2(0, -1))
	check_false(level.flash_feed(Iso.cell_center(kiosk + Vector2i(0, -1)), Clerk.FLASH_REACH, Clerk.BLIND_SECONDS), "the kiosk between")
	await wait_frames(2)
	check_false(level.feed_blind.is_blinding(), "and nothing washed out")


func test_a_second_flash_only_brightens_it() -> void:
	await _stand(Vector2i(13, 36), Vector2(0, -1))
	var source := Iso.cell_center(Vector2i(13, 31))
	level.flash_feed(source, Clerk.FLASH_REACH, Clerk.BLIND_SECONDS)
	await wait_frames(ceili((FeedBlind.RISE + FeedBlind.HOLD) * 60.0) + 15)
	var fading := level.feed_blind.amount()
	check(fading < FeedBlind.PEAK, "fading by now (%.2f)" % fading)
	level.flash_feed(source, Clerk.FLASH_REACH, Clerk.BLIND_SECONDS)
	var last := fading
	for k: int in ceili(FeedBlind.RISE * 60.0) + 4:
		await wait_frames(1)
		check(level.feed_blind.amount() >= last, "frame %d: no dip back toward clear (a flicker)" % k)
		last = level.feed_blind.amount()
	check_near(last, FeedBlind.PEAK, 0.001, "back to white")


func test_it_sits_over_the_world_and_under_the_hud() -> void:
	check(level.feed_blind.layer < level.hud.layer, "the subtitles stay readable")
	var rain_layers := 0
	for n: Node in level.get_children():
		if n is CanvasLayer and n.get_child_count() > 0 and n.get_child(0) is Rain:
			rain_layers += 1
			check((n as CanvasLayer).layer < level.feed_blind.layer, "the rain is washed out too")
	check_eq(rain_layers, 1, "the Vellum's rain")


func test_a_clerk_throws_a_bale_then_turns_the_feed_on_you() -> void:
	await _stand(Vector2i(13, 36), Vector2(0, -1))
	var events: Array[String] = []
	level.feed_flashed.connect(func(c: bool) -> void: events.append("flash:%s" % c))
	level.world.child_entered_tree.connect(func(n: Node) -> void:
		if n is Projectile and (n as Projectile).team == Projectile.Team.ENEMY:
			events.append("bale"))
	var clerk := level.add_enemy(Clerk.new(), Vector2i(13, 31), Clerk.MAX_INTEGRITY) as Clerk
	for k: int in 900:
		await wait_physics_frames(1)
		level.player.face(Vector2(0, -1) if events.size() < 2 else Vector2(0, 1))
		if events.size() >= 4:
			break
	var expected: Array[String] = ["bale", "flash:true", "bale", "flash:false"]
	check(clerk.is_alive())
	check_eq(events, expected, "in turn: looked at, then turned from")


## "Reduce flashing" (Options): the white-out comes up over most of a second and only half as bright.
func test_with_reduced_flashing_it_comes_up_slowly_and_half_as_bright() -> void:
	Options.reduce_flashing = true
	await _stand(Vector2i(13, 36), Vector2(0, -1))
	check(level.flash_feed(Iso.cell_center(Vector2i(13, 31)), Clerk.FLASH_REACH, Clerk.BLIND_SECONDS), "still caught")
	await wait_frames(ceili(FeedBlind.RISE * 60.0) + 2)
	check(level.feed_blind.amount() < FeedBlind.GENTLE_PEAK * 0.5, "after the usual rise, barely begun (%.2f)" % level.feed_blind.amount())
	var most := 0.0
	for k: int in ceili(Clerk.BLIND_SECONDS * 60.0) + 30:
		await wait_frames(1)
		most = maxf(most, level.feed_blind.amount())
	check_near(most, FeedBlind.GENTLE_PEAK, 0.001, "half as bright at most")
	check_false(level.feed_blind.is_blinding(), "and it clears")
	Options.reduce_flashing = false

