class_name Hud
extends CanvasLayer
## In-level HUD (mockups 1 and 2). Integrity and the two weapon slots, bottom-left. A weapon's mode tag
## is Steward gold while the Steward tunes it and ivory when the Operator runs it.

var view: HudView


func _ready() -> void:
	layer = 10
	view = HudView.new()
	view.level = get_parent() as Level
	add_child(view)
