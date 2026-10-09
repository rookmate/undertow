class_name Level
extends Node2D
## Builds a playable level from a text map (data/levels/*.txt): floor, depth-sorted buildings and
## props, Lattice lamps, collision, the Operator and the camera. Placeholder shapes in the brief's
## palette at image 10's camera angle and scale.

signal player_spawned(player: Operator)
signal enemy_died(enemy: Enemy)

@export var level_id: String = "vellum"
@export_file("*.txt") var map_path: String = "res://data/levels/vellum_street.txt"

var grid: LevelGrid
var world: Node2D
## Effects that lie on the ground (swing arcs, shock rings), above the floor and below the world.
var fx_ground: Node2D
var player: Operator
var camera: Camera2D
## A* over every walkable cell, for enemies.
var enemy_nav: GridNav
## The Steward's view of the level: routes over Lattice cells only.
var predictor: PathPredictor
var predicted_path: PredictedPath
var checkpoint_cell: Vector2i

var exploration: Exploration
var lighting: LightingState
var slow_mo: SlowMo
var watch: StewardWatch
var hud: Hud

var _ambient: CanvasModulate
var _enemies: Array[Enemy] = []


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
	fx_ground = Node2D.new()
	fx_ground.name = "GroundFx"
	fx_ground.z_index = -14
	add_child(fx_ground)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	enemy_nav = GridNav.new(grid, func(c: Vector2i) -> bool: return grid.is_walkable(c) and not grid.is_occupied(c))
	_build_cells()
	_build_collision()
	_spawn_player()
	_populate()
	_add_steward_path()
	_add_atmosphere()
	exploration = Exploration.new()
	exploration.setup(grid)
	add_child(exploration)
	lighting = LightingState.new()
	add_child(lighting)
	lighting.setup(self, _ambient)
	slow_mo = SlowMo.new()
	add_child(slow_mo)
	slow_mo.setup(self)
	watch = StewardWatch.new()
	add_child(watch)
	watch.setup(self)
	hud = Hud.new()
	add_child(hud)
	Steward.voice_changed.connect(_on_voice_changed)
	add_child(PauseMenu.new())
	add_child(LevelHints.new())
	GameState.set_location(location_key())
	GameState.save()
	_on_ready_extra()


func _process(delta: float) -> void:
	if get_tree().paused:
		return
	# Level play only (DECISIONS #11): menus, pause and the Ark don't count toward voice_on_ratio.
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	GameState.add_play_time(real_delta)
	if not is_hub():
		GameState.add_voice_time(real_delta, Steward.voice_on)
	exploration.observe(player.cell())
	_update_checkpoint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"voice_toggle") and not get_tree().paused:
		Steward.toggle_voice()
		get_viewport().set_input_as_handled()


func _on_voice_changed(on: bool) -> void:
	if on:
		Narrator.notify(&"voice_restored")


func _exit_tree() -> void:
	if Steward.voice_changed.is_connected(_on_voice_changed):
		Steward.voice_changed.disconnect(_on_voice_changed)
	Engine.time_scale = 1.0


# --- Hooks (the Ark overrides these) --------------------------------------------------------------
## A hub (the Ark) has no enemies, no Steward path, no weapons, and doesn't count voice time.
func is_hub() -> bool:
	return false


## What RunState.location records while the player is here.
func location_key() -> String:
	return "level:" + level_id


func _populate() -> void:
	_spawn_enemies()
	_spawn_people_and_finds()


func _on_ready_extra() -> void:
	pass


func living_enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e: Enemy in _enemies:
		if is_instance_valid(e) and e.is_alive():
			out.append(e)
	return out


func _update_checkpoint() -> void:
	if player == null or not player.is_alive():
		return
	for c: Vector2i in grid.cells_with("C"):
		if c != checkpoint_cell and Iso.ground_distance(player.global_position, Iso.cell_center(c)) < 1.3:
			checkpoint_cell = c


## Back on your feet at the last checkpoint, at full Integrity.
func respawn_player() -> void:
	if player == null:
		return
	player.revive_at(Iso.cell_center(checkpoint_cell))
	camera.reset_smoothing()


