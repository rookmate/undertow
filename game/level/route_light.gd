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
	var bounds := Rect2(-8, -48, 16, 48)
	ArtCatalog.paint(self, "route_light", bounds)
	var on := Steward.voice_on and fmod(_t, PERIOD) < 0.5
	draw_circle(ArtCatalog.anchor("route_light", "lens", bounds), 2.5, Palette.STEWARD_GOLD_HOT if on else Palette.GREY_DEEP, true, -1.0, true)
