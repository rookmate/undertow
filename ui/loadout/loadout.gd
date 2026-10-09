extends Control
## Loadout (mockup 4): pick two of the reclaimed city tools before the level, and a mode for each.
## A 2×2 grid of weapons (the fourth not yet recovered) and two slots, each with a Tuned/Manual toggle
## and ease vs skill-ceiling bars. The Steward would rather you kept the tuning on.


## The district these weapons are for (from the saved location).
var level_id: String = LevelCatalog.FIRST_LEVEL
var picked: Array[String] = []
var modes: Dictionary[String, Loadout.Mode] = {}

var _cards: Dictionary[String, Button] = {}
var _slots: Array[LoadoutSlot] = []
var _depart: Button
var _notice: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var run := GameState.run
	var saved_level := LevelCatalog.level_in(run.location)
	if LevelCatalog.has_level(saved_level):
		level_id = saved_level
	picked = Loadout.from_run(run)
	for id: String in WeaponDefs.PLAYABLE:
		modes[id] = Loadout.chosen_mode(run, id)
	_build()
	_refresh()
	_cards[picked[0]].grab_focus()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.NEAR_BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "LOADOUT"
	title.add_theme_font_override(&"font", UiFonts.heading())
	title.add_theme_font_size_override(&"font_size", 72)
	title.position = Vector2(96, 64)
	add_child(title)
	var sub := Label.new()
	var slots := Loadout.slots_for(GameState.run.weapons_owned)
	sub.text = "%s · CARRY %s" % [LevelCatalog.name_of(level_id).to_upper(), "TWO" if slots == 2 else "ONE"]
	sub.add_theme_font_override(&"font", UiFonts.mono())
	sub.add_theme_font_size_override(&"font_size", 20)
	sub.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	sub.position = Vector2(100, 152)
	add_child(sub)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 20)
	grid.add_theme_constant_override(&"v_separation", 20)
	grid.position = Vector2(96, 220)
	add_child(grid)
	for id: String in WeaponDefs.GRID:
		var card := _make_card(id)
		grid.add_child(card)
		_cards[id] = card

	var slots_box := VBoxContainer.new()
	slots_box.add_theme_constant_override(&"separation", 20)
	slots_box.position = Vector2(1000, 220)
	add_child(slots_box)
	for i: int in Loadout.SLOTS:
		var slot := LoadoutSlot.new()
		slot.slot_index = i
		slot.mode_toggled.connect(_on_mode_toggled)
		slots_box.add_child(slot)
		_slots.append(slot)

	# The Steward's nudge only while it is listening (muted, it isn't talking).
	if Steward.voice_on:
		var line := Label.new()
		line.text = VoiceLines.fixed("loadout_nudge")
		_say_after.call_deferred(0.6, "loadout_nudge")
		line.add_theme_font_override(&"font", UiFonts.narration())
		line.add_theme_font_size_override(&"font_size", 28)
		line.add_theme_color_override(&"font_color", Palette.STEWARD_GOLD)
		line.position = Vector2(100, 900)
		add_child(line)

	_notice = Label.new()
	_notice.add_theme_font_override(&"font", UiFonts.mono())
	_notice.add_theme_font_size_override(&"font_size", 18)
	_notice.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	_notice.position = Vector2(1000, 860)
	add_child(_notice)

	_depart = Button.new()
	_depart.text = "DEPART"
	_depart.custom_minimum_size = Vector2(300, 64)
	_depart.position = Vector2(1520, 940)
	_depart.pressed.connect(_on_depart)
	add_child(_depart)


func _make_card(id: String) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(420, 290)
	card.disabled = not _owned(id)
	card.add_theme_stylebox_override(&"normal", UiTheme.panel_style(0.9))
	card.pressed.connect(_on_card_pressed.bind(id))
	var icon := WeaponIcon.new()
	icon.weapon_id = id
	icon.position = Vector2(24, 24)
	icon.size = Vector2(150, 150)
	card.add_child(icon)
	var name_label := Label.new()
	name_label.text = WeaponDefs.display_name(id).to_upper()
	name_label.add_theme_font_override(&"font", UiFonts.heading())
	name_label.add_theme_font_size_override(&"font_size", 36)
	name_label.position = Vector2(24, 190)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)
	var tag := Label.new()
	tag.text = WeaponDefs.asset_tag(id) if _owned(id) else "NOT RECOVERED"
	tag.add_theme_font_override(&"font", UiFonts.mono())
	tag.add_theme_font_size_override(&"font_size", 13)
	tag.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	tag.position = Vector2(26, 236)
	tag.size = Vector2(370, 40)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(tag)
	var badge := Label.new()
	badge.name = "Badge"
	badge.add_theme_font_override(&"font", UiFonts.mono_medium())
	badge.add_theme_font_size_override(&"font_size", 16)
	badge.position = Vector2(300, 24)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(badge)
	return card


func _on_card_pressed(id: String) -> void:
	var slots := Loadout.slots_for(GameState.run.weapons_owned)
	if picked.has(id):
		picked.erase(id)
	elif picked.size() < slots:
		picked.append(id)
	else:
		picked[slots - 1] = id
	_refresh()


func _owned(id: String) -> bool:
	return GameState.run.weapons_owned.has(id) and WeaponDefs.is_playable(id)


func _on_mode_toggled(slot_index: int) -> void:
	if slot_index >= picked.size():
		return
	var id := picked[slot_index]
	modes[id] = Loadout.Mode.MANUAL if modes[id] == Loadout.Mode.TUNED else Loadout.Mode.TUNED
	_refresh()


func _refresh() -> void:
	for id: String in _cards:
		var badge := _cards[id].get_node(^"Badge") as Label
		var at := picked.find(id)
		badge.text = "SLOT %d" % (at + 1) if at >= 0 else ""
	for i: int in _slots.size():
		var id := picked[i] if i < picked.size() else ""
		_slots[i].show_weapon(id, modes.get(id, Loadout.Mode.TUNED))
	var problem := Loadout.validate(picked, GameState.run.weapons_owned)
	_depart.disabled = problem != ""
	_notice.text = problem


func _on_depart() -> void:
	if Loadout.validate(picked, GameState.run.weapons_owned) != "":
		return
	var mode_keys: Dictionary[String, String] = {}
	for id: String in picked:
		mode_keys[id] = Loadout.mode_key(modes[id])
	SceneRouter.goto_level(level_id, func() -> void: GameState.set_loadout(picked, mode_keys))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.goto(&"title")


func _say_after(seconds: float, line_id: String) -> void:
	await get_tree().create_timer(seconds).timeout
	if is_inside_tree() and Steward.voice_on:
		Sound.say(line_id)
