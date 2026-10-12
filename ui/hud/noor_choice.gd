class_name NoorChoice
extends CanvasLayer
## Noor's turn, decided (Bastion's Zulf beat; design/act-3.md): down at the border, she says her piece and
## you carry her to the Wardfolk's boat, or leave her. If her trust in you has fallen to the bottom, she
## won't take your hand, and the only way is to leave her. People talking: plain type.

signal closed

const LINES := {
	"carry": "It got there first. Of course it did. ... Help me up, then. Not for it. For the Ward.",
	"refuse": "Not from you. Not with that thing in your ear. Go on. I'll wait for my own people.",
}

var noor: NoorDown
var _carry: Button
var _leave: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(Palette.NEAR_BLACK, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var who := _label("NOOR", UiFonts.mono_medium(), 18, Palette.TRUTH_CYAN)
	who.position = Vector2(160, 240)
	add_child(who)
	var line := _label(LINES["refuse" if NoorDown.refuses() else "carry"], UiFonts.label(), 40, Palette.IVORY)
	line.position = Vector2(160, 280)
	line.size = Vector2(1560, 200)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(line)
	var row := VBoxContainer.new()
	row.position = Vector2(160, 560)
	row.add_theme_constant_override(&"separation", 14)
	add_child(row)
	if not NoorDown.refuses():
		_carry = _button("CARRY HER TO THE BOAT", carry)
		row.add_child(_carry)
	_leave = _button("LEAVE HER", leave)
	row.add_child(_leave)
	var note := _label("Carrying her, you can't fight, only roll. You walk slower.", UiFonts.mono(), 16, Palette.IVORY_DIM)
	note.position = Vector2(160, 720)
	note.visible = _carry != null
	add_child(note)
	Modals.push(self)
	(_carry if _carry != null else _leave).grab_focus()


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(560, 56)
	b.pressed.connect(on_press)
	return b


## Up on your shoulder; the curfew patrol comes for you both.
func carry() -> void:
	if noor == null or NoorDown.refuses():
		return
	noor.carried = true
	if noor.level != null:
		noor.level.player.set_carrying(true)
		noor.level.call_the_curfew_patrol()
	close()


## She stays in the Ward. She's gone from the run.
func leave() -> void:
	if noor != null:
		noor.staying = true
	GameState.noor_stays_in_ward()
	Narrator.say_fixed("noor_left")
	close()


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Modals.pop(self)
		closed.emit()
		queue_free()


func close() -> void:
	Modals.pop(self)
	closed.emit()
	queue_free()
