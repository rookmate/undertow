class_name OptionsScreen
extends CanvasLayer
## Options, from the title and the pause menu: volumes, display, subtitle size, and controls. Every
## change takes effect and is saved at once (if the save fails, a notice says the change lasts this
## session only). Works with a mouse, the keyboard or a pad throughout: sliders move with left/right, and
## a binding is changed by selecting it and pressing the new input (Esc or Start cancels). An input
## another action keeps (an arrow key, J/K, the d-pad, F3) is refused, and the screen says whose it is.

signal closed

const ACTION_NAMES: Dictionary[StringName, String] = {
	&"move_up": "MOVE UP", &"move_down": "MOVE DOWN", &"move_left": "MOVE LEFT", &"move_right": "MOVE RIGHT",
	&"attack_primary": "WEAPON 1", &"attack_secondary": "WEAPON 2", &"dodge": "DODGE",
	&"interact": "INTERACT", &"voice_toggle": "STEWARD ON / OFF", &"use_item": "FIELD DRESSING",
	&"pause": "PAUSE", &"debug_overlay": "THE DEBUG OVERLAY",
	&"aim_left": "AIM", &"aim_right": "AIM", &"aim_up": "AIM", &"aim_down": "AIM",
}
const NOT_SAVED := "Your settings are in effect now, but couldn't be saved: next time they'll be as they were."
const BUS_NAMES: Dictionary[StringName, String] = {
	&"Master": "MASTER", &"Music": "MUSIC", &"Ambience": "AMBIENCE", &"SFX": "EFFECTS",
	&"Steward": "THE STEWARD'S VOICE", &"UI": "INTERFACE",
}
## Seconds to wait for the new input before giving up.
const LISTEN_SECONDS := 6.0

