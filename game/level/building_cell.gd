class_name BuildingCell
extends Node2D
## One cell of a building, drawn as an isometric prism and depth-sorted with everything else. Faces
## hidden by a neighbouring building cell are skipped. Old Meridian brick and stained glass with lit
## windows (human warmth), old-city neon, and the Steward's gilt threaded along the balcony ironwork,
## which dies when the voice is muted.

enum Facade { PLAIN, DOOR, NEON_MAGENTA, NEON_LIME, ARCHIVE, LAUNDRY, SIGNAL_ROOM, WORKSHOP, HOSPITAL, HOSPITAL_DOOR, CLINIC, PUMPING_STATION, PUMPING_STATION_DOOR, PUMPHOUSE, BOATHOUSE, BOATHOUSE_DOOR, BRIDGE_STUB }

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
var look: DistrictLook = DistrictLook.new()
var _emissive: Emissive


func setup(at: Vector2i, kind: Facade, left_open: bool, right_open: bool, district_look: DistrictLook = null) -> void:
	cell = at
	if district_look != null:
		look = district_look
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
		_base.poly(PackedVector2Array([left, bottom, bottom + up, left + up]), look.wall_shade)
		_face(left, bottom, h, false)
	if show_right:
		_base.poly(PackedVector2Array([bottom, right, right + up, bottom + up]), look.wall)
		_face(bottom, right, h, true)
	_base.poly(PackedVector2Array([top + up, right + up, bottom + up, left + up]), look.wall_top)
	_base.polyline(PackedVector2Array([left + up, top + up, right + up]), Color(Palette.NEAR_BLACK, 0.5), 2.0)
	if facade == Facade.SIGNAL_ROOM and show_left and show_right:
		# A signal mast on the roof, its lamps the old cream ones people switched by hand.
		var foot := up + Vector2(0, -4)
		_base.line(foot, foot + Vector2(0, -90), Palette.IRON_DARK, 4.0)
		for k: int in 3:
			_glow.circle(foot + Vector2(0, -40 - k * 22), 5.0, Palette.HUMAN_CREAM)


## Point on a face: `a`→`b` is the face's bottom edge, u runs along it (0..1), v is height in px.
static func _on_face(a: Vector2, b: Vector2, u: float, v: float) -> Vector2:
	return a.lerp(b, u) + Vector2(0, -v)


func _face(a: Vector2, b: Vector2, h: float, street_side: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, 1 if street_side else 2))
	if facade == Facade.HOSPITAL or facade == Facade.HOSPITAL_DOOR:
		_hospital_face(a, b, h, street_side, rng)
		return
	if facade == Facade.PUMPING_STATION or facade == Facade.PUMPING_STATION_DOOR:
		_pump_face(a, b, h, street_side)
		return
	if facade == Facade.BOATHOUSE or facade == Facade.BOATHOUSE_DOOR:
		_boathouse_face(a, b, h, street_side, rng)
		return
	if facade == Facade.BRIDGE_STUB:
		_bridge_face(a, b, h)
		return
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
		if facade == Facade.WORKSHOP:
			# A roller shutter half up on the ground floor, light and sparks inside; warm windows above.
			if story == 0 and street_side:
				var shutter := PackedVector2Array([_on_face(a, b, 0.15, 0.0), _on_face(a, b, 0.85, 0.0), _on_face(a, b, 0.85, 40.0), _on_face(a, b, 0.15, 40.0)])
				_glow.poly(shutter, Color(Palette.HUMAN_CREAM, 0.5))
				for k: int in 5:
					var slat := 44.0 + k * 6.0
					_base.line(_on_face(a, b, 0.15, slat), _on_face(a, b, 0.85, slat), Palette.IRON_DARK, 2.0)
			else:
				_window(a, b, base, true, rng)
			continue
		if facade == Facade.SIGNAL_ROOM:
			# Restored and staffed by people: warm windows, and the signal lamps on its mast (below).
			_window(a, b, base, true, rng)
			continue
		if facade == Facade.PUMPHOUSE:
			# Run by people again: warm windows, the crews' cranks back on the wall, a pipe down the face.
			_window(a, b, base, true, rng)
			if story == 0 and street_side:
				_base.line(_on_face(a, b, 0.85, 0.0), _on_face(a, b, 0.85, STORY * STORIES), Palette.IRON_DARK.lightened(0.15), 8.0)
			continue
		if facade == Facade.CLINIC:
			# Staffed by people: every window warm, and a cross lit in cream over the door (not red:
			# red-orange is danger, and this is the opposite).
			_window(a, b, base, true, rng)
			if story == 2 and street_side:
				var c := _on_face(a, b, 0.5, base + STORY * 0.5)
				_glow.poly(PackedVector2Array([c + Vector2(-5, -16), c + Vector2(5, -16), c + Vector2(5, 16), c + Vector2(-5, 16)]), Palette.HUMAN_CREAM)
				_glow.poly(PackedVector2Array([c + Vector2(-16, -5), c + Vector2(16, -5), c + Vector2(16, 5), c + Vector2(-16, 5)]), Palette.HUMAN_CREAM)
			continue
		if facade == Facade.ARCHIVE:
			# Restored and in use: every window warm, a rose of stained glass over the door.
			_window(a, b, base, true, rng)
			if story == 1 and street_side:
				_rose(a, b, base)
			continue
		_window(a, b, base, rng.randf() < (0.42 if street_side else 0.22), rng)
		if story == 1:
			_balcony(a, b, base)
		if facade == Facade.LAUNDRY and street_side and story >= 1:
			_laundry(a, b, base, rng)
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


