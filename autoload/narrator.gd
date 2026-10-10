extends Node
## Turns gameplay events into the Steward's narration. Lines come from data/narration/steward_lines.json
## through a LineSelector biased by the playstyle profile. Muted, the Steward is silent. Each event has a
## cooldown, and lines keep a short gap between them unless the event is a priority.
##
## Everything the Steward says (pooled lines, fixed lines, replies, screen voice-overs) passes allows():
## every line has a purpose (fact, warning, praise) and the signed orders silence by purpose.

signal line_spoken(line_id: String, text: String)

const LINES_PATH := VoiceLines.NARRATION_PATH
const MIN_GAP := 2.8

var selector: LineSelector
## How many lines of each tone have been spoken this session (debug overlay, tests).
var tone_counts: Dictionary[StringName, int] = {&"bold": 0, &"cautious": 0, &"neutral": 0}
var last_line_id: String = ""

var _rng := RandomNumberGenerator.new()
var _clock: float = 0.0
var _last_spoken_at: float = -INF
var _last_event_at: Dictionary[StringName, float] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	selector = LineSelector.load_file(LINES_PATH)
	for e: String in selector.errors:
		Diagnostics.error("Narrator: %s" % e)
	_rng.randomize()
	# Cooldowns, recent lines and tone counts belong to one run.
	GameState.run_replaced.connect(reset_session)


func _process(delta: float) -> void:
	_clock += delta / maxf(Engine.time_scale, 0.01)


## Tests make selection repeatable.
func seed_rng(value: int) -> void:
	_rng.seed = value


func reset_session() -> void:
	selector.recent.clear()
	_last_event_at.clear()
	_last_spoken_at = -INF
	last_line_id = ""
	for t: StringName in tone_counts:
		tone_counts[t] = 0


## Something happened that the Steward might comment on, in district `level` ("" anywhere). Returns the
## line spoken, or "".
func notify(event: StringName, level: String = "") -> String:
	if not Steward.assists().narration:
		return ""
	var since_event := _clock - float(_last_event_at.get(event, -INF))
	if since_event < selector.cooldown_for(event):
		return ""
	if _clock - _last_spoken_at < MIN_GAP and not selector.is_priority(event):
		return ""
	if not purpose_allowed(selector.purpose_of(event)):
		return ""
	if warning_in_progress():
		return ""
	# "Stop praising me": and no drift toward the voice you like to hear.
	var plain := GameState.has_override(Overrides.NO_PRAISE)
	var line := selector.pick(event, 0.0 if plain else GameState.run.playstyle_profile.lean(), _rng, level, &"neutral" if plain else &"")
	if line == null:
		return ""
	_last_event_at[event] = _clock
	_last_spoken_at = _clock
	tone_counts[line.tone] = int(tone_counts.get(line.tone, 0)) + 1
	last_line_id = line.id
	line_spoken.emit(line.id, line.text)
	return line.id


## Whether the Steward may say a line with this purpose now: it's listening and reaches you, and no
## signed order forbids it.
func allows(purpose: StringName) -> bool:
	return Steward.assists().narration and purpose_allowed(purpose)


## Whether the signed orders let a line with this purpose be said: "Never warn me about traps" silences
## warnings, "Stop praising me" silences praise. Facts are always allowed.
func purpose_allowed(purpose: StringName) -> bool:
	match purpose:
		LineSelector.FACT:
			return true
		LineSelector.WARNING:
			return not GameState.has_override(Overrides.NO_TRAP_WARNINGS)
		LineSelector.PRAISE:
			return not GameState.has_override(Overrides.NO_PRAISE)
	return false


## A one-off line, voiced and subtitled. One of the Steward's own lines is judged by its own purpose
## (VoiceLines.purpose_of), whatever the caller says; `purpose` only counts for text that isn't one of
## them. While a warning is being said nothing else is, unless `urgent` (a boss's call, which its fight
## spaces so it never cuts its own: Boss.CALL_GAPS). Returns whether it was said.
func speak_text(line_id: String, text: String, purpose: StringName, urgent: bool = false) -> bool:
	var known := VoiceLines.purpose_of(line_id)
	if not allows(known if known != &"" else purpose):
		return false
	if warning_in_progress() and not urgent:
		return false
	_last_spoken_at = _clock
	last_line_id = line_id
	line_spoken.emit(line_id, text)
	return true


## A line from data/narration/steward_fixed.json (`urgent`: see speak_text). Returns whether it was said.
func say_fixed(line_id: String, urgent: bool = false) -> bool:
	var text := VoiceLines.fixed(line_id)
	return text != "" and speak_text(line_id, text, VoiceLines.purpose(line_id), urgent)


## A warning is being said: it's what you need to hear in full, so nothing cuts it off but a boss's call.
func warning_in_progress() -> bool:
	return Sound.voice_line != "" and VoiceLines.purpose_of(Sound.voice_line) == LineSelector.WARNING and Sound.voice_left() > 0.0


## A screen's voice-over (a core card, a memory log, the loadout nudge), judged by the line's own
## purpose: the text is already on screen, so it's voiced, not subtitled. On the Ark's screens the
## Steward is with you whenever it's listening. Like any line, it waits for a warning being said.
## Returns whether it was said.
func voice_over(line_id: String) -> bool:
	var purpose := VoiceLines.purpose_of(line_id)
	if purpose == &"":
		Diagnostics.error("Narrator: %s isn't one of the Steward's lines" % line_id)
		return false
	if not Steward.voice_on or not purpose_allowed(purpose) or warning_in_progress():
		return false
	last_line_id = line_id
	Sound.say(line_id)
	return true
