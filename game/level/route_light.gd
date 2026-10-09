class_name RouteLight
extends Node2D
## One of the Loop's amber route lights: a post on the platform edge, still blinking in sequence for a
## train that will never come (the ring's lights are the Steward's, so gold). Muted, they go dark.

const PERIOD := 2.4

var cell: Vector2i
var _t: float = 0.0


func setup(at: Vector2i) -> void:
	cell = at
	position = Iso.cell_center(at)
	# Neighbours along the ring blink one after another.
	_t = float(at.x + at.y) * 0.18


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-3, -40, 6, 40), Palette.IRON_DARK)
	var on := Steward.voice_on and fmod(_t, PERIOD) < 0.5
	draw_circle(Vector2(0, -44), 5.0, Palette.STEWARD_GOLD_HOT if on else Palette.GREY_DEEP, true, -1.0, true)
