class_name BuildingCell
extends Node2D
## One cell of a building, drawn as an isometric prism and depth-sorted with everything else. Faces
## hidden by a neighbouring building cell are skipped. Old Meridian brick and stained glass with lit
## windows (human warmth), old-city neon, and the Steward's gilt threaded along the balcony ironwork,
## which dies when the voice is muted.

enum Facade { PLAIN, DOOR, NEON_MAGENTA, NEON_LIME, ARCHIVE, LAUNDRY, SIGNAL_ROOM, WORKSHOP, HOSPITAL, HOSPITAL_DOOR, CLINIC, PUMPING_STATION, PUMPING_STATION_DOOR, PUMPHOUSE, BOATHOUSE, BOATHOUSE_DOOR, BRIDGE_STUB, COMMONS }

const STORY := 74.0
const STORIES := 3
const PARAPET := 16.0

var cell: Vector2i
var facade: Facade = Facade.PLAIN
## A mast on this roof: Noor's on the Commons once she's home (lit, the Ward's cyan), or the Ward's own on
## a boat-house by the border (`mast_dark`: unpowered since the Quiet).
var roof_mast: bool = false
var mast_dark: bool = false
var show_left: bool = true
var show_right: bool = true
var gilt_lit: bool = true:
	set(value):
		gilt_lit = value
		if _gilt_emissive != null:
			_gilt_emissive.set_layer_enabled(0, value)

var _base := DrawOps.new()
var _glow := DrawOps.new()
var _gilt := DrawOps.new()
var _ornaments := DrawOps.new()
var look: DistrictLook = DistrictLook.for_district("vellum")
var _gilt_emissive: Emissive


func setup(at: Vector2i, kind: Facade, left_open: bool, right_open: bool, district_look: DistrictLook = null) -> void:
	cell = at
	if district_look != null:
		look = district_look
	facade = kind
	show_left = left_open
	show_right = right_open
	position = Iso.cell_center(at)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_to_group(&"gilt")
	_build()
	var window_light := Emissive.new()
	window_light.layers = [_glow]
	add_child(window_light)
	if not _ornaments.is_empty():
		_ornaments.add_layer(self, &"PaintedFacade")
	# Gold sits above the painted ironwork; only this last layer follows the voice toggle.
	_gilt_emissive = Emissive.new()
	_gilt_emissive.layers = [_gilt]
	_gilt_emissive.set_layer_enabled(0, gilt_lit)
	add_child(_gilt_emissive)
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
		_wall_material(PackedVector2Array([left, bottom, bottom + up, left + up]), look.wall_shade, true)
		_face(left, bottom, h, false)
	if show_right:
		_wall_material(PackedVector2Array([bottom, right, right + up, bottom + up]), look.wall, false)
		_face(bottom, right, h, true)
	var roof := PackedVector2Array([top + up, right + up, bottom + up, left + up])
	_base.textured_poly(roof, PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]), look.roof_texture)
	if facade == Facade.SIGNAL_ROOM and show_left and show_right:
		var foot := up + Vector2(0, -4)
		_base.sprite("relay_mast", Rect2(foot + Vector2(-12, -90), Vector2(24, 90)))
		for k: int in 3:
			_glow.circle(foot + Vector2(0, -40 - k * 22), 4.0, Palette.HUMAN_CREAM)
	if roof_mast and show_left and show_right:
		var foot := up + Vector2(0, -4)
		_base.sprite("relay_mast", Rect2(foot + Vector2(-22, -176), Vector2(44, 176)))
		if not mast_dark:
			_glow.circle(foot + Vector2(0, -170), 5.0, Palette.WARD_CYAN)


func _wall_material(points: PackedVector2Array, _tone: Color, shaded: bool) -> void:
	# Atlas materials repeat inside their crop, never into a neighbouring atlas panel.
	var tint := Color.WHITE.darkened(0.24) if shaded else Color.WHITE
	var h := height()
	var base_a := points[0]
	var base_b := points[1]
	var y := 0.0
	while y < h:
		var end := minf(y + Iso.HALF_W, h)
		var strip := PackedVector2Array([base_a + Vector2(0, -y), base_b + Vector2(0, -y), base_b + Vector2(0, -end), base_a + Vector2(0, -end)])
		_base.textured_poly(strip, PackedVector2Array([Vector2.DOWN, Vector2.ONE, Vector2(1, 1 - (end - y) / Iso.HALF_W), Vector2(0, 1 - (end - y) / Iso.HALF_W)]), look.wall_texture, tint)
		y = end


