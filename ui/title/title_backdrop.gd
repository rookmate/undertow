extends Control
## Painted Meridian skyline and water, matching the approved title direction.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x > 0.0 and size.y > 0.0:
		ArtCatalog.paint(self, "title_painting", Rect2(Vector2.ZERO, size))
