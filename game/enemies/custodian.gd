class_name Custodian
extends Enemy
## A floor-cleaning unit that scrubs one tile forever and attacks anything it classifies as debris.
## Weak, numerous. White shell, green panels, a lamp dome (image 10).

const MAX_INTEGRITY := 26.0
const WINDUP := 0.55
const LUNGE := 0.16
const RECOVER := 0.6
const REACH := 1.0
const DAMAGE := 8.0
const LUNGE_SPEED := 7.0

var _scrub: float = 0.0
var _struck: bool = false


func _ready() -> void:
	radius_tiles = 0.38
	speed_tiles = 2.3
	aggro_tiles = 3.8
	_scrub = randf() * TAU


func windup_seconds() -> float:
	return WINDUP * windup_scale


func _think(delta: float) -> Vector2:
	var p := player()
	var dist := distance_to_player()
	var player_ok := p != null and p.is_alive()
	match state:
		State.IDLE:
			_scrub += delta * 2.2
			if player_ok and dist <= aggro_tiles:
				_enter(State.CHASE)
				return Vector2.ZERO
			var orbit := home + Iso.grid_to_world(Vector2.from_angle(_scrub) * 0.35)
			return Iso.ground_velocity(Iso.ground_dir_between(global_position, orbit), 0.8)
		State.CHASE:
			if not player_ok or dist > leash_tiles:
				_enter(State.RECOVER)
				return Vector2.ZERO
			face_player()
			if dist <= REACH:
				_enter(State.WINDUP)
				return Vector2.ZERO
			return steer_to(p.global_position, delta)
		State.WINDUP:
			face_player()
			if _state_time >= windup_seconds():
				_struck = false
				_enter(State.ATTACK)
			return Vector2.ZERO
		State.ATTACK:
			if not _struck and _state_time >= LUNGE * 0.6 and player_ok:
				_struck = true
				if CombatMath.in_arc(global_position, facing_ground, p.global_position, REACH + 0.2, 130.0, Operator.RADIUS_TILES) and level.grid.line_clear(global_position, p.global_position):
					p.take_hit(DAMAGE, global_position)
			if _state_time >= LUNGE:
				_enter(State.RECOVER)
			return Iso.ground_velocity(facing_ground, LUNGE_SPEED)
		State.RECOVER:
			if _state_time >= RECOVER:
				if player_ok and dist <= leash_tiles:
					_enter(State.CHASE)
				else:
					# Back to scrubbing; idle orbits drift it home.
					_enter(State.IDLE)
			return Vector2.ZERO
	return Vector2.ZERO


func _draw() -> void:
	draw_shadow(34.0, 15.0)
	draw_windup_ring(REACH)
	draw_polyline(Fx.ground_ellipse(0.42, 20), Color(Palette.FOG, 0.18), 2.0, true)
	paint_body("custodian", 84.0)
	var lamp := Palette.DANGER if state == State.WINDUP or state == State.ATTACK else Palette.STEWARD_GOLD
	draw_circle(body_anchor("custodian", "lamp", 84.0), 4.0, Color(lamp.r * 1.5, lamp.g * 1.5, lamp.b * 1.5), true, -1.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
