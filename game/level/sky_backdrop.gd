class_name SkyBackdrop
extends Control
## Behind the level: violet-to-teal sky (never neutral black) and a far skyline of black-glass towers and
## 1900s civic roofs, drifting slowly with the camera for depth. No spires, domes or moon.

const PARALLAX := 0.08

var follow: Level
var look: DistrictLook = DistrictLook.new()

var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if follow == null or not is_instance_valid(follow):
		return
	var target := -follow.view_center() * PARALLAX
	if target.distance_squared_to(_offset) > 0.25:
		_offset = target
		queue_redraw()


func _draw() -> void:
	# Overscan keeps the original painting continuous while the camera drifts.
	var drift := bounded_drift(_offset)
	ArtCatalog.paint(self, "sky_" + look.district_id, Rect2(Vector2(-80, -50) + drift, size + Vector2(160, 100)))


static func bounded_drift(offset: Vector2) -> Vector2:
	return Vector2(clampf(offset.x, -60.0, 60.0), clampf(offset.y, -35.0, 35.0))
