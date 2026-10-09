extends TestCase
## The Ark hub and the Archive screen in the real scenes.

var ark: ArkLevel


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	GameState.add_survivor(ContentIds.SURVIVOR_DOORWAY)
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var picks: Array[String] = ["vellum_truth_0522", ContentIds.CORE_TRUTH_STACKS]
	CoreChoice.apply(ContentIds.LEVEL_VELLUM, CoreChoice.offer(ContentIds.LEVEL_VELLUM, GameState.run), picks)
	ark = (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(3)


func after_each() -> void:
	# Some tests stand in a much larger Archive; the real content is read back even if one aborted.
	ContentDb._loaded = false
	ContentDb.ensure_loaded()
	Modals.clear()
	get_tree().paused = false
	if not Steward.voice_on:
		Steward.set_voice(true)
	ark.queue_free()
	await wait_frames(2)


func _figures(who: ArkFigure.Who) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is ArkFigure and (c as ArkFigure).who == who:
			n += 1
	return n


func test_the_ark_has_the_archive_noor_teo_and_the_survivors() -> void:
	var archive := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == BuildingCell.Facade.ARCHIVE:
			archive += 1
	check(archive > 0, "the Archive stands")
	check_eq(_figures(ArkFigure.Who.NOOR), 1)
	check_eq(_figures(ArkFigure.Who.TEO), 1)
	check_eq(_figures(ArkFigure.Who.SURVIVOR), GameState.run.survivors_found())
	check_eq(GameState.run.location, "ark", "Continue will bring you back here")
	check(ark.predicted_path == null, "the Steward may advise here and may not act: no path")
	check(ark.player.weapons.is_empty(), "no weapons on the Ark")


func test_time_on_the_ark_does_not_count_toward_the_voice_ratio() -> void:
	var before := GameState.run.voice_tracked_seconds()
	await wait_seconds(1.0)
	check_near(GameState.run.voice_tracked_seconds(), before, 0.001)


func test_archive_replay_reveals_the_record_then_the_reactions_once() -> void:
	var screen := ark.open_archive()
	await wait_frames(2)
	check(get_tree().paused, "the Ark waits while you read")
	screen.select("log_0522_feed_adjustment")
	check_false(screen.get("_now").visible, "nothing to say before the record is seen")
	screen.call("_on_replay")
	check(screen.replaying)
	var lines := (ContentDb.memory_log("log_0522_feed_adjustment")["record"] as Array).size()
	await wait_seconds(lines * ArchiveScreen.LINE_SECONDS + 0.5)
	check_false(screen.replaying)
	check(screen.last_replay.first_time)
	check(screen.get("_now").visible, "the Steward's present-day comment")
	check(GameState.run.noor_trust != 0 or GameState.run.teo_trust != 0, "trust moved")
	var noor := GameState.run.noor_trust
	screen.call("_on_replay")
	await wait_seconds(lines * ArchiveScreen.LINE_SECONDS + 0.5)
	check_false(screen.last_replay.first_time)
	check_eq(GameState.run.noor_trust, noor, "only the first replay moves trust")
	screen.close()
	await wait_frames(2)
	check_false(get_tree().paused)


func test_muted_the_steward_keeps_its_comment_to_itself() -> void:
	Steward.set_voice(false)
	var screen := ark.open_archive()
	await wait_frames(2)
	screen.select("log_vashti_audit_note")
	screen.call("_on_replay")
	await wait_seconds(6 * ArchiveScreen.LINE_SECONDS + 0.5)
	check_false(screen.get("_now").visible)
	check(screen.get("_noor").visible, "Noor still speaks for herself")
	screen.close()


func test_the_dock_opens_the_loop_map() -> void:
	var map := ark.open_city_map()
	await wait_frames(2)
	check(map != null and get_tree().paused and Modals.is_top(map))
	var buttons: Dictionary = map.get("_buttons")
	check_eq(buttons.size(), LevelCatalog.CITY.size(), "every district of Meridian is on it")
	check_eq(CityMap.state_of(GameState.run, "vellum"), "done", "the Vellum is behind you")
	check_eq(CityMap.state_of(GameState.run, "spire"), "unbuilt")
	var open := LevelCatalog.open_districts(GameState.run)
	check_eq((map.get("_go") as Button).disabled, open.is_empty(), "the skiff goes only where it's open")
	if not open.is_empty():
		check_eq(map.chosen, open[0], "the first open district is chosen")
	map.choose("vellum")
	check_eq(map.chosen, "", "a done district can't be chosen")
	var summary := map.open_summary()
	await wait_frames(2)
	check(Modals.is_top(summary), "the run so far opens over the map")
	summary.close()
	await wait_frames(1)
	check(Modals.is_top(map), "and closes back to it")
	map.close()
	await wait_frames(1)
	check_false(get_tree().paused)


func test_buildings_stand_only_once_restored() -> void:
	ark.queue_free()
	await wait_frames(1)
	GameState.new_run()
	var bare := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(bare)
	await wait_frames(2)
	var archive := 0
	var plots := 0
	var doors := 0
	for c: Node in bare.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == BuildingCell.Facade.ARCHIVE:
			archive += 1
		if c is UnbuiltPlot:
			plots += 1
		if c is ArkFixture and (c as ArkFixture).kind == ArkFixture.Kind.ARCHIVE_DOOR:
			doors += 1
	check_eq(archive, 0, "no Archive before the Vellum's core comes home")
	check(plots > 0, "just its plot")
	check_eq(doors, 0, "and no door into it")
	ark = bare


func test_every_survivor_has_a_place_on_the_ark() -> void:
	ark.queue_free()
	await wait_frames(1)
	for i: int in 7:
		GameState.add_survivor("survivor_%d" % i)
	var crowded := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(crowded)
	await wait_frames(2)
	check_eq(_count_in(crowded, ArkFigure.Who.SURVIVOR), GameState.run.survivors_found(), "all %d survivors are there" % GameState.run.survivors_found())
	var cells := crowded.survivor_cells(GameState.run.survivors_found())
	var unique: Dictionary[Vector2i, bool] = {}
	for c: Vector2i in cells:
		unique[c] = true
	check_eq(unique.size(), cells.size(), "nobody stands on anybody")
	ark = crowded


func _count_in(level: ArkLevel, who: ArkFigure.Who) -> int:
	var n := 0
	for c: Node in level.world.get_children():
		if c is ArkFigure and (c as ArkFigure).who == who:
			n += 1
	return n


func test_the_archive_list_scrolls() -> void:
	var screen := ark.open_archive()
	await wait_frames(2)
	var list: VBoxContainer = screen.get("_list")
	check(list.get_parent() is ScrollContainer, "the log list lives in a scroll container")
	check((list.get_parent() as ScrollContainer).follow_focus, "and follows controller focus")
	screen.close()


## The interaction prompt follows the camera, so it redraws while shown; when you walk away it must be
## drawn away too, then the HUD goes back to redrawing only on change.
func test_walking_away_clears_the_interaction_prompt() -> void:
	var noor: Node2D = null
	for c: Node in ark.world.get_children():
		if c is ArkFigure and (c as ArkFigure).who == ArkFigure.Who.NOOR:
			noor = c
	var view := ark.hud.view
	var draws := [0]
	view.draw.connect(func() -> void: draws[0] += 1)
	ark.player.position = noor.position + Iso.ground_velocity(Vector2(1, 0), 0.8)
	await wait_frames(4)
	check(ark.player.interact_target() != null, "next to Noor there is something to do")
	var while_near: int = draws[0]
	check(while_near >= 2, "the prompt is redrawn as it follows the camera")
	ark.player.position = Iso.cell_center(ark.grid.start_cell())
	await wait_frames(3)
	check(ark.player.interact_target() == null, "away from everyone there is nothing")
	check(draws[0] > while_near, "the HUD is redrawn without the prompt")
	var settled: int = draws[0]
	await wait_frames(10)
	check_eq(draws[0], settled, "and then left alone while nothing changes")


func test_a_full_ark_is_reported_not_crashed_on() -> void:
	var capacity := ark.survivor_cells(100000).size()
	ark.queue_free()
	await wait_frames(1)
	check(capacity > 20, "room for a crowd (%d)" % capacity)
	for i: int in capacity + 5:
		GameState.add_survivor("crowd_%d" % i)
	Diagnostics.capture()
	var full := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(full)
	await wait_frames(2)
	var reports := Diagnostics.release()
	check_eq(_count_in(full, ArkFigure.Who.SURVIVOR), capacity, "everyone there's room for stands on the Ark")
	check(reports.size() == 1 and reports[0].contains("room for %d" % capacity), "and the overflow is reported: %s" % [reports])
	check_eq(GameState.run.survivors_found(), capacity + 5 + 1, "nobody is dropped from the run")
	ark = full


func test_an_ark_map_without_survivor_spots_is_refused() -> void:
	var bare := LevelGrid.parse("#####\n#pND#\n#Y..#\n#####")
	var probe := ArkLevel.new()
	probe.grid = bare
	var problems := "\n".join(probe.call(&"_map_problems"))
	check(problems.contains("'s'"), "no survivor spots: %s" % problems)
	probe.free()


## A full Archive (many districts' logs, a long record, writers' long titles and reactions) still fits
## its screen and works with a pad.
func test_a_full_archive_fits_and_scrolls_with_a_pad() -> void:
	var long_record: Array = []
	for i: int in 60:
		long_record.append("%02d:%02d · line %d of a long decision record" % [i % 24, i, i])
	for i: int in 40:
		var id := "log_bulk_%02d" % i
		ContentDb._logs[id] = {
			"title": "A title that goes on and on and on " .repeat(4) if i == 0 else "Bulk %d" % i, "kind": "truth",
			"core": "", "record": long_record if i == 0 else ["one line"], "steward_now": "s",
			"noor": {"text": "Noor has a great deal to say about this. ".repeat(20), "trust": 0}, "teo": {"text": "t", "trust": 0}}
		GameState.unlock_log(id)
		GameState.run.logs_replayed.append(id)
	var screen := ark.open_archive()
	await wait_frames(2)
	var list: VBoxContainer = screen.get("_list")
	var scroll := list.get_parent() as ScrollContainer
	var last := list.get_child(list.get_child_count() - 1) as Button
	var first_unlocked: Button = (screen.get("_buttons") as Dictionary)["log_bulk_00"]
	check(first_unlocked.size.x <= scroll.size.x, "a long title doesn't widen the list (%.0f)" % first_unlocked.size.x)
	for b: Node in list.get_children():
		if not (b as Button).disabled:
			last = b as Button
	last.grab_focus()
	await wait_frames(3)
	check(scroll.scroll_vertical > 0, "focusing the last log scrolls the list to it")
	screen.select("log_bulk_00")
	await wait_frames(2)
	var title: Label = screen.get("_title")
	check(title.clip_text and title.size.x <= 1141.0, "the long title stays in its box")
	var noor: Label = screen.get("_noor")
	check(noor.clip_text and noor.size.y <= 161.0, "a long reaction stays in its box (%.0f tall)" % noor.size.y)
	var record: RichTextLabel = screen.get("_record")
	first_unlocked.grab_focus()
	await _press_action(&"ui_right")
	check(record.has_focus(), "right from the list reaches the record")
	var bar := record.get_v_scroll_bar()
	check(bar.max_value > bar.page, "the record is longer than its box")
	bar.value = 0.0
	for i: int in 4:
		await _press_action(&"ui_down")
	check(bar.value > 0.0, "down scrolls the record")
	var lower := bar.value
	await _press_action(&"ui_up")
	check(bar.value < lower, "up scrolls back to earlier lines")
	await _press_action(&"ui_left")
	check(first_unlocked.has_focus(), "left goes back to the log in the list")
	screen.close()


func _press_action(action: StringName) -> void:
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
