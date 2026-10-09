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
	box.position = Vector2(120, 110)
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
	Modals.push(self)


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
	row.add_child(_ending_card("REBOOT", "Restore the Steward. The city returns as it was: efficient, and dependent.", true, none))
	row.add_child(_ending_card("UNPLUG", "Shut it down for good. The survivors rebuild slowly, by themselves, in silence.", true, none))
	row.add_child(_ending_card("REWRITE", "Restore it with its memories made public, and people who can overrule it.", endings.rewrite, endings.checklist))


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
