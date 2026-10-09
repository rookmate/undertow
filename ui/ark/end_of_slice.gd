class_name EndOfSlice
extends CanvasLayer
## The dock: the end of the vertical slice. The skiff isn't ready; more of Meridian is coming.

var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(Palette.NEAR_BLACK, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(160, 160)
	box.add_theme_constant_override(&"separation", 18)
	add_child(box)
	var title := Label.new()
	title.text = "THE SKIFF ISN'T READY"
	title.add_theme_font_override(&"font", UiFonts.heading())
	title.add_theme_font_size_override(&"font_size", 72)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "More of Meridian is coming. This is the end of the vertical slice."
	sub.add_theme_font_size_override(&"font_size", 30)
	sub.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	box.add_child(sub)
	_add_details(box)
	_back = Button.new()
	_back.text = "SAVE AND RETURN TO TITLE"
	_back.custom_minimum_size = Vector2(420, 60)
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.pressed.connect(_to_title)
	box.add_child(_back)
	_back.grab_focus()


## Extended in step 8 with the run summary and the endings the run would allow.
func _add_details(_box: VBoxContainer) -> void:
	pass


func _to_title() -> void:
	GameState.save()
	get_tree().paused = false
	SceneRouter.goto(&"title")
