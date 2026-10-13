class_name ToolDoor
extends Interactable
## A door one of the Ark's tools opens (ToolDoors, DECISIONS 188): a Steward lock the Signal Jammer
## jams, a dead lift the Defib Gauntlet jolts. You need the tool with you, in your loadout; without it the
## door says what would open it. Opened, it stays open. While what's behind it is still there to find,
## it glows through the gap at the sill in truth cyan.

var door_id: String = ""
var cell: Vector2i
var _body: StaticBody2D
## 0..1 as the door swings back.
var _open_amount: float = 0.0
var _t: float = 0.0


func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	door_id = id
	cell = at
	position = Iso.cell_center(at)
	if is_open():
		_open_amount = 1.0
		return
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	var pts := PackedVector2Array()
	for p: Vector2 in Iso.cell_diamond(at):
		pts.append(p - position)
	poly.points = pts
	shape.shape = poly
	_body.add_child(shape)
	add_child(_body)


func is_open() -> bool:
	return GameState.run.doors_opened.has(door_id)


## Whether the Operator has its tool with them (in the loadout they set off with).
func carrying_tool() -> bool:
	if level == null or level.player == null:
		return false
	for w: Weapon in level.player.weapons:
		if w.weapon_id == ToolDoors.tool(door_id):
			return true
	return false


func can_interact() -> bool:
	return not is_open() and carrying_tool()


func prompt_verb() -> String:
	return ToolDoors.text(door_id, "verb")


func blocked_reason() -> String:
	if is_open() or carrying_tool():
		return ""
	return ToolDoors.text(door_id, "bring" if GameState.run.weapons_owned.has(ToolDoors.tool(door_id)) else "locked")


## What's behind it is still there to find.
func still_behind() -> bool:
	var core := ToolDoors.truth(door_id)
	var r := GameState.run
	return not (r.truth_core_ids.has(core) or r.found_core_ids.has(core) or r.cores_left.has(core))


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	GameState.open_door(door_id)
	if _body != null:
		_body.queue_free()
		_body = null
	Sound.play(&"seal_crank", global_position)
	var line := ToolDoors.text(door_id, "steward")
	if line != "":
		Narrator.say_fixed(line)
	var t := create_tween()
	t.tween_property(self, "_open_amount", 1.0, 0.8)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var hw := Iso.HALF_W * 0.85
	var h := 96.0
	# The frame: two posts and a lintel.
	for x: float in [-hw, hw]:
		draw_rect(Rect2(Vector2(x - 5, -h), Vector2(10, h)), Palette.IRON_DARK)
	draw_line(Vector2(-hw, -h), Vector2(hw, -h), Palette.IRON_DARK, 8.0, true)
	# The leaf swings back as it opens.
	var leaf := hw * 2.0 * (1.0 - _open_amount)
	if leaf > 2.0:
		draw_rect(Rect2(Vector2(-hw + 5, -h + 6), Vector2(leaf - 10, h - 6)), Palette.STONE_OLD.darkened(0.35))
		draw_rect(Rect2(Vector2(-hw + 5, -h + 6), Vector2(leaf - 10, h - 6)), Palette.IRON_DARK, false, 2.0)
		# Its lock plate, by the handle.
		draw_rect(Rect2(Vector2(-hw + leaf - 22, -h * 0.55), Vector2(10, 16)), Palette.GREY_COLD)
	# What's behind it, still there: a glow through the gap at the sill.
	if still_behind():
		var a := 0.25 + 0.15 * sin(_t * 2.0)
		draw_line(Vector2(-hw + 6, -2), Vector2(hw - 6, -2), Color(Palette.TRUTH_CYAN, a), 4.0, true)
