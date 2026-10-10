class_name Minimap
extends Control
## Top-right of the HUD. Voice on: the Steward's map, drawn in its gold, "100% charted", and silent about
## everywhere it never indexed (the stacks aren't on it). Off the Lattice it can't place you. Muted: a
## hand scan, only what you have seen, with an honest percentage, and anything you found marked in cyan.
##
## Drawing a thousand cell polygons in GDScript costs milliseconds, so the map is split into chunks that
## each keep their draw list and redraw only when something in them changes (a cell seen for the first
## time, or the map switching mode). The moving parts (the Operator's dot, found markers) are a tiny
## overlay redrawn every frame.

const PANEL_SIZE := Vector2(330, 236)
## Room kept free under the map for the charted label.
const LABEL_BAND := 34.0
const MARGIN := 12.0
const CHUNK := 8
const CHECK_SECONDS := 0.1

var level: Level

var _chunks: Dictionary[Vector2i, _ChunkLayer] = {}
var _marks: _MarkLayer
var _mode_signature: String = ""
var _label_text: String = ""
var _check_in: float = 0.0
var _tile: float = 1.0
var _origin: Vector2 = Vector2.ZERO
## Per cell, computed once: its polygon on the map and its colour on each kind of map.
var _poly: Dictionary[Vector2i, PackedVector2Array] = {}
var _steward_colour: Dictionary[Vector2i, Color] = {}
var _scan_colour: Dictionary[Vector2i, Color] = {}


class _ChunkLayer:
	extends Control
	var map: Minimap
	var chunk: Vector2i

	func _draw() -> void:
		map.draw_chunk(self, chunk)


class _MarkLayer:
	extends Control
	var map: Minimap

	func _draw() -> void:
		map.draw_marks(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -PANEL_SIZE.x - 36
	offset_right = -36
	offset_top = 32
	offset_bottom = 32 + PANEL_SIZE.y
	if level == null or level.grid == null:
		return
	_prepare()
	for cy: int in ceili(level.grid.size.y / float(CHUNK)):
		for cx: int in ceili(level.grid.size.x / float(CHUNK)):
			var layer := _ChunkLayer.new()
			layer.map = self
			layer.chunk = Vector2i(cx, cy)
			layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			layer.size = PANEL_SIZE
			add_child(layer)
			_chunks[layer.chunk] = layer
	_marks = _MarkLayer.new()
	_marks.map = self
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.size = PANEL_SIZE
	add_child(_marks)
	if level.exploration != null:
		level.exploration.discovered.connect(_on_discovered)


func _process(delta: float) -> void:
	if _marks == null:
		return
	_marks.queue_redraw()
	_check_in -= delta
	if _check_in > 0.0:
		return
	_check_in = CHECK_SECONDS
	var a := Steward.assists()
	var mode_signature := "%d|%d" % [mode(), int(a.signal_lost)]
	if mode_signature != _mode_signature:
		_mode_signature = mode_signature
		for layer: _ChunkLayer in _chunks.values():
			layer.queue_redraw()
	var label := charted_label()
	if label != _label_text:
		_label_text = label
		queue_redraw()


## Only the chunks holding newly seen cells (and their edges) change on the hand scan.
func _on_discovered(cells: Array[Vector2i]) -> void:
	if mode() != Assists.MapMode.HAND_SCAN:
		return
	var dirty: Dictionary[Vector2i, bool] = {}
	for c: Vector2i in cells:
		for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n := c + d
			dirty[Vector2i(floori(n.x / float(CHUNK)), floori(n.y / float(CHUNK)))] = true
	for k: Vector2i in dirty:
		if _chunks.has(k):
			_chunks[k].queue_redraw()


func mode() -> Assists.MapMode:
	return Steward.assists().map_mode


func charted_label() -> String:
	if Steward.assists().signal_lost:
		return "STEWARD MAP · SIGNAL LOST"
	if mode() == Assists.MapMode.STEWARD:
		return "STEWARD MAP · 100% CHARTED"
	return "HAND SCAN · %d%% CHARTED" % roundi(level.exploration.charted_ratio() * 100.0)


func _draw() -> void:
	if level == null or level.grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Palette.PANEL)
	draw_rect(Rect2(Vector2.ZERO, PANEL_SIZE), Palette.IVORY_FAINT, false, 1.0)
	var label_col := Palette.STEWARD_GOLD if mode() == Assists.MapMode.STEWARD and not Steward.assists().signal_lost else Palette.IVORY
	draw_string(UiFonts.mono_medium(), Vector2(12, PANEL_SIZE.y - 12), charted_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, label_col)


