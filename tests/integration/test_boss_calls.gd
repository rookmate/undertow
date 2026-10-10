extends TestCase
## The Steward's calls in a boss fight are said in full: each recording ends before the boss's next call
## can come (a new line cuts the one being spoken), every call a boss makes is listed with its gap, and
## the fight waits for the Steward to finish introducing the boss.

const BOSSES: Dictionary[String, Dictionary] = {
	"conductor_": Conductor.CALL_GAPS,
	"crane_": Crane.CALL_GAPS,
	"surgeon_": Surgeon.CALL_GAPS,
	"lung_": Lung.CALL_GAPS,
	"editor_": Editor.CALL_GAPS,
}
## A beat between one call ending and the next starting.
const MARGIN := 0.1


func test_every_call_ends_before_the_next_can_come() -> void:
	for prefix: String in BOSSES:
		var gaps: Dictionary = BOSSES[prefix]
		check(not gaps.is_empty(), "%s lists its calls" % prefix)
		for id: String in gaps:
			var clip := load(VoiceLines.clip_path(id)) as AudioStream
			check(clip != null, "%s is voiced" % id)
			if clip != null:
				check(clip.get_length() + MARGIN <= float(gaps[id]), "%s (%.2f s) is said in full before the next call (%.2f s)" % [id, clip.get_length(), float(gaps[id])])


func test_every_boss_line_is_listed() -> void:
	for id: String in VoiceLines.all():
		for prefix: String in BOSSES:
			if id.begins_with(prefix):
				check((BOSSES[prefix] as Dictionary).has(id), "%s is in its boss's CALL_GAPS" % id)


## In a real district the Steward introduces the boss, and the fight starts once it has finished.
func test_the_fight_waits_for_the_introduction() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	var level := (load("res://tests/fixtures/editor_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	var editor := level.boss as Editor
	# After the arena's own entry line (in a district the boss is far from the start).
	await wait_physics_frames(roundi(StewardWatch.ENTER_DELAY * 60.0) + 10)
	Sound.hush()
	level.player.position = Iso.cell_center(Vector2i(7, 8))
	await wait_physics_frames(3)
	check(editor.is_engaged, "engaged")
	check_eq(Sound.voice_line, "VEL_BOSS_N1", "the Steward introduces it")
	check_false(editor.is_fighting, "and it waits")
	var waited := 0
	while not editor.is_fighting and waited < 600:
		await wait_physics_frames(1)
		waited += 1
	check(editor.is_fighting, "then it starts")
	check(waited >= roundi((Sound.voice_length("VEL_BOSS_N1") - 0.2) * 60.0), "after the introduction (%d frames)" % waited)
	check_eq(Sound.voice_line, "editor_rollers", "with its first call")
	level.queue_free()
	await wait_frames(2)


## A warning being said is never cut off by narration: praise waits until it's done.
func test_narration_never_cuts_a_warning_off() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	check(Narrator.say_fixed("lung_surge"), "a warning")
	check_eq(Sound.voice_line, "lung_surge")
	check_eq(Narrator.notify(&"multi_kill"), "", "praise doesn't cut it off")
	check_eq(Sound.voice_line, "lung_surge", "the warning is still being said")
	Sound.hush()
	check(Narrator.notify(&"multi_kill") != "", "and is said once it's done")
	Sound.hush()


## Nor by a fixed line (a fact the Steward says when you try something): only a boss's own call cuts in.
func test_only_a_boss_call_cuts_a_warning_off() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	check(Narrator.say_fixed("tide_swell"), "the tide's warning")
	check_false(Narrator.say_fixed("waiting_refusal"), "a fact waits")
	check_false(Narrator.say_fixed("lung_far"), "another warning that isn't a boss's call waits")
	check_eq(Sound.voice_line, "tide_swell", "the warning is still being said")
	check(Narrator.say_fixed("lung_far", true), "a boss's call cuts in")
	check_eq(Sound.voice_line, "lung_far")
	Sound.hush()


## In Greywater, while the Lung fights, the tide turns without a word: the Lung's calls have the voice.
func test_the_tide_keeps_quiet_while_the_lung_fights() -> void:
	GameState.new_run()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	var level := (load("res://game/level/greywater.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	await wait_physics_frames(roundi(StewardWatch.ENTER_DELAY * 60.0) + 10)
	Sound.hush()
	level.tide.enter(Tide.Phase.SWELL)
	check_eq(Sound.voice_line, "tide_swell", "away from the fight, the Steward calls the tide")
	Sound.hush()
	level.boss.is_engaged = true
	level.boss.is_fighting = true
	level.tide.enter(Tide.Phase.SWELL)
	check(Sound.voice_line != "tide_swell", "while the Lung fights, it doesn't")
	level.queue_free()
	await wait_frames(2)

