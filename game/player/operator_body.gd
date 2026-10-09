class_name OperatorBody
extends Node2D
## The Operator's placeholder silhouette (character lineup, image 12): stocky, dark coveralls, dull
## hi-vis chevrons, a cap. The earpiece glows Steward gold when the voice is on and goes dark when muted.
## Origin is at the feet. About 1.3 tile widths tall, as in image 10.

const HEIGHT := 172.0
## Drawn at 160 px and scaled up to HEIGHT: about 1.3 tile widths, as in image 10.
const DRAW_SCALE := HEIGHT / 160.0

## Lying on the ground after Integrity runs out.
var downed: bool = false:
	set(value):
		downed = value
		queue_redraw()

var _facing_screen: Vector2 = Vector2(0.5, -0.5)
var _flash: float = 0.0
var _walk_phase: float = 0.0
var _moving: bool = false
var _roll: float = -1.0


func _ready() -> void:
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
	if downed:
		draw_set_transform(Vector2(-60, -8), -PI * 0.5 * side, Vector2(side, 1.0) * DRAW_SCALE * 0.9)
	elif _roll >= 0.0:
		var squash := sin(_roll * PI)
		draw_set_transform(Vector2(0, -6.0 * squash), _facing_screen.x * squash * 0.5, Vector2(side * (1.0 + 0.15 * squash), 1.0 - 0.32 * squash) * DRAW_SCALE)
	else:
		var bob := -absf(sin(_walk_phase)) * 3.0 if _moving else 0.0
		draw_set_transform(Vector2(0, bob), 0.0, Vector2(side, 1.0) * DRAW_SCALE)
	var swing := sin(_walk_phase) * 5.0 if _moving else 0.0
	# Legs and boots.
	draw_rect(Rect2(-17 + swing * 0.4, -70, 15, 58), Palette.COVERALL)
	draw_rect(Rect2(2 - swing * 0.4, -70, 15, 58), Palette.COVERALL.darkened(0.15))
	draw_rect(Rect2(-18 + swing, -14, 16, 14), Palette.IRON_DARK)
	draw_rect(Rect2(2 - swing, -14, 16, 14), Palette.IRON_DARK)
	draw_rect(Rect2(-18, -46, 36, 5), Color(Palette.HIVIS_DULL, 0.7))
	# Torso: stocky, shoulders wider than the waist.
	var torso := PackedVector2Array([Vector2(-26, -122), Vector2(26, -122), Vector2(21, -66), Vector2(-21, -66)])
	draw_colored_polygon(torso, Palette.COVERALL_LIGHT)
	# A faint cold rim so the silhouette reads against wet stone.
	draw_polyline(PackedVector2Array([Vector2(-21, -66), Vector2(-26, -122), Vector2(26, -122)]), Color(Palette.IVORY, 0.14), 2.0, true)
	if back:
		draw_rect(Rect2(-19, -119, 38, 44), Palette.IRON_DARK)
		draw_rect(Rect2(-15, -115, 30, 8), Palette.COVERALL)
		draw_rect(Rect2(-21, -78, 42, 5), Color(Palette.HIVIS_DULL, 0.8))
	else:
		for k: int in 2:
			var y := -106.0 + k * 13.0
			draw_polyline(PackedVector2Array([Vector2(-21, y - 6), Vector2(0, y + 4), Vector2(21, y - 6)]), Palette.HIVIS_DULL, 5.0, true)
	# Arms.
	draw_rect(Rect2(-35, -120 - swing * 0.3, 11, 56), Palette.COVERALL)
	draw_rect(Rect2(24, -120 + swing * 0.3, 11, 56), Palette.COVERALL.darkened(0.1))
	draw_circle(Vector2(-29.5, -62 - swing * 0.3), 6.0, Palette.SKIN_SHADOW, true, -1.0, true)
	draw_circle(Vector2(29.5, -62 + swing * 0.3), 6.0, Palette.SKIN_SHADOW, true, -1.0, true)
	# Head and cap.
	draw_circle(Vector2(0, -136), 15.0, Palette.SKIN_SHADOW, true, -1.0, true)
	draw_arc(Vector2(0, -138), 15.5, PI, TAU, 16, Palette.COVERALL, 9.0, true)
	var brim := 1.0 if not back else -1.0
	draw_line(Vector2(4 * brim, -140), Vector2(22 * brim, -138), Palette.COVERALL, 5.0, true)
	# Earpiece on the near side of the head: the Steward's light.
	var ear := Vector2(-12.0 if not back else 12.0, -134)
	if Steward.voice_on:
		draw_circle(ear, 9.0, Color(Palette.STEWARD_GOLD, 0.25), true, -1.0, true)
		draw_circle(ear, 4.5, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
	else:
		draw_circle(ear, 4.5, Palette.IRON_DARK, true, -1.0, true)
	if _flash > 0.0:
		draw_rect(Rect2(-36, -152, 72, 152), Color(Palette.IVORY, _flash * 2.0))
	draw_set_transform(Vector2.ZERO)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 18:
		var a := TAU * i / 18.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
