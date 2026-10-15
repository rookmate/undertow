class_name StrideCycle
extends RefCounted
## Distance-driven contacts for bipeds and tripods. Supporting feet counter actual body travel;
## one lifted foot passes forward while the other contacts stay planted.

const STRIDE_TILES := 1.6
var stride_tiles: float = STRIDE_TILES
var lift_height: float = 9.0
var leg_count: int = 2
var phase: float = 0.0
var weight: float = 0.0
var direction: Vector2 = Vector2(1, 0)
var _turn_offsets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]


func configure(stride: float, lift: float, legs: int = 2) -> void:
	stride_tiles = stride
	lift_height = lift
	leg_count = legs
	_turn_offsets.resize(legs)
	_turn_offsets.fill(Vector2.ZERO)


func advance(travel_world: Vector2, walking: bool, delta: float) -> void:
	var travel := Iso.world_to_grid(travel_world)
	var moving := walking and travel.length_squared() > 0.000001
	var old_weight := weight
	var old_phase := phase
	var old_direction := direction
	var contacts: Array[Vector2] = []
	for leg: int in leg_count:
		contacts.append(_ground_foot(leg) + _turn_offsets[leg])
	weight = move_toward(weight, 1.0 if moving else 0.0, delta * 10.0)
	if moving:
		direction = travel.normalized()
		phase = fposmod(phase + travel.length() / stride_tiles, 1.0)
	for leg: int in leg_count:
		if not moving:
			_turn_offsets[leg] *= weight / old_weight if old_weight > 0.0 else 0.0
			continue
		var p := _leg_phase(phase, leg)
		var old_p := _leg_phase(old_phase, leg)
		if p < stance_fraction() and old_weight >= 1.0:
			# Keep the support point in world space even when movement reverses. Rebase the
			# local trajectory rather than teleporting the foot to the new heading's contact.
			if old_p < stance_fraction() or not direction.is_equal_approx(old_direction):
				_turn_offsets[leg] = contacts[leg] - travel_world - _ground_foot(leg)
		else:
			if old_weight > 0.0:
				_turn_offsets[leg] += Iso.grid_to_world(old_direction - direction) * _along(p) * stride_tiles * stance_fraction() * 0.5 * weight
			# Blend while lifted. If a turn arrives just before landing, carry the residual
			# into that contact instead of snapping it away at the phase boundary.
			_turn_offsets[leg] *= exp(-delta * 14.0)


func foot(opposite: bool) -> Vector2:
	return foot_index(1 if opposite else 0)


func foot_index(leg: int) -> Vector2:
	var p := _leg_phase(phase, leg)
	var lift := sin((p - stance_fraction()) / (1.0 - stance_fraction()) * PI) * lift_height if p >= stance_fraction() else 0.0
	return _ground_foot(leg) + _turn_offsets[leg] - Vector2(0, lift * weight)


func _ground_foot(leg: int) -> Vector2:
	return Iso.grid_to_world(direction * _along(_leg_phase(phase, leg)) * stride_tiles * stance_fraction() * 0.5) * weight


func _leg_phase(cycle: float, leg: int) -> float:
	return fposmod(cycle + float(leg) / leg_count, 1.0)


func stance_fraction() -> float:
	return 1.0 - 1.0 / leg_count


func _along(p: float) -> float:
	var stance := stance_fraction()
	return 1.0 - p * 2.0 / stance if p < stance else lerpf(-1.0, 1.0, smoothstep(0.0, 1.0, (p - stance) / (1.0 - stance)))


func bob() -> float:
	return cos(phase * TAU * leg_count) * 2.0 * weight
