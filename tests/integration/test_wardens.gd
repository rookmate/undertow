extends TestCase
## The Wardens (Harbor Ward): the only thing in the city that hunts. It walks its beat; its red eye sees a
## cone ahead (line of sight, SIGHT_TILES) and hears you close; once it has you it follows you anywhere,
## loses you after a while out of sight, searches where it last saw you, and goes back to its beat. Up
## close, a shock baton. Jammed, it loses you.

var level: Level
var warden: Warden


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/warden_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	for e: Enemy in level.living_enemies():
		if e is Warden:
			warden = e


func after_each() -> void:
	level.queue_free()
	await wait_frames(2)


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func test_it_walks_its_beat_until_it_sees_you() -> void:
	check(warden != null, "a Warden on the map")
	await _put(Vector2i(2, 10))
	var start := warden.global_position
	var furthest := 0.0
	for k: int in 240:
		await wait_physics_frames(1)
		furthest = maxf(furthest, Iso.ground_distance(start, warden.global_position))
	check(furthest > 2.5, "it walks its beat (%.1f tiles)" % furthest)
	check_false(warden.hunting, "and hasn't seen you")


func test_it_sees_in_its_cone_not_behind_it_or_through_a_wall() -> void:
	warden.set_physics_process(false)
	warden.position = Iso.cell_center(Vector2i(4, 3))
	warden.facing_ground = Vector2(1, 0)
	check(warden.sees(Iso.cell_center(Vector2i(10, 2))), "ahead, in the open")
	check_false(warden.sees(Iso.cell_center(Vector2i(10, 5))), "ahead, but the wall's between")
	check_false(warden.sees(Iso.cell_center(Vector2i(4, 9))), "off to the side: out of its cone")
	check_false(warden.sees(Iso.cell_center(Vector2i(15, 3))), "too far")
	check(warden.sees(Iso.cell_center(Vector2i(3, 3))), "right behind it: it hears you")


func test_once_it_has_you_it_follows_you_anywhere() -> void:
	await _put(Vector2i(9, 3))
	await wait_physics_frames(10)
	check(warden.hunting, "it has you")
	var home := warden.home
	# Walk away, slower than it hunts, keeping in its sight.
	var at := Iso.world_to_grid(level.player.global_position)
	for k: int in 480:
		at += Vector2(1.0, 0.55).normalized() * (2.0 / 60.0)
		at = at.clamp(Vector2(1.5, 1.5), Vector2(19.5, 10.5))
		level.player.position = Iso.grid_to_world(at)
		await wait_physics_frames(1)
	check(warden.hunting, "still after you")
	check(Iso.ground_distance(home, warden.global_position) > Warden.SIGHT_TILES, "far from its beat (%.1f tiles): no leash" % Iso.ground_distance(home, warden.global_position))


func test_it_loses_you_searches_and_goes_back_to_its_beat() -> void:
	await _put(Vector2i(9, 3))
	await wait_physics_frames(10)
	check(warden.hunting)
	var seen_at := warden.last_seen
	await _put(Vector2i(19, 10))
	var gave_up := false
	for k: int in roundi((Warden.LOSE_SECONDS + Warden.SEARCH_SECONDS + 4.0) * 60.0):
		await wait_physics_frames(1)
		if not warden.hunting:
			gave_up = true
			break
	check(gave_up, "it gives up in the end")
	check(Iso.ground_distance(warden.global_position, seen_at) < 1.5, "after looking where it last saw you")


func test_up_close_the_baton() -> void:
	await _put(Vector2i(5, 3))
	var before := level.player.integrity.value
	await wait_physics_frames(roundi((Warden.WINDUP + 0.4) * 60.0))
	check(level.player.integrity.value < before, "struck")


func test_jammed_it_loses_you() -> void:
	await _put(Vector2i(9, 3))
	await wait_physics_frames(10)
	check(warden.hunting)
	warden.jam(2.0)
	check_false(warden.hunting, "it's lost you")
	check_eq(warden.state, Enemy.State.STUNNED, "and stands stunned")
