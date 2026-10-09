class_name LevelHints
extends CanvasLayer
## Control hints at the start of a level, in the prompt style of the current device. Fade after a while.

const SHOW_SECONDS := 7.0

var _label: Label


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
	_refresh()
	Controls.device_changed.connect(func(_d: int) -> void: _refresh())
	var t := create_tween()
	t.tween_interval(SHOW_SECONDS)
	t.tween_property(_label, "modulate:a", 0.0, 1.5)


func _refresh() -> void:
	var move := "LEFT STICK" if Controls.using_pad() else "WASD"
	_label.text = "%s  MOVE    %s  DODGE    %s  PAUSE" % [move, Controls.prompt(&"dodge"), Controls.prompt(&"pause")]
