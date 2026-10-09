class_name StaticProp
extends Node2D
## Placeholder props drawn as small isometric prisms and shapes: the canal railing, low walls, stack
## shelves, a Feed kiosk, a stalled tram segment and bollards; in Kestrel Heights, trimmed hedges, stone
## planters of white blossom, and lawn sprinklers that still come on.

enum Kind { RAILING, LOW_WALL, SHELF, KIOSK, TRAM, BOLLARD, HEDGE, PLANTER, SPRINKLER, BED, CARRIAGE_SIDE, DESK }

const SPRAY_PERIOD := 6.0

var kind: Kind = Kind.RAILING
var cell: Vector2i
## For multi-cell props (the tram), which neighbours are part of the same prop.
var joined_left: bool = false
var joined_right: bool = false
## For railings: grid directions of neighbouring railing cells (the rail runs toward each).
var rail_dirs: Array[Vector2i] = []
var look: DistrictLook = DistrictLook.new()
var _t: float = 0.0


func setup(at: Vector2i, prop_kind: Kind, district_look: DistrictLook = null) -> void:
	cell = at
	kind = prop_kind
	if district_look != null:
		look = district_look
	position = Iso.cell_center(at)
	# Sprinklers are the only props that move: they still come on, for nobody.
	set_process(kind == Kind.SPRINKLER)
	_t = float(hash(at) % 600) / 100.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.RAILING:
			_railing()
		Kind.LOW_WALL:
			_prism(26.0, Palette.STONE_OLD, Palette.STONE_OLD.darkened(0.3), Palette.STONE_OLD.lightened(0.08), 1.0)
		Kind.SHELF:
			_prism(118.0, Palette.IRON_DARK, Palette.IRON_DARK.darkened(0.3), Palette.IRON_DARK.lightened(0.1), 0.62)
			_shelf_bales()
		Kind.KIOSK:
			_kiosk()
		Kind.TRAM:
			_tram()
		Kind.BOLLARD:
			draw_rect(Rect2(-6, -34, 12, 34), Palette.IRON_DARK)
			draw_circle(Vector2(0, -34), 6.0, Palette.IRON_DARK, true, -1.0, true)
		Kind.HEDGE:
			_prism(34.0, look.hedge, look.hedge.darkened(0.3), look.hedge.lightened(0.1), 0.94)
		Kind.PLANTER:
			_planter()
		Kind.SPRINKLER:
			_sprinkler()
		Kind.BED:
			_bed()
		Kind.CARRIAGE_SIDE:
			# Cut away to the window line so the carriage's inside (and who sits in it) shows.
			_prism(30.0, look.wall, look.wall_shade, look.wall_top, 1.0)
			draw_line(Vector2(-Iso.HALF_W, -30), Vector2(0, Iso.HALF_H - 30), Color(Palette.BLACK_MIRROR, 0.8), 3.0)
		Kind.DESK:
			_prism(36.0, Palette.IRON_DARK.lightened(0.15), Palette.IRON_DARK, Palette.GREY_DEEP, 0.7)
			# The manual override: welded over at installation.
			draw_line(Vector2(-14, -40), Vector2(10, -46), Palette.GREY_COLD, 4.0, true)


## A stone urn of white blossom.
func _planter() -> void:
	_prism(30.0, look.wall, look.wall_shade, look.wall.lightened(0.1), 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell)
	draw_circle(Vector2(0, -42), 22.0, look.hedge, true, -1.0, true)
	for k: int in 14:
		var p := Vector2(rng.randf_range(-20, 20), rng.randf_range(-58, -30))
		draw_circle(p, rng.randf_range(2.5, 4.5), look.blossom, true, -1.0, true)


## A child's bed, unmade, and the nightlight still on beside it.
func _bed() -> void:
	_prism(22.0, look.timber.lightened(0.1), look.timber.darkened(0.2), look.blossom.darkened(0.1), 0.8)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -26), Vector2(4, -10), Vector2(24, -20), Vector2(-10, -36)]), Palette.STAINED_TEAL.lightened(0.2))
	draw_circle(Vector2(36, -30), 7.0, Color(Palette.HUMAN_CREAM, 0.95), true, -1.0, true)


## A pop-up sprinkler on the lawn: for half of every few seconds it fans water over the grass.
func _sprinkler() -> void:
	draw_rect(Rect2(-3, -8, 6, 8), Palette.IRON_DARK)
	var phase := fmod(_t, SPRAY_PERIOD) / SPRAY_PERIOD
	if phase > 0.5:
		return
	var sweep := sin(phase * TAU * 2.0) * 0.9
	for k: int in 9:
		var a := -PI * 0.5 + sweep + (k - 4) * 0.12
		var reach := 46.0 + (k % 3) * 8.0
		var tip := Vector2(cos(a) * reach, sin(a) * reach * 0.6 - 10.0)
		draw_line(Vector2(0, -8), tip, Color(look.ground_wet.lightened(0.4), 0.35), 1.5, true)


