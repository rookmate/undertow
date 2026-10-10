class_name ClinicScreen
extends CanvasLayer
## The Clinic (the Ark, from Mercy General): run by people again. It stocks you up with field dressings
## whenever you're home (one puts 40 Integrity back), and keeps the triage records: the memory logs about
## who the Steward sent help to, readable here once recovered. While it listens, the Steward says its
## piece on each record, aloud.

signal closed

## Memory logs about medical triage decisions carry this topic (data/logs/memory_logs.json).
const TOPIC := "triage"

var _rows: Dictionary[String, Button] = {}
var _record: Label
var _reply: Label
var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label("THE CLINIC", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(100, 56)
	add_child(title)
	var sub := _label("Run by people again. Dressings for the road, and the triage records it kept.", UiFonts.label(), 24, Palette.IVORY_DIM)
	sub.position = Vector2(104, 132)
	add_child(sub)
	var stock := _label("FIELD DRESSINGS  %d / %d" % [GameState.run.dressings, Tunables.DRESSINGS_MAX], UiFonts.mono_medium(), 24, Palette.IVORY)
	stock.position = Vector2(104, 196)
	add_child(stock)
	var how := _label("Restocked whenever you're home.  %s  puts one on: +%d Integrity." % [Controls.prompt(&"use_item"), roundi(Tunables.DRESSING_HEAL)], UiFonts.mono(), 16, Palette.IVORY_DIM)
	how.position = Vector2(106, 232)
	add_child(how)
	var head := _label("TRIAGE RECORDS", UiFonts.mono_medium(), 16, Palette.IVORY_DIM)
	head.position = Vector2(104, 300)
	add_child(head)
	var list := VBoxContainer.new()
	list.position = Vector2(100, 330)
	list.add_theme_constant_override(&"separation", 10)
	add_child(list)
	for id: String in triage_logs():
		list.add_child(_row(id))
	_record = _label("", UiFonts.mono(), 18, Palette.IVORY)
	_record.position = Vector2(780, 300)
	_record.size = Vector2(1040, 360)
	_record.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_record)
	_reply = _label("", UiFonts.narration(), 28, Palette.STEWARD_GOLD)
	_reply.position = Vector2(780, 700)
	_reply.size = Vector2(1040, 200)
	_reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_reply)
	_back = Button.new()
	_back.text = "BACK TO THE ARK"
	_back.position = Vector2(100, 980)
	_back.custom_minimum_size = Vector2(320, 56)
	_back.pressed.connect(close)
	add_child(_back)
	Modals.push(self)
	if _rows.is_empty():
		_back.grab_focus()
	else:
		_rows[_rows.keys()[0]].grab_focus()


## Every triage log in the game, recovered ones first.
static func triage_logs() -> Array[String]:
	var recovered: Array[String] = []
	var not_yet: Array[String] = []
	for id: String in ContentDb.log_ids():
		if str(ContentDb.memory_log(id).get("topic", "")) != TOPIC:
			continue
		if GameState.run.logs_unlocked.has(id):
			recovered.append(id)
		else:
			not_yet.append(id)
	recovered.append_array(not_yet)
	return recovered


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _row(id: String) -> Button:
	var b := Button.new()
	var recovered := GameState.run.logs_unlocked.has(id)
	b.text = str(ContentDb.memory_log(id).get("title", id)).to_upper() if recovered else "UNRECOVERED"
	b.custom_minimum_size = Vector2(620, 52)
	b.disabled = not recovered
	b.pressed.connect(read.bind(id))
	_rows[id] = b
	return b


## Shows a record, and lets the Steward say what it thinks of it now (if it's listening).
func read(id: String) -> void:
	if not GameState.run.logs_unlocked.has(id):
		return
	var def := ContentDb.memory_log(id)
	_record.text = "\n".join(def.get("record", []) as Array)
	var said := Narrator.voice_over(VoiceLines.log_line(id))
	_reply.text = str(def.get("steward_now", "")) if said else ""


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()
