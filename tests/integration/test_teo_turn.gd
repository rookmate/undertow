extends TestCase
## Teo's turn (design/act-3.md): setting off for the Spire, he has his say at the dock. With his trust in
## you at the bottom he leaves the Ark and is gone from the run (and Rewrite with him); otherwise he stays.
## Once.

var level: ArkLevel


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum", "harbor"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)


func _set_off_for_the_spire() -> CityMap:
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(level)
	await wait_frames(3)
	var map := level.open_city_map()
	await wait_frames(2)
	map.choose("spire")
	check_eq(map.chosen, "spire", "the Spire is open")
	map.call(&"_go_to_chosen")
	await wait_frames(2)
	return map


func test_he_stays_and_says_so() -> void:
	var map := await _set_off_for_the_spire()
	check(map.departure is TeoTurn, "at the dock, Teo first")
	check_false((map.departure as TeoTurn).left)
	check(GameState.run.teo_present and GameState.run.teo_turn_had, "he stays")
	check(RunState.from_dict(GameState.run.to_dict()).teo_turn_had, "saved")
	# (Closing it sets off for the Spire, which would leave the test's scene: just take it away.)
	map.departure.queue_free()
	await wait_frames(2)


func test_once() -> void:
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(level)
	await wait_frames(3)
	var map := level.open_city_map()
	await wait_frames(2)
	GameState.teo_turn(false)
	check(map.turn_before("spire") == null, "had already: straight off")
	map.close()


func test_with_his_trust_at_the_bottom_he_leaves() -> void:
	GameState.run.teo_trust = TeoTurn.LEAVES_AT
	var map := await _set_off_for_the_spire()
	check(map.departure is TeoTurn and (map.departure as TeoTurn).left, "he won't watch")
	check_false(GameState.run.teo_present, "gone from the run")
	check_false(EndingRules.evaluate(GameState.run).rewrite, "and Rewrite can't be had")
	map.departure.queue_free()
	await wait_frames(2)
