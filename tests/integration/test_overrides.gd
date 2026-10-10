extends TestCase
## Overrides: standing orders signed in the Signal Room. Each makes the city harder, is obeyed whether
## or not the Steward is listening, and gets the Steward's (voiced) reasoning while it is.


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if not Steward.voice_on:
		Steward.set_voice(true)
	await wait_frames(1)


func test_the_orders_are_all_there_and_valid() -> void:
	Overrides.ensure_loaded()
	check(Overrides.errors.is_empty(), "%s" % [Overrides.errors])
	for id: String in Overrides.IDS:
		check(Overrides.is_known(id), "%s is written" % id)
		check(Overrides.pips(id) >= 1 and Overrides.pips(id) <= 3)
	var none: Array[String] = []
	check_eq(Overrides.difficulty(none), Vector2i(0, 9), "nine pips in all, none signed")


func test_broken_orders_are_reported_not_used() -> void:
	var problems := PackedStringArray()
	var out := Overrides.validate({
		"no_path": {"order": "x", "effect": "x", "unlocks": "x", "sign": "x", "revoke": "x", "pips": 2},
		"no_slowmo": {"order": "x", "effect": "x", "unlocks": "x", "sign": "x", "pips": 5},
		"make_me_tea": {"order": "Make me tea."},
	}, problems)
	check_eq(out.keys(), ["no_path"], "only the complete, real order survives")
	check(problems.size() >= 4, "missing reply, bad pips, unknown order, and the orders missing outright: %s" % [problems])
	Diagnostics.capture()
	GameState.set_override("make_me_tea", true)
	check_eq(Diagnostics.release().size(), 1, "an unknown order can't be signed")
	check(GameState.run.active_overrides.is_empty())


func test_each_order_takes_away_one_assist() -> void:
	var base := Assists.compute(true, 1, [] as Array[String])
	var no_slowmo := Assists.compute(true, 1, [Overrides.NO_SLOWMO] as Array[String])
	check(base.dodge_slowmo_seconds > 0.0 and no_slowmo.dodge_slowmo_seconds == 0.0 and no_slowmo.slowmo_overridden)
	var aim := Assists.compute(true, 1, [Overrides.LET_ME_AIM] as Array[String])
	check(base.aim_assist > 0.0 and aim.aim_assist == 0.0 and aim.aim_overridden)
	var no_path := Assists.compute(true, 1, [Overrides.NO_PATH] as Array[String])
	check(not no_path.path_visible and no_path.path_overridden, "no path")
	check_eq(no_path.map_mode, Assists.MapMode.STEWARD, "the map still works")
	var muted := Assists.compute(false, 1, [Overrides.NO_PATH] as Array[String])
	check_false(muted.path_overridden, "muted, it's the voice that's off, not the order")


