class_name Epilogue
extends Control
## The ending (design/act-3.md): the chosen epilogue card by card, then the credits, then the title.
## Reboot: its voice, warm and unbroken, its words in its serif and its gold. Unplug: silence, no voice
## and no sound at all, the words in plain type. Rewrite: it speaks to Noor, to Teo, to the Commons, in
## its serif and in the cyan of what was found (its gap filled). Accept moves on a card. The title after
## it keeps the finished run (Continue isn't offered for it); New Game starts again.

## A card of plain type stays at least this long; a spoken one as long as its voice, and a breath after.
const CARD_SECONDS := 5.0
const AFTER_VOICE := 1.0
const CREDITS_SECONDS := 9.0
const CREDITS := "UNDERTOW\n\nA game about a city that was looked after.\n\nMade in Godot 4.\nThe Steward's placeholder voice: Piper.\nType: Oswald, IBM Plex Mono, Abril Fatface.\n\nThank you for playing."

## Which ending this is (Endings.*).
var ending: String = ""
## The card showing (index into the epilogue; its size means the credits).
var at: int = -1
var finished: bool = false
## Where it goes once the credits are done: the title. (Tests, which can't follow a scene change,
## replace it.)
var on_done: Callable = func() -> void: SceneRouter.goto(&"title")
var _cards: Array = []
var _left: float = 0.0
var _words: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ending == "":
		ending = GameState.run.ending
	_cards = Endings.EPILOGUES.get(ending, [])
	var back := ColorRect.new()
	back.color = Palette.NEAR_BLACK
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_words = Label.new()
	_words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_words.offset_left = 260
	_words.offset_right = -260
	_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_words)
	Sound.hush()
	Sound.set_ambience({})
	# Unplug: the narration stops, and so does everything else.
	Sound.set_silent(ending == Endings.UNPLUG)
	next_card()


func _process(delta: float) -> void:
	if finished:
		return
	_left -= delta
	if _left <= 0.0:
		next_card()


func _unhandled_input(event: InputEvent) -> void:
	if not finished and event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		next_card()


## On to the next card; after the last, the credits; after them, the title.
func next_card() -> void:
	at += 1
	if at < _cards.size():
		var card: Dictionary = _cards[at]
		if card.has("say"):
			var line := str(card["say"])
			_show(VoiceLines.fixed(line), UiFonts.narration(), 40, Palette.TRUTH_CYAN if ending == Endings.REWRITE else Palette.STEWARD_GOLD)
			_left = maxf(CARD_SECONDS, Sound.say(line) + AFTER_VOICE)
		else:
			_show(str(card.get("text", "")), UiFonts.label(), 40, Palette.IVORY)
			_left = CARD_SECONDS
		return
	if at == _cards.size():
		_show(CREDITS, UiFonts.mono(), 22, Palette.IVORY_DIM)
		_left = CREDITS_SECONDS
		return
	_finish()


## What's on the screen now.
func shown() -> String:
	return _words.text


func _show(text: String, font: Font, font_size: int, col: Color) -> void:
	_words.text = text
	_words.add_theme_font_override(&"font", font)
	_words.add_theme_font_size_override(&"font_size", font_size)
	_words.add_theme_color_override(&"font_color", col)


func _finish() -> void:
	if finished:
		return
	finished = true
	Sound.hush()
	Sound.set_silent(false)
	on_done.call()


func _exit_tree() -> void:
	Sound.set_silent(false)
