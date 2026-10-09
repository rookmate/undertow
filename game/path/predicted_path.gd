class_name PredictedPath
extends Node2D
## Draws the Steward's predicted path: three gilded floor tiles ahead of the Operator with the
## four-petal inlay of image 10, nearest brightest. Tiles fade in as the prediction reaches them; a tile
## that stops being predicted goes at once, so no more than three are ever painted (the brief: always
## exactly three ahead). Gold is the Steward's colour; this is the Steward's light. Only while it can
## see you (voice on, on the Lattice).

const FADE_SPEED := 6.0
const BRIGHTNESS: Array[float] = [1.0, 0.68, 0.42]

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
		_light.energy = move_toward(_light.energy, 0.9, delta * 4.0)
	queue_redraw()


## Cells with a tile painted right now (tests check this, not just the prediction).
func painted_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in _tiles:
		if _tiles[c].alpha > 0.0:
			out.append(c)
	return out


func _draw() -> void:
	for t: Tile in _tiles.values():
		if t.alpha > 0.0:
			PathTilePainter.paint(self, Iso.cell_center(t.cell), t.alpha)
