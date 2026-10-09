class_name ArchiveDot
extends Control
## Colour key for an Archive entry: the Steward's own records in its gold, what you found in truth cyan,
## unrecovered entries in grey.

var kind: String = "comforting"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(12, 12)


func _draw() -> void:
	var col := Palette.GREY_DEEP
	match kind:
		"comforting":
			col = Palette.STEWARD_GOLD
		"truth", "unindexed":
			col = Palette.TRUTH_CYAN
	draw_circle(Vector2(6, 6), 6.0, col, true, -1.0, true)
