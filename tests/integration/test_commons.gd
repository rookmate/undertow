extends TestCase
## The Commons on the Ark (Harbor Ward's building): standing, the survivors you woke each carry a light of
## their own and say something of their own, and the Wardfolk who came over stand by it and talk about
## Noor. Home with you, Noor wires her Mast on its roof; left in the Ward, there's no Mast.

const PLAIN_LINE := "I was waiting for it to tell me I could go. Thank you."

var level: ArkLevel


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	GameState.add_survivor("loop_waiting_carriage_1")
	GameState.add_survivor("mercy_waiting_night_nurse")
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)


func _open() -> void:
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(level)
	await wait_frames(3)


## Harbor Ward done: Noor carried home to the boat, or left in the Ward.
func _harbor_done(noor_home: bool) -> void:
	GameState.noor_leaves_for_ward()
	if noor_home:
		GameState.noor_comes_home()
	GameState.complete_level("harbor")
	GameState.restore_building("commons")


func _survivors() -> Array[ArkFigure]:
	var out: Array[ArkFigure] = []
	for n: Node in level.world.get_children():
		if n is ArkFigure and (n as ArkFigure).who == ArkFigure.Who.SURVIVOR:
			out.append(n)
	return out


func _roof_masts() -> int:
	var n := 0
	for c: Node in level.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == BuildingCell.Facade.COMMONS and (c as BuildingCell).roof_mast:
			n += 1
	return n


func test_before_the_commons_nobody_has_come_over_and_nobody_is_lit() -> void:
	await _open()
	check(level.wardfolk.is_empty(), "nobody's come over from the Ward")
	var people := _survivors()
	check_eq(people.size(), 2, "the two you woke")
	for f: ArkFigure in people:
		check_false(f.lit, "%s: no light of their own yet" % f.survivor_id)
		check_eq(f.current_line(), PLAIN_LINE)


func test_with_the_commons_its_people_light_up_and_talk() -> void:
	_harbor_done(true)
	await _open()
	check_eq(level.wardfolk.size(), 2, "two of the Wardfolk by the Commons")
	for f: ArkFigure in level.wardfolk:
		check(f.lit, "a cyan lantern each")
		check_eq(f.current_line(), CommonsPeople.wardfolk_line(f.wardfolk_index, GameState.run))
		check(level.grid.is_occupied(Vector2i(Iso.world_to_grid(f.position).floor())), "standing on their spot: nobody routes through them")
	check(level.wardfolk[0].current_line() != level.wardfolk[1].current_line(), "two things to say")
	for f: ArkFigure in _survivors():
		check(f.lit, "%s: a light of their own" % f.survivor_id)
		check_eq(f.current_line(), CommonsPeople.survivor_line(f.survivor_id), "and something of their own to say")
		check(f.current_line() != PLAIN_LINE)
	var w := level.wardfolk[1]
	w.interact(level.player)
	check_eq(w.spoken_line(), w.current_line(), "talked to, they say it")


func test_noor_home_her_mast_stands_on_the_commons_roof() -> void:
	_harbor_done(true)
	check(GameState.run.buildings_restored.has(GameState.MAST), "she wires the Mast")
	await _open()
	check_eq(_roof_masts(), 1, "on the roof's front corner")
	check(level.noor != null and level.noor.current_line().contains("Mast"), "and she says what it does")


func test_left_in_the_ward_there_is_no_mast() -> void:
	_harbor_done(false)
	check_false(GameState.run.buildings_restored.has(GameState.MAST), "no Noor, no Mast")
	await _open()
	check_eq(_roof_masts(), 0)
	check(level.noor == null, "she isn't there")
	check_eq(level.wardfolk.size(), 2, "the Wardfolk came over anyway")
	var home := RunState.new()
	check(level.wardfolk[0].current_line() != CommonsPeople.wardfolk_line(0, home), "and they say she stayed")
