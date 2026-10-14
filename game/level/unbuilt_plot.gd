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
	var up := Vector2(0, -14)
	ArtCatalog.mapped(self, "mat_concrete", PackedVector2Array([Vector2(-hw, 0), Vector2(0, hh), Vector2(0, hh) + up, Vector2(-hw, 0) + up]), Color.WHITE.darkened(0.4))
	ArtCatalog.mapped(self, "mat_concrete", PackedVector2Array([Vector2(0, hh), Vector2(hw, 0), Vector2(hw, 0) + up, Vector2(0, hh) + up]), Color.WHITE.darkened(0.25))
	ArtCatalog.mapped(self, "mat_concrete", PackedVector2Array([Vector2(0, -hh) + up, Vector2(hw, 0) + up, Vector2(0, hh) + up, Vector2(-hw, 0) + up]))
	ArtCatalog.paint(self, "rebar", Rect2(-36, -56, 72, 48))
