extends Node
## Input map (keyboard/mouse and controller for every gameplay action), last-used-device tracking and
## button-prompt labels. The map is defined here rather than in project.godot so it is readable and
## testable (tests/unit/test_controls.gd). Each rebindable action's first keyboard/mouse binding and first
## controller binding can be changed in Options; the other defaults (arrow keys, J/K, the d-pad) stay.

signal device_changed(device: Device)
## Any binding changed (rebound, reset, loaded): prompts read off bindings refresh on this.
signal bindings_changed

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
	&"use_item": [["key", KEY_Q], ["pad_button", JOY_BUTTON_LEFT_SHOULDER]],
	&"pause": [["key", KEY_ESCAPE], ["pad_button", JOY_BUTTON_START]],
	&"debug_overlay": [["key", KEY_F3]],
}

## Spare inputs, by slot, for an action whose default a player's earlier choice already uses (an action
## added after they chose: Act 2's use_item on Q / LB): it moves to the first one free.
const SPARES: Dictionary[String, Array] = {
	"kb": [["key", KEY_F], ["key", KEY_R], ["key", KEY_G], ["key", KEY_C], ["key", KEY_X]],
	"pad": [["pad_button", JOY_BUTTON_RIGHT_SHOULDER], ["pad_button", JOY_BUTTON_B]],
}

## Actions that must be reachable on both keyboard/mouse and controller. The debug overlay is
## reached on a pad through the Back+R3 chord handled below.
const GAMEPLAY_ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down",
	&"attack_primary", &"attack_secondary", &"dodge", &"interact", &"voice_toggle", &"use_item", &"pause",
]

## Actions the player can rebind (Options). Pause stays on Esc / Start so nobody can lock themselves out.
const REBINDABLE: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"attack_primary", &"attack_secondary", &"dodge", &"interact", &"voice_toggle", &"use_item",
]

## Prompt labels for actions whose prompt isn't read off their bindings. Placeholder text glyphs until
## real button art exists.
const PROMPTS: Dictionary[StringName, Array] = {
	&"pause": ["ESC", "START"],
	&"debug_overlay": ["F3", "BACK+R3"],
	&"ui_accept": ["ENTER", "A"],
	&"ui_cancel": ["ESC", "B"],
}

const PAD_BUTTON_NAMES: Dictionary[int, String] = {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_BACK: "BACK", JOY_BUTTON_START: "START",
	JOY_BUTTON_DPAD_UP: "D-UP", JOY_BUTTON_DPAD_DOWN: "D-DOWN", JOY_BUTTON_DPAD_LEFT: "D-LEFT", JOY_BUTTON_DPAD_RIGHT: "D-RIGHT",
}

## The player's changes: action -> {"kb": binding, "pad": binding} (either may be missing).
var _overrides: Dictionary = {}

## The device prompts are shown for. Every change announces itself, however it's made (input, the
## autopilot, tests), so nothing showing prompts can go stale.
var device: Device = Device.KEYBOARD_MOUSE:
	set(value):
		if value != device:
			device = value
			device_changed.emit(device)


func _enter_tree() -> void:
	register_actions()


func register_actions() -> void:
	for action: StringName in BINDINGS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, 0.2)
		for binding: Array in bindings_for(action):
			InputMap.action_add_event(action, _make_event(binding))
	bindings_changed.emit()


## An action's bindings: its defaults, with the player's choice in place of the first keyboard/mouse one
## and the first controller one.
func bindings_for(action: StringName) -> Array:
	var out: Array = []
	var done := {"kb": false, "pad": false}
	var chosen: Dictionary = _overrides.get(action, {})
	for binding: Array in BINDINGS.get(action, []):
		var slot := slot_of(binding)
		if not done[slot] and chosen.has(slot):
			out.append(chosen[slot])
		else:
			out.append(binding)
		done[slot] = true
	return out


## "kb" for keys and mouse buttons, "pad" for controller buttons and sticks.
func slot_of(binding: Array) -> String:
	return "pad" if str(binding[0]).begins_with("pad") else "kb"


## The binding shown and rebound for an action on one kind of device ([] if it has none).
func primary(action: StringName, slot: String) -> Array:
	for binding: Array in bindings_for(action):
		if slot_of(binding) == slot:
			return binding
	return []


