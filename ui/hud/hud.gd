class_name Hud
extends CanvasLayer
## In-level HUD (mockups 1 and 2). Integrity and the two weapon slots, bottom-left. A weapon's mode tag
## is Steward gold while the Steward tunes it and ivory when the Operator runs it.

var view: HudView
var pill: StewardPill
var minimap: Minimap
var subtitles: Subtitles


func _ready() -> void:
	layer = 10
	var level := get_parent() as Level
	view = HudView.new()
	view.level = level
	add_child(view)
	pill = StewardPill.new()
	add_child(pill)
	minimap = Minimap.new()
	minimap.level = level
	add_child(minimap)
	subtitles = Subtitles.new()
	subtitles.speaking_changed.connect(func(on: bool) -> void: pill.speaking = on)
	add_child(subtitles)
