extends Node
## The Steward in the earpiece. One switch, the voice, decides what it does for you (Assists): the
## predicted path, its map, threat warnings, slowed time on dodges, aim assist, tuned weapons and its
## narration. Muting it takes all of that away and lets the city hit harder.

signal voice_changed(voice_on: bool)
## An enemy is about to strike and the Steward is warning you (threat warnings on).
signal threat_warned(enemy: Node2D, seconds: float)
## The Lattice started or stopped reaching the Operator.
signal coverage_changed(covered: bool)

var voice_on: bool = true
## Whether the Steward's hardware reaches the Operator right now (levels set this; menus leave it on).
var covered: bool = true
## Seconds since the voice was last muted (for the HUD's muted timer).
var muted_for: float = 0.0


func _ready() -> void:
	GameState.run_replaced.connect(_sync_from_run)


func _process(delta: float) -> void:
	if not voice_on:
		muted_for += delta


func set_voice(on: bool) -> void:
	if on == voice_on:
		return
	voice_on = on
	muted_for = 0.0
	GameState.run.voice_on = on
	GameState.count_voice_toggle()
	voice_changed.emit(voice_on)


## The player's own switch (the earpiece clicks); loading a save just sets the voice quietly.
func toggle_voice() -> void:
	set_voice(not voice_on)
	Sound.play(&"voice_on" if voice_on else &"voice_off")


func set_coverage(on: bool) -> void:
	if on == covered:
		return
	covered = on
	coverage_changed.emit(covered)


func assists() -> Assists:
	return Assists.compute(voice_on, GameState.run.cores_power(), GameState.run.active_overrides, covered)


## Called by enemies as they wind up. Passed on to the HUD only while threat warnings are on.
func report_windup(enemy: Node2D, seconds: float) -> void:
	if assists().threat_warnings:
		threat_warned.emit(enemy, seconds)


func _sync_from_run() -> void:
	if voice_on != GameState.run.voice_on:
		voice_on = GameState.run.voice_on
		muted_for = 0.0
		voice_changed.emit(voice_on)
