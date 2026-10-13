class_name Level
extends Node2D
## Builds a playable level from a text map (data/levels/*.txt): floor, depth-sorted buildings and
## props, Lattice lamps, collision, the Operator and the camera. Placeholder shapes in the brief's
## palette at image 10's camera angle and scale.

signal player_spawned(player: Operator)
signal enemy_died(enemy: Enemy)
## A screen flashed the Feed at the Operator (FeedBlind); `caught` if they were looking.
signal feed_flashed(caught: bool)

@export var level_id: String = "vellum"
## Districts take their map from LevelCatalog; hubs and test fixtures name one here.
@export_file("*.txt") var map_path: String = ""

var grid: LevelGrid
## The district's materials, sky and light (DistrictLook.for_district(level_id)).
var look: DistrictLook
## The district's boss, once spawned (null if it has none).
var boss: Boss
## Test fixtures with their own map name the boss to spawn here.
@export var boss_override: String = ""
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
## The Feed's flash, when a screen is turned on the Operator.
var feed_blind: FeedBlind

## True when the map was broken and the level never started (see _ready).
var failed: bool = false
## Greywater's tide, if this level floods (null otherwise).
## Noor down at the border (Harbor Ward, while her turn is undecided), and the choice over her.
var noor_down: NoorDown
var noor_choice: NoorChoice
## A descent's dark (only where the map has one).
var descent_dark: DescentDark
## The street's sky and its rain: not down in a descent.
var _backdrop: CanvasLayer
var _rain_layer: CanvasLayer
## The curfew patrol (Harbor Ward), once it's been called.
var _patrol: Array[Warden] = []
var _patrol_called: bool = false
var tide: Tide
var _ambient: CanvasModulate
var _enemies: Array[Enemy] = []
var _off_lattice_for: float = 0.0

## Seconds off the Lattice before the Steward loses the Operator (time for "there's nothing down there").
const COVERAGE_GRACE := 0.6
## Walking through kelp, as a share of walking speed.
const KELP_FOOTING := 0.65


func _ready() -> void:
	if map_path == "":
		map_path = LevelCatalog.map_of(level_id)
	grid = LevelGrid.load_file(map_path)
	look = DistrictLook.for_district(level_id)
	var problems := grid.validate(is_hub(), has_lattice())
	problems.append_array(_map_problems())
	if not is_hub():
		problems.append_array(LevelCatalog.boss_problems(boss_id(), grid))
	if not problems.is_empty():
		# A broken map never becomes a saved location: report it, stop here, and let the router take the
		# player back to the title. Nothing below ran, so nothing may run per frame either.
		failed = true
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		for p: String in problems:
			Diagnostics.error("Level %s: %s" % [map_path, p])
		SceneRouter.abandon(self)
		return
	_add_backdrop()
	FloorLayer.build(self, grid, look)
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
	_add_tide()
	_build_cells()
	_build_collision()
	_spawn_player()
	_populate()
	_add_steward_path()
	if tide != null and predictor != null:
		tide.phase_changed.connect(func(phase: Tide.Phase) -> void: predictor.set_blocked(tide.cells, phase != Tide.Phase.LOW))
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
	feed_blind = FeedBlind.new()
	add_child(feed_blind)
	hud = Hud.new()
	add_child(hud)
	var audio := LevelAudio.new()
	audio.name = "Audio"
	audio.level = self
	add_child(audio)
	Steward.voice_changed.connect(_on_voice_changed)
	_apply_perf_flags.call_deferred()
	add_child(PauseMenu.new())
	var hints := LevelHints.new()
	hints.level = self
	add_child(hints)
	GameState.set_location(location_key())
	SaveFlow.checkpoint(get_tree())
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
	_update_coverage(real_delta)
	_update_checkpoint()


## The Lattice reaches the Operator on indexed cells. The Ark is the charter's exception: the Steward may
## advise there (it can talk) though it may not act.
func _update_coverage(delta: float) -> void:
	var on_lattice := is_hub() or grid.is_indexed(player.cell())
	_off_lattice_for = 0.0 if on_lattice else _off_lattice_for + delta
	Steward.set_coverage(_off_lattice_for < COVERAGE_GRACE)


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
	Steward.set_coverage(true)
	# A warning about this place is moot once you've left it; so are lines waiting to be said here.
	if Narrator.warning_in_progress():
		Sound.hush()
	Narrator.drop_queued()


