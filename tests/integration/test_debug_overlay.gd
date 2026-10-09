extends TestCase
## The debug overlay: opens with F3, shows the tracked state live, and its debug keys flip the
## overrides and the companions' presence so the ending rules can be checked by eye.


func before_each() -> void:
	GameState.new_run()
	if DebugOverlay.visible:
		DebugOverlay.toggle()


func after_each() -> void:
	if DebugOverlay.visible:
		DebugOverlay.toggle()
	GameState.new_run()


func _key(code: Key) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	await wait_frames(2)
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)


func test_f3_opens_it_and_it_shows_the_state() -> void:
	await _key(KEY_F3)
	check(DebugOverlay.visible, "F3 opens the overlay")
	GameState.add_survivor("someone")
	await wait_seconds(0.4)
	var label: RichTextLabel = DebugOverlay.get("_label")
	check(label.get_parsed_text().contains("survivors_found    1"), "live: %s" % label.get_parsed_text().substr(0, 200))
	await _key(KEY_F3)
	check_false(DebugOverlay.visible)


func test_debug_keys_flip_overrides_and_presence_only_while_open() -> void:
	await _key(KEY_F5)
	check_false(GameState.has_override(Overrides.NO_TRAP_WARNINGS), "closed: keys do nothing")
	await _key(KEY_F3)
	await _key(KEY_F5)
	check(GameState.has_override(Overrides.NO_TRAP_WARNINGS))
	await _key(KEY_F6)
	check(GameState.has_override(Overrides.SURVIVORS_FIRST))
	await _key(KEY_F7)
	check_false(GameState.run.noor_present)
	await _key(KEY_F8)
	check_false(GameState.run.teo_present)
	await _key(KEY_F5)
	check_false(GameState.has_override(Overrides.NO_TRAP_WARNINGS), "pressed again: revoked")
