class_name CraneLeg
extends Node2D
## A leg of a gantry crane: a tall lattice of rusted steel, a gold light-trace climbing it (ten years of
## the Steward laid over the docks: the gilt).

const HEIGHT := 260.0

var cell: Vector2i
var look: DistrictLook = DistrictLook.new()
var _gilt: Emissive


func setup(at: Vector2i, district_look: DistrictLook) -> void:
	cell = at
	look = district_look
	position = Iso.cell_center(at)
	add_to_group(&"gilt")
	var ops := DrawOps.new()
	ops.line(Vector2(6, -20), Vector2(6, -HEIGHT + 20), Palette.STEWARD_GOLD_HOT, 1.5)
	_gilt = Emissive.new()
	_gilt.layers = [ops]
	add_child(_gilt)


## Muted, the gilt dies with the rest of the Steward's light (LightingState drives every "gilt" node).
var gilt_lit: bool = true:
	set(value):
		gilt_lit = value
		if _gilt != null:
			_gilt.visible = value


func _draw() -> void:
	draw_colored_polygon(Fx.ground_ellipse(0.26, 18, false), Color(Palette.NEAR_BLACK, 0.4))
	ArtCatalog.paint(self, "crane_leg", Rect2(-29, -HEIGHT, 58, HEIGHT + 9))
