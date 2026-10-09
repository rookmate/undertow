class_name ArchiveScreen
extends CanvasLayer
## The Archive (mockup 5): read and replay recovered memories. A log list (the Steward's comforting
## records, the truth it buried, what it never indexed, and what you left behind), a decision-record
## readout with replay, the Steward's present-day comment, and Noor's and Teo's reactions with trust
## changes. Opening it pauses the Ark.

signal closed

const LINE_SECONDS := 0.45

var selected: String = ""
## True while a replay is printing its record line by line.
var replaying: bool = false
var last_replay: ArchiveModel.Replay

var _list: VBoxContainer
var _title: Label
var _kind: Label
var _record: RecordView
var _replay: Button
var _now_heading: Label
var _now: Label
var _noor: Label
var _teo: Label
var _back: Button
var _shown_lines: int = 0
var _buttons: Dictionary[String, Button] = {}


## The decision record's box. Up and down scroll it from a keyboard or a pad (Godot's own scrolling
## only reads keys); when the record fits, they move focus as usual.
class RecordView:
	extends RichTextLabel

	func _gui_input(event: InputEvent) -> void:
		var bar := get_v_scroll_bar()
		if bar.max_value <= bar.page:
			return
		var lines := 0
		if event.is_action_pressed(&"ui_up", true):
			lines = -2
		elif event.is_action_pressed(&"ui_down", true):
			lines = 2
		if lines != 0:
			bar.value += lines * get_theme_font(&"normal_font").get_height(get_theme_font_size(&"normal_font_size"))
			accept_event()


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label("THE ARCHIVE", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(80, 50)
	add_child(title)
	var sub := _label("RECOVERED MEMORIES · THE VELLUM", UiFonts.mono(), 18, Palette.IVORY_DIM)
	sub.position = Vector2(84, 132)
	add_child(sub)
	# The list grows with every district: it scrolls, and follows controller focus.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(80, 190)
	scroll.size = Vector2(590, 760)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", 8)
	scroll.add_child(_list)
	_title = _bounded(_label("", UiFonts.heading(), 44, Palette.IVORY), Vector2(700, 180), Vector2(1140, 56))
	add_child(_title)
	_kind = _label("", UiFonts.mono_medium(), 16, Palette.IVORY_DIM)
	_kind.position = Vector2(704, 240)
	add_child(_kind)
	var box := PanelContainer.new()
	box.position = Vector2(700, 274)
	box.size = Vector2(1140, 290)
	add_child(box)
	# A long record scrolls inside its box instead of pushing everything below it down; it takes focus so
	# a pad can scroll back through it (up/down while it has focus, left back to the list).
	_record = RecordView.new()
	_record.focus_mode = Control.FOCUS_ALL
	_record.bbcode_enabled = false
	_record.fit_content = false
	_record.scroll_active = true
	_record.scroll_following = true
	_record.custom_minimum_size = Vector2(1100, 250)
	_record.add_theme_font_override(&"normal_font", UiFonts.mono())
	_record.add_theme_font_size_override(&"normal_font_size", 20)
	_record.add_theme_color_override(&"default_color", Palette.IVORY)
	box.add_child(_record)
	_replay = Button.new()
	_replay.text = "REPLAY"
	_replay.position = Vector2(700, 578)
	_replay.custom_minimum_size = Vector2(220, 52)
	_replay.pressed.connect(_on_replay)
	add_child(_replay)
	_now_heading = _label("THE STEWARD, NOW", UiFonts.mono_medium(), 16, Palette.IVORY_DIM)
	_now_heading.position = Vector2(704, 650)
	add_child(_now_heading)
	_now = _bounded(_label("", UiFonts.narration(), 30, Palette.STEWARD_GOLD), Vector2(700, 676), Vector2(1140, 90))
	_now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_now)
	_noor = _reaction(Vector2(700, 790))
	_teo = _reaction(Vector2(1280, 790))
	_back = Button.new()
	_back.text = "BACK TO THE ARK"
	_back.position = Vector2(80, 980)
	_back.custom_minimum_size = Vector2(320, 56)
	_back.pressed.connect(close)
	add_child(_back)
	_build_list()
	Modals.push(self)


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _reaction(at: Vector2) -> Label:
	var l := _bounded(_label("", UiFonts.label(), 26, Palette.HUMAN_CREAM), at, Vector2(540, 160))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l


## Text that keeps to its box however long the writers make it: clipped, with an ellipsis.
func _bounded(l: Label, at: Vector2, box: Vector2) -> Label:
	l.position = at
	l.size = box
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l


