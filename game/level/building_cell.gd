class_name BuildingCell
extends Node2D
## One cell of a building, drawn as an isometric prism and depth-sorted with everything else. Faces
## hidden by a neighbouring building cell are skipped. Old Meridian brick and stained glass with lit
## windows (human warmth), old-city neon, and the Steward's gilt threaded along the balcony ironwork,
## which dies when the voice is muted.

enum Facade { PLAIN, DOOR, NEON_MAGENTA, NEON_LIME }

const STORY := 74.0
const STORIES := 3
const PARAPET := 16.0
const GLOW_LAYER := 0
const GILT_LAYER := 1

var cell: Vector2i
var facade: Facade = Facade.PLAIN
var show_left: bool = true
var show_right: bool = true
var gilt_lit: bool = true:
	set(value):
		gilt_lit = value
		if _emissive != null:
			_emissive.set_layer_enabled(GILT_LAYER, value)

var _base := DrawOps.new()
var _glow := DrawOps.new()
var _gilt := DrawOps.new()
var _emissive: Emissive


func setup(at: Vector2i, kind: Facade, left_open: bool, right_open: bool) -> void:
	cell = at
	facade = kind
	show_left = left_open
	show_right = right_open
	position = Iso.cell_center(at)
	add_to_group(&"gilt")
	_build()
	_emissive = Emissive.new()
	_emissive.layers = [_glow, _gilt]
	add_child(_emissive)
	if is_neon():
		var col := neon_color()
		var light := PointLight2D.new()
		light.texture = LightTextures.radial()
		light.color = col
		light.energy = 0.9
		light.texture_scale = 1.8
		light.scale = Vector2(1.0, Iso.SQUASH)
		light.position = Vector2(Iso.HALF_W * 0.7, Iso.HALF_H * 1.2)
		add_child(light)
		WetReflections.add(self, Vector2(Iso.HALF_W * 0.85, Iso.HALF_H * 0.15), 150.0, col, Callable())


func is_neon() -> bool:
	return facade == Facade.NEON_MAGENTA or facade == Facade.NEON_LIME


func neon_color() -> Color:
	return Palette.NEON_MAGENTA if facade == Facade.NEON_MAGENTA else Palette.NEON_LIME


func height() -> float:
	return STORY * STORIES + PARAPET


func _draw() -> void:
	_base.paint(self)


func _build() -> void:
	var h := height()
	var hw := Iso.HALF_W
	var hh := Iso.HALF_H
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var up := Vector2(0, -h)
	if show_left:
		_base.poly(PackedVector2Array([left, bottom, bottom + up, left + up]), Palette.BRICK_DARK)
		_face(left, bottom, h, false)
	if show_right:
		_base.poly(PackedVector2Array([bottom, right, right + up, bottom + up]), Palette.BRICK)
		_face(bottom, right, h, true)
	_base.poly(PackedVector2Array([top + up, right + up, bottom + up, left + up]), Palette.BRICK_TOP)
	_base.polyline(PackedVector2Array([left + up, top + up, right + up]), Color(Palette.NEAR_BLACK, 0.5), 2.0)


## Point on a face: `a`→`b` is the face's bottom edge, u runs along it (0..1), v is height in px.
static func _on_face(a: Vector2, b: Vector2, u: float, v: float) -> Vector2:
	return a.lerp(b, u) + Vector2(0, -v)


func _face(a: Vector2, b: Vector2, h: float, street_side: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, 1 if street_side else 2))
	var mortar := Color(Palette.NEAR_BLACK, 0.16)
	var v := 12.0
	while v < h - PARAPET:
		_base.line(_on_face(a, b, 0.0, v), _on_face(a, b, 1.0, v), mortar, 1.0)
		v += 12.0
	_base.line(_on_face(a, b, 0.0, h - PARAPET), _on_face(a, b, 1.0, h - PARAPET), Palette.STONE_OLD, 4.0)
	for story: int in STORIES:
		var base := story * STORY
		if story == 0 and facade == Facade.DOOR and street_side:
			_door(a, b)
			continue
		_window(a, b, base, rng.randf() < (0.42 if street_side else 0.22), rng)
		if story == 1:
			_balcony(a, b, base)
	if street_side and is_neon():
		_neon(a, b)


