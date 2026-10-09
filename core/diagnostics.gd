class_name Diagnostics
extends RefCounted
## Where broken content and maps are reported: the engine's error log. A test that breaks something on
## purpose captures these reports instead and checks them, so every other error still fails the test
## and the gate's log scan stays strict.

static var _captured: PackedStringArray = []
static var _capturing: bool = false


static func error(message: String) -> void:
	if _capturing:
		_captured.append(message)
	else:
		push_error(message)


## Starts holding reports back (tests only).
static func capture() -> void:
	_capturing = true
	_captured = PackedStringArray()


## Stops capturing and returns what was reported meanwhile.
static func release() -> PackedStringArray:
	_capturing = false
	var out := _captured
	_captured = PackedStringArray()
	return out
