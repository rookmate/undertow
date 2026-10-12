class_name StaticProp
extends Node2D
## Placeholder props drawn as small isometric prisms and shapes: the canal railing, low walls, stack
## shelves, a Feed kiosk, a stalled tram segment and bollards; in Kestrel Heights, trimmed hedges, stone
## planters of white blossom, and lawn sprinklers that still come on; in Mercy General, glass ward
## partitions cut away to waist height, and ambulances parked nose to tail; in the Vellum's newsroom,
## desks with their dead screens; in Harbor Ward, the Wardfolk's lanterns and the pilings.

enum Kind { RAILING, LOW_WALL, SHELF, KIOSK, TRAM, BOLLARD, HEDGE, PLANTER, SPRINKLER, BED, CARRIAGE_SIDE, DESK, CONTAINER, PARTITION, AMBULANCE, NURSE_DESK, HOSPITAL_BED, TURBINE, NEWS_DESK, LANTERN, PILING }
## Props that move (and so redraw every frame); every other kind is drawn once.
const MOVING: Array[Kind] = [Kind.SPRINKLER, Kind.TURBINE]

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
	_t = float(hash(at) % 600) / 100.0


func _ready() -> void:
	# Sprinklers are the only props that move: they still come on, for nobody. (This has to wait for
	# _ready: Godot switches processing on for any script with a _process when it enters the tree, so
	# switching it off in setup() did nothing and every prop redrew itself every frame.)
	set_process(MOVING.has(kind))


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
		Kind.CONTAINER:
			_container()
		Kind.DESK:
			_prism(36.0, Palette.IRON_DARK.lightened(0.15), Palette.IRON_DARK, Palette.GREY_DEEP, 0.7)
			# The manual override: welded over at installation.
			draw_line(Vector2(-14, -40), Vector2(10, -46), Palette.GREY_COLD, 4.0, true)
		Kind.PARTITION:
			_partition()
		Kind.AMBULANCE:
			_ambulance()
		Kind.NURSE_DESK:
			_nurse_desk()
		Kind.HOSPITAL_BED:
			_hospital_bed()
		Kind.TURBINE:
			_turbine()
		Kind.NEWS_DESK:
			_news_desk()
		Kind.LANTERN:
			_lantern()
		Kind.PILING:
			_piling()


## A Wardfolk lantern: a pole with a hand-wired cyan lamp, a cable sagging off to the next one.
func _lantern() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -96), Palette.IRON_DARK, 4.0)
	draw_line(Vector2(0, -96), Vector2(14, -92), Palette.IRON_DARK, 3.0)
	draw_rect(Rect2(8, -92, 14, 20), Palette.IRON_DARK)
	draw_rect(Rect2(10, -90, 10, 15), Palette.WARD_CYAN_HOT)
	draw_line(Vector2(0, -90), Vector2(-40, -70), Color(Palette.NEAR_BLACK, 0.7), 1.5, true)


## A piling in the water: a tarred post, kelp hanging off it at the tide line.
func _piling() -> void:
	draw_rect(Rect2(-7, -46, 14, 52), Palette.BOATHOUSE_SHADE)
	draw_rect(Rect2(-7, -46, 14, 4), Palette.BOATHOUSE)
	for k: int in 3:
		draw_line(Vector2(-6 + k * 6, -14), Vector2(-8 + k * 6, 4), Palette.KELP, 3.0, true)


## A newsroom desk: a black screen with the Feed's ring burned into it, and a tube carrier left on top.
func _news_desk() -> void:
	_prism(28.0, Palette.NEWS_DESK, Palette.NEWS_DESK.darkened(0.3), Palette.NEWS_DESK.lightened(0.12), 0.78)
	var screen := PackedVector2Array([Vector2(-20, -40), Vector2(8, -26), Vector2(8, -58), Vector2(-20, -72)])
	draw_colored_polygon(screen, Palette.BLACK_MIRROR)
	draw_line(Vector2(-6, -33), Vector2(-6, -28), Palette.IRON_DARK, 3.0)
	var ring := PackedVector2Array()
	for k: int in 25:
		var a := TAU * k / 24.0
		ring.append(Vector2(-6 + cos(a) * 7.0, -49 + sin(a) * 9.0 + cos(a) * 3.5))
	draw_polyline(ring, Palette.SCREEN_BURN, 2.0, true)
	draw_line(Vector2(14, -32), Vector2(26, -26), Palette.IRON_VERDIGRIS, 5.0, true)


## A tidal turbine in the channel, still turning on the current: a pylon and three blades.
func _turbine() -> void:
	draw_rect(Rect2(-6, -110, 12, 110), Palette.PUMP_CONCRETE_SHADE)
	var hub := Vector2(0, -110)
	for k: int in 3:
		var a := _t * 1.6 + TAU * k / 3.0
		draw_line(hub, hub + Vector2(cos(a) * 48.0, sin(a) * 48.0), Palette.PUMP_CONCRETE, 7.0, true)
	draw_circle(hub, 9.0, Palette.IRON_DARK, true, -1.0, true)


