class_name OperatorGait
extends RefCounted
## A distance clock and two opposing feet. The planted half of each stride travels backwards
## at the body's speed; the other half passes forward with a lifted toe.

const STRIDE_TILES := 1.6
var phase: float = 0.0
var weight: float = 0.0
var direction: Vector2 = Vector2(1, 0)
var _turn_offsets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]


func advance(travel_world: Vector2, walking: bool, delta: float) -> void:
	var travel := Iso.world_to_grid(travel_world)
	var moving := walking and travel.length_squared() > 0.000001
	var old_weight := weight
	var old_phase := phase
	var old_direction := direction
	var contacts: Array[Vector2] = [_ground_foot(0) + _turn_offsets[0], _ground_foot(1) + _turn_offsets[1]]
	weight = move_toward(weight, 1.0 if moving else 0.0, delta * 10.0)
	if moving:
		direction = travel.normalized()
		phase = fposmod(phase + travel.length() / STRIDE_TILES, 1.0)
	for leg: int in 2:
		if not moving:
			_turn_offsets[leg] *= weight / old_weight if old_weight > 0.0 else 0.0
			continue
		var p := _leg_phase(phase, leg)
		var old_p := _leg_phase(old_phase, leg)
		if p < 0.5 and old_weight >= 1.0:
			# Keep the support point in world space even when movement reverses. Rebase the
			# local trajectory rather than teleporting the foot to the new heading's contact.
			if old_p < 0.5 or not direction.is_equal_approx(old_direction):
				_turn_offsets[leg] = contacts[leg] - travel_world - _ground_foot(leg)
		else:
			if old_weight > 0.0:
				_turn_offsets[leg] += Iso.grid_to_world(old_direction - direction) * _along(p) * STRIDE_TILES * 0.25 * weight
			# Blend while lifted. If a turn arrives just before landing, carry the residual
			# into that contact instead of snapping it away at the phase boundary.
			_turn_offsets[leg] *= exp(-delta * 14.0)


func foot(opposite: bool) -> Vector2:
	var leg := 1 if opposite else 0
	var p := _leg_phase(phase, leg)
	var lift := sin((p - 0.5) * TAU) * 9.0 if p >= 0.5 else 0.0
	return _ground_foot(leg) + _turn_offsets[leg] - Vector2(0, lift * weight)


func _ground_foot(leg: int) -> Vector2:
	return Iso.grid_to_world(direction * _along(_leg_phase(phase, leg)) * STRIDE_TILES * 0.25) * weight


static func _leg_phase(cycle: float, leg: int) -> float:
	return fposmod(cycle + float(leg) * 0.5, 1.0)


static func _along(p: float) -> float:
	return 1.0 - p * 4.0 if p < 0.5 else lerpf(-1.0, 1.0, smoothstep(0.0, 1.0, (p - 0.5) * 2.0))


func bob() -> float:
	return cos(phase * TAU * 2.0) * 2.0 * weight
