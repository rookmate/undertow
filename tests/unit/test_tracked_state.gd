extends TestCase
## Brief, first milestone item 7: tracking for all the state variables, plus a debug overlay that
## shows them.


func before_each() -> void:
	GameState.new_run()


func test_every_brief_variable_is_tracked() -> void:
	var r := GameState.run
	# The brief's table, each read from the run.
	check(r.voice_on_ratio() >= 0.0)
	check(r.cores_power() >= 0 and r.cores_truth() >= 0)
	check(r.survivors_found() >= 0)
	check(r.noor_trust == 0 and r.teo_trust == 0)
	check(r.noor_present and r.teo_present)
	check(r.active_overrides is Array)
	check(r.playstyle_profile != null)


func test_debug_readout_shows_every_brief_variable() -> void:
	var text := DebugReadout.text_for(GameState.run, true)
	for variable: String in DebugReadout.BRIEF_VARIABLES:
		check(text.contains(variable), "overlay shows %s" % variable)
	check(text.contains("REWRITE"), "and the ending checklist")


## A field added to RunState but forgotten in to_dict() would silently not be saved.
func test_every_run_state_field_is_saved() -> void:
	var keys := RunState.new().to_dict().keys()
	for prop: Dictionary in RunState.new().get_property_list():
		if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		check(keys.has(prop["name"]), "RunState.%s is saved" % prop["name"])


func test_played_state_survives_a_save_and_load() -> void:
	GameState.add_voice_time(30.0, true)
	GameState.add_voice_time(20.0, false)
	GameState.count_voice_toggle()
	GameState.take_core("vellum_power_lattice", false)
	GameState.take_core("vellum_truth_0522", true)
	GameState.add_survivor(ContentIds.SURVIVOR_DOORWAY)
	GameState.change_trust(RunState.WHO_NOOR, 2)
	GameState.change_trust(RunState.WHO_TEO, -1)
	GameState.set_present(RunState.WHO_TEO, false)
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	GameState.record_playstyle(&"kill_close")
	GameState.unlock_log("log_0522_feed_adjustment")
	GameState.mark_log_replayed("log_0522_feed_adjustment")
	GameState.set_location("ark")
	var before := JSON.stringify(GameState.run.to_dict())
	check_eq(GameState.save(), OK)
	var loaded := SaveService.load_run()
	check_eq(loaded.status, SaveStore.Status.OK)
	check_eq(JSON.stringify(loaded.run.to_dict()), before, "identical after the round trip")
	check_near(loaded.run.voice_on_ratio(), 0.6)
	check_false(loaded.run.teo_present)


func test_continue_routes_every_saved_location() -> void:
	for id: String in LevelCatalog.LEVELS:
		check_eq(SceneRouter.destination_for("loadout:" + id), &"loadout")
		check_eq(SceneRouter.destination_for("level:" + id), &"loadout", "levels resume at the loadout")
		check_eq(SceneRouter.destination_for("reliquary:" + id), &"core_choice")
		check(ResourceLoader.exists(LevelCatalog.scene_of(id)), "%s's scene exists" % id)
	check_eq(SceneRouter.destination_for("ark"), &"ark")
	check_eq(SceneRouter.destination_for("level:tideworks"), &"", "districts this build doesn't have are refused")
	check_eq(SceneRouter.destination_for("somewhere"), &"")
	for key: StringName in SceneRouter.SCENES:
		check(ResourceLoader.exists(SceneRouter.SCENES[key]), "%s exists" % SceneRouter.SCENES[key])


func test_closing_the_window_saves_then_quits() -> void:
	SaveService.delete_save()
	GameState.set_location("ark")
	var quit_called := [false]
	var real_quit := GameState.quit_handler
	GameState.quit_handler = func() -> void: quit_called[0] = true
	GameState.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await wait_frames(2)
	GameState.quit_handler = real_quit
	check(SaveService.has_save(), "saved on close")
	check(quit_called[0], "and then quit")


func test_steam_wrapper_runs_without_steam() -> void:
	check_false(SteamService.available, "no GodotSteam in this build")
	SteamService.unlock_achievement("ACH_TEST")
	SteamService.set_rich_presence("status", "testing")
	check(true, "calls without Steam are harmless no-ops")