## Binds an action's keyboard/mouse or controller slot. Checked against every binding in effect, the
## kept defaults (arrow keys, J/K, the d-pad) and Esc / Start / F3 included: if another rebindable
## action's own choice for that slot uses the input, the two swap, so no action is left unreachable; if
## anything else uses it (blocker_for()), nothing changes. Returns whether it was bound.
func set_binding(action: StringName, binding: Array) -> bool:
	var wanted := normalized(binding)
	if not REBINDABLE.has(action) or wanted.is_empty():
		Diagnostics.error("Controls: can't bind %s to %s" % [action, binding])
		return false
	if blocker_for(action, wanted) != &"":
		return false
	var slot := slot_of(wanted)
	var previous := primary(action, slot)
	var holder := holder_of(wanted, action)
	if holder != &"":
		_set_override(holder, slot, previous)
	_set_override(action, slot, wanted)
	register_actions()
	return true


## The action that keeps `binding` if `action` asks for it, or &"" if it can have it. It can only swap
## with another rebindable action's own choice for that slot, and only if afterwards no input is shared
## (that action may also keep the input as a default: Move Up rebound to Up Arrow still has Up Arrow).
func blocker_for(action: StringName, binding: Array) -> StringName:
	var wanted := normalized(binding)
	var holder := holder_of(wanted, action)
	if holder == &"":
		return &""
	var slot := slot_of(wanted)
	var previous := primary(action, slot)
	if not REBINDABLE.has(holder) or primary(holder, slot) != wanted or previous.is_empty():
		return holder
	# Try the swap on the choices alone, see whether anything is shared, and put them back.
	var before := _overrides.duplicate(true)
	_set_override(holder, slot, previous)
	_set_override(action, slot, wanted)
	var shared := not conflicts().is_empty()
	_overrides = before
	return holder if shared else &""


## The other action that has `binding` among its bindings in effect, or &"".
func holder_of(binding: Array, except: StringName = &"") -> StringName:
	for other: StringName in BINDINGS:
		if other != except and bindings_for(other).has(binding):
			return other
	return &""


## Every input bound to more than one action ([binding, action, action] each). Empty, always: tests and
## loading check it.
func conflicts() -> Array:
	var out: Array = []
	var seen := {}
	for action: StringName in BINDINGS:
		for binding: Array in bindings_for(action):
			var key := str(binding)
			if seen.has(key) and seen[key] != action:
				out.append([binding, seen[key], action])
			seen[key] = action
	return out


func _set_override(action: StringName, slot: String, binding: Array) -> void:
	var chosen: Dictionary = _overrides.get(action, {})
	chosen[slot] = binding
	_overrides[action] = chosen


func overrides() -> Dictionary:
	return _overrides.duplicate(true)


## Loads saved choices. Anything that isn't a valid binding for a rebindable action is dropped. A choice
## that collides with another action's default (an action added since: Act 2's use_item on Q / LB) is
## kept, and that action moves to a free spare (SPARES). Any choice still sharing an input with another
## action is dropped (a damaged or hand-edited file).
func set_overrides(saved: Dictionary) -> void:
	_overrides = {}
	for action: Variant in saved:
		var chosen: Variant = saved[action]
		if not REBINDABLE.has(StringName(str(action))) or not chosen is Dictionary:
			continue
		for slot: Variant in chosen:
			var raw: Variant = (chosen as Dictionary)[slot]
			var binding := normalized(raw if raw is Array else [])
			if not binding.is_empty() and slot_of(binding) == str(slot):
				_set_override(StringName(str(action)), str(slot), binding)
	for clash: Array in conflicts():
		_move_default_aside(clash[0], clash[1], clash[2])
	var clashes := conflicts()
	while not clashes.is_empty():
		for clash: Array in clashes:
			for action: StringName in [clash[1], clash[2]]:
				var chosen: Dictionary = _overrides.get(action, {})
				chosen.erase(slot_of(clash[0]))
		clashes = conflicts()
	register_actions()


## If one of two actions holds `binding` as the player's choice and the other only as its default, the
## choice stays and the default moves to the first free spare for that slot (if there is one).
func _move_default_aside(binding: Array, a: StringName, b: StringName) -> void:
	var slot := slot_of(binding)
	for pair: Array in [[a, b], [b, a]]:
		var chooser: StringName = pair[0]
		var other: StringName = pair[1]
		var chose: bool = (_overrides.get(chooser, {}) as Dictionary).get(slot, []) == binding
		var other_chose: bool = (_overrides.get(other, {}) as Dictionary).has(slot)
		if not chose or other_chose or not REBINDABLE.has(other):
			continue
		for spare: Array in SPARES[slot]:
			if holder_of(spare) == &"":
				_set_override(other, slot, spare)
				return