# --- Hooks (the Ark overrides these) --------------------------------------------------------------
## What else this kind of level needs from its map, beyond LevelGrid.validate: real content behind ids.
func _map_problems() -> PackedStringArray:
	return grid.content_problems()


## A hub (the Ark) has no enemies, no Steward path, no weapons, and doesn't count voice time.
func is_hub() -> bool:
	return false


## What RunState.location records while the player is here.
func location_key() -> String:
	return "level:" + level_id


## Back in a district you've done (DECISIONS 187): its boss stays beaten and its barriers open, its
## machines as hard as the truths you've carried out of it make them (Hardening), what you find goes
## straight to the Archive, and the Reliquary, opened once, takes you home.
var revisit: bool = false
## How hard it is now (Hardening.step); 0 on a first visit.
var hardening: int = 0


func _populate() -> void:
	revisit = not is_hub() and GameState.run.levels_completed.has(level_id)
	hardening = Hardening.step(GameState.run, level_id) if revisit else 0
	_spawn_enemies()
	_spawn_boss()
	_spawn_people_and_finds()


## Greywater: the tide over the low streets (and its water), and the thick Marrow on the cells under it.
func _add_tide() -> void:
	var floodable: Array[Vector2i] = []
	var marrow: Array[Vector2i] = []
	for c: Vector2i in grid.all_cells():
		if grid.floods(c):
			floodable.append(c)
		if grid.is_marrow(c):
			marrow.append(c)
	if not floodable.is_empty():
		tide = Tide.new()
		tide.name = "Tide"
		tide.setup(self, floodable)
		add_child(tide)
		var water := TideWater.new()
		water.setup(tide)
		add_child(water)
	if not marrow.is_empty():
		var fog := MarrowFog.new()
		fog.setup(marrow)
		add_child(fog)


## How fast the Operator can move on a cell: 1 on dry ground; less through kelp, or wading at high water.
func footing(cell: Vector2i) -> float:
	var f := KELP_FOOTING if grid.floor_at(cell) == LevelGrid.Floor.KELP else 1.0
	if tide != null:
		f = minf(f, tide.footing(cell))
	return f


## Whether a building cell's building exists yet (the Ark builds from progression).
func _building_standing(_ch: String) -> bool:
	return true


func _on_ready_extra() -> void:
	pass


func living_enemies() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e: Enemy in _enemies:
		if is_instance_valid(e) and e.is_alive():
			out.append(e)
	return out


## What the Operator's weapons can strike now (every hit query uses this).
func hittable_enemies() -> Array[Enemy]:
	return living_enemies().filter(func(e: Enemy) -> bool: return e.is_hittable())


## What the Steward's aim may bend toward: struck-able, and not something it keeps quiet about.
func steward_targets() -> Array[Enemy]:
	return living_enemies().filter(func(e: Enemy) -> bool: return e.steward_will_aim())


func _update_checkpoint() -> void:
	if player == null or not player.is_alive():
		return
	for c: Vector2i in grid.cells_with("C"):
		if c != checkpoint_cell and Iso.ground_distance(player.global_position, Iso.cell_center(c)) < 1.3:
			checkpoint_cell = c
			Sound.play(&"checkpoint")


## Back on your feet at the last checkpoint, at full Integrity; a boss fight you died in starts over, and
## so does a hold you were running.
func restart_after_death() -> void:
	restart_boss_fight()
	for n: Node in world.get_children():
		if n is Hold:
			(n as Hold).reset()
	respawn_player()


## The hold running now (the HUD shows it), or null.
func running_hold() -> Hold:
	for n: Node in world.get_children():
		if n is Hold and (n as Hold).running:
			return n
	return null


## The passage end with this id ("<name>_down" / "<name>_up"), or null.
func passage(passage_id: String) -> Passage:
	for n: Node in world.get_children():
		if n is Passage and (n as Passage).passage_id == passage_id:
			return n
	return null


## Down or back up: a short fade, and you're at the other end, beside its ladder.
func take_passage(from: Passage) -> void:
	var to := passage(from.partner_id())
	if to == null or player == null:
		return
	var fade := CanvasLayer.new()
	fade.layer = 40
	var black := ColorRect.new()
	black.color = Color(Palette.NEAR_BLACK, 0.0)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.add_child(black)
	add_child(fade)
	Sound.play(&"dressing", player.global_position)
	var t := create_tween()
	t.tween_property(black, "color:a", 1.0, 0.18)
	t.tween_callback(func() -> void:
		var landing := to.cell
		for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
			if grid.is_walkable(to.cell + d) and not grid.is_occupied(to.cell + d):
				landing = to.cell + d
				break
		player.position = Iso.cell_center(landing)
		camera.reset_smoothing())
	t.tween_property(black, "color:a", 0.0, 0.25)
	t.tween_callback(fade.queue_free)


