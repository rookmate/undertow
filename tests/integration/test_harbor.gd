extends TestCase
## Harbor Ward (design/act-3.md): no Lattice anywhere in it but the city's ferry slip and the border
## plaza. Off the slip the Steward has no say: no path, the map is your own scan, the light is the
## Wardfolk's, and muting changes nothing (what you can find included). At the border its path takes up
## again. Setting off for the Ward, Noor goes ahead.

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _open() -> void:
	level = (load("res://game/level/harbor_ward.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func test_the_lattice_reaches_only_the_slip_and_the_border() -> void:
	await _open()
	check(level.grid.validate(false, false).is_empty() and level.grid.content_problems().is_empty(), "%s" % [level.grid.validate(false, false)])
	check_false(level.has_lattice())
	check(level.grid.validate(false, true).size() > 0, "the Reliquary can't be reached along the Lattice from the slip: on foot only")
	var start := level.grid.start_cell()
	for c: Vector2i in level.grid.all_cells():
		if level.grid.is_indexed(c):
			check(Vector2(c).distance_to(Vector2(start)) <= 4.0 or c.x >= 34, "%s on the Lattice: only the slip and the border" % c)
	check(level.grid.is_indexed(start), "the ferry slip is the city's")
	check_false(level.grid.is_indexed(Vector2i(16, 19)), "Net Lane isn't")


func test_off_the_slip_the_steward_has_no_say() -> void:
	await _open()
	await _put(Vector2i(7, 24))
	await wait_physics_frames(60)
	check_false(Steward.covered, "out of its reach")
	check(level.predicted_path.shown.is_empty(), "no path")
	var map := level.hud.minimap
	check_eq(map.mode(), Assists.MapMode.HAND_SCAN, "the map is your own scan, voice on")
	check(map.charted_label().contains("NO LATTICE"))
	check_near(level.lighting.grade_amount(), 0.0, 0.001, "the light is the Wardfolk's: never graded")
	var cache: TruthCache = null
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n is TruthCache and level.is_ancestor_of(n):
			cache = n
	check(cache != null and cache.is_present(), "the dashcam is there for you, voice on")
	Steward.set_voice(false)
	await wait_physics_frames(80)
	check_eq(map.mode(), Assists.MapMode.HAND_SCAN, "muted: the same map")
	check_near(level.lighting.grade_amount(), 0.0, 0.001, "muted: the same light")
	check(cache.is_present(), "muted: the same finds")


func test_at_the_border_its_path_takes_up_again() -> void:
	await _open()
	check(level.predictor.goal.x >= 0, "the path has somewhere to go, though the slip's Lattice doesn't run there")
	await _put(Vector2i(37, 20))
	await wait_physics_frames(30)
	check(Steward.covered, "back on the Lattice")
	check_eq(level.predicted_path.shown.size(), Tunables.PATH_TILES_AHEAD, "its path, three tiles ahead")
	for c: Vector2i in level.predicted_path.shown:
		check(level.grid.is_indexed(c), "%s on the Lattice" % c)
	check(level.lighting.steward_lit(), "and its light")


func test_setting_off_for_the_ward_noor_goes_ahead() -> void:
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	var ark := level as ArkLevel
	check(ark.noor != null, "Noor's on the Ark")
	var map := ark.open_city_map()
	await wait_frames(2)
	map.choose("harbor")
	check_eq(map.chosen, "harbor", "the Ward is open after two of Act 2's three")
	map.call(&"_go_to_chosen")
	await wait_frames(2)
	check(map.departure != null, "at the dock, Noor first")
	check(GameState.run.noor_away, "she's gone ahead")
	check_false(GameState.run.companion_here(RunState.WHO_NOOR), "not on the Ark")
	check(GameState.run.noor_present, "but still with you, for now")
	var loaded := RunState.from_dict(GameState.run.to_dict())
	check(loaded.noor_away, "saved")
	# (Closing it sets off for the Ward, which would leave the test's scene: just take it away.)
	map.departure.queue_free()
	await wait_frames(2)


func test_with_noor_away_the_ark_has_no_noor_and_no_conversations() -> void:
	GameState.noor_leaves_for_ward()
	level = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	check((level as ArkLevel).noor == null, "she isn't there")
	check((level as ArkLevel).teo != null, "Teo is")
	check_eq(GameState.run.pending_conversation(), "", "no talking it over without her")


## The Ward's own mast, dark on the boat-house roof by the gate; the Wardfolk out on Net Lane, who'll talk
## (about the curfew, about Noor going by), and who come to the Commons once it's built.
func test_the_wards_mast_and_its_people() -> void:
	await _open()
	var masts: Array[BuildingCell] = []
	for n: Node in level.world.get_children():
		if n is BuildingCell and (n as BuildingCell).roof_mast:
			masts.append(n)
	check(masts.size() == 1 and masts[0].mast_dark, "one mast, dark")
	var folk: Array[ArkFigure] = []
	for n: Node in level.world.get_children():
		if n is ArkFigure and (n as ArkFigure).who == ArkFigure.Who.WARDFOLK:
			folk.append(n)
	check_eq(folk.size(), 2, "two of the Wardfolk on Net Lane")
	for f: ArkFigure in folk:
		check(f.is_present(), "there for you, voice on")
		check_eq(f.current_line(), CommonsPeople.wardfolk_line(f.wardfolk_index, GameState.run, true), "the Ward's own words")
		check(f.current_line() != CommonsPeople.wardfolk_line(f.wardfolk_index, GameState.run), "not what they say on the Ark")
	folk[0].interact(level.player)
	check(folk[0].spoken_line() != "", "talked to, they answer")


## The Warden-Prime is the Steward's (DECISIONS 191): out on the Ward's lanes across the fence it doesn't
## see you, however close (fighting the patrol by the gate, winding the mast's generator); on its Lattice
## at the border it does.
func test_the_prime_sees_you_only_on_its_lattice() -> void:
	GameState.noor_leaves_for_ward()
	level = (load("res://game/level/harbor_ward.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	var prime := level.boss as WardenPrime
	check(prime != null, "the Prime")
	if prime == null:
		return
	var lane := Vector2i(33, 20)
	check_false(level.grid.is_indexed(lane), "the lane is the Ward's")
	level.player.set_physics_process(false)
	level.player.position = Iso.cell_center(lane) + Iso.ground_velocity(Vector2(1, 0), 0.3)
	await wait_physics_frames(2)
	check_eq(level.player.cell(), lane)
	check(Iso.ground_distance(level.player.global_position, prime.global_position) < Boss.ENGAGE_TILES, "within its reach")
	await wait_physics_frames(30)
	check_false(prime.is_engaged, "from the lane it doesn't see you")
	level.player.position = Iso.cell_center(Vector2i(36, 20))
	await wait_physics_frames(5)
	check(prime.is_engaged, "on its Lattice it does")
	level.player.set_physics_process(true)

