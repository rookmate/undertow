extends TestCase
## Noor's Mast (design/act-3.md): with it on the Ark, a district's map rings every unindexed place still
## to find, on the Steward's map and your own scan alike, and what you've found drops off. Without it,
## nothing is marked.

var level: Level


func before_each() -> void:
	GameState.new_run()
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
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func _still_to_find() -> Array[Interactable]:
	var out: Array[Interactable] = []
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := n as Interactable
		if it != null and level.is_ancestor_of(it) and it.off_path and it.still_to_find():
			out.append(it)
	return out


func test_without_the_mast_nothing_is_marked() -> void:
	await _open()
	await wait_frames(10)
	check(level.unindexed_to_find().is_empty())
	check(level.hud.minimap.mast_marks().is_empty(), "no marks on the map")


func test_with_the_mast_the_map_rings_what_is_still_to_find() -> void:
	GameState.restore_building(GameState.MAST)
	await _open()
	var things := _still_to_find()
	check(things.size() >= 3, "the Vellum's unindexed places: the stacks' cache, slips, the Waiting (%d)" % things.size())
	await wait_frames(10)
	var map := level.hud.minimap
	check_eq(map.mode(), Assists.MapMode.STEWARD, "voice on: the Steward's map")
	check_eq(map.mast_marks().size(), things.size(), "every one ringed on it all the same")
	Steward.set_voice(false)
	await wait_frames(10)
	check_eq(map.mode(), Assists.MapMode.HAND_SCAN)
	check_eq(map.mast_marks().size(), things.size(), "muted: the same marks")
	var cache: TruthCache = null
	for it: Interactable in things:
		if it is TruthCache:
			cache = it
	check(cache != null, "a truth cache among them")
	cache.interact(level.player)
	await wait_frames(10)
	check_eq(map.mast_marks().size(), things.size() - 1, "found: off the map")
