class_name PressRollers
extends Node2D
## The Editor's rollers on the press hall's floor, drawn on the ground under everyone. As it warns: the
## run they'll make, outlined in red-orange with the gap left out, and while the Steward listens (and may
## warn you) the gap lit in its gold. As they run: the rollers themselves, inked black.

var editor: Editor


func _process(_delta: float) -> void:
	queue_redraw()
	if editor == null or not is_instance_valid(editor) or not editor.is_alive():
		set_process(false)


## The Steward lights the gap for you: only while it's with you and may warn you.
func gap_lit() -> bool:
	return editor != null and editor.phase == Editor.Phase.ROLL_WARN and Narrator.allows(LineSelector.WARNING)


func _draw() -> void:
	if editor == null or not is_instance_valid(editor) or not editor.is_alive():
		return
	var span := editor.roller_span()
	var gap := Vector2(editor.gap_start, editor.gap_start + Editor.GAP_CELLS)
	match editor.phase:
		Editor.Phase.ROLL_WARN:
			var run := editor.run_span()
			for part: Vector2 in [Vector2(span.x, gap.x), Vector2(gap.y, span.y)]:
				if part.y > part.x:
					_area(part, run, Color(Palette.DANGER, 0.12), Color(Palette.DANGER, 0.85))
			if gap_lit():
				_area(gap, run, Color(Palette.STEWARD_GOLD, 0.1), Color(Palette.STEWARD_GOLD, 0.9))
		Editor.Phase.ROLL:
			var at := editor.roller_at()
			for part: Vector2 in [Vector2(span.x, gap.x), Vector2(gap.y, span.y)]:
				if part.y > part.x:
					_roller(part, at)


## A grid point (`along` the roller's length, `run` along its run) on screen.
func _pt(along: float, run: float) -> Vector2:
	if editor.sweep == Editor.Sweep.DOWN:
		return Iso.grid_to_world(Vector2(along, run))
	return Iso.grid_to_world(Vector2(run, along))


func _area(along: Vector2, run: Vector2, fill: Color, edge: Color) -> void:
	var pts := PackedVector2Array([_pt(along.x, run.x), _pt(along.y, run.x), _pt(along.y, run.y), _pt(along.x, run.y)])
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, edge, 3.0, true)


## A length of roller at `run`: an inked drum rolling over the floor, its top catching the light, its
## leading edge on the ground in red-orange (it hurts).
func _roller(along: Vector2, run: float) -> void:
	var r := Editor.ROLLER_HALF * 0.8
	var base := PackedVector2Array([_pt(along.x, run - r), _pt(along.y, run - r), _pt(along.y, run + r), _pt(along.x, run + r)])
	draw_colored_polygon(base, Palette.BLACK_MIRROR)
	var top := PackedVector2Array()
	for p: Vector2 in base:
		top.append(p + Vector2(0, -22))
	draw_colored_polygon(top, Palette.IRON_DARK.lightened(0.2))
	draw_line(_pt(along.x, run) + Vector2(0, -24), _pt(along.y, run) + Vector2(0, -24), Palette.IRON_DARK.lightened(0.55), 4.0, true)
	var ahead := editor.run_span()
	var front := run + r * signf(ahead.y - ahead.x)
	draw_line(_pt(along.x, front), _pt(along.y, front), Palette.DANGER, 3.0, true)
