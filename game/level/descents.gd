class_name Descents
extends Node
## Holds, the ways down they open, the doors the Ark's tools open, and the descents below the street
## (design/deeper-districts.md, DECISIONS 181, 188): placing them from the map, going down and back up,
## and what's still to find down there.

var level: Level


func setup(owner_level: Level) -> void:
	level = owner_level


## The cranks, the ladders and the tool doors on the map; and the dark, if there's a descent.
func build() -> void:
	var grid := level.grid
	for c: Vector2i in grid.cells_with(Tiles.CRANK):
		var hold := Hold.new()
		hold.setup(level, c, grid.entity_id(c))
		level.world.add_child(hold)
	for c: Vector2i in grid.cells_with(Tiles.LADDER):
		var way := Passage.new()
		way.setup(level, c, grid.entity_id(c))
		level.world.add_child(way)
	for c: Vector2i in grid.cells_with(Tiles.TOOL_DOOR):
		var door := ToolDoor.new()
		door.setup(level, c, grid.entity_id(c))
		level.world.add_child(door)
	if grid.all_cells().any(func(c: Vector2i) -> bool: return grid.floor_at(c) == LevelGrid.Floor.CULVERT):
		level.descent_dark = DescentDark.new()
		level.descent_dark.level = level
		level.add_child(level.descent_dark)


## The hold running now (the HUD shows it), or null.
func running_hold() -> Hold:
	for n: Node in level.world.get_children():
		if n is Hold and (n as Hold).running:
			return n
	return null


## You went down: a hold you were running starts over.
func reset_holds() -> void:
	for n: Node in level.world.get_children():
		if n is Hold:
			(n as Hold).reset()


## The passage end with this id ("<name>_down" / "<name>_up"), or null.
func passage(passage_id: String) -> Passage:
	for n: Node in level.world.get_children():
		if n is Passage and (n as Passage).passage_id == passage_id:
			return n
	return null


## Down or back up: a short fade, and you're at the other end, beside its ladder.
func take_passage(from: Passage) -> void:
	var to := passage(from.partner_id())
	var player := level.player
	if to == null or player == null:
		return
	var fade := CanvasLayer.new()
	fade.layer = 40
	var black := ColorRect.new()
	black.color = Color(Palette.NEAR_BLACK, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.add_child(black)
	level.add_child(fade)
	Sound.play(&"dressing", player.global_position)
	var t := create_tween()
	t.tween_property(black, "color:a", 1.0, 0.18)
	t.tween_callback(func() -> void:
		var landing := to.cell
		for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if level.grid.is_walkable(to.cell + d) and not level.grid.is_occupied(to.cell + d):
				landing = to.cell + d
				break
		player.position = Iso.cell_center(landing)
		level.camera.reset_smoothing())
	t.tween_property(black, "color:a", 0.0, 0.25)
	t.tween_callback(fade.queue_free)


## Standing on a descent's floor (below the street).
func in_descent() -> bool:
	return level.player != null and level.grid.floor_at(level.player.cell()) == LevelGrid.Floor.CULVERT


## Unindexed things still to find down in the descents (what glows up through a shut way down).
func finds_left() -> int:
	var n := 0
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := node as Interactable
		if it != null and it.off_path and it.still_to_find() and level.is_ancestor_of(it) \
				and level.grid.floor_at(Iso.world_to_cell(it.global_position)) == LevelGrid.Floor.CULVERT:
			n += 1
	return n
