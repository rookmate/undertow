class_name EliteMark
extends Node2D
## A revisit's elite (Hardening): a pale double ring at its feet, so you can tell which ones take longer
## to bring down. Never red-orange: that's only for what's about to hit you.


func _ready() -> void:
	z_index = -1


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, Iso.SQUASH))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(Palette.IVORY, 0.55), 2.0, true)
	draw_arc(Vector2.ZERO, 37.0, 0.0, TAU, 32, Color(Palette.IVORY, 0.3), 1.5, true)
