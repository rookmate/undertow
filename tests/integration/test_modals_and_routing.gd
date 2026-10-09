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
