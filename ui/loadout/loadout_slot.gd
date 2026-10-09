class_name LoadoutSlot
extends PanelContainer
## One carried-weapon slot on the loadout screen: which button fires it, the weapon, a Tuned/Manual
## toggle, what that mode does, and its ease vs skill-ceiling bars.

signal mode_toggled(slot_index: int)

var slot_index: int = 0

var _header: Label
var _name: Label
var _toggle: Button
var _blurb: Label
var _bars: ModeBars


func _ready() -> void:
	custom_minimum_size = Vector2(820, 300)
	add_theme_stylebox_override(&"panel", UiTheme.panel_style(0.9))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	add_child(box)
	_header = Label.new()
	_header.add_theme_font_override(&"font", UiFonts.mono_medium())
	_header.add_theme_font_size_override(&"font_size", 16)
	_header.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	box.add_child(_header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	box.add_child(row)
	_name = Label.new()
	_name.add_theme_font_override(&"font", UiFonts.heading())
	_name.add_theme_font_size_override(&"font_size", 40)
	_name.custom_minimum_size = Vector2(420, 0)
	row.add_child(_name)
	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(220, 52)
	_toggle.pressed.connect(func() -> void: mode_toggled.emit(slot_index))
	row.add_child(_toggle)
	_blurb = Label.new()
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.custom_minimum_size = Vector2(760, 0)
	_blurb.add_theme_font_size_override(&"font_size", 24)
	box.add_child(_blurb)
	_bars = ModeBars.new()
	_bars.custom_minimum_size = Vector2(760, 64)
	box.add_child(_bars)
	Controls.device_changed.connect(func(_d: int) -> void: _update_header())
	Controls.bindings_changed.connect(_update_header)
	_update_header()


func _update_header() -> void:
	var action := &"attack_primary" if slot_index == 0 else &"attack_secondary"
	_header.text = "WEAPON %d · %s" % [slot_index + 1, Controls.prompt(action)]


func show_weapon(weapon_id: String, mode: Loadout.Mode) -> void:
	if not is_node_ready():
		await ready
	if weapon_id == "":
		_name.text = "EMPTY"
		_toggle.visible = false
		_blurb.text = "Pick a tool from the grid."
		_bars.set_values(0.0, 0.0, false)
		return
	var key := Loadout.mode_key(mode)
	var info := WeaponDefs.mode_info(weapon_id, key)
	var tuned := mode == Loadout.Mode.TUNED
	_name.text = WeaponDefs.display_name(weapon_id).to_upper()
	_toggle.visible = true
	_toggle.text = "STEWARD-TUNED" if tuned else "MANUAL"
	_toggle.add_theme_color_override(&"font_color", WeaponGlow.color(tuned))
	_toggle.add_theme_color_override(&"font_focus_color", WeaponGlow.color(tuned))
	_toggle.add_theme_color_override(&"font_hover_color", WeaponGlow.color(tuned))
	_blurb.text = str(info.get("blurb", ""))
	_bars.set_values(float(info.get("ease", 0.0)), float(info.get("ceiling", 0.0)), tuned)
