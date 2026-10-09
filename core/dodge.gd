class_name Dodge
extends RefCounted
## The Operator's dodge roll as a small state machine, separate from the node so it can be tested.
## A roll lasts DURATION, is invulnerable for the first INVULNERABLE seconds and can't be repeated
## until COOLDOWN has passed since it started.

const DURATION := 0.3
const INVULNERABLE := 0.24
const COOLDOWN := 0.55
## Ground speed during the roll, tiles per second.
const SPEED := 8.0

## Ground (grid-space) direction of the roll.
var direction: Vector2 = Vector2.ZERO
var _time_since_start: float = INF


func try_start(dir: Vector2) -> bool:
	if not can_start() or dir.length_squared() < 0.0001:
		return false
	direction = dir.normalized()
	_time_since_start = 0.0
	return true


func can_start() -> bool:
	return _time_since_start >= COOLDOWN


func update(delta: float) -> void:
	_time_since_start += delta


func is_rolling() -> bool:
	return _time_since_start < DURATION


func is_invulnerable() -> bool:
	return _time_since_start < INVULNERABLE


## 0 → 1 over the roll; 1 when not rolling.
func progress() -> float:
	return clampf(_time_since_start / DURATION, 0.0, 1.0)


func velocity() -> Vector2:
	if not is_rolling():
		return Vector2.ZERO
	# Fast out of the start, easing into the end of the roll.
	var ease_out := 1.0 - progress() * 0.55
	return Iso.ground_velocity(direction, SPEED * ease_out)
