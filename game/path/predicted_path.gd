class_name PredictedPath
extends Node2D
## Draws the Steward's predicted path through the three cells ahead of the Operator: a quiet trail, not
## image 10's gilded tiles (the user's call, DECISIONS 151). A thin dashed thread of its gold from cell to
## cell, a small stud at each, nearest brightest. A cell fades in as the prediction reaches it and goes
## at once when it stops being predicted, so no more than three are ever marked (the brief: always
## exactly three ahead). Gold is the Steward's colour; this is the Steward's light. Only while it can
## see you (voice on, on the Lattice).

const FADE_SPEED := 6.0
const BRIGHTNESS: Array[float] = [0.85, 0.6, 0.38]
## A stud's half size on screen, and the thread's dashes.
const STUD := Vector2(9.0, 5.0)
const DASH := 10.0
const GAP := 8.0

class Tile:
	var cell: Vector2i
	var alpha: float = 0.0
	var target: float = 0.0
	var rank: int = 0

var predictor: PathPredictor
var player: Operator
## Cells currently predicted, nearest first (read by tests and the autopilot).
var shown: Array[Vector2i] = []

var _tiles: Dictionary[Vector2i, Tile] = {}
var _light: PointLight2D


func _ready() -> void:
	z_index = -13
	material = Emissive.unshaded_material()
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial()
	_light.color = Palette.STEWARD_GOLD
	_light.energy = 0.0
	_light.texture_scale = 1.6
	_light.scale = Vector2(1.0, Iso.SQUASH)
	add_child(_light)


func _process(delta: float) -> void:
	shown = []
	if predictor != null and player != null and player.is_alive() and Steward.assists().path_visible:
		shown = predictor.predict(player.global_position)
	for c: Vector2i in _tiles.keys():
		if not shown.has(c):
			_tiles.erase(c)
	for i: int in shown.size():
		var c := shown[i]
		if not _tiles.has(c):
			var t := Tile.new()
			t.cell = c
			_tiles[c] = t
		_tiles[c].target = BRIGHTNESS[mini(i, BRIGHTNESS.size() - 1)]
		_tiles[c].rank = i
	for t: Tile in _tiles.values():
		t.alpha = move_toward(t.alpha, t.target, FADE_SPEED * delta)
	if shown.is_empty():
		_light.energy = move_toward(_light.energy, 0.0, delta * 4.0)
	else:
		_light.position = Iso.cell_center(shown[0])
		_light.energy = move_toward(_light.energy, 0.35, delta * 4.0)
	queue_redraw()


## Cells marked right now (tests check this, not just the prediction).
func painted_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in _tiles:
		if _tiles[c].alpha > 0.0:
			out.append(c)
	return out


func _draw() -> void:
	var marked: Array[Tile] = []
	for c: Vector2i in shown:
		if _tiles.has(c) and _tiles[c].alpha > 0.0:
			marked.append(_tiles[c])
	for i: int in range(marked.size() - 1):
		_thread(Iso.cell_center(marked[i].cell), Iso.cell_center(marked[i + 1].cell), minf(marked[i].alpha, marked[i + 1].alpha))
	for t: Tile in marked:
		var at := Iso.cell_center(t.cell)
		var stud := PackedVector2Array([at + Vector2(0, -STUD.y), at + Vector2(STUD.x, 0), at + Vector2(0, STUD.y), at + Vector2(-STUD.x, 0)])
		draw_colored_polygon(stud, Color(Palette.STEWARD_GOLD, 0.35 * t.alpha))
		draw_circle(at, 2.5, Color(Palette.STEWARD_GOLD_HOT, t.alpha), true, -1.0, true)


## A dashed thread of gold on the ground between two cell centres.
func _thread(a: Vector2, b: Vector2, alpha: float) -> void:
	var length := a.distance_to(b)
	var dir := (b - a) / maxf(length, 0.001)
	var t := STUD.x
	while t < length - STUD.x:
		var end := minf(t + DASH, length - STUD.x)
		draw_line(a + dir * t, a + dir * end, Color(Palette.STEWARD_GOLD_HOT, 0.6 * alpha), 2.0, true)
		t += DASH + GAP
