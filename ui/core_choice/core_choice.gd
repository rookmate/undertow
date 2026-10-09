extends Control
## Core choice (mockup 3): the Reliquary's cards, carry two. While it listens, each card carries the
## Steward's comment: it pushes the power cores and dismisses the truth cores. Muted, the cards show only
## what they are.

var level_id: String = ContentIds.LEVEL_VELLUM
var offered: Array[String] = []
var picked: Array[String] = []

var _cards: Dictionary[String, Button] = {}
var _confirm: Button
var _count: Label
var _summary: Label
var _done: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var loc := GameState.run.location
	if loc.begins_with("reliquary:"):
		level_id = loc.get_slice(":", 1)
	offered = CoreChoice.offer(level_id, GameState.run)
	_build()
	_refresh()
	if not offered.is_empty():
		_cards[offered[0]].grab_focus()
	else:
		_confirm.grab_focus()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.NEAR_BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Label.new()
	title.text = "THE RELIQUARY"
	title.add_theme_font_override(&"font", UiFonts.heading())
	title.add_theme_font_size_override(&"font_size", 72)
	title.position = Vector2(96, 64)
	add_child(title)
	var sub := Label.new()
	sub.text = "%d CORES · YOU CAN CARRY %d" % [offered.size(), Tunables.CORES_CARRIED_PER_LEVEL]
	sub.add_theme_font_override(&"font", UiFonts.mono())
	sub.add_theme_font_size_override(&"font_size", 20)
	sub.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	sub.position = Vector2(100, 152)
	add_child(sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	row.position = Vector2(96, 220)
	add_child(row)
	for id: String in offered:
		var card := _make_card(id)
		row.add_child(card)
		_cards[id] = card
	_count = Label.new()
	_count.add_theme_font_override(&"font", UiFonts.mono_medium())
	_count.add_theme_font_size_override(&"font_size", 20)
	_count.position = Vector2(100, 950)
	add_child(_count)
	_summary = Label.new()
	_summary.add_theme_font_size_override(&"font_size", 28)
	_summary.position = Vector2(100, 880)
	_summary.size = Vector2(1300, 60)
	add_child(_summary)
	_confirm = Button.new()
	_confirm.text = "CARRY THESE TWO"
	_confirm.custom_minimum_size = Vector2(380, 64)
	_confirm.position = Vector2(1440, 936)
	_confirm.pressed.connect(_on_confirm)
	add_child(_confirm)


func _make_card(id: String) -> Button:
	var def := ContentDb.core(id)
	var truth := ContentDb.is_truth(id)
	var card := Button.new()
	card.custom_minimum_size = Vector2(400, 650)
	card.add_theme_stylebox_override(&"normal", UiTheme.panel_style(0.92))
	card.pressed.connect(_toggle.bind(id))
	# While it listens, the Steward says its piece about each card you look at.
	card.focus_entered.connect(func() -> void:
		if Steward.voice_on and not _done:
			Sound.say(VoiceLines.core_line(id)))
	var art := CoreArt.new()
	art.truth = truth
	art.position = Vector2(100, 30)
	art.size = Vector2(200, 170)
	card.add_child(art)
	var kind := Label.new()
	kind.text = "TRUTH CORE" if truth else "POWER CORE"
	kind.add_theme_font_override(&"font", UiFonts.mono_medium())
	kind.add_theme_font_size_override(&"font_size", 16)
	kind.add_theme_color_override(&"font_color", Palette.TRUTH_CYAN if truth else Palette.STEWARD_GOLD)
	kind.position = Vector2(28, 214)
	card.add_child(kind)
	var name_label := Label.new()
	name_label.text = str(def.get("name", id)).to_upper()
	name_label.add_theme_font_override(&"font", UiFonts.heading())
	name_label.add_theme_font_size_override(&"font_size", 40)
	name_label.position = Vector2(26, 238)
	card.add_child(name_label)
	var origin := Label.new()
	origin.text = str(def.get("origin", ""))
	origin.add_theme_font_override(&"font", UiFonts.mono())
	origin.add_theme_font_size_override(&"font_size", 14)
	origin.add_theme_color_override(&"font_color", Palette.IVORY_DIM)
	origin.position = Vector2(28, 292)
	card.add_child(origin)
	var blurb := Label.new()
	blurb.text = str(def.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blurb.add_theme_font_size_override(&"font_size", 24)
	blurb.position = Vector2(28, 324)
	blurb.size = Vector2(344, 120)
	card.add_child(blurb)
	if Steward.voice_on:
		var comment := Label.new()
		comment.text = str(def.get("steward", ""))
		comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		comment.add_theme_font_override(&"font", UiFonts.narration())
		comment.add_theme_font_size_override(&"font_size", 26)
		comment.add_theme_color_override(&"font_color", Palette.STEWARD_GOLD)
		comment.position = Vector2(28, 462)
		comment.size = Vector2(344, 110)
		comment.name = "StewardComment"
		card.add_child(comment)
	var badge := Label.new()
	badge.name = "Badge"
	badge.add_theme_font_override(&"font", UiFonts.mono_medium())
	badge.add_theme_font_size_override(&"font_size", 18)
	badge.position = Vector2(28, 604)
	card.add_child(badge)
	for child: Node in card.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


func _toggle(id: String) -> void:
	if _done:
		return
	if picked.has(id):
		picked.erase(id)
	elif picked.size() < Tunables.CORES_CARRIED_PER_LEVEL:
		picked.append(id)
	elif not picked.is_empty():
		picked[picked.size() - 1] = id
	_refresh()


func _refresh() -> void:
	for id: String in _cards:
		var card := _cards[id]
		var badge := card.get_node(^"Badge") as Label
		var carried := picked.has(id)
		badge.text = "CARRY" if carried else ("LEAVE" if picked.size() == Tunables.CORES_CARRIED_PER_LEVEL else "")
		badge.add_theme_color_override(&"font_color", Palette.IVORY if carried else Palette.GREY_COLD)
		var style := UiTheme.panel_style(0.92)
		if carried:
			style.border_color = Palette.IVORY
			style.set_border_width_all(3)
		card.add_theme_stylebox_override(&"normal", style)
	_count.text = "%d / %d CHOSEN" % [picked.size(), Tunables.CORES_CARRIED_PER_LEVEL]
	var broken := CoreChoice.offer_problem(level_id, offered)
	if broken != "":
		# Broken content (reported at boot): say so and let the player leave; nothing is completed.
		_summary.text = broken
		_confirm.text = "BACK TO THE TITLE"
		_confirm.disabled = false
		return
	_confirm.disabled = CoreChoice.validate(level_id, offered, picked) != ""


func _on_confirm() -> void:
	if _done:
		_continue()
		return
	if CoreChoice.offer_problem(level_id, offered) != "":
		SceneRouter.goto(&"title")
		return
	var problem := CoreChoice.apply(level_id, offered, picked)
	if problem != "":
		_summary.text = problem
		return
	_done = true
	Sound.play(&"core_take")
	var saved := SaveFlow.checkpoint(get_tree())
	var names := PackedStringArray()
	for id: String in picked:
		var kind := "truth" if ContentDb.is_truth(id) else "power"
		names.append("the %s %s" % [str(ContentDb.core(id).get("name", id)).to_lower(), kind])
	_summary.text = "You carry %s. The rest stays in the dark." % " and ".join(names)
	if not saved:
		_summary.text += " (Not saved yet: the Ark will try again.)"
	_confirm.text = "TO THE ARK"
	_confirm.disabled = false
	_confirm.grab_focus()


func _continue() -> void:
	if not SceneRouter.resume(GameState.run.location):
		SceneRouter.goto(&"title")