## Point on a face: `a`→`b` is the face's bottom edge, u runs along it (0..1), v is height in px.
static func _on_face(a: Vector2, b: Vector2, u: float, v: float) -> Vector2:
	return a.lerp(b, u) + Vector2(0, -v)


func _face_ornament(a: Vector2, b: Vector2, bounds: Rect2, texture: Texture2D) -> void:
	var points := PackedVector2Array([
		_on_face(a, b, bounds.position.x, bounds.position.y),
		_on_face(a, b, bounds.end.x, bounds.position.y),
		_on_face(a, b, bounds.end.x, bounds.end.y),
		_on_face(a, b, bounds.position.x, bounds.end.y),
	])
	_ornaments.textured_poly(points, PackedVector2Array([Vector2.DOWN, Vector2.ONE, Vector2.RIGHT, Vector2.ZERO]), texture)


func _module(a: Vector2, b: Vector2, bounds: Rect2, key: String) -> void:
	_face_ornament(a, b, bounds, ArtCatalog.texture(key))


func _face(a: Vector2, b: Vector2, h: float, street_side: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cell.x, cell.y, 1 if street_side else 2))
	if look.black_glass:
		_module(a, b, Rect2(0.02, 4, 0.96, h - 12), "glass_frame")
		if rng.randf() < 0.25:
			var c := _on_face(a, b, 0.5, h * 0.55)
			var arc := PackedVector2Array()
			for i: int in 25:
				var t := deg_to_rad(-30.0 + 300.0 * i / 24.0)
				arc.append(c + Vector2(sin(t), -cos(t)) * 22.0)
			_base.polyline(arc, Color(Palette.GREY_COLD, 0.25), 2.0)
		return
	if facade == Facade.BRIDGE_STUB:
		_module(a, b, Rect2(0.04, h - 28, 0.92, 55), "bridge_rebar")
		return
	if facade in [Facade.HOSPITAL, Facade.HOSPITAL_DOOR]:
		if street_side and facade == Facade.HOSPITAL_DOOR:
			_module(a, b, Rect2(0.15, 0, 0.7, 90), "ward_seal")
		else:
			_module(a, b, Rect2(0.16, 66, 0.68, 70), "hospital_frame")
		if street_side and (cell.x + cell.y) % 3 == 0:
			_gilt.circle(_on_face(a, b, 0.5, h - PARAPET - 10), 5.0, Palette.STEWARD_GOLD_HOT)
		return
	if facade in [Facade.PUMPING_STATION, Facade.PUMPING_STATION_DOOR]:
		_module(a, b, Rect2(0.14, h - 86, 0.5, 54), "louvre")
		_module(a, b, Rect2(0.72, 0, 0.18, h - PARAPET), "pipe")
		if street_side and facade == Facade.PUMPING_STATION_DOOR:
			_module(a, b, Rect2(0.12, 0, 0.52, 72), "tool_door")
		if street_side and (cell.x + cell.y) % 2 == 0:
			_gilt.line(_on_face(a, b, 0.2, h - PARAPET - 26), _on_face(a, b, 0.6, h - PARAPET - 26), Palette.STEWARD_GOLD, 1.5)
		return
	for story: int in STORIES:
		var base := story * STORY
		if story == 0 and street_side and facade in [Facade.DOOR, Facade.BOATHOUSE_DOOR]:
			_door(a, b)
			continue
		if story == 0 and street_side and facade == Facade.WORKSHOP:
			_module(a, b, Rect2(0.12, 0, 0.76, 68), "shutter")
			_glow.line(_on_face(a, b, 0.18, 3), _on_face(a, b, 0.82, 3), Color(Palette.HUMAN_CREAM, 0.7), 2.0)
			continue
		var staffed := facade in [Facade.ARCHIVE, Facade.SIGNAL_ROOM, Facade.WORKSHOP, Facade.CLINIC, Facade.PUMPHOUSE, Facade.COMMONS]
		_window(a, b, base, staffed or rng.randf() < (0.42 if street_side else 0.22), rng)
		if story == 1 and facade not in [Facade.BOATHOUSE, Facade.BOATHOUSE_DOOR]:
			_balcony(a, b, base)
		if facade == Facade.LAUNDRY and street_side and story >= 1:
			_module(a, b, Rect2(0.05, base + 28, 0.90, 43), "laundry")
		if facade == Facade.ARCHIVE and street_side and story == 1:
			_module(a, b, Rect2(0.3, base + 12, 0.4, 38), "rose")
		if facade == Facade.PUMPHOUSE and street_side and story == 0:
			_module(a, b, Rect2(0.80, 0, 0.16, STORY * STORIES), "pipe")
		if facade == Facade.CLINIC and street_side and story == 2:
			var c := _on_face(a, b, 0.5, base + STORY * 0.5)
			_glow.line(c + Vector2(0, -14), c + Vector2(0, 14), Palette.HUMAN_CREAM, 6.0)
			_glow.line(c + Vector2(-14, 0), c + Vector2(14, 0), Palette.HUMAN_CREAM, 6.0)
		if facade == Facade.COMMONS and street_side and story == 2:
			for k: int in 5:
				var u := 0.1 + k * 0.2
				_glow.circle(_on_face(a, b, u, base + STORY * 0.8 - absf(sin(u * PI)) * 10), 3.0, Palette.WARD_CYAN)
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
		_base.poly(pane, Palette.BLACK_MIRROR)
		_glow.poly(pane, Color(Palette.WARD_CYAN if facade in [Facade.BOATHOUSE, Facade.BOATHOUSE_DOOR] else Palette.HUMAN_CREAM, 0.55))
		_glow.poly(transom, Color(stain.lightened(0.25), 0.9))
	else:
		_base.poly(pane, Palette.BLACK_MIRROR)
		_base.poly(transom, Color(stain, 0.5))
	_face_ornament(a, b, Rect2(0.24, base + 6.0, 0.52, 66.0), look.window_texture)


