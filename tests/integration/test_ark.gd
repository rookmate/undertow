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


func test_the_dock_ends_the_slice() -> void:
	var panel := ark.open_end_panel()
	await wait_frames(2)
	check(panel != null and get_tree().paused)
