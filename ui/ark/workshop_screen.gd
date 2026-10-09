class_name WorkshopScreen
extends CanvasLayer
## The Workshop (the Ark, from the Tideworks): upgrade each recovered tool's tuned mode and its manual
## mode, a level at a time, for scrap. While it listens, the Steward is pleased when you upgrade what it
## runs for you and resigned when you upgrade what you run yourself.

signal closed

var _rows: Dictionary[String, Button] = {}
var _scrap: Label
var _reply: Label
var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var title := _label("THE WORKSHOP", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(100, 56)
	add_child(title)
	var sub := _label("Each tool, each way of using it: a level at a time, for scrap. Every level hits %d%% harder." % roundi(Upgrades.DAMAGE_PER_LEVEL * 100.0), UiFonts.label(), 24, Palette.IVORY_DIM)
	sub.position = Vector2(104, 132)
	add_child(sub)
	_scrap = _label("", UiFonts.mono_medium(), 22, Palette.IVORY)
	_scrap.position = Vector2(1300, 70)
	add_child(_scrap)
	var list := VBoxContainer.new()
	list.position = Vector2(100, 200)
	list.add_theme_constant_override(&"separation", 10)
	add_child(list)
	for id: String in WeaponDefs.GRID:
		if GameState.run.weapons_owned.has(id) and WeaponDefs.is_playable(id):
			for mode: String in ["tuned", "manual"]:
				list.add_child(_row(id, mode))
	var reply_head := _label("THE STEWARD", UiFonts.mono_medium(), 16, Palette.IVORY_DIM)
	reply_head.position = Vector2(1300, 380)
	add_child(reply_head)
	_reply = _label("", UiFonts.narration(), 30, Palette.STEWARD_GOLD)
	_reply.position = Vector2(1300, 410)
	_reply.size = Vector2(520, 260)
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
		_rows.values()[0].grab_focus()
	else:
		_back.grab_focus()


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


func _row(weapon_id: String, mode: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(1120, 88)
	b.pressed.connect(buy.bind(weapon_id, mode))
	var name_label := _label("%s · %s" % [WeaponDefs.display_name(weapon_id).to_upper(), mode.to_upper()], UiFonts.heading(), 30, Palette.IVORY)
	name_label.position = Vector2(24, 10)
	b.add_child(name_label)
	var info := _label(str(WeaponDefs.mode_info(weapon_id, mode).get("blurb", "")), UiFonts.mono(), 14, Palette.IVORY_DIM)
	info.position = Vector2(26, 54)
	b.add_child(info)
	var state := _label("", UiFonts.mono_medium(), 20, Palette.IVORY)
	state.name = "State"
	state.position = Vector2(820, 24)
	b.add_child(state)
	for child: Node in b.get_children():
		(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows[Upgrades.key(weapon_id, mode)] = b
	return b


## Buys the next level; the Steward has a view on which mode you chose.
func buy(weapon_id: String, mode: String) -> void:
	if GameState.buy_upgrade(weapon_id, mode) != "":
		Sound.play(&"ui_back")
		return
	Sound.play(&"core_take")
	SaveFlow.checkpoint(get_tree())
	var line := "workshop_" + mode
	if Steward.assists().narration:
		_reply.text = VoiceLines.fixed(line)
		Narrator.speak_text(line, VoiceLines.fixed(line))
	_refresh()


func _refresh() -> void:
	var run := GameState.run
	_scrap.text = "SCRAP  %d" % run.scrap
	for k: String in _rows:
		var weapon_id := k.get_slice(":", 0)
		var mode := k.get_slice(":", 1)
		var at := Upgrades.level(run, weapon_id, mode)
		var pips := "●".repeat(at) + "○".repeat(Tunables.UPGRADE_LEVELS - at)
		var cost := Upgrades.next_cost(run, weapon_id, mode)
		var state := _rows[k].get_node(^"State") as Label
		state.text = "%s   %s" % [pips, "MAX" if cost < 0 else "UPGRADE · %d" % cost]
		var problem := Upgrades.why_not(run, weapon_id, mode)
		state.add_theme_color_override(&"font_color", Palette.IVORY if problem == "" else Palette.GREY_COLD)


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()
