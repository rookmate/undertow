extends CanvasLayer
## Live readout of every tracked variable (F3, or Back+R3 on a controller). Debug builds only.
## Launch with `-- --debug-overlay` to start with it open (used for recordings).

const REFRESH_SECONDS := 0.2

var _panel: PanelContainer
var _label: RichTextLabel
var _accum: float = 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(&"panel", UiTheme.panel_style(0.9))
	_panel.position = Vector2(24, 200)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2(560, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override(&"normal_font", UiFonts.mono())
	_label.add_theme_font_override(&"bold_font", UiFonts.mono_medium())
	_label.add_theme_font_size_override(&"normal_font_size", 17)
	_label.add_theme_font_size_override(&"bold_font_size", 17)
	_panel.add_child(_label)
	visible = OS.is_debug_build() and OS.get_cmdline_user_args().has("--debug-overlay")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if not OS.is_debug_build():
		return
	visible = not visible
	_accum = REFRESH_SECONDS


func _process(delta: float) -> void:
	if not visible:
		return
	_accum += delta
	if _accum < REFRESH_SECONDS:
		return
	_accum = 0.0
	_label.text = DebugReadout.text_for(GameState.run, Steward.voice_on)