## A ward bed: a white frame with its rails up, a grey blanket, the pillow.
func _hospital_bed() -> void:
	_prism(20.0, Palette.AMBULANCE_WHITE.darkened(0.3), Palette.AMBULANCE_WHITE.darkened(0.45), Palette.WARD_GLASS.darkened(0.45), 0.8)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -24), Vector2(-6, -12), Vector2(10, -20), Vector2(-14, -32)]), Palette.AMBULANCE_WHITE.darkened(0.1))
	for x: float in [-38.0, 38.0]:
		draw_line(Vector2(x, -18), Vector2(x * 0.3, -18 + absf(x) * 0.28), Palette.WARD_WALL_SHADE, 2.0, true)


## A ward's glass partition, cut away at waist height: a painted lower panel, then the glass.
func _partition() -> void:
	_prism(30.0, look.wall_shade, look.wall_shade.darkened(0.25), look.wall_top, 0.9)
	var hw := Iso.HALF_W * 0.9
	var hh := Iso.HALF_H * 0.9
	var pane := PackedVector2Array([Vector2(-hw, -30), Vector2(0, hh - 30), Vector2(hw, -30), Vector2(hw, -64), Vector2(0, hh - 64), Vector2(-hw, -64)])
	draw_colored_polygon(pane, Color(look.glass, 0.16))
	draw_polyline(PackedVector2Array([Vector2(-hw, -64), Vector2(0, hh - 64), Vector2(hw, -64)]), Color(look.glass, 0.45), 1.5, true)


## The night nurses' desk: paper everywhere, and the desk lamp they brought from home still on.
func _nurse_desk() -> void:
	_prism(34.0, look.staff_floor.lightened(0.15), look.staff_floor.darkened(0.15), look.staff_floor.lightened(0.3), 0.75)
	for k: int in 4:
		var p := Vector2(-18 + k * 11, -38 - (k % 2) * 4)
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(10, 5), p + Vector2(20, 0), p + Vector2(10, -5)]), Color(Palette.PAPER, 0.85))
	draw_line(Vector2(16, -36), Vector2(20, -60), Palette.IRON_DARK, 2.0, true)
	draw_circle(Vector2(22, -62), 6.0, Palette.HUMAN_CREAM, true, -1.0, true)


## An ambulance parked nose to tail in the yard, its light bar dark.
func _ambulance() -> void:
	var h := 66.0
	var body := Palette.AMBULANCE_WHITE.darkened(0.25)
	var hw := Iso.HALF_W
	var hh := Iso.HALF_H
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var top := Vector2(0, -hh)
	var up := Vector2(0, -h)
	var base := Vector2(0, -10)
	if not joined_left:
		draw_colored_polygon(PackedVector2Array([left + base, bottom + base, bottom + up, left + up]), body.darkened(0.3))
	if not joined_right:
		draw_colored_polygon(PackedVector2Array([bottom + base, right + base, right + up, bottom + up]), body)
		# A stripe along the side, and the back doors' dark windows.
		draw_line(bottom + Vector2(0, -34), right + Vector2(0, -34), Palette.WARD_GLASS.darkened(0.3), 5.0, true)
		draw_colored_polygon(PackedVector2Array([bottom.lerp(right, 0.2) + Vector2(0, -42), bottom.lerp(right, 0.5) + Vector2(0, -42), bottom.lerp(right, 0.5) + Vector2(0, -58), bottom.lerp(right, 0.2) + Vector2(0, -58)]), Palette.BLACK_MIRROR)
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), body.lightened(0.06))
	draw_rect(Rect2(-10, -h - 6, 20, 6), Palette.GREY_DEEP)


## A stone urn of white blossom.
func _planter() -> void:
	_prism(30.0, look.wall, look.wall_shade, look.wall.lightened(0.1), 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell)
	draw_circle(Vector2(0, -42), 22.0, look.hedge, true, -1.0, true)
	for k: int in 14:
		var p := Vector2(rng.randf_range(-20, 20), rng.randf_range(-58, -30))
		draw_circle(p, rng.randf_range(2.5, 4.5), look.blossom, true, -1.0, true)


## A stack of shipping containers, rust through the paint: the walls of the Tideworks' canyons.
func _container() -> void:
	var shades: Array[Color] = [Palette.CONTAINER_TEAL, Palette.CONTAINER_RED, Palette.CONTAINER_GREY, Palette.RUST]
	var c := shades[absi(hash(cell)) % shades.size()]
	_prism(58.0, c, c.darkened(0.3), c.lightened(0.1), 0.98)
	for k: int in 5:
		var u := (k + 0.5) / 5.0
		var foot := Vector2(0, Iso.HALF_H * 0.98).lerp(Vector2(Iso.HALF_W * 0.98, 0), u)
		draw_line(foot, foot + Vector2(0, -58), Color(Palette.NEAR_BLACK, 0.22), 1.5)


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
