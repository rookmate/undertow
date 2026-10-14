class_name StaticProp
extends Node2D
## Painted scenery: the canal railing, low walls, stack
## shelves, a Feed kiosk, a stalled tram segment and bollards; in Kestrel Heights, trimmed hedges, stone
## planters of white blossom, and lawn sprinklers that still come on; in Mercy General, glass ward
## partitions cut away to waist height, and ambulances parked nose to tail; in the Vellum's newsroom,
## desks with their dead screens; in Harbor Ward, the Wardfolk's lanterns and the pilings; in the Spire,
## its server racks and its glass panes.

enum Kind { RAILING, LOW_WALL, SHELF, KIOSK, TRAM, BOLLARD, HEDGE, PLANTER, SPRINKLER, BED, CARRIAGE_SIDE, DESK, CONTAINER, PARTITION, AMBULANCE, NURSE_DESK, HOSPITAL_BED, TURBINE, NEWS_DESK, LANTERN, PILING, RACK, PANE }
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
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
	if kind == Kind.RAILING:
		_railing()
		return
	if kind in [Kind.TRAM, Kind.AMBULANCE, Kind.CARRIAGE_SIDE]:
		_vehicle()
		return
	ArtCatalog.paint(self, ArtBindings.PROP[kind], ArtBindings.PROP_RECT[kind])
	match kind:
		Kind.KIOSK, Kind.DESK, Kind.NEWS_DESK:
			_screen_afterimage()
		Kind.SPRINKLER:
			_sprinkler_spray()
		Kind.TURBINE:
			draw_set_transform(Vector2(0, -110), _t * 1.6)
			ArtCatalog.paint(self, "turbine_blades", Rect2(-48, -48, 96, 96))
			draw_set_transform(Vector2.ZERO)
		Kind.NURSE_DESK:
			draw_circle(Vector2(20, -60), 5.0, Palette.HUMAN_CREAM, true, -1.0, true)
		Kind.LANTERN:
			draw_rect(Rect2(10, -90, 10, 15), Palette.WARD_CYAN_HOT)
		Kind.PANE:
			var ring := RingPainter.Look.new()
			ring.thin = true
			ring.color = Palette.GREY_COLD
			ring.alpha = 0.3
			ring.show_center = false
			ring.halo = 0.0
			RingPainter.paint(self, Vector2(0, -82), 18.0, ring)


func _screen_afterimage() -> void:
	var key: String = ArtBindings.PROP[kind]
	var bounds: Rect2 = ArtBindings.PROP_RECT[kind]
	var tl := ArtCatalog.anchor(key, "screen_tl", bounds)
	var across := ArtCatalog.anchor(key, "screen_tr", bounds) - tl
	var down := ArtCatalog.anchor(key, "screen_bl", bounds) - tl
	# Project the canonical ring into the painted monitor's plane.
	draw_set_transform_matrix(Transform2D(across / 100.0, down / 100.0, tl + (across + down) * 0.5))
	var ring := RingPainter.Look.new()
	ring.thin = true
	ring.color = Palette.GREY_COLD
	ring.alpha = 0.45
	ring.show_center = false
	ring.halo = 0.0
	RingPainter.paint(self, Vector2.ZERO, 30.0, ring)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _vehicle() -> void:
	var h := 66.0 if kind == Kind.AMBULANCE else (30.0 if kind == Kind.CARRIAGE_SIDE else 104.0)
	var side_key := "ambulance_side" if kind == Kind.AMBULANCE else "tram_side"
	var roof_key := "ambulance_roof" if kind == Kind.AMBULANCE else "tram_roof"
	var left := Vector2(-Iso.HALF_W, 0)
	var right := Vector2(Iso.HALF_W, 0)
	var front := Vector2(0, Iso.HALF_H)
	var back := Vector2(0, -Iso.HALF_H)
	var up := Vector2(0, -h)
	if not joined_left:
		ArtCatalog.mapped(self, side_key, PackedVector2Array([left + up, front + up, front, left]))
	if not joined_right:
		ArtCatalog.mapped(self, side_key, PackedVector2Array([front + up, right + up, right, front]))
	ArtCatalog.mapped(self, roof_key, PackedVector2Array([back + up, right + up, front + up, left + up]))


func _sprinkler_spray() -> void:
	var on := fmod(_t, SPRAY_PERIOD) < 3.0
	if not on:
		return
	for k: int in 7:
		var a := _t * 1.8 + TAU * k / 7.0
		var to := Vector2(cos(a) * 46.0, sin(a) * 22.0 - 10.0)
		draw_line(Vector2(0, -10), to, Color(Palette.WATER_SHEEN, 0.5), 1.0, true)


func _railing() -> void:
	var rail_h := 44.0
	var dirs: Array[Vector2i] = rail_dirs
	if dirs.is_empty():
		dirs = [Vector2i(0, -1), Vector2i(0, 1)]
	for d: Vector2i in dirs:
		var end := Iso.grid_to_world(Vector2(d) * 0.5)
		var up := Vector2(0, -rail_h)
		ArtCatalog.mapped(self, "kestrel_railing", PackedVector2Array([up, end + up, end, Vector2.ZERO]))
