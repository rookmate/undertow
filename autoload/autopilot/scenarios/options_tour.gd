extends AutopilotScenario
## Options from the title with the keyboard or pad: turn a volume down, turn on reduced flashing, rebind
## dodge, and go back.

const CHECKS: Array[String] = ["options_opened", "options_volume", "options_reduce_flashing", "options_rebind", "options_closed"]


func expected() -> Array[String]:
	var out := super()
	out.append_array(CHECKS)
	return out


func on_title(title: Node, gen: int) -> void:
	var open: Button = null
	for b: Node in title.find_children("*", "Button", true, false):
		if (b as Button).text == "OPTIONS":
			open = b
	if open == null:
		return
	open.grab_focus()
	Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(1.0, gen):
		return
	var screen: OptionsScreen = null
	for c: Node in title.get_children():
		if c is OptionsScreen:
			screen = c
	Autopilot.check(screen != null, "options_opened")
	if screen == null:
		return
	await Autopilot.snap("options")
	var sliders: Dictionary = screen.get("_sliders")
	(sliders[&"Music"] as Control).grab_focus()
	for i: int in 4:
		Autopilot.tap(&"ui_left")
		if not await Autopilot.wait(0.3, gen):
			return
	Autopilot.check(Options.volumes[&"Music"] < Options.VOLUME_DEFAULTS[&"Music"], "options_volume")
	var flashing: Button = screen.get("_flashing_button")
	flashing.grab_focus()
	if not await Autopilot.wait(0.6, gen):
		return
	Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(0.6, gen):
		return
	Autopilot.check(Options.reduce_flashing and flashing.text == "ON", "options_reduce_flashing")
	await Autopilot.snap("options_reduce_flashing")
	var dodge_kb: Button = (screen.get("_binding_buttons") as Dictionary)["dodge/kb"]
	dodge_kb.grab_focus()
	if not await Autopilot.wait(0.8, gen):
		return
	Autopilot.tap(&"ui_accept")
	if not await Autopilot.wait(0.8, gen):
		return
	var key := InputEventKey.new()
	key.physical_keycode = KEY_R
	key.pressed = true
	Input.parse_input_event(key)
	if not await Autopilot.wait(0.8, gen):
		return
	Autopilot.check(Controls.primary(&"dodge", "kb") == ["key", KEY_R], "options_rebind")
	await Autopilot.snap("options_rebound")
	if not await Autopilot.wait(1.0, gen):
		return
	screen.close()
	if not await Autopilot.wait(0.5, gen):
		return
	Autopilot.check(not is_instance_valid(screen) or screen.is_queued_for_deletion(), "options_closed")
