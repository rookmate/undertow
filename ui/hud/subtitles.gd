class_name Subtitles
extends Control
## The Steward's narration, bottom centre, in its own serif and its own gold, for as long as it takes to
## say. Gone the moment the voice is muted or it loses you: it stops speaking then, mid-word. A voiced
## line keeps the voice's own clock (Sound.voice_left()): up while the recording plays, through a pause
## and through slowed time alike, then a short fade; never shorter than it takes to read.

signal speaking_changed(speaking: bool)

const MIN_SECONDS := 2.6
const SECONDS_PER_CHAR := 0.045
const FADE := 0.4
## A line wider than this (at scale 1) wraps.
const MAX_WIDTH := 1500.0

var text: String = ""
## Seconds the line has left on screen.
var _left: float = 0.0
var _line_id: String = ""
## Reading time still owed, whatever the voice does (real seconds).
var _floor: float = 0.0
## The fade once the voice has finished (real seconds).
var _tail: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_line_id = line_id
	_floor = maxf(MIN_SECONDS, line_text.length() * SECONDS_PER_CHAR)
	_tail = FADE
	_left = _remaining()
	speaking_changed.emit(true)


## While its voice plays: what the recording has left, plus the fade. Never less than the reading time.
func _remaining() -> float:
	var voice := Sound.voice_left() if Sound.voice_line == _line_id else 0.0
	return maxf(_floor, voice + _tail)


func _on_coverage(covered: bool) -> void:
	if not covered:
		_on_voice(false)


func _on_voice(on: bool) -> void:
	if not on:
		_left = 0.0
		_floor = 0.0
		_tail = 0.0
		text = ""
		speaking_changed.emit(false)
		queue_redraw()


func _process(delta: float) -> void:
	# Nothing to fade while nothing is shown; the line that ends still gets one last (empty) redraw.
	if _left > 0.0:
		var real := delta / maxf(Engine.time_scale, 0.01)
		_floor = maxf(0.0, _floor - real)
		if Sound.voice_line != _line_id:
			_tail = maxf(0.0, _tail - real)
		_left = _remaining()
		if _left <= 0.0:
			speaking_changed.emit(false)
		queue_redraw()


func _draw() -> void:
	if _left <= 0.0 or text == "":
		return
	var alpha := clampf(_left / FADE, 0.0, 1.0)
	var font := UiFonts.narration()
	var font_size := roundi(34 * Options.subtitle_scale())
	var rows := wrapped(text, font, font_size, minf(MAX_WIDTH * Options.subtitle_scale(), size.x - 96.0))
	var line_h := font_size * 1.3
	var widest := 0.0
	for row: String in rows:
		widest = maxf(widest, font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	# The last row sits where a single line always has; the rest stack above it.
	var base_y := size.y - 190.0 - line_h * (rows.size() - 1)
	var box := Rect2(Vector2((size.x - widest) * 0.5 - 24.0, base_y - font_size * 1.24), Vector2(widest + 48.0, font_size * 1.76 + line_h * (rows.size() - 1)))
	draw_rect(box, Color(Palette.NEAR_BLACK, 0.55 * alpha))
	for i: int in rows.size():
		var w := font.get_string_size(rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2((size.x - w) * 0.5, base_y + line_h * i), rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(Palette.STEWARD_GOLD, alpha))


## `line` broken into rows no wider than `max_width` (word by word; a single word wider stays whole).
static func wrapped(line: String, font: Font, font_size: int, max_width: float) -> PackedStringArray:
	var rows := PackedStringArray()
	var row := ""
	for word: String in line.split(" ", false):
		var next := word if row == "" else row + " " + word
		if row != "" and font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
			rows.append(row)
			row = word
		else:
			row = next
	if row != "":
		rows.append(row)
	return rows
