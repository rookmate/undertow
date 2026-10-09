extends Node
## Turns gameplay events into the Steward's narration. Lines come from data/narration/steward_lines.json
## through a LineSelector biased by the playstyle profile. Muted, the Steward is silent. Each event has a
## cooldown, and lines keep a short gap between them unless the event is a priority.

signal line_spoken(line_id: String, text: String)

const LINES_PATH := "res://data/narration/steward_lines.json"
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
		push_error("Narrator: %s" % e)
	_rng.randomize()


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


## Something happened that the Steward might comment on. Returns the line spoken, or "".
func notify(event: StringName) -> String:
	if not Steward.assists().narration:
		return ""
	var since_event := _clock - float(_last_event_at.get(event, -INF))
	if since_event < selector.cooldown_for(event):
		return ""
	if _clock - _last_spoken_at < MIN_GAP and not selector.is_priority(event):
		return ""
	var line := selector.pick(event, GameState.run.playstyle_profile.lean(), _rng)
	if line == null:
		return ""
	_last_event_at[event] = _clock
	_last_spoken_at = _clock
	tone_counts[line.tone] = int(tone_counts.get(line.tone, 0)) + 1
	last_line_id = line.id
	line_spoken.emit(line.id, line.text)
	return line.id


## A one-off line that isn't in the pools (still silent when muted).
func speak_text(line_id: String, text: String) -> void:
	if not Steward.assists().narration:
		return
	_last_spoken_at = _clock
	last_line_id = line_id
	line_spoken.emit(line_id, text)