## Below the street there's no sky and no rain; back up, they're there again.
func show_the_street(on: bool) -> void:
	for layer: CanvasLayer in [_backdrop, _rain_layer]:
		if layer != null:
			layer.visible = on


## Standing on a descent's floor (below the street).
func in_descent() -> bool:
	return player != null and grid.floor_at(player.cell()) == LevelGrid.Floor.CULVERT


## Unindexed things still to find down in the descents (what glows up through a shut way down).
func descent_finds_left() -> int:
	var n := 0
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := node as Interactable
		if it != null and it.off_path and it.still_to_find() and is_ancestor_of(it) \
				and grid.floor_at(Iso.world_to_cell(it.global_position)) == LevelGrid.Floor.CULVERT:
			n += 1
	return n


## The enemies a hold can bring out, by name.
const ENEMY_KINDS: Array[String] = ["custodian", "salvager", "clerk", "lamplighter", "warden"]


## Brings one of the city's machines out at `cell` (a hold's wave). Null for a kind there isn't.
func spawn_kind(kind: String, cell: Vector2i) -> Enemy:
	match kind:
		"custodian":
			return add_enemy(Custodian.new(), cell, Custodian.MAX_INTEGRITY)
		"salvager":
			return add_enemy(Salvager.new(), cell, Salvager.MAX_INTEGRITY)
		"clerk":
			return add_enemy(Clerk.new(), cell, Clerk.MAX_INTEGRITY)
		"lamplighter":
			return add_enemy(Lamplighter.new(), cell, Lamplighter.MAX_INTEGRITY)
		"warden":
			var w := add_enemy(Warden.new(), cell, Warden.MAX_INTEGRITY) as Warden
			w.hunting = true
			w.last_seen = player.global_position if player != null else w.global_position
			return w
	return null


