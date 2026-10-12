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
	Options.reduce_flashing = true
	Controls.set_binding(&"dodge", ["key", KEY_Q])
	check_eq(Options.save_settings(), OK)
	Options.reset_all()
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_SPACE], "reset to defaults")
	check_false(Options.reduce_flashing, "reset to defaults")
	Options.load_settings()
	check_near(Options.volumes[&"SFX"], 0.4, 0.0001)
	check_eq(Options.subtitle_size, "large")
	check(Options.reduce_flashing, "reduced flashing came back")
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_Q], "the rebound dodge came back")


## A scratch settings file starts from the defaults in effect, not just on paper: whatever the player's
## own settings had applied (a muted bus) doesn't carry into tests or automated runs.
func test_default_settings_are_in_effect_not_just_stored() -> void:
	Sound.set_volume(&"Music", 0.0)
	Sound.set_volume(&"Steward", 0.1)
	Options.use_path(PATH)
	for bus: StringName in Options.VOLUME_DEFAULTS:
		check_near(Sound.volume(bus), Options.VOLUME_DEFAULTS[bus], 0.001, "%s at its default" % bus)


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


## The kept defaults count: Right Arrow is still Move Right's, J is still Weapon 1's, F3 the overlay's.
## Asking for one of those changes nothing (a swap is only ever with another action's own choice).
func test_an_input_another_action_keeps_is_refused() -> void:
	check(Controls.conflicts().is_empty(), "the shipped bindings share nothing")
	for ask: Array in [[&"move_left", ["key", KEY_RIGHT], &"move_right"], [&"dodge", ["key", KEY_J], &"attack_primary"],
			[&"interact", ["key", KEY_F3], &"debug_overlay"], [&"dodge", ["pad_button", JOY_BUTTON_DPAD_DOWN], &"move_down"],
			[&"interact", ["pad_axis", [JOY_AXIS_RIGHT_X, 1.0]], &"aim_right"]]:
		var action: StringName = ask[0]
		var before := Controls.bindings_for(action)
		check_eq(Controls.blocker_for(action, ask[1]), ask[2], "%s keeps %s" % [ask[2], ask[1]])
		check_false(Controls.set_binding(action, ask[1]))
		check_eq(Controls.bindings_for(action), before, "nothing changed")
	check(Controls.set_binding(&"move_left", ["key", KEY_D]), "another action's own key: a swap")
	check(Controls.set_binding(&"move_up", ["key", KEY_UP]), "an action's own kept default is fine")
	check(Controls.conflicts().is_empty(), "and still nothing is shared")


## Move Up rebound to its own kept Up Arrow holds that key twice; swapping it away would leave the kept
## one behind, so Move Down can't take it. The same on a pad with the d-pad.
func test_a_swap_that_would_still_share_an_input_is_refused() -> void:
	for ask: Array in [["kb", ["key", KEY_UP]], ["pad", ["pad_button", JOY_BUTTON_DPAD_UP]]]:
		Controls.reset_bindings()
		check(Controls.set_binding(&"move_up", ask[1]), "Move Up takes its own kept %s" % [ask[1]])
		var before := Controls.bindings_for(&"move_down")
		check_eq(Controls.blocker_for(&"move_down", ask[1]), &"move_up")
		check_false(Controls.set_binding(&"move_down", ask[1]), "Move Down can't have it")
		check_eq(Controls.bindings_for(&"move_down"), before)
		check(Controls.conflicts().is_empty(), "nothing shared (%s)" % ask[0])
	Controls.reset_bindings()


func test_saved_bindings_are_checked_like_new_ones() -> void:
	Diagnostics.capture()
	Controls.set_overrides({
		"dodge": {"kb": ["key", KEY_J], "pad": ["pad_axis", ["bad", 1.0]]},
		"interact": {"pad": ["pad_axis", [JOY_AXIS_TRIGGER_LEFT, 0.5]]},
		"voice_toggle": {"pad": ["pad_axis", [JOY_AXIS_LEFT_X, 7.0]], "kb": ["mouse", 99]},
		"move_up": {"kb": ["key", KEY_D]}, "move_right": {"kb": ["key", KEY_W]},
		"attack_secondary": {"pad": ["pad_axis", [JOY_AXIS_TRIGGER_RIGHT, -1]]},
	})
	check(Diagnostics.release().is_empty(), "damaged settings are dropped quietly, not crashed on")
	check_eq(Controls.primary(&"dodge", "kb"), ["key", KEY_SPACE], "J is Weapon 1's")
	check_eq(Controls.primary(&"dodge", "pad"), ["pad_button", JOY_BUTTON_A], "an axis that isn't one")
	check_eq(Controls.primary(&"interact", "pad"), ["pad_button", JOY_BUTTON_X], "half a direction")
	check_eq(Controls.primary(&"voice_toggle", "kb"), ["key", KEY_V], "no mouse button 99")
	check_eq(Controls.primary(&"move_up", "kb"), ["key", KEY_D], "a saved swap is kept")
	check_eq(Controls.primary(&"move_right", "kb"), ["key", KEY_W])
	check_eq(Controls.primary(&"attack_secondary", "pad"), ["pad_axis", [JOY_AXIS_TRIGGER_RIGHT, -1.0]], "whole numbers are made directions")
	check(Controls.conflicts().is_empty())


func test_the_screen_says_whose_input_it_is() -> void:
	var screen := OptionsScreen.new()
	add_child(screen)
	await wait_frames(2)
	var buttons: Dictionary = screen.get("_binding_buttons")
	(buttons["move_left/kb"] as Button).pressed.emit()
	await _press_key(KEY_RIGHT)
	check_eq(Controls.primary(&"move_left", "kb"), ["key", KEY_A], "refused")
	check_eq((screen.get("_status") as Label).text, "RIGHT STAYS ON MOVE RIGHT.")
	screen.close()
	await wait_frames(1)


func test_prompts_follow_a_rebind_at_once() -> void:
	var hints := LevelHints.new()
	add_child(hints)
	await wait_frames(1)
	var label: Label = hints.get("_label")
	check(label.text.begins_with("WASD  MOVE    SPACE  DODGE"), label.text)
	Controls.set_binding(&"dodge", ["key", KEY_Q])
	Controls.set_binding(&"move_up", ["key", KEY_I])
	check(label.text.begins_with("IASD  MOVE    Q  DODGE"), "same device, new keys: %s" % label.text)
	Controls.device = Controls.Device.PAD
	check(label.text.begins_with("LEFT STICK  MOVE    A  DODGE"), label.text)
	hints.queue_free()


func test_a_settings_save_that_fails_says_so() -> void:
	Options.use_path("user://no_such_folder/settings.cfg")
	var screen := OptionsScreen.new()
	add_child(screen)
	await wait_frames(2)
	screen.call(&"_toggle_vsync")
	var notices := get_tree().root.get_children().filter(func(n: Node) -> bool: return n is SaveFailure and not n.is_queued_for_deletion())
	check_eq(notices.size(), 1, "a notice: it lasts this session only")
	screen.call(&"_cycle_subtitles")
	check_eq(get_tree().root.get_children().filter(func(n: Node) -> bool: return n is SaveFailure and not n.is_queued_for_deletion()).size(), 1, "just the one")
	screen.close()
	for n: Node in notices:
		n.queue_free()
	Options.vsync = true
	await wait_frames(1)


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
