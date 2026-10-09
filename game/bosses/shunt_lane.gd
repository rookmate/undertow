class_name ShuntLane
extends Node2D
## One of the Conductor's tracks: a straight run of cells it sends a carriage down. Its warning lights
## flicker red-orange (danger) before a run; the carriage sweeps the whole lane and hits anyone on it.

const CARRIAGE_SECONDS := 0.7
const DAMAGE := 18.0

## The lane's cells, in the order the carriage passes them.
var cells: Array[Vector2i] = []
## "left", "middle" or "right", as the Operator sees them on screen.
var side: String = ""
var level: Level
## 0..1 while the warning shows (how lit the lights are), -1 when not warning.
var warning: float = -1.0
## 0..1 along the lane while a carriage is running, -1 when not.
var run: float = -1.0
var _struck: bool = false


func setup(owner_level: Level, lane_cells: Array[Vector2i], lane_side: String) -> void:
	level = owner_level
	cells = lane_cells
	side = lane_side
	z_index = -11


func has_cell(c: Vector2i) -> bool:
	return cells.has(c)


func warn(amount: float) -> void:
	warning = amount
	queue_redraw()


func fire() -> void:
	warning = -1.0
	run = 0.0
	_struck = false
	Sound.play(&"carriage_run", Iso.cell_center(cells[0]))


func is_running() -> bool:
	return run >= 0.0


func _physics_process(delta: float) -> void:
	if run < 0.0:
		return
	run += delta / CARRIAGE_SECONDS
	var p := level.player if level != null else null
	if p != null and p.is_alive() and not _struck and has_cell(p.cell()):
		var front := _at(run)
		if Iso.ground_distance(front, p.global_position) < 1.1:
			_struck = true
			p.take_hit(DAMAGE, front - Iso.ground_velocity(_direction(), 1.0))
	if run >= 1.0:
		run = -1.0
	queue_redraw()


func _direction() -> Vector2:
	return Iso.ground_dir_between(Iso.cell_center(cells[0]), Iso.cell_center(cells[cells.size() - 1]))


func _at(t: float) -> Vector2:
	var a := Iso.cell_center(cells[0])
	var b := Iso.cell_center(cells[cells.size() - 1])
	return a.lerp(b, clampf(t, 0.0, 1.0))


func _draw() -> void:
	if warning >= 0.0:
		var on := fmod(Time.get_ticks_msec() / 1000.0, 0.24) < 0.14
		for c: Vector2i in cells:
			var p := Iso.cell_center(c)
			draw_circle(p, 6.0, Color(Palette.DANGER, (0.35 + 0.65 * warning) if on else 0.2), true, -1.0, true)
	if run >= 0.0:
		# A runaway carriage: a dark box with its headlamps, sweeping the lane.
		var front := _at(run)
		var dir := _direction()
		var back := front - Iso.ground_velocity(dir, 2.2)
		var side_v := Iso.ground_velocity(Vector2(-dir.y, dir.x), 0.5)
		var body := PackedVector2Array([back - side_v, front - side_v, front + side_v, back + side_v])
		var up := Vector2(0, -60)
		draw_colored_polygon(PackedVector2Array([body[0] + up, body[1] + up, body[2] + up, body[3] + up]), Palette.IRON_DARK.lightened(0.15))
		draw_colored_polygon(PackedVector2Array([body[1], body[2], body[2] + up, body[1] + up]), Palette.IRON_DARK)
		draw_colored_polygon(PackedVector2Array([body[2], body[3], body[3] + up, body[2] + up]), Palette.IRON_DARK.darkened(0.2))
		draw_circle(front + Vector2(0, -24), 6.0, Palette.HUMAN_CREAM, true, -1.0, true)