## Takes an enemy out of the level without a fight (a hold starting over).
func forget_enemy(e: Enemy) -> void:
	_enemies.erase(e)
	e.remove_from_group(&"enemies")
	e.queue_free()


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
			if not _building_standing(ch):
				var plot := UnbuiltPlot.new()
				plot.setup(cell)
				world.add_child(plot)
				continue
			var b := BuildingCell.new()
			var facade := BuildingCell.Facade.PLAIN
			match ch:
				Tiles.HOSPITAL_WALL:
					facade = BuildingCell.Facade.HOSPITAL
				Tiles.HOSPITAL_DOOR:
					facade = BuildingCell.Facade.HOSPITAL_DOOR
				Tiles.CLINIC:
					facade = BuildingCell.Facade.CLINIC
				Tiles.PUMPHOUSE:
					facade = BuildingCell.Facade.PUMPHOUSE
				Tiles.COMMONS:
					facade = BuildingCell.Facade.COMMONS
					# Noor's Mast, on the roof's front corner.
					b.roof_mast = GameState.run.buildings_restored.has(GameState.MAST) \
						and not grid.is_building(cell + Vector2i(0, 1)) and not grid.is_building(cell + Vector2i(1, 0))
				Tiles.PUMP_WALL:
					facade = BuildingCell.Facade.PUMPING_STATION
				Tiles.PUMP_DOOR:
					facade = BuildingCell.Facade.PUMPING_STATION_DOOR
				Tiles.BOATHOUSE:
					facade = BuildingCell.Facade.BOATHOUSE
				Tiles.BOATHOUSE_DOOR:
					facade = BuildingCell.Facade.BOATHOUSE_DOOR
				Tiles.WARD_MAST:
					facade = BuildingCell.Facade.BOATHOUSE
					b.roof_mast = true
					b.mast_dark = true
				Tiles.BRIDGE_STUB:
					facade = BuildingCell.Facade.BRIDGE_STUB
				"A":
					facade = BuildingCell.Facade.ARCHIVE
				"d":
					facade = BuildingCell.Facade.DOOR
				"m":
					facade = BuildingCell.Facade.NEON_MAGENTA
				"g":
					facade = BuildingCell.Facade.NEON_LIME
				"l":
					facade = BuildingCell.Facade.LAUNDRY
				"M":
					facade = BuildingCell.Facade.SIGNAL_ROOM
				"I":
					facade = BuildingCell.Facade.WORKSHOP
			b.setup(cell, facade, not grid.is_building(cell + Vector2i(0, 1)), not grid.is_building(cell + Vector2i(1, 0)), look)
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
			"H":
				_prop(cell, StaticProp.Kind.HEDGE)
			"F":
				_prop(cell, StaticProp.Kind.PLANTER)
			"j":
				_prop(cell, StaticProp.Kind.SPRINKLER)
			"r":
				_prop(cell, StaticProp.Kind.CARRIAGE_SIDE)
			"[":
				_prop(cell, StaticProp.Kind.CONTAINER)
			"]":
				var hanging := HangingContainer.new()
				hanging.setup(cell, look)
				world.add_child(hanging)
			"^":
				var leg := CraneLeg.new()
				leg.setup(cell, look)
				world.add_child(leg)
			"J":
				_prop(cell, StaticProp.Kind.DESK)
			"*":
				var route_light := RouteLight.new()
				route_light.setup(cell)
				world.add_child(route_light)
			"b":
				var bed := _prop(cell, StaticProp.Kind.BED)
				var nightlight := PointLight2D.new()
				nightlight.texture = LightTextures.radial()
				nightlight.color = Palette.HUMAN_CREAM
				nightlight.energy = 1.3
				nightlight.texture_scale = 1.4
				nightlight.scale = Vector2(1.0, Iso.SQUASH)
				nightlight.position = Vector2(36, -20)
				bed.add_child(nightlight)
			"Q":
				var gate := SmartGate.new()
				gate.setup(self, cell)
				world.add_child(gate)
			"t":
				var tram := _prop(cell, StaticProp.Kind.TRAM)
				tram.joined_left = grid.char_at(cell + Vector2i(0, 1)) == "t"
				tram.joined_right = grid.char_at(cell + Vector2i(1, 0)) == "t"
			Tiles.PARTITION:
				_prop(cell, StaticProp.Kind.PARTITION)
			Tiles.HOSPITAL_BED:
				_prop(cell, StaticProp.Kind.HOSPITAL_BED)
			Tiles.TURBINE:
				_prop(cell, StaticProp.Kind.TURBINE)
			Tiles.TIDE_GAUGE:
				var gauge := TideGauge.new()
				gauge.setup(cell, tide)
				world.add_child(gauge)
			Tiles.AMBULANCE:
				var ambulance := _prop(cell, StaticProp.Kind.AMBULANCE)
				ambulance.joined_left = grid.char_at(cell + Vector2i(0, 1)) == Tiles.AMBULANCE
				ambulance.joined_right = grid.char_at(cell + Vector2i(1, 0)) == Tiles.AMBULANCE
			Tiles.NURSE_DESK:
				var desk := _prop(cell, StaticProp.Kind.NURSE_DESK)
				var lamp := PointLight2D.new()
				lamp.texture = LightTextures.radial()
				lamp.color = Palette.HUMAN_CREAM
				lamp.energy = 1.2
				lamp.texture_scale = 1.6
				lamp.scale = Vector2(1.0, Iso.SQUASH)
				lamp.position = Vector2(22, -40)
				desk.add_child(lamp)
			Tiles.NEWSROOM_DESK:
				_prop(cell, StaticProp.Kind.NEWS_DESK)
			Tiles.PILING:
				_prop(cell, StaticProp.Kind.PILING)
			Tiles.RACK:
				_prop(cell, StaticProp.Kind.RACK)
			Tiles.PANE:
				_prop(cell, StaticProp.Kind.PANE)
			Tiles.LANTERN:
				var lantern := _prop(cell, StaticProp.Kind.LANTERN)
				var glow := PointLight2D.new()
				glow.texture = LightTextures.radial()
				glow.color = Palette.WARD_CYAN
				glow.energy = 1.4
				glow.texture_scale = 3.2
				glow.scale = Vector2(1.0, Iso.SQUASH)
				glow.position = Vector2(15, -40)
				lantern.add_child(glow)
			Tiles.WARD_SEAL:
				var seal := WardSeal.new()
				seal.setup(self, cell)
				world.add_child(seal)


