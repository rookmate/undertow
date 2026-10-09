class_name Integrity
extends RefCounted
## Health for the Operator and the city's machines ("integrity", as the world bible calls it).

signal changed(value: float, max_value: float)
signal depleted

var max_value: float
var value: float


func _init(maximum: float = 100.0) -> void:
	max_value = maxf(maximum, 1.0)
	value = max_value


## Applies damage and returns how much was actually taken.
func take(amount: float) -> float:
	if amount <= 0.0 or value <= 0.0:
		return 0.0
	var taken := minf(amount, value)
	value -= taken
	changed.emit(value, max_value)
	if value <= 0.0:
		depleted.emit()
	return taken


func heal(amount: float) -> void:
	if amount <= 0.0 or value <= 0.0:
		return
	value = minf(max_value, value + amount)
	changed.emit(value, max_value)


func reset() -> void:
	value = max_value
	changed.emit(value, max_value)


func is_depleted() -> bool:
	return value <= 0.0


func ratio() -> float:
	return value / max_value
