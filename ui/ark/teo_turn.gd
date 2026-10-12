class_name TeoTurn
extends CanvasLayer
## Teo's turn (design/act-3.md): at the dock, as you set off for the Spire, he says what he thinks you're
## going to do to it. With his trust in you at the bottom he leaves the Ark and is gone from the run;
## otherwise he stays, and says so. People talking: plain type. Closing it sets off.

signal closed

## His trust in you at or below this, and he leaves.
const LEAVES_AT := -3
const LINES: Array[String] = [
	"The Spire. I worked in there for eleven years. I know what you'll find, and most of it's mine.",
	"You're going to get to the bottom of it and decide what it gets to be. Somebody has to. I know that.",
]
const STAYS := "I'll be here when you get back. Whatever you do to it, I'll be here."
const LEAVES := "Not you. Not after everything you've sided against. I won't watch you take it apart."

## He's gone: this turn was the end of him on the Ark.
var left: bool = false
var _go: Button


static func leaves() -> bool:
	return GameState.run.teo_trust <= LEAVES_AT


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var head := _label("THE DOCK", UiFonts.mono_medium(), 18, Palette.IVORY_DIM)
	head.position = Vector2(160, 120)
	add_child(head)
	var who := _label("TEO", UiFonts.mono_medium(), 18, Palette.HUMAN_CREAM)
	who.position = Vector2(160, 170)
	add_child(who)
	var y := 210.0
	left = leaves()
	for line: String in LINES + [LEAVES if left else STAYS]:
		var l := _label(line, UiFonts.label(), 36, Palette.IVORY)
		l.position = Vector2(160, y)
		l.size = Vector2(1560, 90)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(l)
		y += 96.0
	if left:
		var gone := _label("Teo leaves the Ark.", UiFonts.mono(), 18, Palette.IVORY_DIM)
		gone.position = Vector2(160, y + 20.0)
		add_child(gone)
	_go = Button.new()
	_go.text = "SET OFF FOR THE SPIRE"
	_go.position = Vector2(160, 960)
	_go.custom_minimum_size = Vector2(420, 56)
	_go.pressed.connect(close)
	add_child(_go)
	Modals.push(self)
	_go.grab_focus()
	GameState.teo_turn(left)


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Modals.pop(self)
	closed.emit()
	queue_free()
