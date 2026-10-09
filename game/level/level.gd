class_name Level
extends Node2D
## Builds a playable level from a text map (data/levels/*.txt): floor, depth-sorted buildings and
## props, Lattice lamps, collision, the Operator and the camera. Placeholder shapes in the brief's
## palette at image 10's camera angle and scale.

signal player_spawned(player: Operator)

@export var level_id: String = "vellum"
@export_file("*.txt") var map_path: String = "res://data/levels/vellum_street.txt"

var grid: LevelGrid
var world: Node2D
var player: Operator
var camera: Camera2D

var _ambient: CanvasModulate


func _ready() -> void:
	grid = LevelGrid.load_file(map_path)
	_add_backdrop()
	var floor_layer := FloorLayer.new()
	floor_layer.name = "Floor"
	add_child(floor_layer)
	floor_layer.setup(grid)
	var reflections := WetReflections.new()
	reflections.name = "WetReflections"
	add_child(reflections)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	_build_cells()
	_build_collision()
	_spawn_player()
	_add_atmosphere()
	add_child(PauseMenu.new())
	add_child(LevelHints.new())
	GameState.set_location("level:" + level_id)
	GameState.save()


func _process(delta: float) -> void:
	if not get_tree().paused:
		GameState.add_play_time(delta)


# --- Construction ----------------------------------------------------------------------------------
func _build_cells() -> void:
	for cell: Vector2i in grid.all_cells():
		var ch := grid.char_at(cell)
		if grid.is_building(cell):
			var b := BuildingCell.new()
			var facade := BuildingCell.Facade.PLAIN
			match ch:
				"d":
					facade = BuildingCell.Facade.DOOR
				"m":
					facade = BuildingCell.Facade.NEON_MAGENTA
				"g":
					facade = BuildingCell.Facade.NEON_LIME
			b.setup(cell, facade, not grid.is_building(cell + Vector2i(0, 1)), not grid.is_building(cell + Vector2i(1, 0)))
			world.add_child(b)
			continue
		match ch:
			"L":
				var lamp := LampPost.new()
				lamp.setup(cell)
				world.add_child(lamp)
			"=":
				var rail := _prop(cell, StaticProp.Kind.RAILING)
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if grid.char_at(cell + d) == "=":
						rail.rail_dirs.append(d)
			"-":
				_prop(cell, StaticProp.Kind.LOW_WALL)
			"|":
				_prop(cell, StaticProp.Kind.SHELF)
			"K":
				_prop(cell, StaticProp.Kind.KIOSK)
			"o":
				_prop(cell, StaticProp.Kind.BOLLARD)
			"R":
				_prop(cell, StaticProp.Kind.RELIQUARY)
			"t":
				var tram := _prop(cell, StaticProp.Kind.TRAM)
				tram.joined_left = grid.char_at(cell + Vector2i(0, 1)) == "t"
				tram.joined_right = grid.char_at(cell + Vector2i(1, 0)) == "t"


func _prop(cell: Vector2i, kind: StaticProp.Kind) -> StaticProp:
	var p := StaticProp.new()
	p.setup(cell, kind)
	world.add_child(p)
	return p


## One static body; a diamond shape for every solid cell that borders walkable ground. Lamp posts
## and bollards get a smaller footprint so the street doesn't feel walled off around them.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for y: int in range(-1, grid.size.y + 1):
		for x: int in range(-1, grid.size.x + 1):
			var cell := Vector2i(x, y)
			if not grid.is_solid(cell) or not _borders_walkable(cell):
				continue
			var ch := grid.char_at(cell)
			var shrink := 0.32 if (ch == "L" or ch == "o") else 1.0
			var pts := PackedVector2Array()
			var c := Iso.cell_center(cell)
			for p: Vector2 in Iso.cell_diamond(cell):
				pts.append(c + (p - c) * shrink)
			var shape := CollisionShape2D.new()
			var poly := ConvexPolygonShape2D.new()
			poly.points = pts
			shape.shape = poly
			body.add_child(shape)


func _borders_walkable(cell: Vector2i) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var n := cell + Vector2i(dx, dy)
			if grid.in_bounds(n) and grid.is_walkable(n):
				return true
	return false


func _spawn_player() -> void:
	player = Operator.new()
	player.name = "Operator"
	player.position = Iso.cell_center(grid.first("P"))
	world.add_child(player)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	var bounds := grid.world_bounds().grow(160.0)
	camera.limit_left = floori(bounds.position.x)
	camera.limit_top = floori(bounds.position.y - 260.0)
	camera.limit_right = ceili(bounds.end.x)
	camera.limit_bottom = ceili(bounds.end.y)
	player.add_child(camera)
	camera.make_current()
	player_spawned.emit(player)


func _add_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	var sky := SkyBackdrop.new()
	layer.add_child(sky)
	add_child(layer)
	sky.follow = self


func _add_atmosphere() -> void:
	_ambient = CanvasModulate.new()
	_ambient.color = Palette.AMBIENT_VOICE_ON
	add_child(_ambient)
	var rain_layer := CanvasLayer.new()
	rain_layer.layer = 2
	var rain := Rain.new()
	rain_layer.add_child(rain)
	add_child(rain_layer)
	rain.setup(Rect2(Vector2.ZERO, get_viewport_rect().size), 1.0)
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## Current camera centre in world space (for the parallax backdrop).
func view_center() -> Vector2:
	return camera.get_screen_center_position() if camera != null else Vector2.ZERO
