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
## How far its brushes reach past its body: the blow lands on what they reach along the way it actually
## went (stopped short by another machine, it doesn't hit you from where it meant to be).
const BRUSH_TILES := 0.35

var _scrub: float = 0.0
var _struck: bool = false
## Where its lunge set off from, and the way it committed to as the windup ran out.
var _lunge_from: Vector2 = Vector2.ZERO
var _lunge_dir: Vector2 = Vector2(0, 1)


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
				_lunge_from = global_position
				_lunge_dir = facing_ground
				_enter(State.ATTACK)
			return Vector2.ZERO
		State.ATTACK:
			# The blow lands where it was aimed: judged from where the lunge set off, along the way it
			# committed to (not from wherever it ends up), once it meets you or is most of the way through,
			# and for as long as the lunge lasts: you walking into it late still meets it.
			var touching := player_ok and dist <= radius_tiles + Operator.RADIUS_TILES + 0.05
			if not _struck and player_ok and (touching or _state_time >= LUNGE * 0.6) \
					and _swept_distance(p.global_position) <= radius_tiles + BRUSH_TILES + Operator.RADIUS_TILES \
					and CombatMath.in_arc(_lunge_from, _lunge_dir, p.global_position, REACH + 0.25, 130.0, Operator.RADIUS_TILES) \
					and level.grid.line_clear(_lunge_from, p.global_position):
				_struck = true
				p.take_hit(DAMAGE, global_position)
			if _state_time >= LUNGE:
				_enter(State.RECOVER)
				return Vector2.ZERO
			# It stops against what it meets (the Operator's body too), not through it.
			return Iso.ground_velocity(_lunge_dir, LUNGE_SPEED)
		State.RECOVER:
			if _state_time >= RECOVER:
				if player_ok and dist <= leash_tiles:
					_enter(State.CHASE)
				else:
					# Back to scrubbing; idle orbits drift it home.
					_enter(State.IDLE)
			return Vector2.ZERO
	return Vector2.ZERO


func draw_ground(ci: CanvasItem) -> void:
	shadow_on(ci, 34.0, 15.0)
	windup_ring_on(ci, REACH)
	ci.draw_polyline(Fx.ground_ellipse(0.42, 20), Color(Palette.FOG, 0.18), 2.0, true)


## How near `at` comes to the ground it has actually covered in this lunge (from where it set off to
## where it is now), in tiles.
func _swept_distance(at: Vector2) -> float:
	var a := Iso.world_to_grid(_lunge_from)
	var ab := Iso.world_to_grid(global_position) - a
	var c := Iso.world_to_grid(at)
	var t := 0.0 if ab.length_squared() < 0.000001 else clampf((c - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return c.distance_to(a + ab * t)


func _draw() -> void:
	var compression := absf(attack_pose()) * 3.0
	paint_body("custodian", 84.0 - compression)
	var lamp := Palette.DANGER if state == State.WINDUP or state == State.ATTACK else Palette.STEWARD_GOLD
	draw_circle(body_anchor("custodian", "lamp", 84.0 - compression), 4.0, Color(lamp.r * 1.5, lamp.g * 1.5, lamp.b * 1.5), true, -1.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
