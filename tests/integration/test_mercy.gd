extends TestCase
## Mercy General: sealed wards the Steward keeps shut and you crank open by hand (muted), Sterilizers and
## their mist, the Defib Gauntlet home in the resus bay, the night nurses' station off the Lattice, and
## the Reliquary that offers Log 0417 on the path.

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks"]:
		GameState.complete_level(district)
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://game/level/mercy_general.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	Input.action_release(&"interact")
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _seals() -> Array[WardSeal]:
	var out: Array[WardSeal] = []
	for n: Node in level.world.get_children():
		if n is WardSeal:
			out.append(n as WardSeal)
	return out


func _put(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_physics_frames(1)
	Input.action_release(&"interact")
	await wait_physics_frames(1)


func test_mercy_general_is_a_real_district() -> void:
	check(level.grid.validate(false).is_empty() and level.grid.content_problems().is_empty(), "%s" % [level.grid.validate(false)])
	check_eq(level.look.wall, Palette.WARD_WALL, "white walls gone grey")
	check_false(level.look.rain, "indoors, no rain")
	check(LevelCatalog.is_open(GameState.run, "mercy"), "open once Act 1 is done")
	check_eq(LevelCatalog.restores("mercy"), "clinic")
	check_eq(CoreChoice.offer("mercy", GameState.run).size(), 3)
	check(CoreChoice.offer("mercy", GameState.run).has("mercy_truth_0417"), "Log 0417 is on the path, in the Reliquary")


## While it listens the seal holds and the Steward says why; muted, Interact cranks it open, for good.
func test_a_sealed_ward_opens_only_by_hand() -> void:
	var seal := _seals()[0]
	await _put(seal.cell + Vector2i(-1, 0))
	check(level.nearest_interactable(level.player.global_position) == seal, "the seal is what's in reach")
	await _press_interact()
	check(seal.sealed, "the seal holds while it listens")
	check_eq(Sound.voice_line, "ward_sealed", "and it says so, aloud")
	check(level.grid.is_walkable(seal.cell), "the doorway itself is floor; the seal is what's in the way")
	Steward.set_voice(false)
	await wait_frames(1)
	await _press_interact()
	check_false(seal.sealed, "muted, the crank turns")
	Steward.set_voice(true)
	await wait_frames(2)
	check_false(seal.sealed, "and it stays open when the Steward comes back")
	# Walk through where the seal stood.
	level.player.position = Iso.cell_center(seal.cell + Vector2i(-1, 0))
	Controls.device = Controls.Device.PAD
	Input.action_press(&"move_right", 1.0)
	Input.action_press(&"move_down", 1.0)
	await wait_physics_frames(40)
	Input.action_release(&"move_right")
	Input.action_release(&"move_down")
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	check(level.player.cell().x > seal.cell.x, "through the open door: %s" % [level.player.cell()])


func test_a_sterilizers_mist_stings_until_it_clears() -> void:
	level.remove_all_enemies()
	await _put(Vector2i(7, 10))
	var s := level.add_enemy(Sterilizer.new(), Vector2i(7, 8), Sterilizer.MAX_INTEGRITY) as Sterilizer
	var before := level.player.integrity.value
	var waited := 0
	while _clouds().is_empty() and waited < 240:
		await wait_physics_frames(1)
		waited += 1
	check_false(_clouds().is_empty(), "it winds up and lets its mist go")
	var cloud := _clouds()[0]
	check(cloud.covers(level.player.global_position), "over you")
	await wait_seconds(1.0)
	var stung := before - level.player.integrity.value
	check(stung >= SterileCloud.TICK_DAMAGE * 2.0, "it stings, tick after tick (%.1f)" % stung)
	s.queue_free()
	await wait_seconds(SterileCloud.SECONDS)
	check_false(is_instance_valid(cloud), "then it clears")


## It stings in ticks, so a roll through it evades them.
func test_a_roll_through_the_mist_evades_its_sting() -> void:
	level.remove_all_enemies()
	await _put(Vector2i(7, 10))
	var cloud := SterileCloud.new()
	cloud.setup(level, level.player.global_position)
	level.player.dodge.try_start(Vector2(0, 1))
	level.fx_ground.add_child(cloud)
	var before := level.player.integrity.value
	await wait_physics_frames(3)
	check(level.player.is_invulnerable(), "mid-roll")
	check_eq(level.player.integrity.value, before, "the sting misses you mid-roll")
	cloud.queue_free()


func _clouds() -> Array[SterileCloud]:
	var out: Array[SterileCloud] = []
	for n: Node in level.fx_ground.get_children():
		if n is SterileCloud and not n.is_queued_for_deletion():
			out.append(n as SterileCloud)
	return out


## Its own district's find: the Gauntlet on a crash cart in the resus bay, beside the corridor.
func test_the_defib_gauntlet_is_found_here() -> void:
	var find: WeaponFind = null
	for n: Node in level.world.get_children():
		if n is WeaponFind:
			find = n
	check(find != null and find.weapon_id == WeaponDefs.DEFIB)
	check(level.grid.reachable_from(level.grid.start_cell()).has(find.cell), "you can walk to it")
	find.interact(level.player)
	check(GameState.run.weapons_owned.has(WeaponDefs.DEFIB), "yours from now on")
	check_eq(Sound.voice_line, "find_defib_gauntlet", "the Steward has a view on it")


## The night nurses kept paper: their station is off the Lattice, and the Steward loses you there.
func test_the_night_nurses_station_is_off_the_lattice() -> void:
	var cache := level.grid.first("T")
	check_false(level.grid.is_indexed(cache + Vector2i(-1, 0)), "staff floor, not on the Steward's map")
	check_false(level.grid.reachable_from(level.grid.start_cell(), true).has(cache + Vector2i(-1, 0)), "and the Steward can't route you there")
	await _put(cache + Vector2i(-1, 0))
	await wait_seconds(Level.COVERAGE_GRACE + 0.3)
	check(Steward.assists().signal_lost, "no signal at the nurses' desk")
