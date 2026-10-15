class_name SterileCloud
extends Node2D
## A Sterilizer's mist: it hangs where it was let go for a few seconds and drains the Integrity of
## anything standing in it (the hospital still treats you as contamination). It stings in ticks, so a
## roll through it evades them (Operator.take_hit). Pale mist, its edge in red-orange: a danger.

const RADIUS_TILES := 1.35
const SECONDS := 3.5
const TICK := 0.35
const TICK_DAMAGE := 2.5

var level: Level
var _left: float = SECONDS
var _tick: float = 0.0


func setup(owner_level: Level, at: Vector2) -> void:
	level = owner_level
	position = at


## In it: within its reach, and nothing solid between (a wall cuts the mist off).
func covers(at: Vector2) -> bool:
	return _left > 0.0 and Iso.ground_distance(at, global_position) <= RADIUS_TILES \
			and (level == null or level.grid.line_clear(global_position, at))


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	_tick -= delta
	var p := level.player if level != null else null
	if _tick <= 0.0 and p != null and p.is_alive() and covers(p.global_position):
		_tick = TICK
		p.take_hit(TICK_DAMAGE, global_position)
	queue_redraw()


func _draw() -> void:
	var fade := clampf(_left / 0.6, 0.0, 1.0) * clampf((SECONDS - _left) / 0.25, 0.0, 1.0)
	draw_colored_polygon(Fx.ground_ellipse(RADIUS_TILES, 28, false), Color(Palette.STERILE_MIST, 0.22 * fade))
	draw_colored_polygon(Fx.ground_ellipse(RADIUS_TILES * 0.6, 20, false), Color(Palette.STERILE_MIST, 0.16 * fade))
	draw_polyline(Fx.ground_ellipse(RADIUS_TILES, 28), Color(Palette.DANGER, 0.5 * fade), 2.0, true)
