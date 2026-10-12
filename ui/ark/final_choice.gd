class_name FinalChoice
extends CanvasLayer
## The Council Chamber (design/act-3.md): three doors. Reboot and Unplug are always there; Rewrite only
## once its three conditions hold (EndingRules), and otherwise there's no third door at all. A choice
## is final: it asks once more, then the epilogue plays (Epilogue), then the credits, then the title.

signal closed

## The doors on offer, in order (Endings ids).
var offered: Array[String] = []
## The door picked and waiting to be confirmed ("" while choosing).
var asking: String = ""
## What happens once it's chosen: the epilogue. (Tests, which can't follow a scene change, replace it.)
var on_chosen: Callable = func() -> void: SceneRouter.goto(&"epilogue")
var _doors: Dictionary[String, Button] = {}
var _box: VBoxContainer
var _confirm_box: VBoxContainer
var _question: Label
var _yes: Button
var _no: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var head := _label("THE COUNCIL CHAMBER", UiFonts.mono_medium(), 18, Palette.IVORY_DIM)
	head.position = Vector2(160, 120)
	add_child(head)
	var line := _label("Whatever you choose is final.", UiFonts.label(), 40, Palette.IVORY)
	line.position = Vector2(160, 160)
	add_child(line)
	offered = [Endings.REBOOT, Endings.UNPLUG]
	if EndingRules.evaluate(GameState.run).rewrite:
		offered.append(Endings.REWRITE)
	_box = VBoxContainer.new()
	_box.position = Vector2(160, 300)
	_box.add_theme_constant_override(&"separation", 26)
	add_child(_box)
	for id: String in offered:
		var row := VBoxContainer.new()
		row.add_theme_constant_override(&"separation", 6)
		_box.add_child(row)
		var button := Button.new()
		button.text = Endings.TITLES[id]
		button.custom_minimum_size = Vector2(420, 56)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if id == Endings.REWRITE:
			button.add_theme_color_override(&"font_color", Palette.TRUTH_CYAN)
			button.add_theme_color_override(&"font_focus_color", Palette.TRUTH_CYAN)
			button.add_theme_color_override(&"font_hover_color", Palette.TRUTH_CYAN)
		button.pressed.connect(choose.bind(id))
		row.add_child(button)
		_doors[id] = button
		var say := _label(Endings.DOORS[id], UiFonts.label(), 26, Palette.IVORY_DIM)
		row.add_child(say)
	_confirm_box = VBoxContainer.new()
	_confirm_box.position = Vector2(160, 300)
	_confirm_box.add_theme_constant_override(&"separation", 18)
	_confirm_box.visible = false
	add_child(_confirm_box)
	_question = _label("", UiFonts.label(), 36, Palette.IVORY)
	_question.custom_minimum_size = Vector2(1500, 0)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_box.add_child(_question)
	_yes = Button.new()
	_yes.custom_minimum_size = Vector2(420, 56)
	_yes.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_yes.pressed.connect(confirm)
	_confirm_box.add_child(_yes)
	_no = Button.new()
	_no.text = "NOT YET"
	_no.custom_minimum_size = Vector2(420, 56)
	_no.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_no.pressed.connect(back)
	_confirm_box.add_child(_no)
	Modals.push(self)
	_doors[Endings.REBOOT].grab_focus()
	# Its word at the doors, aloud and in its own serif, if it's listening.
	if Narrator.voice_over("council_enter"):
		var said := _label(VoiceLines.fixed("council_enter"), UiFonts.narration(), 30, Palette.STEWARD_GOLD)
		said.position = Vector2(160, 900)
		add_child(said)


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func door(id: String) -> Button:
	return _doors.get(id)


## A door picked: it asks once more.
func choose(id: String) -> void:
	if not offered.has(id):
		return
	asking = id
	_question.text = Endings.CONFIRM[id]
	_yes.text = "%s. IT'S FINAL" % Endings.TITLES[id]
	_box.visible = false
	_confirm_box.visible = true
	_no.grab_focus()


## Not yet: back to the three doors.
func back() -> void:
	if asking == "":
		return
	var was := asking
	asking = ""
	_confirm_box.visible = false
	_box.visible = true
	_doors[was].grab_focus()


## Done: the run's ending is chosen and saved, and the epilogue plays.
func confirm() -> void:
	if asking == "":
		return
	var id := asking
	GameState.choose_ending(id)
	SaveFlow.checkpoint(get_tree())
	Modals.pop(self)
	closed.emit()
	on_chosen.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if asking != "":
			back()
		else:
			close()


func close() -> void:
	Modals.pop(self)
	closed.emit()
	queue_free()
