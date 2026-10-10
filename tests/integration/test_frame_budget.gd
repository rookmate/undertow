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
