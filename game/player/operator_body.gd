class_name OperatorBody
extends Node2D
## Painted Operator poses (character lineup, image 12): stocky, dark coveralls, dull hi-vis chevrons,
## a cap. The earpiece glows Steward gold when the voice is on and goes dark when muted.
## Origin is at the feet. About 1.3 tile widths tall, as in image 10.

const HEIGHT := 172.0

## Lying on the ground after Integrity runs out.
var downed: bool = false:
	set(value):
		downed = value
		queue_redraw()

## Carrying Noor over the shoulder.
var carrying: bool = false
var _facing_screen: Vector2 = Vector2(0.5, -0.5)
var _flash: float = 0.0
var _walk_phase: float = 0.0
var _moving: bool = false
var _roll: float = -1.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Steward.voice_changed.connect(func(_on: bool) -> void: queue_redraw())


func update_pose(facing_ground: Vector2, velocity: Vector2, dodge: Dodge, delta: float) -> void:
	var f := Iso.grid_to_world(facing_ground)
	if f.length_squared() > 0.001:
		_facing_screen = f.normalized()
	_moving = velocity.length_squared() > 4.0
	if _moving:
		_walk_phase += delta * 11.0
	_roll = dodge.progress() if dodge.is_rolling() else -1.0
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()


func flash() -> void:
	_flash = 0.15


func _draw() -> void:
	draw_colored_polygon(_ellipse(Vector2.ZERO, 30.0, 13.0), Color(Palette.NEAR_BLACK, 0.45))
	var side := 1.0 if _facing_screen.x >= 0.0 else -1.0
	var back := _facing_screen.y < -0.25
	var direction := "back" if back else "front"
	var step := int(_walk_phase / PI) % 2
	var key := "operator_%s_idle" % direction
	if _moving:
		key = "operator_%s_step%d" % [direction, step + 1]
	if carrying:
		key = "carry_%s_%s" % [direction, "step" if _moving and step == 1 else "idle"]
	var h := HEIGHT
	if downed:
		key = "operator_downed"
		h = 52.0
	elif _roll >= 0.0:
		if not carrying:
			key = "operator_dodge"
			h = lerpf(HEIGHT * 0.8, HEIGHT * 0.63, sin(_roll * PI))
		else:
			h = HEIGHT * (1.0 - 0.25 * sin(_roll * PI))
	var bob := -absf(sin(_walk_phase)) * 3.0 if _moving and not downed else 0.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(side, 1.0))
	ArtCatalog.actor(self, key, h, Vector2.ZERO, _flash)
	var ear := ArtCatalog.actor_anchor(key, "ear", h)
	var light := Palette.STEWARD_GOLD_HOT if Steward.voice_on else Palette.IRON_DARK
	if Steward.voice_on:
		draw_circle(ear, 7.0, Color(Palette.STEWARD_GOLD, 0.2), true, -1.0, true)
	draw_circle(ear, 2.6, light, true, -1.0, true)
	if carrying and not downed:
		var lantern := ArtCatalog.actor_anchor(key, "lantern", h)
		draw_circle(lantern, 14.0, Color(Palette.TRUTH_CYAN, 0.15), true, -1.0, true)
		draw_circle(lantern, 3.5, Palette.TRUTH_CYAN_HOT, true, -1.0, true)
	draw_set_transform(Vector2.ZERO)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 18:
		var a := TAU * i / 18.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
