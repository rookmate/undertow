extends TestCase
## Who owns the pause, and that navigation and its state change happen together or not at all.


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	await wait_frames(1)


func _stage_ark() -> ArkLevel:
	GameState.new_run()
	GameState.restore_building("archive")
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(3)
	return ark


func _pause_menu(level: Node) -> PauseMenu:
	for c: Node in level.get_children():
		if c is PauseMenu:
			return c
	return null


func test_resuming_from_pause_keeps_the_archive_paused_and_on_top() -> void:
	var ark := await _stage_ark()
	var archive := ark.open_archive()
	await wait_frames(2)
	check(get_tree().paused, "the Archive pauses the Ark")
	var pause := _pause_menu(ark)
	pause.open()
	check(Modals.is_top(pause), "pause sits over the Archive")
	pause.close()
	check(get_tree().paused, "resuming the pause menu leaves the Archive's pause in place")
	check(Modals.is_top(archive), "and the Archive owns input again")
	archive.close()
	await wait_frames(1)
	check_false(get_tree().paused, "closing the last screen unpauses")
	ark.queue_free()


func test_only_the_top_screen_takes_cancel() -> void:
	var ark := await _stage_ark()
	var archive := ark.open_archive()
	await wait_frames(2)
	var pause := _pause_menu(ark)
	pause.open()
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await wait_frames(2)
	check(is_instance_valid(archive) and not archive.is_queued_for_deletion(), "the Archive under the pause menu stays open")
	check_false(pause.visible, "the pause menu took the cancel")
	ark.queue_free()


func test_a_refused_navigation_does_not_change_the_run() -> void:
	GameState.new_run()
	GameState.set_location("ark")
	GameState.change_trust(RunState.WHO_NOOR, 3)
	# Pretend a transition is running.
	SceneRouter.set("_busy", true)
	var ran := [false]
	var accepted := SceneRouter.goto(&"loadout", func() -> void:
		ran[0] = true
		GameState.new_run())
	SceneRouter.set("_busy", false)
	check_false(accepted, "a second navigation during a fade is refused")
	check_false(ran[0], "and its state change never runs")
	check_eq(GameState.run.noor_trust, 3, "the current run is untouched")


const BROKEN_LEVEL := "res://tests/fixtures/broken_level.tscn"


