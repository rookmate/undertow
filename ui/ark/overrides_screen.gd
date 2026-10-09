class_name OverridesScreen
extends CanvasLayer
## The Signal Room (mockup 6): standing orders the Steward must obey. Each row is an order in your words,
## its difficulty pips, what it does, and what it unlocks; select it to sign or revoke it. The city's
## difficulty meter sums the signed orders' pips. The Steward answers each order (its reasoning, voiced)
## while it listens; muted, the orders still bind it, and it says nothing.

signal closed

var _rows: Dictionary[String, Button] = {}
var _meter: Control
var _reply: Label
var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label("THE SIGNAL ROOM", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(100, 56)
	add_child(title)
	var sub := _label("Standing orders the Steward must obey. Each makes the city harder, and tells you how it reasons.", UiFonts.label(), 24, Palette.IVORY_DIM)
	sub.position = Vector2(104, 132)
	add_child(sub)
	var list := VBoxContainer.new()
	list.position = Vector2(100, 190)
	list.add_theme_constant_override(&"separation", 10)
	add_child(list)
	Overrides.ensure_loaded()
	for id: String in Overrides.IDS:
		if Overrides.is_known(id):
			list.add_child(_row(id))
	_meter = _Meter.new()
	_meter.position = Vector2(1300, 200)
	_meter.size = Vector2(500, 120)
	add_child(_meter)
	var reply_head := _label("THE STEWARD", UiFonts.mono_medium(), 16, Palette.IVORY_DIM)
	reply_head.position = Vector2(1300, 380)
	add_child(reply_head)
	_reply = _label("", UiFonts.narration(), 30, Palette.STEWARD_GOLD)
	_reply.position = Vector2(1300, 410)
	_reply.size = Vector2(520, 300)
	_reply.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_reply)
	_back = Button.new()
	_back.text = "BACK TO THE ARK"
	_back.position = Vector2(100, 980)
	_back.custom_minimum_size = Vector2(320, 56)
	_back.pressed.connect(close)
	add_child(_back)
	_refresh()
	Modals.push(self)
	if not _rows.is_empty():
		_rows[Overrides.IDS[0]].grab_focus()


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _row(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(1140, 112)
	b.add_theme_stylebox_override(&"normal", UiTheme.panel_style(0.9))
	b.pressed.connect(toggle.bind(id))
	var order := _label(Overrides.order_text(id), UiFonts.heading(), 30, Palette.IVORY)
	order.position = Vector2(24, 12)
	b.add_child(order)
	var effect := _label(Overrides.field(id, "effect"), UiFonts.mono(), 16, Palette.IVORY_DIM)
	effect.position = Vector2(26, 54)
	b.add_child(effect)
	var unlocks := _label("UNLOCKS: " + Overrides.field(id, "unlocks"), UiFonts.mono(), 14, Palette.IVORY_DIM)
	unlocks.position = Vector2(26, 80)
	b.add_child(unlocks)
	var pips := _label("●".repeat(Overrides.pips(id)) + "○".repeat(3 - Overrides.pips(id)), UiFonts.mono_medium(), 20, Palette.IVORY)
	pips.position = Vector2(860, 16)
	b.add_child(pips)
	var state := _label("", UiFonts.heading(), 28, Palette.IVORY)
	state.name = "State"
	state.position = Vector2(960, 12)
	b.add_child(state)
	for child: Node in b.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows[id] = b
	return b


## Signs an order or revokes it, saves, and lets the Steward answer (if it's listening).
func toggle(id: String) -> void:
	var signed := not GameState.has_override(id)
	GameState.set_override(id, signed)
	SaveFlow.checkpoint(get_tree())
	var line := Overrides.reply_line(id, signed)
	var text := Overrides.field(id, "sign" if signed else "revoke")
	if Steward.assists().narration:
		_reply.text = text
		Narrator.speak_text(line, text)
	else:
		_reply.text = ""
	_refresh()


func _refresh() -> void:
	for id: String in _rows:
		var signed := GameState.has_override(id)
		var state := _rows[id].get_node(^"State") as Label
		state.text = "SIGNED" if signed else "SIGN"
		state.add_theme_color_override(&"font_color", Palette.IVORY if signed else Palette.GREY_COLD)
		var style := UiTheme.panel_style(0.9)
		if signed:
			style.border_color = Palette.IVORY
			style.set_border_width_all(2)
		_rows[id].add_theme_stylebox_override(&"normal", style)
	_meter.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()


## The city's difficulty: one pip per order's difficulty, filled for the signed ones.
class _Meter:
	extends Control

	func _draw() -> void:
		var d := Overrides.difficulty(GameState.run.active_overrides)
		draw_string(UiFonts.mono_medium(), Vector2(0, 18), "CITY DIFFICULTY  %d / %d" % [d.x, d.y], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Palette.IVORY)
		for i: int in d.y:
			var r := Rect2(Vector2(i * 46, 34), Vector2(38, 24))
			if i < d.x:
				draw_rect(r, Palette.IVORY)
			else:
				draw_rect(r, Palette.IVORY_FAINT, false, 1.5)
