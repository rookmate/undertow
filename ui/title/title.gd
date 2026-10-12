extends Control
## Title screen. The Steward's last words before the Quiet play under the wordmark, cut off mid-sentence.

## Its last words before the Quiet are said once per launch, when the title first appears.
static var _quiet_said: bool = false
const TYPE_SECONDS := 2.4

var _wordmark: Wordmark
var _new_game: Button
var _continue: Button
var _quit: Button
var _quiet: Label
var _prompt: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Sound.set_ambience({&"rain": 0.7})
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
	var options := _menu_button("OPTIONS", column)
	options.pressed.connect(func() -> void:
		var screen := OptionsScreen.new()
		screen.closed.connect(func() -> void: options.grab_focus())
		add_child(screen))
	_quit = _menu_button("QUIT", column)
	_continue.disabled = not SaveService.has_save() or saved_run_finished()
	# A Rewrite the title wasn't told about (its record failed to write) is written down now; if it still
	# can't be, the player hears so (and no save replaces the finished one until it is).
	var settled := SaveService.settle_legacy()
	if settled != OK:
		SaveFailure.notice(get_tree(), settled, "The title couldn't be told about your Rewrite. It will keep trying.")
	_new_game.pressed.connect(_start_new_game)
	_continue.pressed.connect(_continue_game)
	_quit.pressed.connect(func() -> void: Sound.quit())

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


## The saved run has ended (its final choice made): it's kept, but there's nothing to continue.
static func saved_run_finished() -> bool:
	if not SaveService.has_save():
		return false
	var result := SaveService.load_run()
	return result.status == SaveStore.Status.OK and result.run.ending != ""


## The new run only replaces the current one if the transition is accepted (one operation).
func _start_new_game() -> void:
	SceneRouter.goto(&"loadout", func() -> void:
		GameState.new_run()
		GameState.set_location("loadout:" + LevelCatalog.FIRST_LEVEL))


func _continue_game() -> void:
	if SceneRouter.is_busy():
		return
	var result := SaveService.load_run()
	if result.status != SaveStore.Status.OK:
		_show_notice(result.note)
		return
	if SceneRouter.destination_for(result.run.location) == &"":
		_show_notice("The save points somewhere this build doesn't have yet (%s)." % result.run.location)
		return
	SceneRouter.resume(result.run.location, func() -> void: GameState.replace_run(result.run))


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
	_quiet.text = VoiceLines.fixed("title_quiet")
	if not _quiet_said:
		_quiet_said = true
		_say_quiet.call_deferred()
	var ring := _wordmark.ring
	await Wait.seconds(self, 0.8)
	ring.state = StewardRing.State.SPEAKING
	var tween := create_tween()
	tween.tween_property(_quiet, "visible_ratio", 1.0, TYPE_SECONDS)
	await tween.finished
	ring.state = StewardRing.State.GLITCH
	await Wait.seconds(self, 0.5)
	# After a Rewrite (any run's), the gap stays filled.
	ring.state = StewardRing.State.REWRITE if SaveService.rewritten() else StewardRing.State.IDLE
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


## The title sequence's own line (before any run or order): not narration, so not through the Narrator.
func _say_quiet() -> void:
	await get_tree().create_timer(1.4).timeout
	if is_inside_tree():
		Sound.say("title_quiet")
