extends TestCase
## Doors the Ark's tools open (DECISIONS 188): each placed once in its district with the truth it keeps
## behind it, out of reach on foot until it opens; it opens only with its tool in your loadout, and says
## what would open it otherwise; opened, it stays open (saved), and the Steward has its word.

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _open_kestrel() -> void:
	if level != null:
		level.queue_free()
		await wait_frames(2)
	level = (load(LevelCatalog.scene_of("kestrel")) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)


func _door() -> ToolDoor:
	for n: Node in level.world.get_children():
		if n is ToolDoor:
			return n
	return null


func test_the_words_are_all_there() -> void:
	check(ToolDoors.problems().is_empty(), "%s" % [ToolDoors.problems()])
	check(ToolDoors.ids().size() >= 3, "a door for each tool to open: %s" % [ToolDoors.ids()])


func test_every_door_keeps_its_truth_out_of_reach_until_it_opens() -> void:
	var placed: Dictionary[String, String] = {}
	for id: String in LevelCatalog.LEVELS:
		var g := LevelGrid.load_file(LevelCatalog.map_of(id))
		for c: Vector2i in g.cells_with(Tiles.TOOL_DOOR):
			var door := g.entity_id(c)
			check(ToolDoors.has(door), "%s: %s is a door" % [id, door])
			check_false(placed.has(door), "%s placed once" % door)
			placed[door] = id
			var truth := ToolDoors.truth(door)
			var at := Vector2i(-1, -1)
			for t: Vector2i in g.cells_with("T"):
				if g.entity_id(t) == truth:
					at = t
			check(at.x >= 0, "%s: %s is behind it" % [id, truth])
			if at.x < 0:
				continue
			check_false(g.is_indexed(at), "%s: off the Lattice" % truth)
			var start := g.first("P")
			var shut := g.reachable_from(start, false, Tiles.TOOL_DOOR)
			var open := g.reachable_from(start, false)
			var near := func(seen: Dictionary[Vector2i, bool]) -> bool:
				for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
					if seen.has(at + d):
						return true
				return false
			check_false(near.call(shut), "%s: out of reach while the door's shut" % truth)
			check(near.call(open), "%s: on foot once it's open" % truth)
	for door: String in ToolDoors.ids():
		check(placed.has(door), "%s is in its district" % door)


func test_it_says_what_would_open_it() -> void:
	await _open_kestrel()
	var door := _door()
	check(door != null and not door.is_open(), "the gatehouse door, shut")
	check_false(door.can_interact(), "nothing to open it with")
	check_eq(door.blocked_reason(), ToolDoors.text("kestrel_gatehouse", "locked"))
	GameState.give_weapon(WeaponDefs.SIGNAL_JAMMER)
	check_eq(door.blocked_reason(), ToolDoors.text("kestrel_gatehouse", "bring"), "the Jammer's on the Ark, not with you")
	check(door.still_behind(), "what it keeps is still there")


func test_its_tool_opens_it_and_it_stays_open() -> void:
	GameState.give_weapon(WeaponDefs.SIGNAL_JAMMER)
	var kit: Array[String] = [WeaponDefs.BATON, WeaponDefs.SIGNAL_JAMMER]
	GameState.run.loadout = kit
	await _open_kestrel()
	var door := _door()
	check(door.carrying_tool(), "the Jammer in the loadout")
	check(door.can_interact())
	check_eq(door.prompt_verb(), "JAM THE LOCK")
	level.player.position = Iso.cell_center(door.cell + Vector2i(0, -1))
	await wait_physics_frames(2)
	door.interact(level.player)
	check(door.is_open() and GameState.run.doors_opened.has("kestrel_gatehouse"), "jammed open")
	check_eq(Narrator.last_line_id, "kestrel_gate_jammed", "and the Steward has its word")
	check(door.get("_body") == null, "nothing in the doorway now")
	check(not level.enemy_nav.path(door.cell + Vector2i(0, -1), door.cell + Vector2i(0, 2)).is_empty(), "a way through")
	var back := RunState.from_dict(GameState.run.to_dict())
	check(back.doors_opened.has("kestrel_gatehouse"), "saved")
	await _open_kestrel()
	check(_door().is_open() and not _door().can_interact(), "still open next time")
