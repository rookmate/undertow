class_name TideGauge
extends Node2D
## A tide gauge on a post where the water comes up (Greywater): painted marks people read by hand, and
## the water standing against them. Muted, it's how you know the tide's turning.

var tide: Tide
var cell: Vector2i


func setup(at: Vector2i, owner_tide: Tide) -> void:
	cell = at
	tide = owner_tide
	position = Iso.cell_center(at)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	ArtCatalog.paint(self, "tide_gauge", Rect2(-8, -92, 16, 92))
	var level := tide.water_level() if tide != null else 0.0
	if level > 0.01:
		var y := -10.0 - level * 56.0
		draw_line(Vector2(-14, y), Vector2(14, y), Color(Palette.WATER_SHEEN, 0.9), 3.0)
