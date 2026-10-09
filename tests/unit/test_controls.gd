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


func test_prompts_follow_last_used_device() -> void:
	var was := Controls.device
	Controls.device = Controls.Device.KEYBOARD_MOUSE
	check_eq(Controls.prompt(&"voice_toggle"), "V")
	Controls.device = Controls.Device.PAD
	check_eq(Controls.prompt(&"voice_toggle"), "Y")
	Controls.device = was