func test_a_broken_map_stops_the_level_before_anything_runs() -> void:
	GameState.new_run()
	GameState.set_location("loadout:vellum")
	Diagnostics.capture()
	var level := (load(BROKEN_LEVEL) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(5)
	var reports := Diagnostics.release()
	check(level.failed, "the level knows it never started")
	check(reports.size() >= 2 and "\n".join(reports).contains("unknown map character"), "the problems are reported: %s" % [reports])
	check_false(level.is_processing() or level.is_physics_processing(), "nothing runs per frame")
	check_eq(GameState.run.location, "loadout:vellum", "the broken level never became the saved location")
	level.queue_free()
	await wait_frames(1)


## Through the real router: the broken level is entered behind a fade and the player ends up on the title,
## with the save untouched and no errors after the reports.
func test_entering_a_broken_level_lands_on_the_title() -> void:
	GameState.new_run()
	GameState.set_location("loadout:vellum")
	GameState.change_trust(RunState.WHO_TEO, 2)
	check_eq(GameState.save(), OK)
	var saved := FileAccess.get_file_as_string(SaveService.store.path())
	# Let the router replace a stand-in scene instead of the test runner.
	var runner := get_tree().current_scene
	var stand_in := Node.new()
	get_tree().root.add_child(stand_in)
	get_tree().current_scene = stand_in
	Diagnostics.capture()
	check(SceneRouter.call(&"_start", BROKEN_LEVEL, SceneRouter.LEVEL_KEY, "broken", Callable()), "the transition starts")
	var key: StringName = await SceneRouter.scene_changed
	while SceneRouter.is_busy():
		await wait_frames(1)
	await wait_frames(10)
	var reports := Diagnostics.release()
	check_eq(key, &"title", "the player lands on the title")
	check_eq(SceneRouter.current_key, &"title")
	check_eq(SceneRouter.current_level, "")
	check(get_tree().current_scene != null and get_tree().current_scene.scene_file_path == SceneRouter.SCENES[&"title"], "the title is the current scene")
	check_false(get_viewport().gui_disable_input, "input is back")
	check_false(reports.is_empty(), "the broken map was reported")
	check_eq(FileAccess.get_file_as_string(SaveService.store.path()), saved, "the save is exactly as it was")
	get_tree().current_scene.queue_free()
	get_tree().current_scene = runner
	await wait_frames(2)


class FailingStore:
	extends SaveStore
	func _write_text(_file_path: String, _text: String) -> Error:
		return ERR_FILE_CANT_WRITE


func _press(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await wait_frames(1)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(1)


func _question() -> SaveFailure:
	for n: Node in get_tree().root.get_children():
		if n is SaveFailure and (n as SaveFailure).asking and not n.is_queued_for_deletion():
			return n as SaveFailure
	return null


func _questions() -> int:
	var count := 0
	for n: Node in get_tree().root.get_children():
		if n is SaveFailure and (n as SaveFailure).asking and not n.is_queued_for_deletion():
			count += 1
	return count


func _with_failing_saves(body: Callable) -> void:
	var real := SaveService.store
	SaveService.store = FailingStore.new("user://test_saves_modals")
	await body.call()
	SaveService.store = real


## Pause → "save and return" fails → the question sits over the pause menu. Start can't open another
## pause over it, the pause menu can't be focused under it, and answering "stay" with the pad puts focus
## back on the button you pressed.
func test_a_save_question_owns_input_and_stay_gives_focus_back() -> void:
	var ark := await _stage_ark()
	var pause := _pause_menu(ark)
	await _with_failing_saves(func() -> void:
		await _press(&"pause")
		check(pause.visible and Modals.is_top(pause), "Start opens the pause menu")
		await _press(&"ui_down")
		await _press(&"ui_down")
		var quit_button := get_viewport().gui_get_focus_owner()
		check(quit_button is Button and (quit_button as Button).text.begins_with("SAVE AND RETURN"), "focus on save-and-return")
		await _press(&"ui_accept")
		await wait_frames(2)
		var question := _question()
		check(question != null and Modals.is_top(question), "the save failed and the player is asked")
		check_eq(quit_button.focus_mode, Control.FOCUS_NONE, "the pause menu under the question can't be focused")
		check(question != null and question.layer > pause.layer, "and the question is drawn above it")
		await _press(&"pause")
		check(question != null and Modals.is_top(question), "Start doesn't put the pause menu over the question")
		await _press(&"ui_right")
		await _press(&"ui_right")
		check_eq((get_viewport().gui_get_focus_owner() as Button).text, "STAY")
		await _press(&"ui_accept")
		await wait_frames(2)
		check(_question() == null, "the question is answered")
		check(pause.visible and Modals.is_top(pause), "the pause menu is back on top")
		check_eq(get_viewport().gui_get_focus_owner(), quit_button, "focus is back on the button you pressed")
		check(get_tree().paused, "still paused"))
	pause.close()
	ark.queue_free()


func test_closing_the_window_twice_asks_once() -> void:
	var ark := await _stage_ark()
	GameState.set_location("ark")
	var quits := [0]
	var real_quit := GameState.quit_handler
	GameState.quit_handler = func() -> void: quits[0] += 1
	await _with_failing_saves(func() -> void:
		GameState.notification(NOTIFICATION_WM_CLOSE_REQUEST)
		await wait_frames(2)
		GameState.notification(NOTIFICATION_WM_CLOSE_REQUEST)
		await wait_frames(2)
		check_eq(_questions(), 1, "one question, however many times close is pressed")
		await _press(&"pause")
		check_false(_pause_menu(ark).visible, "Start doesn't open the pause menu over the question")
		check(Modals.is_top(_question()), "the question still owns input")
		_question().call(&"_choose", SaveFailure.Choice.LEAVE)
		await wait_frames(2)
		check_eq(quits[0], 1, "and one quit"))
	GameState.quit_handler = real_quit
	ark.queue_free()


func test_a_scene_change_dismisses_an_open_question() -> void:
	GameState.new_run()
	var outcome := [null]
	await _with_failing_saves(func() -> void:
		var leave := func() -> void: outcome[0] = await SaveFlow.before_leaving(get_tree())
		leave.call()
		await wait_frames(2)
		check(_question() != null, "asked")
		Modals.clear()
		await wait_frames(2)
		check(_question() == null, "the question goes with the scene")
		check_eq(outcome[0], false, "and whoever asked hears 'stay', not silence"))


func test_screens_under_the_top_one_are_inert_until_it_closes() -> void:
	var ark := await _stage_ark()
	var archive := ark.open_archive()
	await wait_frames(2)
	var back: Button = archive.get("_back")
	var before := back.focus_mode
	var pause := _pause_menu(ark)
	pause.open()
	await wait_frames(1)
	check_eq(back.focus_mode, Control.FOCUS_NONE, "the Archive can't be focused under the pause menu")
	check_eq(back.mouse_filter, Control.MOUSE_FILTER_IGNORE, "or clicked")
	pause.close()
	await wait_frames(1)
	check_eq(back.focus_mode, before, "it comes back when the pause menu closes")
	archive.close()
	ark.queue_free()


## A screen opened from inside another (options inside a menu) keeps its own controls usable.
func test_a_screen_nested_in_another_is_not_made_inert_with_it() -> void:
	var outer := CanvasLayer.new()
	var outer_button := Button.new()
	outer.add_child(outer_button)
	add_child(outer)
	Modals.push(outer)
	var inner := CanvasLayer.new()
	var inner_button := Button.new()
	inner.add_child(inner_button)
	outer.add_child(inner)
	Modals.push(inner)
	check_eq(outer_button.focus_mode, Control.FOCUS_NONE, "the screen underneath is inert")
	check(inner_button.focus_mode != Control.FOCUS_NONE, "the one on top, though inside it, isn't")
	Modals.pop(inner)
	Modals.pop(outer)
	outer.queue_free()