# --- Construction ----------------------------------------------------------------------------------
func _build_cells() -> void:
	for cell: Vector2i in grid.all_cells():
		var ch := grid.char_at(cell)
		if grid.is_building(cell):
			var b := BuildingCell.new()
			var facade := BuildingCell.Facade.PLAIN
			match ch:
				"A":
					facade = BuildingCell.Facade.ARCHIVE
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
				var reliquary := Reliquary.new()
				reliquary.setup(self, cell, level_id)
				world.add_child(reliquary)
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
	player.level = self
	checkpoint_cell = grid.first("P")
	player.position = Iso.cell_center(checkpoint_cell)
	world.add_child(player)
	if not is_hub():
		var ids := Loadout.from_run(GameState.run)
		var modes: Array[Loadout.Mode] = []
		for id: String in ids:
			modes.append(Loadout.chosen_mode(GameState.run, id))
		player.equip(ids, modes)
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


## The Waiting ('W' on the street, 'w' in the stacks), the truth cache ('T') and the unindexed log ('U').
func _spawn_people_and_finds() -> void:
	var fog := OffPathFog.new()
	fog.name = "Marrow"
	add_child(fog)
	fog.setup(grid)
	for c: Vector2i in grid.cells_with("W"):
		var w := TheWaiting.new()
		w.setup(self, c, ContentIds.SURVIVOR_DOORWAY, false)
		world.add_child(w)
	for c: Vector2i in grid.cells_with("w"):
		var w := TheWaiting.new()
		w.setup(self, c, ContentIds.SURVIVOR_STACKS, true)
		world.add_child(w)
	for c: Vector2i in grid.cells_with("T"):
		var cache := TruthCache.new()
		cache.setup(self, c, ContentIds.CORE_TRUTH_STACKS)
		world.add_child(cache)
	for c: Vector2i in grid.cells_with("U"):
		var slip := UnindexedLog.new()
		slip.setup(self, c, ContentIds.LOG_UNINDEXED_SLIP)
		world.add_child(slip)


func _add_steward_path() -> void:
	predictor = PathPredictor.new(grid)
	predictor.aim_at(grid.first("R"), grid.first("P"))
	predicted_path = PredictedPath.new()
	predicted_path.name = "PredictedPath"
	predicted_path.predictor = predictor
	predicted_path.player = player
	add_child(predicted_path)


## The closest thing within reach the Operator could use (or is told not to), or null.
func nearest_interactable(at: Vector2) -> Interactable:
	var best: Interactable = null
	var best_d := Interactable.REACH_TILES
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := n as Interactable
		if it == null or not it.is_present() or not is_ancestor_of(it):
			continue
		if not it.can_interact() and it.blocked_reason() == "":
			continue
		var d := Iso.ground_distance(at, it.global_position)
		if d <= best_d:
			best = it
			best_d = d
	return best


## Custodians scrub in pairs ('c'); one Clerk ('k').
func _spawn_enemies() -> void:
	for c: Vector2i in grid.cells_with("c"):
		_add_enemy(Custodian.new(), c, Custodian.MAX_INTEGRITY)
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if grid.is_walkable(c + d) and not grid.is_occupied(c + d) and grid.char_at(c + d) == ".":
				_add_enemy(Custodian.new(), c + d, Custodian.MAX_INTEGRITY)
				break
	for k: Vector2i in grid.cells_with("k"):
		_add_enemy(Clerk.new(), k, Clerk.MAX_INTEGRITY)


func _add_enemy(e: Enemy, cell: Vector2i, max_integrity: float) -> void:
	add_enemy(e, cell, max_integrity)


## Places an enemy in the level (also used by tests to stage fights).
func add_enemy(e: Enemy, cell: Vector2i, max_integrity: float) -> Enemy:
	e.setup(self, cell, max_integrity)
	world.add_child(e)
	_enemies.append(e)
	e.died.connect(func(dead: Enemy) -> void: enemy_died.emit(dead))
	return e


## Removes every enemy at once (tests and debug).
func remove_all_enemies() -> void:
	for e: Enemy in _enemies:
		if is_instance_valid(e):
			e.queue_free()
	_enemies.clear()


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
