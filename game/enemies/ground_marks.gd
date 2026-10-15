class_name GroundMarks
extends Node2D
## What a machine puts on the ground (its shadow, the warnings it gives): drawn in the level's ground
## layer, under every body, following its machine and fading with it. Drawn in its own place in the
## world's depth order, a warning ring would paint over whoever stands in it.

var enemy: Enemy


func _process(_delta: float) -> void:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		queue_free()
		return
	global_position = enemy.global_position
	modulate = enemy.modulate
	visible = enemy.is_visible_in_tree()
	queue_redraw()


func _draw() -> void:
	if is_instance_valid(enemy):
		enemy.draw_ground(self)
