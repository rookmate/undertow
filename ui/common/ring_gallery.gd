extends Control
## Developer reference sheet: one large ring to compare with port-city/11-ring-reference.png and every
## state from the brief side by side.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Palette.SKY_TEAL
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var hero := StewardRing.new()
	hero.position = Vector2(60, 90)
	hero.size = Vector2(620, 620)
	add_child(hero)
	_caption("IDLE (reference size)", Vector2(60, 730), Vector2(620, 40))

	var states: Array[StewardRing.State] = [
		StewardRing.State.SPEAKING, StewardRing.State.WITHHOLDING, StewardRing.State.GLITCH,
		StewardRing.State.OFF, StewardRing.State.MUTED, StewardRing.State.REWRITE,
	]
	var names: Array[String] = ["SPEAKING", "WITHHOLDING (inlay +3°)", "GLITCH", "OFF (scorch)", "MUTED (title/HUD)", "REWRITE"]
	for i: int in states.size():
		var col := i % 3
		var row := int(i / 3.0)
		var origin := Vector2(760 + col * 380, 90 + row * 440)
		var ring := StewardRing.new()
		ring.position = origin
		ring.size = Vector2(340, 340)
		ring.state = states[i]
		add_child(ring)
		_caption(names[i], origin + Vector2(0, 350), Vector2(340, 40))

	var title := Label.new()
	title.text = "STEWARD RING · CANONICAL GEOMETRY (port-city/11)"
	title.add_theme_font_override(&"font", UiFonts.heading())
	title.add_theme_font_size_override(&"font_size", 34)
	title.position = Vector2(60, 24)
	add_child(title)


func _caption(text: String, pos: Vector2, box: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", UiFonts.mono())
	l.add_theme_font_size_override(&"font_size", 18)
	l.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = box
	add_child(l)
