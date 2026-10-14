class_name RunSummary
extends CanvasLayer
## The run so far, from the Loop map: voice, cores, survivors, trust, and the three endings the city will
## offer (Rewrite with its checklist). Closes back to the map; or save and return to the title.

signal closed

var _back: Button


func _ready() -> void:
	# Over the Loop map it opens from, and opaque: the map's bright labels show through any translucent
	# backing.
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := VBoxContainer.new()
	box.position = Vector2(120, 110)
	box.add_theme_constant_override(&"separation", 18)
	add_child(box)
	var title := Label.new()
	title.text = "THE RUN SO FAR"
	title.add_theme_font_override(&"font", UiFonts.heading())
	title.add_theme_font_size_override(&"font_size", 72)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "What the city will offer you at the end, and how close you are to the third choice."
	sub.add_theme_font_size_override(&"font_size", 30)
	sub.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	box.add_child(sub)
	_add_details(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	box.add_child(row)
	_back = Button.new()
	_back.text = "BACK TO THE MAP"
	_back.custom_minimum_size = Vector2(360, 60)
	_back.pressed.connect(close)
	row.add_child(_back)
	var title_button := Button.new()
	title_button.text = "SAVE AND RETURN TO TITLE"
	title_button.custom_minimum_size = Vector2(420, 60)
	title_button.pressed.connect(_to_title)
	row.add_child(title_button)
	Modals.push(self)
	_back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()


## The run so far, and the three endings the city will offer (brief, mockup 7): Reboot and Unplug are
## always there; Rewrite shows its checklist, in truth cyan.
func _add_details(box: VBoxContainer) -> void:
	var run := GameState.run
	var summary := Label.new()
	var ratio := "—" if run.voice_tracked_seconds() <= 0.0 else "%d%%" % roundi(run.voice_on_ratio() * 100.0)
	summary.text = "VOICE ON %s OF PLAY · %d TOGGLES   ·   CORES %d POWER / %d TRUTH   ·   SURVIVORS %d   ·   NOOR %+d · TEO %+d" % [
		ratio, run.voice_toggle_count, run.cores_power(), run.cores_truth(), run.survivors_found(), run.noor_trust, run.teo_trust]
	summary.add_theme_font_override(&"font", UiFonts.mono())
	summary.add_theme_font_size_override(&"font_size", 18)
	summary.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	box.add_child(summary)
	var endings := EndingRules.evaluate(run)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	box.add_child(row)
	var none: Array[EndingRules.Condition] = []
	row.add_child(_ending_card("REBOOT", Endings.DOORS[Endings.REBOOT], true, none))
	row.add_child(_ending_card("UNPLUG", Endings.DOORS[Endings.UNPLUG], true, none))
	row.add_child(_ending_card("REWRITE", Endings.DOORS[Endings.REWRITE], endings.rewrite, endings.checklist))


func _ending_card(title: String, text: String, open: bool, checklist: Array[EndingRules.Condition]) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(500, 330)
	var style := UiTheme.panel_style(0.9)
	if title == "REWRITE":
		style.border_color = Palette.TRUTH_CYAN
	card.add_theme_stylebox_override(&"panel", style)
	var v := VBoxContainer.new()
	v.add_theme_constant_override(&"separation", 10)
	card.add_child(v)
	var head := Label.new()
	head.text = title + ("" if open else " · LOCKED")
	head.add_theme_font_override(&"font", UiFonts.heading())
	head.add_theme_font_size_override(&"font_size", 40)
	head.add_theme_color_override(&"font_color", Palette.TRUTH_CYAN if title == "REWRITE" else Palette.IVORY)
	v.add_child(head)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(460, 0)
	body.add_theme_font_size_override(&"font_size", 24)
	v.add_child(body)
	for c: EndingRules.Condition in checklist:
		var item := Label.new()
		item.text = "%s  %s\n     %s" % ["+" if c.met else "-", c.label, c.detail]
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.custom_minimum_size = Vector2(460, 0)
		item.add_theme_font_override(&"font", UiFonts.mono())
		item.add_theme_font_size_override(&"font_size", 15)
		item.add_theme_color_override(&"font_color", Palette.TRUTH_CYAN if c.met else Palette.IVORY_DIM)
		v.add_child(item)
	return card


func _to_title() -> void:
	if not await SaveFlow.before_leaving(get_tree()):
		return
	SceneRouter.goto(&"title")