## Fits the level into the panel and works out every cell's polygon and static colours, once.
func _prepare() -> void:
	var grid := level.grid
	var span := float(grid.size.x + grid.size.y)
	var area := PANEL_SIZE - Vector2(MARGIN * 2.0, MARGIN * 2.0 + LABEL_BAND)
	_tile = minf(area.x / span, area.y / (span * Iso.SQUASH))
	var map_size := Vector2(span * _tile, span * _tile * Iso.SQUASH)
	var corner := Vector2(MARGIN, MARGIN) + (area - map_size) * 0.5
	_origin = corner + Vector2(grid.size.y * _tile, 0.0)
	for c: Vector2i in grid.all_cells():
		var g := Vector2(c)
		_poly[c] = PackedVector2Array([to_map(g), to_map(g + Vector2(1, 0)), to_map(g + Vector2(1, 1)), to_map(g + Vector2(0, 1))])
		var f := grid.floor_at(c)
		if grid.is_marrow(c):
			# It can't see through the thick Marrow: a blank of fog on its map.
			_steward_colour[c] = Color(Palette.FOG, 0.18)
		elif grid.is_indexed(c):
			_steward_colour[c] = Color(Palette.STEWARD_GOLD, 0.32)
		elif f == LevelGrid.Floor.BUILDING:
			_steward_colour[c] = Color(Palette.GREY_DEEP, 0.9)
		elif f == LevelGrid.Floor.WATER and _near_indexed(c):
			_steward_colour[c] = Color(Palette.WATER_SHEEN, 0.5)
		if grid.is_walkable(c):
			_scan_colour[c] = Color(Palette.IVORY, 0.32)
		elif f == LevelGrid.Floor.BUILDING:
			_scan_colour[c] = Color(Palette.GREY_DEEP, 0.9)
		elif f != LevelGrid.Floor.VOID:
			_scan_colour[c] = Color(Palette.WATER_SHEEN, 0.4)


func to_map(g: Vector2) -> Vector2:
	return _origin + Vector2((g.x - g.y) * _tile, (g.x + g.y) * _tile * Iso.SQUASH)


func draw_chunk(ci: CanvasItem, chunk: Vector2i) -> void:
	var steward := mode() == Assists.MapMode.STEWARD
	var size_cells := level.grid.size
	for y: int in range(chunk.y * CHUNK, mini((chunk.y + 1) * CHUNK, size_cells.y)):
		for x: int in range(chunk.x * CHUNK, mini((chunk.x + 1) * CHUNK, size_cells.x)):
			var c := Vector2i(x, y)
			if steward:
				if _steward_colour.has(c):
					ci.draw_colored_polygon(_poly[c], _steward_colour[c])
			elif _scan_colour.has(c) and _seen(c):
				ci.draw_colored_polygon(_poly[c], _scan_colour[c])
	var r := level.grid.first("R")
	if steward and r.x >= 0 and Vector2i(floori(r.x / float(CHUNK)), floori(r.y / float(CHUNK))) == chunk:
		ci.draw_arc(to_map(Vector2(r) + Vector2(0.5, 0.5)), 5.0, 0.0, TAU, 14, Palette.STEWARD_GOLD, 2.0, true)


func draw_marks(ci: CanvasItem) -> void:
	if level == null or level.player == null:
		return
	if mode() == Assists.MapMode.HAND_SCAN:
		# What you found yourself, in its own colour, wherever it was.
		for c: Vector2i in level.found_cache_cells():
			ci.draw_circle(to_map(Vector2(c) + Vector2(0.5, 0.5)), 4.0, Palette.TRUTH_CYAN, true, -1.0, true)
	# Off the Lattice the Steward's map can't place you.
	if not Steward.assists().signal_lost:
		ci.draw_circle(to_map(Iso.world_to_grid(level.player.global_position)), 4.0, Palette.IVORY, true, -1.0, true)


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