func _window(a: Vector2, b: Vector2, base: float, lit: bool, rng: RandomNumberGenerator) -> void:
	var u0 := 0.3
	var u1 := 0.7
	var v0 := base + 12.0
	var v1 := base + STORY - 20.0
	var pane := PackedVector2Array([_on_face(a, b, u0, v0), _on_face(a, b, u1, v0), _on_face(a, b, u1, v1), _on_face(a, b, u0, v1)])
	var transom := PackedVector2Array([_on_face(a, b, u0, v1 + 3.0), _on_face(a, b, u1, v1 + 3.0), _on_face(a, b, (u0 + u1) * 0.5, v1 + 13.0)])
	var stain := Palette.STAINED_ROSE if rng.randf() < 0.5 else Palette.STAINED_TEAL
	if lit:
		_glow.poly(pane, Color(Palette.HUMAN_CREAM, 0.55))
		_glow.poly(transom, Color(stain.lightened(0.25), 0.9))
	else:
		_base.poly(pane, Palette.BLACK_MIRROR)
		_base.poly(transom, Color(stain, 0.5))
	_base.polyline(PackedVector2Array([pane[0], pane[1], pane[2], pane[3], pane[0]]), Palette.IRON_DARK, 2.0)


func _balcony(a: Vector2, b: Vector2, base: float) -> void:
	var v := base + 8.0
	_base.line(_on_face(a, b, 0.18, v), _on_face(a, b, 0.82, v), Palette.IRON_DARK, 3.0)
	_base.line(_on_face(a, b, 0.18, v + 16.0), _on_face(a, b, 0.82, v + 16.0), Palette.IRON_VERDIGRIS, 2.0)
	for k: int in 6:
		var u := lerpf(0.2, 0.8, k / 5.0)
		_base.line(_on_face(a, b, u, v), _on_face(a, b, u, v + 16.0), Palette.IRON_DARK, 1.5)
	# The gilt: ten years of the Steward laid over the ironwork, a gold vein along the rail.
	_gilt.line(_on_face(a, b, 0.18, v + 16.0), _on_face(a, b, 0.82, v + 16.0), Palette.STEWARD_GOLD_HOT, 1.5)


func _door(a: Vector2, b: Vector2) -> void:
	var door := PackedVector2Array([_on_face(a, b, 0.32, 0.0), _on_face(a, b, 0.68, 0.0), _on_face(a, b, 0.68, 52.0), _on_face(a, b, 0.5, 62.0), _on_face(a, b, 0.32, 52.0)])
	_glow.poly(door, Color(Palette.HUMAN_CREAM, 0.45))
	_base.polyline(PackedVector2Array([door[0], door[4], door[3], door[2], door[1]]), Palette.IRON_DARK, 3.0)


func _neon(a: Vector2, b: Vector2) -> void:
	var col := neon_color()
	var hot := Color(col.r * 1.7, col.g * 1.7, col.b * 1.7)
	var plate := PackedVector2Array([_on_face(a, b, 0.78, 96.0), _on_face(a, b, 0.92, 96.0), _on_face(a, b, 0.92, 196.0), _on_face(a, b, 0.78, 196.0)])
	_base.poly(plate, Color(Palette.NEAR_BLACK, 0.8))
	_glow.polyline(PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[0]]), hot, 2.5)
	var squiggle := PackedVector2Array()
	for k: int in 12:
		var t := k / 11.0
		squiggle.append(_on_face(a, b, 0.85 + sin(t * TAU * 1.5) * 0.035, lerpf(110.0, 182.0, t)))
	_glow.polyline(squiggle, hot, 3.0)
