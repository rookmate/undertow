class_name UnbuiltPlot
extends Node2D
## A building cell whose building doesn't exist yet: an Ark plot waiting for a district's core. A low
## concrete slab with rebar stubs; still solid, it's a building site.

var cell: Vector2i


func setup(at: Vector2i) -> void:
	cell = at
	position = Iso.cell_center(at)


func _draw() -> void:
	var hw := Iso.HALF_W
	var hh := Iso.HALF_H
	var h := 14.0
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var up := Vector2(0, -h)
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + up, left + up]), Palette.STONE_OLD.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([bottom, right, right + up, bottom + up]), Palette.STONE_OLD.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), Palette.STONE_OLD.darkened(0.1))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell)
	for k: int in 4:
		var p := Iso.grid_to_world(Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35))) + up
		draw_line(p, p + Vector2(0, -rng.randf_range(16.0, 34.0)), Palette.IRON_DARK, 2.0)