func _build_list() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	_buttons.clear()
	var first := ""
	for e: ArchiveModel.Entry in ArchiveModel.entries(GameState.run):
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(560, 54)
		b.clip_text = true
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_theme_font_size_override(&"font_size", 26)
		if e.state == ArchiveModel.State.UNRECOVERED:
			b.text = "   UNRECOVERED · — — —"
			b.disabled = true
		else:
			b.text = "   %s%s" % [e.title.to_upper(), "" if e.replayed else "  ·  NEW"]
			b.pressed.connect(select.bind(e.log_id))
			if first == "":
				first = e.log_id
		var dot := ArchiveDot.new()
		dot.kind = e.kind if e.state == ArchiveModel.State.UNLOCKED else "unrecovered"
		dot.position = Vector2(12, 21)
		b.add_child(dot)
		_list.add_child(b)
		b.focus_neighbor_right = b.get_path_to(_record)
		if e.state != ArchiveModel.State.UNRECOVERED:
			_buttons[e.log_id] = b
	if first != "":
		select(first)
		(_list.get_child(0) as Button).grab_focus()
	else:
		_back.grab_focus()


func select(log_id: String) -> void:
	if replaying:
		return
	selected = log_id
	if _buttons.has(log_id):
		_record.focus_neighbor_left = _record.get_path_to(_buttons[log_id])
	var def := ContentDb.memory_log(log_id)
	_title.text = str(def.get("title", log_id)).to_upper()
	var kind := str(def.get("kind", ""))
	_kind.text = {"comforting": "THE STEWARD'S RECORD", "truth": "TRUTH · WHAT IT DID", "unindexed": "UNINDEXED · IT NEVER READ THIS"}.get(kind, kind.to_upper())
	var replayed := GameState.run.logs_replayed.has(log_id)
	_shown_lines = _record_lines().size() if replayed else 0
	_render_record()
	_show_aftermath(replayed, null)
	_replay.text = "REPLAY AGAIN" if replayed else "REPLAY"


func _record_lines() -> PackedStringArray:
	var out := PackedStringArray()
	var raw: Variant = ContentDb.memory_log(selected).get("record", [])
	if raw is Array:
		for line: Variant in raw:
			out.append(str(line))
	return out


func _render_record() -> void:
	var lines := _record_lines()
	var shown := PackedStringArray()
	for i: int in mini(_shown_lines, lines.size()):
		shown.append(lines[i])
	if shown.is_empty():
		shown.append("[ decision record sealed · press REPLAY ]")
	_record.text = "\n".join(shown)


## The Steward's comment today and the companions' reactions, once the record has been seen.
func _show_aftermath(visible_now: bool, r: ArchiveModel.Replay) -> void:
	var def := ContentDb.memory_log(selected)
	var listening := Steward.voice_on
	_now_heading.visible = visible_now and listening
	_now.visible = visible_now and listening
	_now.text = str(def.get("steward_now", ""))
	_noor.visible = visible_now and GameState.run.noor_present
	_teo.visible = visible_now and GameState.run.teo_present
	var noor: Dictionary = def.get("noor", {})
	var teo: Dictionary = def.get("teo", {})
	_noor.text = "NOOR%s\n%s" % [_delta_text(r.noor_delta if r != null and r.first_time else 0), noor.get("text", "")]
	_teo.text = "TEO%s\n%s" % [_delta_text(r.teo_delta if r != null and r.first_time else 0), teo.get("text", "")]


static func _delta_text(delta: int) -> String:
	if delta == 0:
		return ""
	return "   %+d TRUST" % delta


func _on_replay() -> void:
	if replaying or selected == "":
		return
	replaying = true
	_show_aftermath(false, null)
	_shown_lines = 0
	_render_record()
	var total := _record_lines().size()
	for i: int in total:
		await Wait.seconds(self, LINE_SECONDS)
		_shown_lines = i + 1
		_render_record()
	last_replay = ArchiveModel.replay(selected)
	SaveFlow.checkpoint(get_tree())
	replaying = false
	_show_aftermath(true, last_replay)
	_replay.text = "REPLAY AGAIN"
	_refresh_list_marks()


func _refresh_list_marks() -> void:
	var i := 0
	for e: ArchiveModel.Entry in ArchiveModel.entries(GameState.run):
		var b := _list.get_child(i) as Button
		if e.state == ArchiveModel.State.UNLOCKED:
			b.text = "   %s%s" % [e.title.to_upper(), "" if e.replayed else "  ·  NEW"]
		i += 1


func _unhandled_input(event: InputEvent) -> void:
	if not Modals.is_top(self):
		return
	if event.is_action_pressed(&"ui_cancel") and not replaying:
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if replaying:
		return
	Modals.pop(self)
	closed.emit()
	queue_free()
