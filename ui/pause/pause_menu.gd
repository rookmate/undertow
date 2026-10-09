class_name PauseMenu
extends CanvasLayer
## Esc / Start pauses the game: resume, or save and return to the title.

var _panel: PanelContainer
var _resume: Button


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(Palette.NEAR_BLACK, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = PanelContainer.new()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	var heading := Label.new()
	heading.text = "PAUSED"
	heading.add_theme_font_override(&"font", UiFonts.heading())
	heading.add_theme_font_size_override(&"font_size", 54)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	_resume = Button.new()
	_resume.text = "RESUME"
	_resume.pressed.connect(close)
	box.add_child(_resume)
	var quit := Button.new()
	quit.text = "SAVE AND RETURN TO TITLE"
	quit.pressed.connect(_to_title)
	box.add_child(quit)
	_panel.add_child(box)
	center.add_child(_panel)
	dim.add_child(center)
	add_child(dim)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	get_tree().paused = true
	_resume.grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _to_title() -> void:
	GameState.save()
	close()
	SceneRouter.goto(&"title")
