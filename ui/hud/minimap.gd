class_name Minimap
extends Control
## Top-right of the HUD. Voice on: the Steward's map, drawn in its gold, "100% charted", and silent about
## everywhere it never indexed (the stacks aren't on it). Muted: a hand scan, only what you have seen,
## with an honest percentage, and anything you found marked in cyan.

const PANEL_SIZE := Vector2(330, 236)
## Room kept free under the map for the charted label.
const LABEL_BAND := 34.0
const MARGIN := 12.0

var level: Level
var _refresh: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -PANEL_SIZE.x - 36
	offset_right = -36
	offset_top = 32
	offset_bottom = 32 + PANEL_SIZE.y


func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.1
		queue_redraw()


func mode() -> Assists.MapMode:
	return Steward.assists().map_mode


func charted_label() -> String:
	if mode() == Assists.MapMode.STEWARD:
		return "STEWARD MAP · 100% CHARTED"
	return "HAND SCAN · %d%% CHARTED" % roundi(level.exploration.charted_ratio() * 100.0)


func _draw() -> void:
	if level == null or level.grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Palette.PANEL)
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Palette.IVORY_FAINT, false, 1.0)
	var steward := mode() == Assists.MapMode.STEWARD
	var label_col := Palette.STEWARD_GOLD if steward else Palette.IVORY
	draw_string(UiFonts.mono_medium(), Vector2(12, PANEL_SIZE.y - 12), charted_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_col)
	var grid := level.grid
	# Fit the whole level's diamond into the panel above the label band.
	var span := float(grid.size.x + grid.size.y)
	var area := PANEL_SIZE - Vector2(MARGIN * 2.0, MARGIN * 2.0 + LABEL_BAND)
	var tile := minf(area.x / span, area.y / (span * Iso.SQUASH))
	var map_size := Vector2(span * tile, span * tile * Iso.SQUASH)
	var corner := Vector2(MARGIN, MARGIN) + (area - map_size) * 0.5
	var origin := corner + Vector2(grid.size.y * tile, 0.0)
	var to_map := func(g: Vector2) -> Vector2:
		return origin + Vector2((g.x - g.y) * tile, (g.x + g.y) * tile * Iso.SQUASH)
	for c: Vector2i in grid.all_cells():
		var col := _cell_colour(c, steward)
		if col.a <= 0.0:
			continue
		var pts := PackedVector2Array([to_map.call(Vector2(c)), to_map.call(Vector2(c.x + 1, c.y)), to_map.call(Vector2(c.x + 1, c.y + 1)), to_map.call(Vector2(c.x, c.y + 1))])
		draw_colored_polygon(pts, col)
	if steward:
		var r := grid.first("R")
		draw_arc(to_map.call(Vector2(r) + Vector2(0.5, 0.5)), 5.0, 0.0, TAU, 14, Palette.STEWARD_GOLD, 2.0, true)
	elif level.exploration.explored.has(grid.first("T")) and GameState.run.found_core_ids.has(ContentIds.CORE_TRUTH_STACKS):
		draw_circle(to_map.call(Vector2(grid.first("T")) + Vector2(0.5, 0.5)), 4.0, Palette.TRUTH_CYAN, true, -1.0, true)
	if level.player != null:
		var p := Iso.world_to_grid(level.player.global_position)
		draw_circle(to_map.call(p), 4.0, Palette.IVORY, true, -1.0, true)


func _cell_colour(c: Vector2i, steward: bool) -> Color:
	var grid := level.grid
	var f := grid.floor_at(c)
	if steward:
		if grid.is_indexed(c):
			return Color(Palette.STEWARD_GOLD, 0.32)
		if f == LevelGrid.Floor.BUILDING:
			return Color(Palette.GREY_DEEP, 0.9)
		if f == LevelGrid.Floor.WATER and _near_indexed(c):
			return Color(Palette.WATER_SHEEN, 0.5)
		return Color(0, 0, 0, 0)
	if not _seen(c):
		return Color(0, 0, 0, 0)
	if grid.is_walkable(c):
		return Color(Palette.IVORY, 0.32)
	if f == LevelGrid.Floor.BUILDING:
		return Color(Palette.GREY_DEEP, 0.9)
	return Color(Palette.WATER_SHEEN, 0.4)


func _seen(c: Vector2i) -> bool:
	var ex := level.exploration.explored
	if ex.has(c):
		return true
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if ex.has(c + d):
			return true
	return false


func _near_indexed(c: Vector2i) -> bool:
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		if level.grid.is_indexed(c + d):
			return true
	return false