## Prism with a footprint shrunk by `scale_fp` around the cell centre.
func _prism(h: float, right_col: Color, left_col: Color, top_col: Color, scale_fp: float) -> void:
	var hw := Iso.HALF_W * scale_fp
	var hh := Iso.HALF_H * scale_fp
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var up := Vector2(0, -h)
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + up, left + up]), left_col)
	draw_colored_polygon(PackedVector2Array([bottom, right, right + up, bottom + up]), right_col)
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), top_col)


func _railing() -> void:
	var rail_h := 44.0
	var dirs: Array[Vector2i] = rail_dirs
	if dirs.is_empty():
		dirs = [Vector2i(0, -1), Vector2i(0, 1)]
	for d: Vector2i in dirs:
		var end := Iso.grid_to_world(Vector2(d) * 0.5)
		draw_line(Vector2(0, -rail_h), end + Vector2(0, -rail_h), Palette.IRON_DARK, 4.0, true)
		draw_line(Vector2(0, -rail_h * 0.55), end + Vector2(0, -rail_h * 0.55), Palette.IRON_VERDIGRIS, 2.0, true)
		var mid := end * 0.5
		draw_line(mid, mid + Vector2(0, -rail_h), Palette.IRON_DARK, 3.0, true)
		draw_line(end, end + Vector2(0, -rail_h), Palette.IRON_DARK, 3.0, true)
	draw_line(Vector2.ZERO, Vector2(0, -rail_h), Palette.IRON_DARK, 3.0, true)
	draw_circle(Vector2(0, -rail_h - 4.0), 5.0, Palette.IRON_DARK, true, -1.0, true)


func _shelf_bales() -> void:
	for k: int in 4:
		var v := 22.0 + k * 24.0
		draw_line(Vector2(-Iso.HALF_W * 0.62, -v), Vector2(0, Iso.HALF_H * 0.62 - v), Color(Palette.PAPER, 0.55), 5.0)
		draw_line(Vector2(0, Iso.HALF_H * 0.62 - v), Vector2(Iso.HALF_W * 0.62, -v), Color(Palette.PAPER, 0.4), 5.0)


func _kiosk() -> void:
	_prism(96.0, Palette.IRON_VERDIGRIS.darkened(0.3), Palette.IRON_DARK, Palette.IRON_VERDIGRIS.darkened(0.1), 0.7)
	# A dead Feed screen with the ring's afterimage burned into it.
	var hw := Iso.HALF_W * 0.7
	var hh := Iso.HALF_H * 0.7
	var screen := PackedVector2Array([Vector2(hw * 0.15, hh * 0.85 - 30.0), Vector2(hw * 0.85, hh * 0.15 - 30.0), Vector2(hw * 0.85, hh * 0.15 - 80.0), Vector2(hw * 0.15, hh * 0.85 - 80.0)])
	draw_colored_polygon(screen, Palette.BLACK_MIRROR)
	# The canonical ring, faint and grey: an afterimage on a dead screen.
	var ring := RingPainter.Look.new()
	ring.thin = true
	ring.color = Palette.GREY_COLD
	ring.alpha = 0.45
	ring.show_center = false
	ring.halo = 0.0
	RingPainter.paint(self, (screen[0] + screen[2]) * 0.5, 11.0, ring)
	# Awning in old-city magenta.
	draw_colored_polygon(PackedVector2Array([Vector2(-hw - 6, -100), Vector2(0, hh - 100 + 6), Vector2(hw + 6, -100), Vector2(0, -hh - 100 - 6)]), Palette.NEON_MAGENTA.darkened(0.55))


func _tram() -> void:
	var h := 104.0
	var body := Palette.IRON_VERDIGRIS.darkened(0.45)
	var hw := Iso.HALF_W
	var hh := Iso.HALF_H
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var top := Vector2(0, -hh)
	var up := Vector2(0, -h)
	var base := Vector2(0, -8)
	if not joined_left:
		draw_colored_polygon(PackedVector2Array([left + base, bottom + base, bottom + up, left + up]), body.darkened(0.3))
	if not joined_right:
		draw_colored_polygon(PackedVector2Array([bottom + base, right + base, right + up, bottom + up]), body)
		for k: int in 2:
			var u0 := 0.15 + k * 0.45
			var win := PackedVector2Array([bottom.lerp(right, u0) + Vector2(0, -50), bottom.lerp(right, u0 + 0.3) + Vector2(0, -50), bottom.lerp(right, u0 + 0.3) + Vector2(0, -88), bottom.lerp(right, u0) + Vector2(0, -88)])
			draw_colored_polygon(win, Color(Palette.HUMAN_CREAM, 0.12))
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), body.lightened(0.08))
