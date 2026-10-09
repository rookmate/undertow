extends TestCase
## Options: settings persist, take effect at once, and controls can be rebound without losing any action.

const PATH := "user://test_options.cfg"


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Options.use_path(PATH)


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	Options.use_path("user://test_settings.cfg")
	Options.apply()
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	await wait_frames(1)


func _press_key(code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await wait_frames(1)
	var up := e.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)


func test_settings_are_saved_and_come_back() -> void:
	Options.set_volume(&"SFX", 0.4)
	Options.subtitle_size = "large"
	Controls.set_binding(&"dodge", ["key", KEY_Q])
	check_eq(Options.save_settings(), OK)
	Options.reset_all()
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_SPACE], "reset to defaults")
	Options.load_settings()
	check_near(Options.volumes[&"SFX"], 0.4, 0.0001)
	check_eq(Options.subtitle_size, "large")
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_Q], "the rebound dodge came back")


func test_volumes_set_the_buses() -> void:
	Options.set_volume(&"Steward", 0.25)
	check_near(Sound.volume(&"Steward"), 0.25, 0.001)


func test_a_rebound_key_drives_the_action_and_its_prompt() -> void:
	Controls.set_binding(&"dodge", ["key", KEY_Q])
	var q := InputEventKey.new()
	q.physical_keycode = KEY_Q
	q.pressed = true
	check(q.is_action(&"dodge"), "Q dodges")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	check_false(space.is_action(&"dodge"), "Space no longer does")
	check_eq(Controls.prompt(&"dodge"), "Q", "and the prompts say so")
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	check(b.is_action(&"dodge"), "the controller binding is untouched")


func test_binding_a_taken_input_swaps_so_nothing_is_lost() -> void:
	Controls.set_binding(&"interact", ["key", KEY_SPACE])
	check_eq(Controls.primary(&"interact", "kb"), ["key", KEY_SPACE])
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_E], "dodge took interact's old key")
	Controls.set_binding(&"dodge", ["pad_button", JOY_BUTTON_X])
	check_eq(Controls.primary(&"interact", "pad"), ["pad_button", JOY_BUTTON_A], "and on the controller too")
	Controls.device = Controls.Device.PAD
	check_eq(Controls.prompt(&"dodge"), "X")


func test_pause_cannot_be_rebound_and_bad_saved_bindings_are_dropped() -> void:
	Diagnostics.capture()
	Controls.set_binding(&"pause", ["key", KEY_P])
	check_eq(Diagnostics.release().size(), 1, "refused and reported")
	Controls.set_overrides({"dodge": {"kb": ["key", "not a key"], "pad": ["key", KEY_Z]}, "pause": {"kb": ["key", KEY_P]}, "nonsense": 5})
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_SPACE], "a malformed binding is ignored")
	check_eq(Controls.primary(&"dodge", "pad"), ["pad_button", JOY_BUTTON_A], "a key can't sit in the controller slot")
	check_eq(Controls.prompt(&"pause"), "ESC")


func test_the_options_screen_rebinds_with_the_next_key_and_esc_cancels() -> void:
	var screen := OptionsScreen.new()
	add_child(screen)
	await wait_frames(2)
	check(Modals.is_top(screen) and get_tree().paused, "it's a screen of its own")
	var buttons: Dictionary = screen.get("_binding_buttons")
	var dodge_kb: Button = buttons["dodge/kb"]
	check_eq(dodge_kb.text, "SPACE")
	dodge_kb.pressed.emit()
	check_eq(dodge_kb.text, "PRESS A KEY…")
	await _press_key(KEY_L)
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_L], "the next key is the new binding")
	check_eq(dodge_kb.text, "L")
	(buttons["interact/kb"] as Button).pressed.emit()
	await _press_key(KEY_ESCAPE)
	check_eq(Controls.primary(&"interact", "kb"), ["key", KEY_E], "Esc cancels")
	check(is_instance_valid(screen) and screen.is_inside_tree(), "and doesn't close the screen")
	var cfg := ConfigFile.new()
	check_eq(cfg.load(PATH), OK, "saved straight away")
	screen.close()
	await wait_frames(1)
	check_false(get_tree().paused)


func test_the_options_screen_sliders_set_the_volume() -> void:
	var screen := OptionsScreen.new()
	add_child(screen)
	await wait_frames(2)
	var sliders: Dictionary = screen.get("_sliders")
	(sliders[&"Music"] as HSlider).value = 0.3
	check_near(Options.volumes[&"Music"], 0.3, 0.001)
	check_near(Sound.volume(&"Music"), 0.3, 0.001)
	screen.close()


func test_options_open_from_the_pause_menu_and_close_back_to_it() -> void:
	GameState.new_run()
	var level := (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	var pause: PauseMenu = null
	for c: Node in level.get_children():
		if c is PauseMenu:
			pause = c
	pause.open()
	await wait_frames(1)
	var options_button: Button = null
	for b: Node in pause.find_children("*", "Button", true, false):
		if (b as Button).text == "OPTIONS":
			options_button = b
	options_button.grab_focus()
	options_button.pressed.emit()
	await wait_frames(2)
	var screen: OptionsScreen = null
	for c: Node in level.get_children():
		if c is OptionsScreen:
			screen = c
	var master: HSlider = (screen.get("_sliders") as Dictionary)[&"Master"]
	check(master.has_focus(), "its first slider has focus (the menu under it is inert, it isn't)")
	check(screen != null and Modals.is_top(screen), "options over the pause menu")
	screen.close()
	await wait_frames(1)
	check(Modals.is_top(pause) and get_tree().paused, "back to the pause menu, still paused")
	check_eq(get_viewport().gui_get_focus_owner(), options_button, "focus back on OPTIONS")
	pause.close()
	level.queue_free()
	await wait_frames(2)
