class_name LevelHints
extends CanvasLayer
## Control hints at the start of a level, in the prompt style of the current device, fading after a while;
## then the map's place hints ('! x,y text' lines) while the Operator is near them. A hint starting with
## [voice_on] or [muted] shows only in that state.

const SHOW_SECONDS := 7.0
## Ground tiles from a hint's cell within which it shows.
const HINT_REACH := 2.6

var level: Level
## The place hint showing now ("" if none).
var place_hint: String = ""
## How far above the top of the weapon cards a place hint sits (px).
const HINT_ABOVE_CARDS := 34.0
var _label: Label
var _hint: Label


func _ready() -> void:
	layer = 10
	_label = Label.new()
	_label.add_theme_font_override(&"font", UiFonts.mono())
	_label.add_theme_font_size_override(&"font_size", 18)
	_label.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.offset_left = -900
	_label.offset_right = -40
	_label.offset_top = -64
	add_child(_label)
	_hint = Label.new()
	_hint.add_theme_font_override(&"font", UiFonts.mono_medium())
	_hint.add_theme_font_size_override(&"font_size", 20)
	_hint.add_theme_color_override(&"font_color", Palette.IVORY)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.offset_left = -600
	_hint.offset_right = 600
	# Between the Steward's subtitles and the weapon cards, over neither.
	_hint.offset_top = -(HudView.MARGIN + HudView.CHIP_H + HINT_ABOVE_CARDS)
	_hint.modulate.a = 0.0
	add_child(_hint)
	_refresh()
	Controls.device_changed.connect(func(_d: int) -> void: _refresh())
	Controls.bindings_changed.connect(_refresh)
	var t := create_tween()
	t.tween_interval(SHOW_SECONDS)
	t.tween_property(_label, "modulate:a", 0.0, 1.5)


func _process(delta: float) -> void:
	var text := ""
	if level != null and level.player != null and level.grid != null:
		for cell: Vector2i in level.grid.hints:
			if Iso.ground_distance(level.player.global_position, Iso.cell_center(cell)) <= HINT_REACH:
				text = shown_text(level.grid.hints[cell], Steward.voice_on)
	if text != "":
		_hint.text = text
	place_hint = text
	_hint.modulate.a = move_toward(_hint.modulate.a, 1.0 if text != "" else 0.0, delta * 3.0)


## What a hint says in this voice state ("" if it's for the other state), keys filled in.
static func shown_text(hint: String, voice_on: bool) -> String:
	if hint.begins_with("[voice_on] "):
		return with_keys(hint.trim_prefix("[voice_on] ")) if voice_on else ""
	if hint.begins_with("[muted] "):
		return with_keys(hint.trim_prefix("[muted] ")) if not voice_on else ""
	return with_keys(hint)


## A hint's {action} placeholders replaced by that action's key on the current device.
static func with_keys(text: String) -> String:
	var out := text
	for action: StringName in Controls.BINDINGS:
		out = out.replace("{%s}" % action, Controls.prompt(action))
	return out


func _refresh() -> void:
	_label.text = "%s  MOVE    %s  DODGE    %s  PAUSE" % [Controls.move_prompt(), Controls.prompt(&"dodge"), Controls.prompt(&"pause")]