func test_survivors_first_costs_you_near_the_waiting() -> void:
	var level := (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(3)
	var waiting := level.grid.first("W")
	level.player.position = Iso.cell_center(waiting + Vector2i(1, 0))
	await wait_physics_frames(2)
	check(level.waiting_near(level.player.global_position, Overrides.SURVIVORS_FIRST_TILES))
	var before := level.player.integrity.value
	level.player.take_hit(10.0, level.player.global_position + Vector2(40, 0))
	var plain := before - level.player.integrity.value
	await wait_seconds(1.0)
	GameState.set_override(Overrides.SURVIVORS_FIRST, true)
	before = level.player.integrity.value
	level.player.take_hit(10.0, level.player.global_position + Vector2(40, 0))
	check_near(before - level.player.integrity.value, plain * Overrides.SURVIVORS_FIRST_DAMAGE, 0.01, "it shields them, not you")
	level.queue_free()
	await wait_frames(2)


func test_stop_praising_me_leaves_only_facts() -> void:
	Narrator.reset_session()
	GameState.set_override(Overrides.NO_PRAISE, true)
	check_eq(Narrator.notify(&"kill"), "", "no praise for a kill")
	var line_id := Narrator.notify(&"level_enter", "kestrel")
	check(line_id != "", "facts are still said")
	var tone := ""
	for l: LineSelector.Line in Narrator.selector.all_lines():
		if l.id == line_id:
			tone = String(l.tone)
	check_eq(tone, "neutral", "and only plainly")


## The orders govern everything the Steward says, not just its pooled narration: a boss's warnings, its
## fixed lines, its screens' voice-overs.
func test_the_orders_govern_every_line_by_purpose() -> void:
	check(Narrator.say_fixed("crane_drop"), "a warning, while nothing forbids it")
	# (Said in full before anything else: done with it.)
	Sound.hush()
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	for id: String in ["conductor_left", "conductor_middle", "conductor_right", "crane_drop", "crane_swing"]:
		check_eq(VoiceLines.purpose(id), LineSelector.WARNING, "%s is a warning" % id)
		check_false(Narrator.say_fixed(id), "%s is not said with 'Never warn me' signed" % id)
	check(Narrator.say_fixed("crane_rest"), "an opening is a fact, still said")
	GameState.set_override(Overrides.NO_PRAISE, true)
	check_false(Narrator.say_fixed("workshop_tuned"), "praise, not said")
	check(Narrator.say_fixed("workshop_manual"))
	check_false(Narrator.voice_over("workshop_tuned"), "nor on a screen: the line's own purpose decides")
	check_false(Narrator.speak_text("workshop_tuned", VoiceLines.fixed("workshop_tuned"), LineSelector.FACT), "whatever the caller calls it")
	check(Narrator.speak_text("ad_hoc", "Something said once.", LineSelector.FACT), "text that isn't one of its lines goes by the purpose given")
	check(Narrator.speak_text(Overrides.reply_line(Overrides.NO_PRAISE, true), Overrides.field(Overrides.NO_PRAISE, "sign"), LineSelector.PRAISE), "its reasoning is a fact, whatever it's called")
	Diagnostics.capture()
	check_false(Narrator.voice_over("no_such_line"))
	check_eq(Diagnostics.release().size(), 1, "a voice-over that isn't a line is reported")


func test_with_never_warn_me_signed_the_crane_drops_in_silence() -> void:
	GameState.set_override(Overrides.NO_TRAP_WARNINGS, true)
	var level := (load("res://tests/fixtures/crane_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	level.player.position = Iso.cell_center(Vector2i(9, 7))
	level.player.set_physics_process(false)
	await wait_physics_frames(4)
	check((level.boss as Crane).is_engaged)
	# Past the Steward's introduction, as if cut short: the fight starts at once.
	Sound.hush()
	await wait_physics_frames(1)
	await wait_seconds(Crane.LIFT_SECONDS + 0.1)
	check_eq((level.boss as Crane).phase, Crane.Phase.AIM)
	check(Sound.voice_line != "crane_drop", "no call: it watches the load come down and says nothing")
	level.queue_free()
	await wait_frames(2)


func test_a_fixed_line_needs_text_and_a_purpose() -> void:
	var problems := PackedStringArray()
	var out := VoiceLines.validate_fixed({
		"fine": {"text": "Fine.", "purpose": "fact"},
		"no_purpose": {"text": "Hm."},
		"odd_purpose": {"text": "Hm.", "purpose": "flattery"},
		"empty": {"text": "", "purpose": "fact"},
		"bad id!": {"text": "Hm.", "purpose": "fact"},
	}, problems)
	check_eq(out.keys(), ["fine"])
	check_eq(problems.size(), 4, "%s" % [problems])


func test_the_signal_room_stands_once_the_loop_is_done() -> void:
	GameState.restore_building("archive")
	var bare := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(bare)
	await wait_frames(2)
	check_eq(_count(bare, BuildingCell.Facade.SIGNAL_ROOM), 0, "no Signal Room before the Loop")
	check_eq(_doors(bare, ArkFixture.Kind.SIGNAL_DOOR), 0)
	bare.queue_free()
	await wait_frames(1)
	GameState.restore_building("signal_room")
	var ark := (load("res://game/ark/ark.tscn") as PackedScene).instantiate() as ArkLevel
	add_child(ark)
	await wait_frames(2)
	check(_count(ark, BuildingCell.Facade.SIGNAL_ROOM) > 0, "the Signal Room stands")
	check_eq(_doors(ark, ArkFixture.Kind.SIGNAL_DOOR), 1, "with its door")
	var screen := ark.open_overrides()
	await wait_frames(2)
	check(Modals.is_top(screen) and get_tree().paused)
	screen.toggle(Overrides.NO_PATH)
	check(GameState.has_override(Overrides.NO_PATH), "signed")
	check_eq(Sound.voice_line, Overrides.reply_line(Overrides.NO_PATH, true), "and the Steward answers, aloud")
	screen.toggle(Overrides.NO_PATH)
	check_false(GameState.has_override(Overrides.NO_PATH), "revoked")
	check_eq(Sound.voice_line, Overrides.reply_line(Overrides.NO_PATH, false))
	Steward.set_voice(false)
	var voices := Sound.heard(&"voice")
	screen.toggle(Overrides.LET_ME_AIM)
	check(GameState.has_override(Overrides.LET_ME_AIM), "muted, the order still binds it")
	check_eq(Sound.heard(&"voice"), voices, "but it says nothing")
	check(SaveService.has_save(), "orders are saved as they're signed")
	screen.close()
	ark.queue_free()
	await wait_frames(2)


func _count(ark: ArkLevel, facade: BuildingCell.Facade) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is BuildingCell and (c as BuildingCell).facade == facade:
			n += 1
	return n


func _doors(ark: ArkLevel, kind: ArkFixture.Kind) -> int:
	var n := 0
	for c: Node in ark.world.get_children():
		if c is ArkFixture and (c as ArkFixture).kind == kind:
			n += 1
	return n
