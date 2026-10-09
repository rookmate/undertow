class_name SkyBackdrop
extends Control
## Behind the level: violet-to-teal sky (never neutral black) and a far skyline of black-glass towers and
## 1900s civic roofs, drifting slowly with the camera for depth. No spires, domes or moon.

const PARALLAX := 0.08

var follow: Level
var look: DistrictLook = DistrictLook.new()

var _towers: Array[Rect2] = []
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var x := -600.0
	while x < 3200.0:
		var w := rng.randf_range(50.0, 120.0)
		var h := rng.randf_range(140.0, 460.0)
		_towers.append(Rect2(x, -h, w, h))
		x += w + rng.randf_range(10.0, 70.0)


func _process(_delta: float) -> void:
	if follow == null or not is_instance_valid(follow):
		return
	var target := -follow.view_center() * PARALLAX
	if target.distance_squared_to(_offset) > 0.25:
		_offset = target
		queue_redraw()


func _draw() -> void:
	var colors := PackedColorArray([look.sky_top, look.sky_top, look.sky_bottom, look.sky_bottom])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), colors)
	var horizon := size.y * 0.62 + _offset.y
	for t: Rect2 in _towers:
		var r := Rect2(t.position + Vector2(_offset.x, horizon), t.size)
		draw_rect(r, look.skyline)
		var wy := r.position.y + 14.0
		while wy < r.end.y:
			draw_line(Vector2(r.position.x + 5.0, wy), Vector2(r.end.x - 5.0, wy), Color(Palette.HUMAN_CREAM, 0.035), 1.0)
			wy += 17.0
	if look.horizon.a > 0.0:
		draw_polygon(PackedVector2Array([Vector2(0, horizon - 160.0), Vector2(size.x, horizon - 160.0), Vector2(size.x, horizon), Vector2(0, horizon)]),
			PackedColorArray([Color(look.horizon, 0.0), Color(look.horizon, 0.0), look.horizon, look.horizon]))
	draw_rect(Rect2(0, horizon, size.x, size.y), look.water)