func _prop(cell: Vector2i, kind: StaticProp.Kind) -> StaticProp:
	var p := StaticProp.new()
	p.setup(cell, kind, look)
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
	checkpoint_cell = grid.start_cell()
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
	# Every placed thing takes its stable id from the map's '@' lines.
	for c: Vector2i in grid.cells_with("W"):
		var w := TheWaiting.new()
		w.setup(self, c, grid.entity_id(c), false)
		world.add_child(w)
	for c: Vector2i in grid.cells_with("w"):
		var w := TheWaiting.new()
		w.setup(self, c, grid.entity_id(c), true)
		world.add_child(w)
	for c: Vector2i in grid.cells_with("T"):
		var cache := TruthCache.new()
		cache.setup(self, c, grid.entity_id(c))
		world.add_child(cache)
	for c: Vector2i in grid.cells_with("V"):
		var find := WeaponFind.new()
		find.setup(self, c, grid.entity_id(c))
		world.add_child(find)
	for c: Vector2i in grid.cells_with("U"):
		var slip := UnindexedLog.new()
		slip.setup(self, c, grid.entity_id(c))
		world.add_child(slip)
	# The Wardfolk out in their own streets (Harbor Ward). On the Ark they stand by the Commons (ArkLevel).
	if not is_hub():
		for c: Vector2i in grid.cells_with(Tiles.WARDFOLK):
			var folk := ArkFigure.new()
			folk.setup(self, c, ArkFigure.Who.WARDFOLK)
			folk.wardfolk_index = grid.cells_with(Tiles.WARDFOLK).find(c)
			world.add_child(folk)
	# Holds and the ways down they open (design/deeper-districts.md).
	for c: Vector2i in grid.cells_with(Tiles.CRANK):
		var hold := Hold.new()
		hold.setup(self, c, grid.entity_id(c))
		world.add_child(hold)
	for c: Vector2i in grid.cells_with(Tiles.LADDER):
		var way := Passage.new()
		way.setup(self, c, grid.entity_id(c))
		world.add_child(way)
	# Doors the Ark's tools open (DECISIONS 188).
	for c: Vector2i in grid.cells_with(Tiles.TOOL_DOOR):
		var door := ToolDoor.new()
		door.setup(self, c, grid.entity_id(c))
		world.add_child(door)
	if not grid.cells_with(Tiles.CULVERT).is_empty() or grid.all_cells().any(func(c: Vector2i) -> bool: return grid.floor_at(c) == LevelGrid.Floor.CULVERT):
		descent_dark = DescentDark.new()
		descent_dark.level = self
		add_child(descent_dark)
	# The Spire: where the Steward says what it did.
	for c: Vector2i in grid.cells_with(Tiles.CONFESSION):
		var confession := Confession.new()
		confession.setup(self, c, grid.entity_id(c))
		world.add_child(confession)
	# Noor, down at the border, while her turn is still to be decided.
	if GameState.run.noor_away:
		for c: Vector2i in grid.cells_with(Tiles.NOOR_DOWN):
			noor_down = NoorDown.new()
			noor_down.setup(self, c)
			world.add_child(noor_down)
	for c: Vector2i in grid.cells_with(Tiles.WARD_BOAT):
		var boat := WardBoat.new()
		boat.setup(self, c)
		world.add_child(boat)


func _add_steward_path() -> void:
	predictor = PathPredictor.new(grid)
	predictor.aim_at(grid.first("R"), grid.first("P"))
	predicted_path = PredictedPath.new()
	predicted_path.name = "PredictedPath"
	predicted_path.predictor = predictor
	predicted_path.player = player
	add_child(predicted_path)


## True if one of the Waiting (not yet woken) is within `tiles` of a point.
func waiting_near(at: Vector2, tiles: float) -> bool:
	for n: Node in world.get_children():
		var w := n as TheWaiting
		if w != null and not w.woken and Iso.ground_distance(at, w.global_position) <= tiles:
			return true
	return false


## Noor's Mast reaches this district: it's built on the Ark, and this isn't the Ark.
func mast_reaches() -> bool:
	return not is_hub() and GameState.run.buildings_restored.has(GameState.MAST)


## With the Mast, how many unindexed places in the district are still to find (a truth cache, a slip, one
## of the Waiting off the path), voice on or off; -1 without it. It says how many, never where: finding
## them is yours to do (DECISIONS 174).
func unindexed_left() -> int:
	if not mast_reaches():
		return -1
	var n := 0
	for node: Node in get_tree().get_nodes_in_group(&"interactables"):
		var it := node as Interactable
		if it != null and it.off_path and it.still_to_find() and is_ancestor_of(it):
			n += 1
	return n


