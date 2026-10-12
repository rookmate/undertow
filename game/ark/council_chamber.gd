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
	draw_colored_polygon(_ellipse(Vector2.ZERO, rx, ry), Palette.STONE_OLD.darkened(0.25))
	# Steps down, ring by ring, to the floor.
	for k: int in 4:
		var f := 1.0 - (k + 1) * 0.17
		draw_colored_polygon(_ellipse(Vector2(0, k * 3.0), rx * f, ry * f), Palette.STONE_OLD.darkened(0.35 + k * 0.1))
		draw_polyline(_ellipse(Vector2(0, k * 3.0), rx * f, ry * f, true), Color(Palette.NEAR_BLACK, 0.5), 1.5, true)
	draw_polyline(_ellipse(Vector2.ZERO, rx, ry, true), Palette.STONE_OLD.lightened(0.1), 2.0, true)
	# The doors on the far rim: the Steward's, the plain one, and the third only if it's there.
	_door(Vector2(-rx * 0.55, -ry * 0.62), Palette.STEWARD_GOLD)
	_door(Vector2(0, -ry * 0.92), Palette.GREY_COLD)
	if rewrite_open:
		_door(Vector2(rx * 0.55, -ry * 0.62), Palette.TRUTH_CYAN)


func _door(foot: Vector2, col: Color) -> void:
	var w := 26.0
	var h := 70.0
	var frame := PackedVector2Array([foot + Vector2(-w * 0.5, 0), foot + Vector2(w * 0.5, 0), foot + Vector2(w * 0.5, -h), foot + Vector2(-w * 0.5, -h)])
	draw_colored_polygon(frame, Palette.NEAR_BLACK)
	var inner := PackedVector2Array([foot + Vector2(-w * 0.32, -2), foot + Vector2(w * 0.32, -2), foot + Vector2(w * 0.32, -h + 8), foot + Vector2(-w * 0.32, -h + 8)])
	draw_colored_polygon(inner, Color(col, 0.75))
	draw_circle(foot + Vector2(0, -h * 0.5), 26.0, Color(col, 0.08), true, -1.0, true)
	frame.append(frame[0])
	draw_polyline(frame, Palette.IRON_DARK, 2.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float, closed: bool = false) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 28:
		var a := TAU * i / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	if closed:
		pts.append(pts[0])
	return pts
