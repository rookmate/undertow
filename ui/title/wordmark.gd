class_name Wordmark
extends Control
## The title treatment (brief, "Title"): UNDERTOW in Barlow Condensed 600 tracked +8%, with the O
## replaced by the Steward's ring, its gap facing the W. Muted: the ring is thin and grey with no centre.

const TRACKING := 0.08
## Band outer diameter relative to the cap height, so the band reads as a capital O.
const RING_TO_CAP := 1.06
const CAP_HEIGHT_EM := 0.70

@export var font_size: int = 168
@export var muted: bool = false:
	set(value):
		muted = value
		if _ring != null and muted:
			_ring.state = StewardRing.State.MUTED

var ring: StewardRing:
	get:
		return _ring

var _ring: StewardRing
var _font: Font
var _before := "UNDERT"
var _after := "W"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UiFonts.tracked_heading(font_size, TRACKING)
	_ring = StewardRing.new()
	_ring.hdr = 1.35
	if muted:
		_ring.state = StewardRing.State.MUTED
	add_child(_ring)
	custom_minimum_size = _measure()
	_place_ring()
	resized.connect(_place_ring)


func _band_radius() -> float:
	return font_size * CAP_HEIGHT_EM * RING_TO_CAP * 0.5


func _gap() -> float:
	return font_size * TRACKING


func _measure() -> Vector2:
	var w1 := _font.get_string_size(_before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var w2 := _font.get_string_size(_after, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var width := w1 + _gap() + _band_radius() * 2.0 + _gap() + w2
	return Vector2(width, _font.get_height(font_size))


func _origin_x() -> float:
	return (size.x - _measure().x) * 0.5


func _baseline() -> float:
	return (size.y - _font.get_height(font_size)) * 0.5 + _font.get_ascent(font_size)


func _place_ring() -> void:
	var w1 := _font.get_string_size(_before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var r := _band_radius()
	var center := Vector2(_origin_x() + w1 + _gap() + r, _baseline() - font_size * CAP_HEIGHT_EM * 0.5)
	var box := r * RingPainter.EXTENT * 2.0
	_ring.size = Vector2(box, box)
	_ring.position = center - _ring.size * 0.5
	queue_redraw()


func _draw() -> void:
	var x := _origin_x()
	var baseline := _baseline()
	var w1 := _font.get_string_size(_before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, Vector2(x, baseline), _before, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.IVORY)
	var x2 := x + w1 + _gap() + _band_radius() * 2.0 + _gap()
	draw_string(_font, Vector2(x2, baseline), _after, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Palette.IVORY)
