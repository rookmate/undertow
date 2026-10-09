extends TestCase
## World bible: "the Steward's light reaches exactly as far as its hardware does. Where there are lamps,
## there is a path, a voice and a map. Where there aren't, there is nothing but what you carry."

var level: Level


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	level = (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	level.queue_free()
	await wait_frames(2)
	Steward.set_coverage(true)


func _into_the_stacks() -> void:
	level.player.position = Iso.cell_center(Vector2i(18, 28))
	await wait_seconds(Level.COVERAGE_GRACE + 0.3)


func test_off_the_lattice_the_voice_on_buys_nothing() -> void:
	check(Steward.assists().steward_present, "on the street it can help")
	await _into_the_stacks()
	var a := Steward.assists()
	check(Steward.voice_on, "the switch is still on")
	check(a.signal_lost and not a.steward_present)
	check_false(a.path_visible)
	check_false(a.threat_warnings)
	check_eq(a.aim_assist, 0.0)
	check_eq(a.dodge_slowmo_seconds, 0.0)
	check(a.weapons_forced_manual)
	check_near(a.damage_taken_mult, Tunables.MUTED_DAMAGE_TAKEN_MULT)
	check_false(a.narration)
	check_eq(Narrator.notify(&"kill"), "", "it can't narrate what it can't see")
	check_eq(level.hud.minimap.charted_label(), "STEWARD MAP · SIGNAL LOST")


func test_it_does_not_profile_what_it_cannot_see() -> void:
	await _into_the_stacks()
	var before := GameState.run.playstyle_profile.risk + GameState.run.playstyle_profile.caution
	level.player.dodged.emit(Vector2(1, 0))
	var e := level.add_enemy(Custodian.new(), Vector2i(18, 29), Custodian.MAX_INTEGRITY)
	e.take_hit(1000.0, Vector2(0, 1), 0.0, 0.0)
	await wait_frames(1)
	check_eq(GameState.run.playstyle_profile.risk + GameState.run.playstyle_profile.caution, before)


func test_back_on_the_lattice_it_returns() -> void:
	await _into_the_stacks()
	level.player.position = Iso.cell_center(level.grid.first("P"))
	await wait_frames(3)
	check(Steward.assists().steward_present)
	check_eq(level.predicted_path.shown.size(), Tunables.PATH_TILES_AHEAD)


func test_losing_the_signal_cancels_slowed_time() -> void:
	level.slow_mo.trigger()
	check(Engine.time_scale < 1.0)
	Steward.set_coverage(false)
	check_eq(Engine.time_scale, 1.0, "no Steward, no slow-mo")


func test_muting_cancels_slowed_time() -> void:
	level.slow_mo.trigger()
	check(Engine.time_scale < 1.0)
	Steward.set_voice(false)
	check_eq(Engine.time_scale, 1.0)


func test_the_ark_is_the_advisory_exception() -> void:
	level.queue_free()
	GameState.new_run()
	GameState.restore_building("archive")
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_seconds(1.0)
	check(Steward.covered, "on the Ark the Steward may advise (it can talk)")
	var before := GameState.run.playstyle_profile.caution
	ark.player.dodged.emit(Vector2(1, 0))
	check_eq(GameState.run.playstyle_profile.caution, before, "rolling around the Ark isn't a combat choice")
	level = ark
