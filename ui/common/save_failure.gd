class_name SaveFailure
extends CanvasLayer
## Tells the player a save didn't happen. At a checkpoint it is a notice: the run carries on in memory
## and the next checkpoint tries again. When leaving the run (back to the title, closing the window) it
## asks: try again, leave without saving, or stay.

signal resolved(choice: Choice)

enum Choice { RETRY, LEAVE, STAY }

const NOTICE_SECONDS := 6.0

var asking: bool = false
var error_code: Error = OK
var _answered: bool = false

var _first_button: Button


static func notice(tree: SceneTree, err: Error) -> SaveFailure:
	var s := SaveFailure.new()
	s.error_code = err
	tree.root.add_child(s)
	return s


static func ask(tree: SceneTree, err: Error) -> SaveFailure:
	var s := SaveFailure.new()
	s.error_code = err
	s.asking = true
	tree.root.add_child(s)
	return s


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", _warning_box())
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 12)
	panel.add_child(box)
	var head := Label.new()
	head.text = "COULDN'T SAVE"
	head.add_theme_font_override(&"font", UiFonts.heading())
	head.add_theme_font_size_override(&"font_size", 36)
	head.add_theme_color_override(&"font_color", Palette.IVORY)
	box.add_child(head)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(640, 0)
	body.text = ("Your progress is still here in this session. If you leave now, the last save is what you'll come back to. (%s)" if asking else "Your progress is kept in this session; the next checkpoint will try again. (%s)") % error_string(error_code)
	box.add_child(body)
	if asking:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 16)
		box.add_child(row)
		_first_button = _button(row, "TRY AGAIN", Choice.RETRY)
		_button(row, "LEAVE WITHOUT SAVING", Choice.LEAVE)
		_button(row, "STAY", Choice.STAY)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var dim := ColorRect.new()
		dim.color = Color(Palette.NEAR_BLACK, 0.7)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		center.add_child(panel)
		add_child(center)
		Modals.push(self, true)
		_first_button.grab_focus()
	else:
		panel.position = Vector2(40, 160)
		add_child(panel)
		var t := create_tween()
		t.tween_interval(NOTICE_SECONDS)
		t.tween_callback(queue_free)


func _button(row: HBoxContainer, text: String, choice: Choice) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(_choose.bind(choice))
	row.add_child(b)
	return b


func _choose(choice: Choice) -> void:
	if _answered or not Modals.is_top(self):
		return
	_answered = true
	Modals.pop(self)
	resolved.emit(choice)
	queue_free()


## The scene changed under the question (Modals.clear): the answer is "stay", and the question goes.
func dismiss() -> void:
	if asking and not _answered:
		_answered = true
		resolved.emit(Choice.STAY)
	queue_free()


static func _warning_box() -> StyleBoxFlat:
	var s := UiTheme.panel_style(0.95)
	s.border_color = Palette.IVORY
	s.set_border_width_all(2)
	return s
