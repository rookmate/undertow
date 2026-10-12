class_name NoorDeparture
extends CanvasLayer
## Noor's turn begins (design/act-3.md): at the dock, as you set off for Harbor Ward, she tells you about
## the bridge and goes ahead in her own boat. Teo has his say, if he's here; the Steward its (aloud, and in
## its own serif, if it's listening). From then on she's away from the Ark. Closing it sets off.

signal closed

const LINES: Array[String] = [
	"Before you go. The Harbor Bridge, two years ago. My sister and her boys were on it.",
	"There was a car with a dashcam. Twenty-three thirty-eight. You can watch the traffic thin out. It knew.",
	"I've got the parts for a jammer. I'm going to cut its relay at the Ward border. Tonight.",
	"My boat-house is the last one on Net Lane. The footage is there, if you want it. Leave that thing on the boat.",
]
const TEO_LINE := "She's carried that for two years. Go after her."

var _go: Button


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
	var who := _label("NOOR", UiFonts.mono_medium(), 18, Palette.TRUTH_CYAN)
	who.position = Vector2(160, 170)
	add_child(who)
	var y := 210.0
	for line: String in LINES:
		var l := _label(line, UiFonts.label(), 36, Palette.IVORY)
		l.position = Vector2(160, y)
		l.size = Vector2(1560, 90)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(l)
		y += 96.0
	if GameState.run.companion_here(RunState.WHO_TEO):
		var teo_head := _label("TEO", UiFonts.mono_medium(), 18, Palette.HUMAN_CREAM)
		teo_head.position = Vector2(160, y + 20.0)
		add_child(teo_head)
		var teo := _label(TEO_LINE, UiFonts.label(), 32, Palette.IVORY_DIM)
		teo.position = Vector2(160, y + 56.0)
		add_child(teo)
	_go = Button.new()
	_go.text = "SET OFF FOR THE WARD"
	_go.position = Vector2(160, 960)
	_go.custom_minimum_size = Vector2(420, 56)
	_go.pressed.connect(close)
	add_child(_go)
	Modals.push(self)
	_go.grab_focus()
	GameState.noor_leaves_for_ward()
	if Narrator.voice_over("noor_departs"):
		var said := _label(VoiceLines.fixed("noor_departs"), UiFonts.narration(), 30, Palette.STEWARD_GOLD)
		said.position = Vector2(160, 870)
		add_child(said)


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