## Cells of truth caches whose core has been taken (the hand-scan map marks them).
func found_cache_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for n: Node in world.get_children():
		var cache := n as TruthCache
		if cache != null and cache.taken:
			out.append(cache.cell)
	return out


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


## Custodians scrub in pairs ('c'); Clerks ('k') keep their distance.
func _spawn_enemies() -> void:
	var used: Dictionary[Vector2i, bool] = {}
	for c: Vector2i in grid.cells_with("c"):
		_add_enemy(Custodian.new(), c, Custodian.MAX_INTEGRITY)
		used[c] = true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if grid.is_walkable(c + d) and not grid.is_occupied(c + d) and grid.char_at(c + d) == ".":
				_add_enemy(Custodian.new(), c + d, Custodian.MAX_INTEGRITY)
				used[c + d] = true
				break
	# Harder on a revisit (Hardening): one more Custodian beside each one placed.
	if hardening >= Hardening.MORE_FROM:
		for c: Vector2i in grid.cells_with("c"):
			for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if grid.is_walkable(c + d) and not grid.is_occupied(c + d) and not used.has(c + d):
					_add_enemy(Custodian.new(), c + d, Custodian.MAX_INTEGRITY)
					used[c + d] = true
					break
	for k: Vector2i in grid.cells_with("k"):
		_add_enemy(Clerk.new(), k, Clerk.MAX_INTEGRITY)
	for x: Vector2i in grid.cells_with("X"):
		_add_enemy(Lamplighter.new(), x, Lamplighter.MAX_INTEGRITY)
	for o: Vector2i in grid.cells_with("O"):
		_add_enemy(Salvager.new(), o, Salvager.MAX_INTEGRITY)
	for s: Vector2i in grid.cells_with(Tiles.STERILIZER):
		_add_enemy(Sterilizer.new(), s, Sterilizer.MAX_INTEGRITY)
	for w: Vector2i in grid.cells_with(Tiles.WARDEN):
		_add_enemy(Warden.new(), w, Warden.MAX_INTEGRITY)


## Whether the Lattice reaches into this district at all. Where it doesn't (Harbor Ward) the Steward has
## no say: finds aren't hidden from you while it listens, its map is your own hand scan, the light is
## yours, voice on or off, and muting changes nothing until the Lattice starts again.
func has_lattice() -> bool:
	return is_hub() or LevelCatalog.has_lattice(level_id)


## Noor's turn decided: carry her or leave her (NoorChoice), over the level.
func open_noor_choice(noor: NoorDown) -> NoorChoice:
	if noor_choice != null:
		return noor_choice
	noor_choice = NoorChoice.new()
	noor_choice.noor = noor
	noor_choice.closed.connect(func() -> void: noor_choice = null)
	add_child(noor_choice)
	return noor_choice


## You picked Noor up: the curfew patrol comes in through the gate after you both, already hunting. It
## comes once: pick her up again (downed, you dropped her) and the ones still standing come after you
## again; none new.
func call_the_curfew_patrol() -> void:
	if not _patrol_called:
		_patrol_called = true
		for c: Vector2i in grid.cells_with(Tiles.PATROL):
			_patrol.append(add_enemy(Warden.new(), c, Warden.MAX_INTEGRITY) as Warden)
	for w: Warden in _patrol:
		if is_instance_valid(w) and w.is_alive():
			w.hunting = true
			w.last_seen = player.global_position
	Sound.play(&"warden_alert", player.global_position)


## The curfew patrol's Wardens still standing.
func curfew_patrol() -> Array[Warden]:
	var out: Array[Warden] = []
	for w: Warden in _patrol:
		if is_instance_valid(w) and w.is_alive():
			out.append(w)
	return out


## Downed carrying her: she's back where she was, to be picked up again.
func noor_dropped() -> void:
	if noor_down != null and is_instance_valid(noor_down):
		noor_down.carried = false


## The boss this level ends with ("" for none): a test arena's own, or the district's.
func boss_id() -> String:
	return boss_override if boss_override != "" else LevelCatalog.boss_of(level_id)