## The binding being changed: {action, slot, button}, empty when not listening.
var listening: Dictionary = {}
var _listen_left: float = 0.0
var _sliders: Dictionary[StringName, HSlider] = {}
var _binding_buttons: Dictionary[String, Button] = {}
var _window_button: Button
var _vsync_button: Button
var _subtitle_button: Button
var _flashing_button: Button
var _back: Button
## Why the last rebind didn't happen, or "".
var _status: Label
var _not_saved: SaveFailure


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Opaque: the title's wordmark is HDR-bright and shows through any translucent backing.
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label("OPTIONS", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(160, 70)
	add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(160, 170)
	scroll.size = Vector2(1600, 760)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	column.custom_minimum_size = Vector2(1560, 0)
	scroll.add_child(column)
	_section(column, "SOUND")
	for bus: StringName in Options.VOLUME_DEFAULTS:
		_volume_row(column, bus)
	_section(column, "DISPLAY")
	_window_button = _choice_row(column, "WINDOW", _cycle_window)
	_vsync_button = _choice_row(column, "VSYNC", _toggle_vsync)
	_section(column, "SUBTITLES")
	_subtitle_button = _choice_row(column, "SIZE", _cycle_subtitles)
	_section(column, "ACCESSIBILITY")
	_flashing_button = _choice_row(column, "REDUCE FLASHING", _toggle_flashing)
	_section(column, "CONTROLS")
	var head := HBoxContainer.new()
	head.add_child(_cell(_label("", UiFonts.mono(), 16, Palette.IVORY_DIM), 420))
	head.add_child(_cell(_label("KEYBOARD / MOUSE", UiFonts.mono_medium(), 16, Palette.IVORY_DIM), 300))
	head.add_child(_cell(_label("CONTROLLER", UiFonts.mono_medium(), 16, Palette.IVORY_DIM), 300))
	column.add_child(head)
	for action: StringName in Controls.REBINDABLE:
		_binding_row(column, action)
	var reset := Button.new()
	reset.text = "RESET CONTROLS"
	reset.custom_minimum_size = Vector2(320, 52)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_reset_controls)
	column.add_child(reset)
	var note := _label("Pause stays on Esc / Start.", UiFonts.mono(), 16, Palette.IVORY_DIM)
	column.add_child(note)
	_back = Button.new()
	_back.text = "BACK"
	_back.position = Vector2(160, 960)
	_back.custom_minimum_size = Vector2(240, 56)
	_back.pressed.connect(close)
	add_child(_back)
	_status = _label("", UiFonts.mono_medium(), 18, Palette.IVORY)
	_status.position = Vector2(440, 976)
	add_child(_status)
	_refresh()
	Modals.push(self)
	(_sliders[&"Master"] as Control).grab_focus()


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _cell(c: Control, width: float) -> Control:
	c.custom_minimum_size = Vector2(width, 48)
	if c is Label:
		(c as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return c


func _section(column: VBoxContainer, text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	column.add_child(gap)
	column.add_child(_label(text, UiFonts.heading(), 34, Palette.IVORY))


func _volume_row(column: VBoxContainer, bus: StringName) -> void:
	var row := HBoxContainer.new()
	row.add_child(_cell(_label(BUS_NAMES[bus], UiFonts.mono_medium(), 20, Palette.IVORY), 420))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(520, 48)
	slider.focus_mode = Control.FOCUS_ALL
	var value := _label("", UiFonts.mono(), 20, Palette.IVORY_DIM)
	slider.value_changed.connect(func(v: float) -> void:
		value.text = "%d%%" % roundi(v * 100.0)
		if not is_equal_approx(Options.volumes[bus], v):
			Options.set_volume(bus, v)
			_save())
	row.add_child(slider)
	row.add_child(_cell(value, 120))
	column.add_child(row)
	_sliders[bus] = slider


func _choice_row(column: VBoxContainer, text: String, on_press: Callable) -> Button:
	var row := HBoxContainer.new()
	row.add_child(_cell(_label(text, UiFonts.mono_medium(), 20, Palette.IVORY), 420))
	var b := Button.new()
	b.custom_minimum_size = Vector2(300, 48)
	b.pressed.connect(on_press)
	row.add_child(b)
	column.add_child(row)
	return b


func _binding_row(column: VBoxContainer, action: StringName) -> void:
	var row := HBoxContainer.new()
	row.add_child(_cell(_label(ACTION_NAMES[action], UiFonts.mono_medium(), 20, Palette.IVORY), 420))
	for slot: String in ["kb", "pad"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(280, 48)
		b.pressed.connect(_listen.bind(action, slot, b))
		row.add_child(b)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(20, 0)
		row.add_child(gap)
		_binding_buttons["%s/%s" % [action, slot]] = b
	column.add_child(row)


func _refresh() -> void:
	for bus: StringName in _sliders:
		_sliders[bus].set_value_no_signal(Options.volumes[bus])
		_sliders[bus].value_changed.emit(Options.volumes[bus])
	_window_button.text = Options.display_mode.to_upper()
	_vsync_button.text = "ON" if Options.vsync else "OFF"
	_subtitle_button.text = Options.subtitle_size.to_upper()
	_flashing_button.text = "ON" if Options.reduce_flashing else "OFF"
	for key: String in _binding_buttons:
		var action := StringName(key.get_slice("/", 0))
		var slot := key.get_slice("/", 1)
		_binding_buttons[key].text = Controls.label_of(Controls.primary(action, slot))


func _cycle_window() -> void:
	var i := Options.DISPLAY_MODES.find(Options.display_mode)
	Options.display_mode = Options.DISPLAY_MODES[(i + 1) % Options.DISPLAY_MODES.size()]
	_changed()


func _toggle_vsync() -> void:
	Options.vsync = not Options.vsync
	_changed()


func _cycle_subtitles() -> void:
	var sizes := Options.SUBTITLE_SIZES.keys()
	Options.subtitle_size = str(sizes[(sizes.find(Options.subtitle_size) + 1) % sizes.size()])
	_changed()


func _toggle_flashing() -> void:
	Options.reduce_flashing = not Options.reduce_flashing
	_changed()


func _reset_controls() -> void:
	Controls.reset_bindings()
	_changed()


func _changed() -> void:
	Options.apply()
	_save()
	_refresh()


## Saves the settings; if that fails, one notice says so.
func _save() -> void:
	var err := Options.save_settings()
	if err != OK and not is_instance_valid(_not_saved):
		_not_saved = SaveFailure.notice(get_tree(), err, NOT_SAVED)


## Waits for the next input of the slot's kind and binds it.
func _listen(action: StringName, slot: String, button: Button) -> void:
	if not listening.is_empty():
		return
	listening = {"action": action, "slot": slot, "button": button}
	_listen_left = LISTEN_SECONDS
	button.text = "PRESS A KEY…" if slot == "kb" else "PRESS A BUTTON…"


func _process(delta: float) -> void:
	if listening.is_empty():
		return
	_listen_left -= delta
	if _listen_left <= 0.0:
		_stop_listening()


func _stop_listening() -> void:
	var button: Button = listening.get("button")
	listening = {}
	_refresh()
	if is_instance_valid(button):
		button.grab_focus()


func _input(event: InputEvent) -> void:
	if listening.is_empty() or not event.is_pressed() or event.is_echo():
		return
	var binding := binding_from(event, str(listening["slot"]))
	var cancel := (event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE) \
		or (event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START)
	if binding.is_empty() and not cancel:
		return
	get_viewport().set_input_as_handled()
	if not cancel:
		var action: StringName = listening["action"]
		var keeper := Controls.blocker_for(action, binding)
		if keeper != &"":
			_status.text = "%s STAYS ON %s." % [Controls.label_of(binding), ACTION_NAMES.get(keeper, String(keeper).to_upper())]
		elif Controls.set_binding(action, binding):
			_status.text = ""
			_save()
	_stop_listening()


## The binding an input event would make for a slot ("kb" or "pad"), or [] if it can't be one.
static func binding_from(event: InputEvent, slot: String) -> Array:
	if slot == "kb":
		if event is InputEventKey and (event as InputEventKey).physical_keycode != KEY_ESCAPE:
			return ["key", int((event as InputEventKey).physical_keycode)]
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
				return ["mouse", int(mb.button_index)]
	else:
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index != JOY_BUTTON_START:
			return ["pad_button", int((event as InputEventJoypadButton).button_index)]
		if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.6:
			var m := event as InputEventJoypadMotion
			return ["pad_axis", [int(m.axis), signf(m.axis_value)]]
	return []


func _unhandled_input(event: InputEvent) -> void:
	if listening.is_empty() and Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if not listening.is_empty():
		return
	Sound.play(&"ui_back")
	_save()
	Modals.pop(self)
	closed.emit()
	queue_free()
