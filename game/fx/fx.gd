class_name Fx
extends Node2D
## Short-lived effects drawn on the ground plane: swing arcs, shock rings, charge rings, telegraphs.
## Shapes are laid out in grid space so circles sit flat on the isometric ground.

enum Shape { RING, DISC, ARC, LINE }

var shape: Shape = Shape.RING
var color: Color = Color.WHITE
var duration: float = 0.3
var radius_tiles: float = 1.0
var facing: Vector2 = Vector2(0, -1)
var arc_deg: float = 90.0
var width: float = 4.0
## For LINE: ground-space offset of the far end.
var reach: Vector2 = Vector2.ZERO
var grow: bool = true

var _t: float = 0.0


static func spawn(parent: Node, at: Vector2, kind: Shape, col: Color, seconds: float) -> Fx:
	var fx := Fx.new()
	fx.shape = kind
	fx.color = col
	fx.duration = maxf(seconds, 0.016)
	fx.position = at
	fx.material = Emissive.unshaded_material()
	parent.add_child(fx)
	return fx


func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / duration, 0.0, 1.0)
	var fade := Color(color, color.a * (1.0 - k))
	var r := radius_tiles * (lerpf(0.55, 1.0, k) if grow else 1.0)
	match shape:
		Shape.RING:
			draw_polyline(ground_ellipse(r, 40), fade, width, true)
		Shape.DISC:
			draw_colored_polygon(ground_ellipse(r, 32, false), Color(fade, fade.a * 0.35))
			draw_polyline(ground_ellipse(r, 32), fade, width, true)
		Shape.ARC:
			var pts := PackedVector2Array([Vector2.ZERO])
			var half := deg_to_rad(arc_deg * 0.5)
			for i: int in 17:
				var a := facing.angle() - half + 2.0 * half * i / 16.0
				pts.append(Iso.grid_to_world(Vector2.from_angle(a) * r))
			draw_colored_polygon(pts, Color(fade, fade.a * 0.3))
			pts.remove_at(0)
			draw_polyline(pts, fade, width, true)
		Shape.LINE:
			draw_line(Vector2.ZERO, Iso.grid_to_world(reach), fade, width, true)


## A circle of `r` tiles on the ground, as screen points around this node. `closed` repeats the first
## point at the end, for outlines; filled polygons must not repeat it.
static func ground_ellipse(r: float, steps: int, closed: bool = true) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in (steps + 1 if closed else steps):
		pts.append(Iso.grid_to_world(Vector2.from_angle(TAU * i / steps) * r))
	return pts
