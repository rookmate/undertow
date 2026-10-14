class_name BossBarrier
extends StaticBody2D
## What stands between a district's boss and the rest of the way (a buffer stop, a fallen crane jib):
## solid until the boss is taken apart, then gone.

var cell: Vector2i
var open: bool = false
var _shape: CollisionShape2D


func setup(at: Vector2i) -> void:
	cell = at
	position = Iso.cell_center(at)
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	var pts := PackedVector2Array()
	for p: Vector2 in Iso.cell_diamond(at):
		pts.append(p - position)
	poly.points = pts
	_shape.shape = poly
	add_child(_shape)
	add_to_group(&"boss_barriers")


func open_up() -> void:
	if open:
		return
	open = true
	_shape.set_deferred(&"disabled", true)
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.8)


func _draw() -> void:
	ArtCatalog.paint(self, "barrier", Rect2(-Iso.HALF_W * 0.7, -54, Iso.W * 0.7, 54))
	draw_line(Vector2(-Iso.HALF_W * 0.6, -48), Vector2(Iso.HALF_W * 0.6, -48), Color(Palette.DANGER, 0.6), 2.0, true)
