class_name UnindexedLog
extends Interactable
## A paper slip the Steward never read: unindexed, so it can't route you to it. Picking it up files it in
## the Archive. Faint truth cyan, because you found it yourself.

var log_id: String = ""
var taken: bool = false
var _t: float = 0.0


func setup(owner_level: Level, cell: Vector2i, id: String) -> void:
	level = owner_level
	log_id = id
	off_path = true
	position = Iso.cell_center(cell)
	taken = GameState.run.logs_unlocked.has(id)


func can_interact() -> bool:
	return is_present() and not taken


func prompt_verb() -> String:
	return "READ THE SLIP"


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	taken = true
	Sound.play(&"truth_find", global_position)
	GameState.unlock_log(log_id)


func _process(delta: float) -> void:
	_t += delta
	visible = is_present() and not taken
	queue_redraw()


func _draw() -> void:
	var pulse := 0.35 + 0.25 * sin(_t * 2.0)
	draw_colored_polygon(Fx.ground_ellipse(0.38, 20, false), Color(Palette.TRUTH_CYAN, 0.12 * pulse))
	var sheet := PackedVector2Array([Vector2(-22, -2), Vector2(4, -16), Vector2(24, -4), Vector2(-2, 10)])
	draw_colored_polygon(sheet, Palette.PAPER)
	for k: int in 3:
		var y := -6.0 + k * 4.0
		draw_line(Vector2(-12, y + 2), Vector2(10, y - 10), Color(Palette.GREY_DEEP, 0.7), 1.0)
	var loop := sheet.duplicate()
	loop.append(sheet[0])
	draw_polyline(loop, Color(Palette.TRUTH_CYAN, pulse), 1.5, true)