func reset_bindings() -> void:
	_overrides = {}
	register_actions()


## A binding in its one canonical form (whole-number codes, a ±1.0 axis direction), or [] if it isn't a
## binding a player could make.
static func normalized(binding: Array) -> Array:
	if binding.size() != 2:
		return []
	var code: Variant = binding[1]
	match str(binding[0]):
		"key":
			if code is int and int(code) > 0 and OS.get_keycode_string(int(code)) != "":
				return ["key", int(code)]
		"mouse":
			if code is int and int(code) >= MOUSE_BUTTON_LEFT and int(code) <= MOUSE_BUTTON_XBUTTON2:
				return ["mouse", int(code)]
		"pad_button":
			if code is int and int(code) >= 0 and int(code) < JOY_BUTTON_SDL_MAX:
				return ["pad_button", int(code)]
		"pad_axis":
			if code is Array and (code as Array).size() == 2:
				var axis: Variant = code[0]
				var dir: Variant = code[1]
				if axis is int and int(axis) >= 0 and int(axis) < JOY_AXIS_SDL_MAX \
						and (dir is int or dir is float) and absf(absf(float(dir)) - 1.0) < 0.001:
					return ["pad_axis", [int(axis), signf(float(dir))]]
	return []


## How a binding is written in prompts: the key's name on this keyboard layout, LMB/RMB, A/B/X/Y, RT/LT.
func label_of(binding: Array) -> String:
	if binding.is_empty():
		return "—"
	match str(binding[0]):
		"key":
			# The name this keyboard layout prints on that key (a headless run has no layout to ask).
			var code := int(binding[1])
			if DisplayServer.get_name() != "headless":
				var mapped := DisplayServer.keyboard_get_keycode_from_physical(code)
				code = mapped if mapped != KEY_NONE else code
			return OS.get_keycode_string(code).to_upper()
		"mouse":
			return {MOUSE_BUTTON_LEFT: "LMB", MOUSE_BUTTON_RIGHT: "RMB", MOUSE_BUTTON_MIDDLE: "MMB",
				MOUSE_BUTTON_XBUTTON1: "M4", MOUSE_BUTTON_XBUTTON2: "M5"}.get(int(binding[1]), "MOUSE %d" % int(binding[1]))
		"pad_button":
			return PAD_BUTTON_NAMES.get(int(binding[1]), "BUTTON %d" % int(binding[1]))
		"pad_axis":
			var spec: Array = binding[1]
			var axis := int(spec[0])
			var positive := float(spec[1]) > 0.0
			match axis:
				JOY_AXIS_TRIGGER_LEFT:
					return "LT"
				JOY_AXIS_TRIGGER_RIGHT:
					return "RT"
				JOY_AXIS_LEFT_X:
					return "LS RIGHT" if positive else "LS LEFT"
				JOY_AXIS_LEFT_Y:
					return "LS DOWN" if positive else "LS UP"
				JOY_AXIS_RIGHT_X:
					return "RS RIGHT" if positive else "RS LEFT"
				JOY_AXIS_RIGHT_Y:
					return "RS DOWN" if positive else "RS UP"
	return "?"


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


## Short label for an action on the current device, e.g. "V" or "Y", read off its current binding.
func prompt(action: StringName) -> String:
	if PROMPTS.has(action):
		var labels: Array = PROMPTS[action]
		return labels[1] if using_pad() else labels[0]
	if BINDINGS.has(action):
		return label_of(primary(action, "pad" if using_pad() else "kb"))
	return String(action).to_upper()


## How moving is written in prompts, read off the bindings: the four keys in up-left-down-right order
## ("WASD", or "ZQSD" on an AZERTY keyboard, or whatever they were rebound to), "LEFT STICK" on a pad.
func move_prompt() -> String:
	var slot := "pad" if using_pad() else "kb"
	var labels: PackedStringArray = []
	var as_shipped := true
	for action: StringName in [&"move_up", &"move_left", &"move_down", &"move_right"]:
		labels.append(label_of(primary(action, slot)))
		as_shipped = as_shipped and primary(action, slot) == _shipped_primary(action, slot)
	if slot == "pad" and as_shipped:
		return "LEFT STICK"
	if Array(labels).all(func(l: String) -> bool: return l.length() == 1):
		return "".join(labels)
	return "/".join(labels)


func _shipped_primary(action: StringName, slot: String) -> Array:
	for binding: Array in BINDINGS.get(action, []):
		if slot_of(binding) == slot:
			return binding
	return []


func move_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func aim_stick() -> Vector2:
	return Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
