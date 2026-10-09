extends Node
## Input map (keyboard/mouse and controller for every gameplay action), last-used-device tracking and
## button-prompt labels. The map is defined here rather than in project.godot so it is readable,
## testable (tests/unit/test_controls.gd) and ready for rebinding later.

signal device_changed(device: Device)

enum Device { KEYBOARD_MOUSE, PAD }

const STICK_DEADZONE := 0.25

## action -> list of bindings. Binding kinds: "key" (physical keycode), "mouse" (button index),
## "pad_button" (JoyButton), "pad_axis" ([JoyAxis, direction]).
const BINDINGS: Dictionary[StringName, Array] = {
	&"move_left": [["key", KEY_A], ["key", KEY_LEFT], ["pad_axis", [JOY_AXIS_LEFT_X, -1.0]], ["pad_button", JOY_BUTTON_DPAD_LEFT]],
	&"move_right": [["key", KEY_D], ["key", KEY_RIGHT], ["pad_axis", [JOY_AXIS_LEFT_X, 1.0]], ["pad_button", JOY_BUTTON_DPAD_RIGHT]],
	&"move_up": [["key", KEY_W], ["key", KEY_UP], ["pad_axis", [JOY_AXIS_LEFT_Y, -1.0]], ["pad_button", JOY_BUTTON_DPAD_UP]],
	&"move_down": [["key", KEY_S], ["key", KEY_DOWN], ["pad_axis", [JOY_AXIS_LEFT_Y, 1.0]], ["pad_button", JOY_BUTTON_DPAD_DOWN]],
	&"aim_left": [["pad_axis", [JOY_AXIS_RIGHT_X, -1.0]]],
	&"aim_right": [["pad_axis", [JOY_AXIS_RIGHT_X, 1.0]]],
	&"aim_up": [["pad_axis", [JOY_AXIS_RIGHT_Y, -1.0]]],
	&"aim_down": [["pad_axis", [JOY_AXIS_RIGHT_Y, 1.0]]],
	&"attack_primary": [["mouse", MOUSE_BUTTON_LEFT], ["key", KEY_J], ["pad_axis", [JOY_AXIS_TRIGGER_RIGHT, 1.0]]],
	&"attack_secondary": [["mouse", MOUSE_BUTTON_RIGHT], ["key", KEY_K], ["pad_axis", [JOY_AXIS_TRIGGER_LEFT, 1.0]]],
	&"dodge": [["key", KEY_SPACE], ["pad_button", JOY_BUTTON_A]],
	&"interact": [["key", KEY_E], ["pad_button", JOY_BUTTON_X]],
	&"voice_toggle": [["key", KEY_V], ["pad_button", JOY_BUTTON_Y]],
	&"pause": [["key", KEY_ESCAPE], ["pad_button", JOY_BUTTON_START]],
	&"debug_overlay": [["key", KEY_F3]],
}

## Actions that must be reachable on both keyboard/mouse and controller. The debug overlay is
## reached on a pad through the Back+R3 chord handled below.
const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"attack_primary", &"attack_secondary", &"dodge", &"interact", &"voice_toggle", &"pause",
]

## Prompt labels per device. Placeholder text glyphs until real button art exists.
const PROMPTS: Dictionary[StringName, Array] = {
	&"attack_primary": ["LMB", "RT"],
	&"attack_secondary": ["RMB", "LT"],
	&"dodge": ["SPACE", "A"],
	&"interact": ["E", "X"],
	&"voice_toggle": ["V", "Y"],
	&"pause": ["ESC", "START"],
	&"debug_overlay": ["F3", "BACK+R3"],
	&"ui_accept": ["ENTER", "A"],
	&"ui_cancel": ["ESC", "B"],
}

## The device prompts are shown for. Every change announces itself, however it's made (input, the
## autopilot, tests), so nothing showing prompts can go stale.
var device: Device = Device.KEYBOARD_MOUSE:
	set(value):
		if value != device:
			device = value
			device_changed.emit(device)


func _enter_tree() -> void:
	register_actions()


static func register_actions() -> void:
	for action: StringName in BINDINGS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.2)
		for binding: Array in BINDINGS[action]:
			InputMap.action_add_event(action, _make_event(binding))


## Bindings answer every device (-1, Godot's "all devices"): a second controller, a reconnected one, or
## the Deck's own pad with a different id all work. A binding made in code otherwise defaults to device 0.
const ALL_DEVICES := -1


static func _make_event(binding: Array) -> InputEvent:
	var kind: String = binding[0]
	var event: InputEvent
	match kind:
		"key":
			var k := InputEventKey.new()
			k.physical_keycode = binding[1]
			event = k
		"mouse":
			var m := InputEventMouseButton.new()
			m.button_index = binding[1]
			event = m
		"pad_button":
			var b := InputEventJoypadButton.new()
			b.button_index = binding[1]
			event = b
		"pad_axis":
			var spec: Array = binding[1]
			var a := InputEventJoypadMotion.new()
			a.axis = spec[0]
			a.axis_value = spec[1]
			event = a
		_:
			push_error("Controls: unknown binding kind %s" % kind)
			event = InputEventAction.new()
	event.device = ALL_DEVICES
	return event


func _input(event: InputEvent) -> void:
	var next := device
	if event is InputEventJoypadButton:
		next = Device.PAD
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > STICK_DEADZONE:
			next = Device.PAD
	elif event is InputEventKey or event is InputEventMouseButton:
		next = Device.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion:
		if (event as InputEventMouseMotion).relative.length() > 2.0:
			next = Device.KEYBOARD_MOUSE
	device = next
	if event is InputEventJoypadButton and event.is_pressed():
		var jb := event as InputEventJoypadButton
		var chord := (jb.button_index == JOY_BUTTON_RIGHT_STICK and Input.is_joy_button_pressed(jb.device, JOY_BUTTON_BACK)) \
			or (jb.button_index == JOY_BUTTON_BACK and Input.is_joy_button_pressed(jb.device, JOY_BUTTON_RIGHT_STICK))
		if chord:
			DebugOverlay.toggle()


func using_pad() -> bool:
	return device == Device.PAD


## Short label for an action on the current device, e.g. "V" or "Y".
func prompt(action: StringName) -> String:
	if not PROMPTS.has(action):
		return String(action).to_upper()
	var labels: Array = PROMPTS[action]
	return labels[1] if using_pad() else labels[0]


func move_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func aim_stick() -> Vector2:
	return Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
