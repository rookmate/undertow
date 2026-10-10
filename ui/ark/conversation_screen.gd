class_name ConversationScreen
extends CanvasLayer
## Noor and Teo on an Act 2 district, once, after you've been (Conversations): each says their piece,
## and you answer: side with one, with the other, or say nothing. It moves their trust and each of them
## answers you. Plain type (Barlow), not the Steward's serif: it's people talking.

signal closed

var district: String = ""
## The answer given ("" until then): "noor", "teo" or "none".
var answered: String = ""

var _choices: Dictionary[String, Button] = {}
var _reply_noor: Label
var _reply_teo: Label
var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label(LevelCatalog.name_of(district).to_upper(), UiFonts.mono_medium(), 18, Palette.IVORY_DIM)
	title.position = Vector2(160, 120)
	add_child(title)
	_add_speech("NOOR", Conversations.line(district, "noor"), Vector2(160, 170), Palette.TRUTH_CYAN)
	_add_speech("TEO", Conversations.line(district, "teo"), Vector2(160, 380), Palette.HUMAN_CREAM)
	var list := VBoxContainer.new()
	list.position = Vector2(160, 620)
	list.add_theme_constant_override(&"separation", 12)
	add_child(list)
	for side: String in Conversations.SIDES:
		var b := Button.new()
		b.text = Conversations.answer_text(district, side, "label")
		b.custom_minimum_size = Vector2(760, 56)
		b.pressed.connect(answer.bind(side))
		list.add_child(b)
		_choices[side] = b
	_reply_noor = _label("", UiFonts.label(), 30, Palette.TRUTH_CYAN)
	_reply_noor.position = Vector2(1000, 620)
	_reply_noor.size = Vector2(800, 90)
	_reply_noor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_reply_noor)
	_reply_teo = _label("", UiFonts.label(), 30, Palette.HUMAN_CREAM)
	_reply_teo.position = Vector2(1000, 730)
	_reply_teo.size = Vector2(800, 90)
	_reply_teo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_reply_teo)
	_back = Button.new()
	_back.text = "BACK TO THE ARK"
	_back.position = Vector2(160, 960)
	_back.custom_minimum_size = Vector2(320, 56)
	_back.visible = false
	_back.pressed.connect(close)
	add_child(_back)
	Modals.push(self)
	_choices[Conversations.SIDES[0]].grab_focus()


func _add_speech(who: String, text: String, at: Vector2, col: Color) -> void:
	var name_label := _label(who, UiFonts.mono_medium(), 18, col)
	name_label.position = at
	add_child(name_label)
	var line := _label(text, UiFonts.label(), 40, Palette.IVORY)
	line.position = at + Vector2(0, 34)
	line.size = Vector2(1500, 150)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(line)


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


## Answers (once): trust moves, and each of them answers back.
func answer(side: String) -> void:
	if answered != "" or not GameState.have_conversation(district, side):
		return
	answered = side
	SaveFlow.checkpoint(get_tree())
	_reply_noor.text = "NOOR  " + Conversations.answer_text(district, side, "reply_noor")
	_reply_teo.text = "TEO  " + Conversations.answer_text(district, side, "reply_teo")
	for b: Button in _choices.values():
		b.disabled = true
	# What you said stays bright; the rest fall away.
	_choices[side].add_theme_color_override(&"font_disabled_color", Palette.IVORY)
	_back.visible = true
	_back.grab_focus()


## Backing out before answering leaves it for next time ("say nothing" is an answer; leaving isn't).
func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()
