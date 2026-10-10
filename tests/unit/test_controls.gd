extends TestCase
## Keyboard/mouse and controller support from day one: every gameplay action must have both.


func test_every_gameplay_action_has_keyboard_or_mouse_and_controller_bindings() -> void:
	for action: StringName in Controls.GAMEPLAY_ACTIONS:
		check(InputMap.has_action(action), "%s registered" % action)
		var kbm := false
		var pad := false
		for e: InputEvent in InputMap.action_get_events(action):
			if e is InputEventKey or e is InputEventMouseButton:
				kbm = true
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				pad = true
		check(kbm, "%s has a keyboard/mouse binding" % action)
		check(pad, "%s has a controller binding" % action)


func test_aim_has_a_right_stick_binding() -> void:
	for action: StringName in [&"aim_left", &"aim_right", &"aim_up", &"aim_down"]:
		var pad := false
		for e: InputEvent in InputMap.action_get_events(action):
			if e is InputEventJoypadMotion:
				pad = true
		check(pad, "%s on right stick" % action)


func test_any_controller_drives_the_actions() -> void:
	for device: int in [0, 1, 3]:
		var ev := InputEventJoypadButton.new()
		ev.device = device
		ev.button_index = JOY_BUTTON_Y
		ev.pressed = true
		check(ev.is_action(&"voice_toggle"), "controller %d toggles the voice" % device)
		var stick := InputEventJoypadMotion.new()
		stick.device = device
		stick.axis = JOY_AXIS_LEFT_X
		stick.axis_value = 1.0
		check(stick.is_action(&"move_right"), "controller %d moves" % device)


func test_prompts_follow_last_used_device() -> void:
	var was := Controls.device
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	check_eq(Controls.prompt(&"voice_toggle"), "V")
	Controls.device = Controls.Device.PAD
	check_eq(Controls.prompt(&"voice_toggle"), "Y")
	Controls.device = was


## Settings saved in Act 1, with Dodge on Q and LB (free then): loading them under Act 2's defaults (the
## dressing on Q / LB) keeps the player's Dodge, and the dressing moves to a free spare instead.
func test_an_older_choice_keeps_its_input_when_a_new_action_wants_it() -> void:
	var q: Array = ["key", KEY_Q]
	var lb: Array = ["pad_button", JOY_BUTTON_LEFT_SHOULDER]
	Controls.set_overrides({"dodge": {"kb": q, "pad": lb}})
	check_eq(Controls.primary(&"dodge", "kb"), q, "Dodge stays on Q")
	check_eq(Controls.primary(&"dodge", "pad"), lb, "and on LB")
	var item_kb := Controls.primary(&"use_item", "kb")
	var item_pad := Controls.primary(&"use_item", "pad")
	check(Controls.SPARES["kb"].has(item_kb), "the dressing moved to a spare key (%s)" % [item_kb])
	check(Controls.SPARES["pad"].has(item_pad), "and a spare button (%s)" % [item_pad])
	check(Controls.conflicts().is_empty(), "nothing shared")
	var saved := Controls.overrides()
	Controls.set_overrides(saved)
	check_eq(Controls.primary(&"use_item", "kb"), item_kb, "and it stays put saved and loaded again")
	Controls.reset_bindings()
	check_eq(Controls.primary(&"use_item", "kb"), q, "a fresh start has the dressing on Q")