## Washing still on the line, days after everyone left.
func _laundry(a: Vector2, b: Vector2, base: float, rng: RandomNumberGenerator) -> void:
	var v := base + STORY - 10.0
	_base.line(_on_face(a, b, 0.08, v), _on_face(a, b, 0.92, v), Palette.IRON_DARK, 1.0)
	var cloths: Array[Color] = [look.blossom, Palette.HUMAN_CREAM, Palette.STAINED_TEAL.lightened(0.3), look.blossom.darkened(0.15)]
	var u := 0.12
	while u < 0.86:
		var w := rng.randf_range(0.08, 0.14)
		var drop := rng.randf_range(14.0, 24.0)
		_base.poly(PackedVector2Array([_on_face(a, b, u, v), _on_face(a, b, u + w, v), _on_face(a, b, u + w, v - drop), _on_face(a, b, u, v - drop)]), cloths[rng.randi() % cloths.size()])
		u += w + rng.randf_range(0.03, 0.06)


func _rose(a: Vector2, b: Vector2, base: float) -> void:
	var c := _on_face(a, b, 0.5, base + 30.0)
	var petals := PackedVector2Array()
	for i: int in 13:
		var ang := TAU * i / 12.0
		petals.append(c + Vector2(cos(ang) * 14.0, sin(ang) * 18.0))
	_glow.poly(petals, Color(Palette.STAINED_ROSE.lightened(0.3), 0.9))
	_base.polyline(petals, Palette.IRON_DARK, 2.0)


## Mercy General's walls from the inside: painted panels, a grey-blue dado and a handrail; the arrows
## people chalked looking for a way out (human cream); every third ceiling light still working, the
## Steward's (it dies when muted). Locked doors are double doors with dark portholes.
func _hospital_face(a: Vector2, b: Vector2, h: float, street_side: bool, rng: RandomNumberGenerator) -> void:
	for k: int in 3:
		var u := (k + 1) * 0.25
		_base.line(_on_face(a, b, u, 0.0), _on_face(a, b, u, h - PARAPET), Color(Palette.NEAR_BLACK, 0.12), 1.0)
	var dado := PackedVector2Array([_on_face(a, b, 0.0, 0.0), _on_face(a, b, 1.0, 0.0), _on_face(a, b, 1.0, 46.0), _on_face(a, b, 0.0, 46.0)])
	_base.poly(dado, Color(Palette.WARD_GLASS.darkened(0.55), 0.85))
	_base.line(_on_face(a, b, 0.0, 52.0), _on_face(a, b, 1.0, 52.0), Palette.WARD_WALL_SHADE.darkened(0.3), 3.0)
	if facade == Facade.HOSPITAL_DOOR and street_side:
		var door := PackedVector2Array([_on_face(a, b, 0.2, 0.0), _on_face(a, b, 0.8, 0.0), _on_face(a, b, 0.8, 84.0), _on_face(a, b, 0.2, 84.0)])
		_base.poly(door, Palette.WARD_WALL_SHADE.darkened(0.15))
		_base.line(_on_face(a, b, 0.5, 0.0), _on_face(a, b, 0.5, 84.0), Palette.NEAR_BLACK, 2.0)
		for u: float in [0.35, 0.65]:
			_base.circle(_on_face(a, b, u, 62.0), 6.0, Palette.BLACK_MIRROR)
	elif rng.randf() < 0.4:
		# A chalk arrow: this way out, someone thought.
		var y := rng.randf_range(70.0, 120.0)
		var dir := 1.0 if rng.randf() < 0.5 else -1.0
		var tail := _on_face(a, b, 0.5 - 0.22 * dir, y)
		var tip := _on_face(a, b, 0.5 + 0.22 * dir, y)
		var chalk := Color(Palette.HUMAN_CREAM, 0.75)
		_base.line(tail, tip, chalk, 3.0)
		_base.line(tip, tip + (tail - tip).rotated(0.5) * 0.3, chalk, 3.0)
		_base.line(tip, tip + (tail - tip).rotated(-0.5) * 0.3, chalk, 3.0)
	if (cell.x + cell.y) % 3 == 0 and street_side:
		_gilt.circle(_on_face(a, b, 0.5, h - PARAPET - 10.0), 5.0, Palette.STEWARD_GOLD_HOT)


