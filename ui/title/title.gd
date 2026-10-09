extends Control
## Title screen. The Steward's last words before the Quiet play under the wordmark, cut off mid-sentence.

const QUIET_LINE := "Good morning, Meridian. Today will be—"
const TYPE_SECONDS := 2.4

var _wordmark: Wordmark
var _new_game: Button
var _continue: Button
var _quit: Button
var _quiet: Label
var _prompt: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop: Control = preload("res://ui/title/title_backdrop.gd").new()
	add_child(backdrop)
	var rain := Rain.new()
	add_child(rain)
	rain.setup(Rect2(Vector2.ZERO, get_viewport_rect().size), 0.8)
	add_child(_glow_environment())

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 18)
	add_child(column)

	_wordmark = Wordmark.new()
	_wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_wordmark)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 70)
	column.add_child(spacer)

	_new_game = _menu_button("NEW GAME", column)
	_continue = _menu_button("CONTINUE", column)
	_quit = _menu_button("QUIT", column)
	_continue.disabled = not SaveService.has_save()
	_new_game.pressed.connect(_start_new_game)
	_continue.pressed.connect(_continue_game)
	_quit.pressed.connect(func() -> void: get_tree().quit())

	_quiet = Label.new()
	_quiet.add_theme_font_override(&"font", UiFonts.narration())
	_quiet.add_theme_font_size_override(&"font_size", 34)
	_quiet.add_theme_color_override(&"font_color", Palette.STEWARD_GOLD)
	_quiet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quiet.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_quiet.offset_left = -700
	_quiet.offset_right = 700
	_quiet.offset_top = -170
	_quiet.offset_bottom = -110
	_quiet.visible_ratio = 0.0
	add_child(_quiet)

	var footer := Label.new()
	footer.text = "v%s · placeholder art" % ProjectSettings.get_setting("application/config/version", "")
	footer.add_theme_font_override(&"font", UiFonts.mono())
	footer.add_theme_font_size_override(&"font_size", 16)
	footer.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 32
	footer.offset_top = -52
	add_child(footer)

	_prompt = Label.new()
	_prompt.add_theme_font_override(&"font", UiFonts.mono())
	_prompt.add_theme_font_size_override(&"font_size", 16)
	_prompt.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_right = -32
	_prompt.offset_left = -432
	_prompt.offset_top = -52
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_prompt)
	_update_prompt()
	Controls.device_changed.connect(func(_d: int) -> void: _update_prompt())

	_focus_first()
	_play_quiet_line()


func _start_new_game() -> void:
	GameState.new_run()
	SceneRouter.goto(&"loadout")


func _continue_game() -> void:
	var result := SaveService.load_run()
	if result.status != SaveStore.Status.OK:
		_show_notice(result.note)
		return
	var target := SceneRouter.key_for_location(result.run.location)
	if target == &"":
		_show_notice("The save points somewhere this build doesn't have yet (%s)." % result.run.location)
		return
	GameState.replace_run(result.run)
	SceneRouter.goto(target)


func _show_notice(text: String) -> void:
	_prompt.text = text


func _menu_button(text: String, parent: Control) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(280, 0)
	parent.add_child(b)
	return b


func _focus_first() -> void:
	for b: Button in [_new_game, _continue, _quit]:
		if not b.disabled:
			b.grab_focus()
			return


func _update_prompt() -> void:
	_prompt.text = "%s  SELECT" % Controls.prompt(&"ui_accept")


func _play_quiet_line() -> void:
	_quiet.text = QUIET_LINE
	var ring := _wordmark.ring
	await Wait.seconds(self, 0.8)
	ring.state = StewardRing.State.SPEAKING
	var tween := create_tween()
	tween.tween_property(_quiet, "visible_ratio", 1.0, TYPE_SECONDS)
	await tween.finished
	ring.state = StewardRing.State.GLITCH
	await Wait.seconds(self, 0.5)
	ring.state = StewardRing.State.IDLE
	var fade := create_tween()
	fade.tween_property(_quiet, "modulate:a", 0.4, 1.6)


static func _glow_environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	return we
