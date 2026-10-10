extends TestCase
## Things that never change mustn't redo their work every frame. Every district's static props (walls
## of containers, glass partitions, beds) once redrew themselves every frame: Godot switches processing
## on at _ready for any script with a _process, undoing a set_process(false) made before that.


func test_props_that_never_move_dont_redraw_every_frame() -> void:
	GameState.new_run()
	for id: String in LevelCatalog.LEVELS:
		var level := (load(LevelCatalog.scene_of(id)) as PackedScene).instantiate() as Level
		add_child(level)
		await wait_frames(2)
		var busy := 0
		for n: Node in level.world.get_children():
			var prop := n as StaticProp
			if prop == null:
				continue
			if StaticProp.MOVING.has(prop.kind):
				check(prop.is_processing(), "%s: what moves (a sprinkler, a turbine) still moves" % id)
			elif prop.is_processing():
				busy += 1
		check_eq(busy, 0, "%s: no still prop is processing" % id)
		level.queue_free()
		await wait_frames(2)


## The floor is drawn in small blocks, so Godot skips the ones off screen: every cell in exactly one
## block, none bigger than FloorLayer.CHUNK a side, none drawing again after the first frame. (One canvas
## item for the whole Vellum, its river and its newsroom, cost 46 fps where every other district ran at 60.)
func test_the_floor_is_drawn_in_blocks_that_cover_every_cell_once() -> void:
	GameState.new_run()
	for id: String in LevelCatalog.LEVELS:
		var level := (load(LevelCatalog.scene_of(id)) as PackedScene).instantiate() as Level
		add_child(level)
		await wait_frames(2)
		var seen: Dictionary[Vector2i, int] = {}
		var blocks := 0
		for n: Node in level.get_children():
			var block := n as FloorLayer
			if block == null:
				continue
			blocks += 1
			check(block.region.size.x <= FloorLayer.CHUNK and block.region.size.y <= FloorLayer.CHUNK and block.region.size.x > 0, "%s: %s is a small block" % [id, block.region])
			check_false(block.is_processing(), "%s: a floor block draws once" % id)
			for y: int in range(block.region.position.y, block.region.end.y):
				for x: int in range(block.region.position.x, block.region.end.x):
					seen[Vector2i(x, y)] = seen.get(Vector2i(x, y), 0) + 1
		check(blocks > 1, "%s: more than one block (%d)" % [id, blocks])
		check_eq(seen.size(), level.grid.size.x * level.grid.size.y, "%s: every cell is drawn" % id)
		check(seen.values().all(func(k: int) -> bool: return k == 1), "%s: and only once" % id)
		level.queue_free()
		await wait_frames(2)
