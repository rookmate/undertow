class_name TestCase
extends Node
## Base class for tests. The runner calls every method whose name starts with `test_`, in file order,
## between before_each() and after_each(). Tests may `await`.

var current_test: String = ""
var _failures: PackedStringArray = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func take_failures() -> PackedStringArray:
	var out := _failures
	_failures = PackedStringArray()
	return out


func fail(message: String) -> void:
	_failures.append("%s: %s" % [current_test, message])


func check(condition: bool, message: String = "expected true") -> void:
	if not condition:
		fail(message)


func check_false(condition: bool, message: String = "expected false") -> void:
	if condition:
		fail(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _same(actual, expected):
		fail("%s expected <%s> got <%s>" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, epsilon: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		fail("%s expected %.5f ± %.5f, got %.5f" % [message, expected, epsilon, actual])


func wait_frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func wait_physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func wait_seconds(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


## Waits, a physics frame at a time, until `condition` holds or `timeout` seconds of game time pass (the
## runner's frames are fixed, not real time: the game's own clock is what a boss counts). Returns whether
## it held.
func wait_until(condition: Callable, timeout: float) -> bool:
	var spent := 0.0
	while not condition.call():
		if spent > timeout:
			return false
		await get_tree().physics_frame
		spent += get_physics_process_delta_time()
	return true


static func _same(a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numeric and typeof(b) in numeric:
		return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		if (a is String or a is StringName) and (b is String or b is StringName):
			return str(a) == str(b)
		return false
	return a == b
