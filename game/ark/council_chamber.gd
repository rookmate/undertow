class_name CouncilChamber
extends Node2D
## The Council Chamber, from the Spire's Reliquary, on the Ark's foundation behind Noor (design/act-3.md):
## a round chamber sunk into the disc, steps down to its floor, and three doors standing on its far rim.
## The Steward's door (Reboot) in its gold; a plain grey one (Unplug); and, only if the run has earned
## it, one in the cyan of what was found (Rewrite); without it, no third door at all. Low: you see over it. Its door is an ArkFixture.

var rewrite_open: bool = false


## `corner` is the plot's top cell; the chamber fills the 2 x 2 from it.
func setup(corner: Vector2i, with_rewrite: bool) -> void:
	position = Iso.grid_to_world(Vector2(corner) + Vector2(1, 1))
	rewrite_open = with_rewrite
	z_index = -1


func _draw() -> void:
	var rx := Iso.HALF_W * 1.7
	var ry := Iso.HALF_H * 1.7
	ArtCatalog.paint(self, "council", Rect2(-rx, -ry, rx * 2, ry * 2))
	_door(Vector2(-rx * 0.55, -ry * 0.62), Palette.STEWARD_GOLD)
	_door(Vector2(0, -ry * 0.92), Palette.GREY_COLD)
	if rewrite_open:
		_door(Vector2(rx * 0.55, -ry * 0.62), Palette.TRUTH_CYAN)


func _door(foot: Vector2, col: Color) -> void:
	ArtCatalog.paint(self, "civic_door", Rect2(foot + Vector2(-15, -70), Vector2(30, 70)))
	draw_line(foot + Vector2(-8, -5), foot + Vector2(-8, -59), Color(col, 0.7), 2.0, true)
	draw_circle(foot + Vector2(0, -35), 26.0, Color(col, 0.08), true, -1.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float, closed: bool = false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	if closed:
		pts.append(pts[0])
	return pts
