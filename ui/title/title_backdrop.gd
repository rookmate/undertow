extends Control
## Title backdrop: violet-to-teal night sky (never neutral black), a skyline of black-glass towers and
## 1900s civic roofs (no spires, domes or cathedral silhouettes), and black water below.

const HORIZON := 0.72

var _towers: Array[Rect2] = []
var _civic: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2214
	_towers.clear()
	_civic.clear()
	var horizon := size.y * HORIZON
	var x := -20.0
	while x < size.x + 40.0:
		var w := rng.randf_range(44.0, 96.0)
		var h := rng.randf_range(size.y * 0.16, size.y * 0.42)
		if rng.randf() < 0.35:
			h *= 0.55
		_towers.append(Rect2(x, horizon - h, w, h))
		x += w + rng.randf_range(6.0, 40.0)
	x = -30.0
	while x < size.x + 40.0:
		var w := rng.randf_range(120.0, 260.0)
		var h := rng.randf_range(size.y * 0.05, size.y * 0.11)
		_civic.append(Rect2(x, horizon - h, w, h))
		x += w + rng.randf_range(-10.0, 24.0)
	queue_redraw()


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var horizon := size.y * HORIZON
	var sky := PackedColorArray([Palette.SKY_VIOLET, Palette.SKY_VIOLET, Palette.SKY_TEAL, Palette.SKY_TEAL])
	var sky_rect := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), Vector2(size.x, horizon), Vector2(0, horizon)])
	draw_polygon(sky_rect, sky)
	for t: Rect2 in _towers:
		draw_rect(t, Color(Palette.BLACK_MIRROR, 0.92))
		var lit := Color(Palette.HUMAN_CREAM, 0.045)
		var wy := t.position.y + 18.0
		while wy < t.end.y - 12.0:
			draw_line(Vector2(t.position.x + 6.0, wy), Vector2(t.end.x - 6.0, wy), lit, 1.0)
			wy += 19.0
	for b: Rect2 in _civic:
		draw_rect(b, Palette.IRON_DARK)
		var roof := PackedVector2Array([b.position, Vector2(b.position.x + b.size.x * 0.5, b.position.y - b.size.y * 0.35), Vector2(b.end.x, b.position.y)])
		draw_colored_polygon(roof, Palette.IRON_DARK)
		var wx := b.position.x + 12.0
		while wx < b.end.x - 12.0:
			draw_rect(Rect2(wx, b.position.y + b.size.y * 0.35, 6.0, 10.0), Color(Palette.HUMAN_CREAM, 0.16))
			wx += 22.0
	var water := PackedColorArray([Palette.SKY_TEAL, Palette.SKY_TEAL, Palette.WATER_DEEP, Palette.WATER_DEEP])
	draw_polygon(PackedVector2Array([Vector2(0, horizon), Vector2(size.x, horizon), Vector2(size.x, size.y), Vector2(0, size.y)]), water)
	draw_rect(Rect2(0, horizon - 24.0, size.x, 48.0), Color(Palette.FOG, 0.025))