## The district's boss on its 'B' cell, with what its fight needs: lanes ('1', '2', '3'), a signal box
## ('Z'), and barriers ('y') that open when it falls.
func _spawn_boss() -> void:
	# On a revisit it stays beaten, and its barriers stay open.
	if revisit:
		return
	for c: Vector2i in grid.cells_with("y"):
		var barrier := BossBarrier.new()
		barrier.setup(c)
		world.add_child(barrier)
	_make_boss()


## Dying in a boss fight restarts it (DECISIONS 177): the boss you were fighting, its weak point, the
## lanes or rollers it works and whatever it had in the air are gone, and a fresh one stands where it was
## built, at full strength and its first stage. It doesn't introduce itself again, and gives you a moment
## at the checkpoint before it engages. Its barriers stay shut. Returns whether a fight was restarted.
func restart_boss_fight() -> bool:
	if boss == null or not is_instance_valid(boss) or not boss.is_alive() or not boss.is_engaged:
		return false
	var parts: Array[Node] = [boss]
	if boss.weak_point != null and is_instance_valid(boss.weak_point):
		parts.append(boss.weak_point)
	parts.append_array(get_tree().get_nodes_in_group(&"boss_parts").filter(func(n: Node) -> bool: return is_ancestor_of(n)))
	for n: Node in world.get_children():
		if n is Projectile and (n as Projectile).team == Projectile.Team.ENEMY:
			parts.append(n)
	for n: Node in parts:
		if n is Enemy:
			_enemies.erase(n)
			(n as Enemy).remove_from_group(&"enemies")
		n.queue_free()
	_make_boss()
	if boss != null:
		boss.retrying = true
	return true


## The district's boss on its 'B' cell, its weak point on 'Z', and what its fight works (lanes, rollers:
## group "boss_parts").
func _make_boss() -> void:
	var b := grid.first("B")
	if b.x < 0:
		return
	match boss_id():
		"conductor":
			var conductor := Conductor.new()
			add_enemy(conductor, b, Conductor.MAX_INTEGRITY)
			boss = conductor
			var lanes: Array[ShuntLane] = []
			for digit: String in ["1", "2", "3"]:
				var cells := grid.cells_with(digit)
				if cells.is_empty():
					continue
				# The carriage runs away from the Conductor down its lane.
				cells.sort_custom(func(p: Vector2i, q: Vector2i) -> bool: return p.distance_squared_to(b) < q.distance_squared_to(b))
				var lane := ShuntLane.new()
				lanes.append(lane)
				lane.cells = cells
			# As the Operator sees them: the lane furthest down-left on screen is the left track.
			lanes.sort_custom(func(p: ShuntLane, q: ShuntLane) -> bool: return p.cells[0].y > q.cells[0].y)
			var sides := ["left", "middle", "right"]
			for i: int in lanes.size():
				lanes[i].setup(self, lanes[i].cells, sides[mini(i, 2)])
				lanes[i].add_to_group(&"boss_parts")
				fx_ground.add_child(lanes[i])
			conductor.lanes = lanes
			_add_weak_point(conductor, SignalBox.new())
		"crane":
			var crane := Crane.new()
			add_enemy(crane, b, Crane.MAX_INTEGRITY)
			boss = crane
			_add_weak_point(crane, HoistBrake.new())
		"surgeon":
			var surgeon := Surgeon.new()
			add_enemy(surgeon, b, Surgeon.MAX_INTEGRITY)
			boss = surgeon
			_add_weak_point(surgeon, TheatreSwitch.new())
		"lung":
			var lung := Lung.new()
			add_enemy(lung, b, Lung.MAX_INTEGRITY)
			boss = lung
			_add_weak_point(lung, HandValve.new())
		"warden_prime":
			var prime := WardenPrime.new()
			add_enemy(prime, b, WardenPrime.MAX_INTEGRITY)
			boss = prime
			_add_weak_point(prime, RelayMast.new())
		"editor":
			var editor := Editor.new()
			add_enemy(editor, b, Editor.MAX_INTEGRITY)
			boss = editor
			_add_weak_point(editor, BaleStack.new())
			var rollers := PressRollers.new()
			rollers.editor = editor
			rollers.add_to_group(&"boss_parts")
			fx_ground.add_child(rollers)


func _add_weak_point(owner_boss: Boss, point: WeakPoint) -> void:
	var z := grid.first("Z")
	if z.x < 0:
		return
	add_enemy(point, z, 1.0)
	point.boss = owner_boss
	owner_boss.weak_point = point


