class_name Confession
extends Node2D
## The Spire (design/act-3.md): at set places along the way the Steward stops lying and says what it did,
## plainly, in the first person for the first time. Walk past one and it's said, aloud if it's listening,
## and written into the glass where you stand in its own serif, so that muted you can still read it.
## Once each.

## Within this of it (tiles), it's said.
const REACH_TILES := 1.6
## How long the words take to come up in the glass.
const FADE_IN := 1.2

var line_id: String = ""
var said: bool = false
var level: Level
var _shown: float = 0.0
var _words: Label


func setup(owner_level: Level, cell: Vector2i, id: String) -> void:
	level = owner_level
	line_id = id
	position = Iso.cell_center(cell)
	z_index = 20
	_words = Label.new()
	_words.text = VoiceLines.fixed(id)
	_words.add_theme_font_override(&"font", UiFonts.narration())
	_words.add_theme_font_size_override(&"font_size", 22)
	_words.add_theme_color_override(&"font_color", Palette.STEWARD_GOLD)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_words.size = Vector2(420, 120)
	_words.position = Vector2(-210, -250)
	_words.modulate.a = 0.0
	add_child(_words)


func _physics_process(_delta: float) -> void:
	if said or level == null or level.player == null:
		return
	if Iso.ground_distance(global_position, level.player.global_position) <= REACH_TILES:
		said = true
		Narrator.say_in_full(line_id)


func _process(delta: float) -> void:
	if said and _shown < FADE_IN:
		_shown = minf(FADE_IN, _shown + delta)
		_words.modulate.a = 0.85 * _shown / FADE_IN


## The words in the glass, once it's said them (what you can read, muted or not).
func written() -> String:
	return _words.text if said else ""