## A pumping station: board-marked concrete, louvres high up, a big pipe down the face, kelp and a tide
## stain low on it; its doors are steel. The gilt on the louvres is the Steward's (dies when muted).
func _pump_face(a: Vector2, b: Vector2, h: float, street_side: bool) -> void:
	for k: int in 6:
		var v := 30.0 + k * 34.0
		_base.line(_on_face(a, b, 0.0, v), _on_face(a, b, 1.0, v), Color(Palette.NEAR_BLACK, 0.12), 1.0)
	_base.poly(PackedVector2Array([_on_face(a, b, 0.0, 0.0), _on_face(a, b, 1.0, 0.0), _on_face(a, b, 1.0, 26.0), _on_face(a, b, 0.0, 26.0)]), Color(Palette.KELP_DARK, 0.55))
	_base.line(_on_face(a, b, 0.0, 30.0), _on_face(a, b, 1.0, 30.0), Color(Palette.LOW_STREET_WET, 0.8), 2.0)
	_base.line(_on_face(a, b, 0.78, 0.0), _on_face(a, b, 0.78, h - PARAPET), Palette.IRON_DARK.lightened(0.15), 8.0)
	for k: int in 4:
		var v := h - PARAPET - 30.0 - k * 9.0
		_base.line(_on_face(a, b, 0.2, v), _on_face(a, b, 0.6, v), Palette.IRON_DARK, 3.0)
	if street_side and (cell.x + cell.y) % 2 == 0:
		_gilt.line(_on_face(a, b, 0.2, h - PARAPET - 26.0), _on_face(a, b, 0.6, h - PARAPET - 26.0), Palette.STEWARD_GOLD, 1.5)
	if facade == Facade.PUMPING_STATION_DOOR and street_side:
		var door := PackedVector2Array([_on_face(a, b, 0.22, 0.0), _on_face(a, b, 0.68, 0.0), _on_face(a, b, 0.68, 70.0), _on_face(a, b, 0.22, 70.0)])
		_base.poly(door, Palette.IRON_DARK.lightened(0.1))
		_base.line(_on_face(a, b, 0.45, 0.0), _on_face(a, b, 0.45, 70.0), Palette.NEAR_BLACK, 2.0)


## A Harbor Ward boat-house: tarred clapboard, a few small windows lit cyan by the Wardfolk's own wiring
## (never gold: there's nothing of the Steward here), a hand-painted sign, a cable strung off the eave.
func _boathouse_face(a: Vector2, b: Vector2, h: float, street_side: bool, rng: RandomNumberGenerator) -> void:
	var v := 9.0
	while v < h - PARAPET:
		_base.line(_on_face(a, b, 0.0, v), _on_face(a, b, 1.0, v), Color(Palette.NEAR_BLACK, 0.22), 1.0)
		v += 9.0
	for story: int in STORIES:
		if rng.randf() < (0.5 if street_side else 0.25):
			var u := rng.randf_range(0.2, 0.6)
			var w := PackedVector2Array([_on_face(a, b, u, story * STORY + 30.0), _on_face(a, b, u + 0.18, story * STORY + 30.0), _on_face(a, b, u + 0.18, story * STORY + 52.0), _on_face(a, b, u, story * STORY + 52.0)])
			_glow.poly(w, Color(Palette.WARD_CYAN, 0.75))
	if facade == Facade.BOATHOUSE_DOOR and street_side:
		var door := PackedVector2Array([_on_face(a, b, 0.3, 0.0), _on_face(a, b, 0.7, 0.0), _on_face(a, b, 0.7, 60.0), _on_face(a, b, 0.3, 60.0)])
		_base.poly(door, Palette.BOATHOUSE_SHADE.darkened(0.3))
		_glow.line(_on_face(a, b, 0.32, 64.0), _on_face(a, b, 0.68, 64.0), Palette.WARD_CYAN_HOT, 2.0)
	elif street_side and rng.randf() < 0.5:
		# A hand-painted sign: NETS, ROPE, ENGINES.
		var board := PackedVector2Array([_on_face(a, b, 0.15, 90.0), _on_face(a, b, 0.85, 90.0), _on_face(a, b, 0.85, 110.0), _on_face(a, b, 0.15, 110.0)])
		_base.poly(board, Palette.HUMAN_CREAM.darkened(0.5))
		for k: int in 4:
			var u := 0.25 + k * 0.14
			_base.line(_on_face(a, b, u, 96.0), _on_face(a, b, u + 0.08, 104.0), Palette.BOATHOUSE_SHADE, 2.0)


## The Harbor Bridge's severed end: board-marked concrete, its rebar bent out where the deck tore away.
func _bridge_face(a: Vector2, b: Vector2, h: float) -> void:
	for k: int in 5:
		var v := 36.0 + k * 40.0
		_base.line(_on_face(a, b, 0.0, v), _on_face(a, b, 1.0, v), Color(Palette.NEAR_BLACK, 0.14), 1.0)
	for k: int in 4:
		var u := 0.15 + k * 0.22
		var foot := _on_face(a, b, u, h - PARAPET)
		_base.line(foot, foot + Vector2(-6 + k * 4, -26), Palette.RUST, 2.5)


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