func _add_enemy(e: Enemy, cell: Vector2i, max_integrity: float) -> void:
	add_enemy(e, cell, max_integrity)


## Places an enemy in the level (also used by tests to stage fights).
func add_enemy(e: Enemy, cell: Vector2i, max_integrity: float) -> Enemy:
	e.setup(self, cell, max_integrity)
	world.add_child(e)
	if revisit:
		Hardening.apply(e, hardening)
	_enemies.append(e)
	e.died.connect(func(dead: Enemy) -> void: enemy_died.emit(dead))
	return e


## A screen flashes the Feed from `source`: if the Operator is looking at it, no more than `reach_tiles`
## away, with nothing tall between and not mid-roll, the world washes out for about `seconds`. Returns
## whether it caught them.
func flash_feed(source: Vector2, reach_tiles: float, seconds: float) -> bool:
	if player == null or feed_blind == null:
		return false
	var caught := player.is_alive() and not player.is_invulnerable() \
		and FeedBlind.catches(player.global_position, player.facing_ground, source, reach_tiles) \
		and grid.line_clear(player.global_position, source)
	if caught:
		feed_blind.blind(seconds)
	feed_flashed.emit(caught)
	return caught


## Removes every enemy at once (tests and debug).
func remove_all_enemies() -> void:
	for e: Enemy in _enemies:
		if is_instance_valid(e):
			e.queue_free()
	_enemies.clear()


func _add_backdrop() -> void:
	var layer := CanvasLayer.new()
	_backdrop = layer
	layer.layer = -10
	var sky := SkyBackdrop.new()
	sky.look = look
	layer.add_child(sky)
	add_child(layer)
	sky.follow = self


func _add_atmosphere() -> void:
	_ambient = CanvasModulate.new()
	_ambient.color = look.ambient_on
	add_child(_ambient)
	if look.rain:
		var rain_layer := CanvasLayer.new()
		_rain_layer = rain_layer
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


## Developer profiling: `-- --perf-disable=lights,glow,grade,rain,reflections,fog,buildings,hdr,minimap,hud,
## path,enemies` features off so their cost can be measured with the autopilot's [perf] report.
## `-- --perf-hide=WardSeal,StaticProp` hides and stops every node of those script classes.
func _apply_perf_flags() -> void:
	var off := PackedStringArray()
	var hidden_classes := PackedStringArray()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-disable="):
			off = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--perf-hide="):
			hidden_classes = arg.get_slice("=", 1).split(",")
	if not hidden_classes.is_empty():
		print("[perf] hidden: ", ", ".join(hidden_classes))
		for n: Node in find_children("*", "", true, false):
			var script := n.get_script() as Script
			while script != null:
				if hidden_classes.has(str(script.get_global_name())):
					if n is CanvasItem:
						(n as CanvasItem).visible = false
					n.set_process(false)
					n.set_physics_process(false)
				script = script.get_base_script()
	if off.is_empty():
		return
	print("[perf] disabled: ", ", ".join(off))
	for n: Node in find_children("*", "", true, false):
		if off.has("lights") and n is PointLight2D:
			(n as PointLight2D).visible = false
		if off.has("glow") and n is WorldEnvironment:
			(n as WorldEnvironment).environment.glow_enabled = false
		if off.has("grade") and n is CanvasLayer and n.name == "MuteGrade":
			(n as CanvasLayer).visible = false
		if off.has("rain") and n is Rain:
			(n as Rain).emitting = false
			(n as Rain).visible = false
		if off.has("reflections") and n is WetReflections:
			(n as WetReflections).visible = false
		if off.has("fog") and n is OffPathFog:
			(n as OffPathFog).visible = false
		if off.has("buildings") and n is BuildingCell:
			(n as BuildingCell).visible = false
		if off.has("minimap") and n is Minimap:
			(n as Minimap).visible = false
			(n as Minimap).set_process(false)
		if off.has("path") and n is PredictedPath:
			n.set_process(false)
		if off.has("enemies") and n is Enemy:
			n.set_physics_process(false)
		if off.has("hud") and n is Hud:
			(n as Hud).visible = false
			for c: Node in n.get_children():
				c.set_process(false)
	if off.has("hdr"):
		get_viewport().use_hdr_2d = false


## Current camera centre in world space (for the parallax backdrop).
func view_center() -> Vector2:
	return camera.get_screen_center_position() if camera != null else Vector2.ZERO
