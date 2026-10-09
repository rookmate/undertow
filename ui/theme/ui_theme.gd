class_name UiTheme
extends RefCounted
## The dark, minimal UI from the mockups: ivory on near-black, Barlow Condensed labels, visible focus
## for controller navigation. No gold here: gold belongs to the Steward, not to UI chrome.

## Makes the game's theme the default for every Control in the project.
static func install() -> void:
	ThemeDB.get_default_theme().merge_with(build())
	ThemeDB.fallback_font = UiFonts.label()
	ThemeDB.fallback_font_size = 26


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = UiFonts.label()
	t.default_font_size = 26

	t.set_color(&"font_color", &"Label", Palette.IVORY)

	t.set_font(&"font", &"Button", UiFonts.heading())
	t.set_font_size(&"font_size", &"Button", 34)
	t.set_color(&"font_color", &"Button", Palette.IVORY_DIM)
	t.set_color(&"font_hover_color", &"Button", Palette.IVORY)
	t.set_color(&"font_focus_color", &"Button", Palette.IVORY)
	t.set_color(&"font_pressed_color", &"Button", Palette.IVORY)
	t.set_color(&"font_hover_pressed_color", &"Button", Palette.IVORY)
	t.set_color(&"font_disabled_color", &"Button", Palette.GREY_DEEP)
	t.set_stylebox(&"normal", &"Button", _button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
	t.set_stylebox(&"hover", &"Button", _button_box(Palette.IVORY_FAINT, Color(0, 0, 0, 0)))
	t.set_stylebox(&"pressed", &"Button", _button_box(Palette.IVORY_FAINT, Palette.IVORY))
	t.set_stylebox(&"focus", &"Button", _button_box(Color(0, 0, 0, 0), Palette.IVORY))
	t.set_stylebox(&"disabled", &"Button", _button_box(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))

	t.set_stylebox(&"panel", &"PanelContainer", panel_style(0.86))
	t.set_stylebox(&"panel", &"Panel", panel_style(0.86))

	t.set_font(&"normal_font", &"RichTextLabel", UiFonts.mono())
	t.set_color(&"default_color", &"RichTextLabel", Palette.IVORY)
	return t


static func panel_style(alpha: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(Palette.NEAR_BLACK, alpha)
	s.border_color = Palette.IVORY_FAINT
	s.set_border_width_all(1)
	s.set_content_margin_all(16)
	return s


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2 if border.a > 0.0 else 0)
	s.content_margin_left = 22
	s.content_margin_right = 22
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s