func _balcony(a: Vector2, b: Vector2, base: float) -> void:
	var v := base + 8.0
	_face_ornament(a, b, Rect2(0.16, base + 5.0, 0.68, 19.0), look.balcony_texture)
	# The gilt: ten years of the Steward laid over the ironwork, a gold vein along the rail.
	_gilt.line(_on_face(a, b, 0.18, v + 16.0), _on_face(a, b, 0.82, v + 16.0), Palette.STEWARD_GOLD_HOT, 1.5)


func _door(a: Vector2, b: Vector2) -> void:
	var door := PackedVector2Array([_on_face(a, b, 0.32, 0), _on_face(a, b, 0.68, 0), _on_face(a, b, 0.68, 62), _on_face(a, b, 0.32, 62)])
	_base.poly(door, Palette.BLACK_MIRROR)
	_glow.poly(door, Color(Palette.WARD_CYAN if facade == Facade.BOATHOUSE_DOOR else Palette.HUMAN_CREAM, 0.45))
	_face_ornament(a, b, Rect2(0.2, 0, 0.6, 72), look.door_texture)


func _neon(a: Vector2, b: Vector2) -> void:
	var col := neon_color()
	var hot := Color(col.r * 1.7, col.g * 1.7, col.b * 1.7)
	var plate := PackedVector2Array([_on_face(a, b, 0.78, 96.0), _on_face(a, b, 0.92, 96.0), _on_face(a, b, 0.92, 196.0), _on_face(a, b, 0.78, 196.0)])
	_module(a, b, Rect2(0.76, 94, 0.18, 104), "pane")
	_glow.polyline(PackedVector2Array([plate[0], plate[1], plate[2], plate[3], plate[0]]), hot, 2.5)
	var squiggle := PackedVector2Array()
	for k: int in 12:
		var t := k / 11.0
		squiggle.append(_on_face(a, b, 0.85 + sin(t * TAU * 1.5) * 0.035, lerpf(110.0, 182.0, t)))
	_glow.polyline(squiggle, hot, 3.0)
