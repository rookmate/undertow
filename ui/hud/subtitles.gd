class_name Subtitles
extends Control
## The Steward's narration, bottom centre, in its own serif and its own gold, for as long as it takes to
## say. Gone the moment the voice is muted or it loses you: it stops speaking then, mid-word.

signal speaking_changed(speaking: bool)

const MIN_SECONDS := 2.6
const SECONDS_PER_CHAR := 0.045
const FADE := 0.4

var text: String = ""
var _left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Narrator.line_spoken.connect(_on_line)
	Steward.voice_changed.connect(_on_voice)
	Steward.coverage_changed.connect(_on_coverage)


func _exit_tree() -> void:
	if Narrator.line_spoken.is_connected(_on_line):
		Narrator.line_spoken.disconnect(_on_line)
	if Steward.voice_changed.is_connected(_on_voice):
		Steward.voice_changed.disconnect(_on_voice)
	if Steward.coverage_changed.is_connected(_on_coverage):
		Steward.coverage_changed.disconnect(_on_coverage)


func is_speaking() -> bool:
	return _left > 0.0 and text != ""


func _on_line(line_id: String, line_text: String) -> void:
	text = line_text
	_left = maxf(maxf(MIN_SECONDS, line_text.length() * SECONDS_PER_CHAR), Sound.voice_length(line_id) + FADE)
	speaking_changed.emit(true)


func _on_coverage(covered: bool) -> void:
	if not covered:
		_on_voice(false)


func _on_voice(on: bool) -> void:
	if not on:
		_left = 0.0
		text = ""
		speaking_changed.emit(false)
		queue_redraw()


func _process(delta: float) -> void:
	# Nothing to fade while nothing is shown; the line that ends still gets one last (empty) redraw.
	if _left > 0.0:
		_left -= delta
		if _left <= 0.0:
			speaking_changed.emit(false)
		queue_redraw()


func _draw() -> void:
	if _left <= 0.0 or text == "":
		return
	var alpha := clampf(_left / FADE, 0.0, 1.0)
	var font := UiFonts.narration()
	var font_size := roundi(34 * Options.subtitle_scale())
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2((size.x - w) * 0.5, size.y - 190.0)
	draw_rect(Rect2(at + Vector2(-24, -font_size * 1.24), Vector2(w + 48, font_size * 1.76)), Color(Palette.NEAR_BLACK, 0.55 * alpha))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(Palette.STEWARD_GOLD, alpha))
