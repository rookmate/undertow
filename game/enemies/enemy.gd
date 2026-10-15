class_name Enemy
extends CharacterBody2D
## Base for the Steward's bodies still running their last instruction. A small state machine: idle at
## home, chase the Operator along the ground, wind up an attack (telegraphed in red-orange, the colour
## of danger and nothing else), attack, recover. Knockback and stun interrupt it.

signal died(enemy: Enemy)
## Fired when an attack starts winding up: the Steward's threat warnings listen for this.
signal attack_windup(enemy: Enemy, seconds: float)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, STUNNED, DEAD }

## Physics layers: the world's solids, the Operator, the Steward's bodies.
const LAYER_WORLD := 1
const LAYER_PLAYER := 1 << 1
const LAYER_ENEMY := 1 << 2

var level: Level
var home: Vector2
var integrity: Integrity
var state: State = State.IDLE
var radius_tiles: float = 0.35
var speed_tiles: float = 2.2
var aggro_tiles: float = 3.8
var leash_tiles: float = 9.0
var facing_ground: Vector2 = Vector2(0, 1)
## Parts a machine gives up when taken apart (spent at the Workshop).
var scrap_value: int = 1
## Whether the Steward will aim at this (tuned targeting and aim assist), when it can be struck at all.
var steward_aims_at: bool = true
## False for things that never attack (a boss's weak point): something to hit, nothing to fear.
var is_threat: bool = true
## A revisit (Hardening): the share of its windup it still takes (its attack comes when the telegraph
## runs out: windup_seconds()), how much faster it moves, and whether it's one of the elites.
var windup_scale: float = 1.0
var speed_scale: float = 1.0
var elite: bool = false

var _state_time: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _stun_left: float = 0.0
var _flash: float = 0.0
var _nav_path: Array[Vector2i] = []
var _repath_in: float = 0.0
var gait: StrideCycle = StrideCycle.new()
## A regular machine meets the Operator's body: it stops against you (its lunges and knockback too), as
## you stop against it, and a roll passes through it either way. Its body is its ground footprint
## (radius_tiles), not a token capsule. Bosses and weak points keep their own (Boss, WeakPoint).
var meets_player: bool = true
var _retreat_to: Vector2 = Vector2.INF
var _retreat_in: float = 0.0
var _retreat_last: Vector2 = Vector2.ZERO
var _retreat_stuck: float = 0.0
var _retreat_avoid: Array[Vector2i] = []
## Its shadow and warnings, in the level's ground layer (a regular machine's; bosses draw their own).
var _marks: GroundMarks


func setup(owner_level: Level, cell: Vector2i, max_integrity: float) -> void:
	level = owner_level
	position = Iso.cell_center(cell)
	home = position
	integrity = Integrity.new(max_integrity)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = LAYER_ENEMY
	collision_mask = LAYER_WORLD | LAYER_ENEMY
	var shape := CollisionShape2D.new()
	shape.name = "Body"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 40.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	add_child(shape)
	add_to_group(&"enemies")
	# Its own radius is set in its _ready: fit the body once that has run.
	ready.connect(_fit_body, CONNECT_ONE_SHOT)


## A regular machine's body is its footprint on the ground: an ellipse of radius_tiles. And what it puts
## on the ground goes in the ground layer.
func _fit_body() -> void:
	if not meets_player:
		return
	if level != null and level.fx_ground != null and _marks == null:
		_marks = GroundMarks.new()
		_marks.enemy = self
		_marks.global_position = global_position
		level.fx_ground.add_child(_marks)
	var shape := get_node_or_null(^"Body") as CollisionShape2D
	if shape == null:
		return
	var footprint := ConvexPolygonShape2D.new()
	footprint.points = Fx.ground_ellipse(radius_tiles, 16, false)
	shape.shape = footprint
	shape.rotation = 0.0


func is_alive() -> bool:
	return state != State.DEAD


## One of a revisit's elites (Hardening): harder to take apart, a little faster, marked at its feet.
func make_elite(integrity_mult: float, speed_mult: float) -> void:
	elite = true
	integrity.max_value *= integrity_mult
	integrity.value = integrity.max_value
	speed_scale = speed_mult
	speed_tiles *= speed_mult
	var mark := EliteMark.new()
	mark.name = "EliteMark"
	add_child(mark)


## Whether the Operator's weapons can strike it now. Every hit query goes through this (Level.
## hittable_enemies()), so a thing that isn't a target can't be chosen, assisted toward, or struck.
func is_hittable() -> bool:
	return is_alive()


## Whether the Steward's aim (tuned targeting, aim assist) may bend toward it.
func steward_will_aim() -> bool:
	return is_hittable() and steward_aims_at


func grid_cell() -> Vector2i:
	return Iso.world_to_cell(global_position)


func player() -> Operator:
	return level.player if level != null else null


func paint_body(model: String, height: float, offset: Vector2 = Vector2.ZERO) -> void:
	var direction := Iso.grid_to_world(visual_facing())
	draw_set_transform(offset, 0.0, Vector2(-1.0 if direction.x < 0.0 else 1.0, 1.0))
	ArtCatalog.actor(self, body_key(model), height, Vector2.ZERO, hit_flash())
	draw_set_transform(Vector2.ZERO)


func body_key(model: String) -> String:
	return model + ("_back" if Iso.grid_to_world(visual_facing()).y < -0.25 else "_front")


func body_anchor(model: String, anchor_id: String, height: float, offset: Vector2 = Vector2.ZERO) -> Vector2:
	var point := ArtCatalog.actor_anchor(body_key(model), anchor_id, height)
	point.x *= -1.0 if Iso.grid_to_world(visual_facing()).x < 0.0 else 1.0
	return point + offset


func distance_to_player() -> float:
	var p := player()
	if p == null:
		return INF
	return Iso.ground_distance(global_position, p.global_position)


func visual_facing() -> Vector2:
	return facing_ground


## How far back the weapon cocks as a windup gathers (of the full -1): a little, so through the
## warning the weapon stays on your side of it rather than pointing away.
const WINDUP_COCK := 0.35


## -1 drawn back .. 0 at rest .. +1 the forward stroke. A windup cocks a little, holds, and strokes forward
## through the last of its warning, reaching the forward pose as the warning expires; damage timing owns
## release.
func attack_pose() -> float:
	if state == State.WINDUP:
		var p := windup_progress()
		return -WINDUP_COCK * smoothstep(0.0, 0.4, p) if p < 0.6 else lerpf(-WINDUP_COCK, 1.0, smoothstep(0.6, 1.0, p))
	if state == State.ATTACK:
		return 1.0
	if state == State.RECOVER:
		return 1.0 - smoothstep(0.0, 0.35, _state_time)
	return 0.0


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_state_time += delta
	_flash = maxf(0.0, _flash - delta)
	var move := Vector2.ZERO
	if state == State.STUNNED:
		_stun_left -= delta
		if _stun_left <= 0.0:
			_enter(State.CHASE)
	else:
		move = _think(delta)
	var walking := move.length_squared() > 0.01 and _knock.length_squared() < 4.0 and state != State.STUNNED
	if meets_player and collision_layer != 0:
		var p := player()
		collision_mask = LAYER_WORLD | LAYER_ENEMY | (0 if p == null or p.dodge.is_rolling() else LAYER_PLAYER)
	velocity = move + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	var before := global_position
	move_and_slide()
	gait.advance(global_position - before, walking, delta)
	queue_redraw()


## Per-frame behaviour; returns the screen velocity to move with.
func _think(_delta: float) -> Vector2:
	return Vector2.ZERO


func _enter(next: State) -> void:
	state = next
	_state_time = 0.0
	if next == State.WINDUP:
		Sound.play(&"windup", global_position)
		attack_windup.emit(self, windup_seconds())
		Steward.report_windup(self, windup_seconds())


func windup_seconds() -> float:
	return 0.5


## 0..1 progress through the current windup (for telegraph drawing).
func windup_progress() -> float:
	return clampf(_state_time / windup_seconds(), 0.0, 1.0) if state == State.WINDUP else 0.0


func take_hit(amount: float, from_dir: Vector2, knock_tiles: float, stun_seconds: float) -> void:
	if state == State.DEAD:
		return
	integrity.take(amount)
	_flash = 0.12
	_knock = Iso.ground_velocity(from_dir.normalized(), knock_tiles * 9.0)
	if integrity.is_depleted():
		_die()
		return
	Sound.play(&"machine_hit", global_position)
	if stun_seconds > 0.0:
		_stun_left = stun_seconds
		_enter(State.STUNNED)
	elif state == State.IDLE:
		_enter(State.CHASE)


func _die() -> void:
	Sound.play(&"machine_death", global_position)
	GameState.add_scrap(scrap_value)
	_enter(State.DEAD)
	# One last drawing without its warnings (the physics that redraws it stops now).
	queue_redraw()
	remove_from_group(&"enemies")
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


## Screen velocity that walks toward `target` (screen position) around obstacles, at `speed` tiles/s
## (its own speed_tiles if not given). Straight at it only when it's close and nothing stands between.
func steer_to(target: Vector2, delta: float, speed: float = -1.0) -> Vector2:
	var pace := speed_tiles if speed < 0.0 else speed
	_repath_in -= delta
	var here := Iso.world_to_cell(global_position)
	var goal := Iso.world_to_cell(target)
	if level == null or (Iso.ground_distance(global_position, target) < 1.2 and level.grid.line_clear(global_position, target)):
		return Iso.ground_velocity(Iso.ground_dir_between(global_position, target), pace)
	if _repath_in <= 0.0 or _nav_path.is_empty():
		_repath_in = 0.35
		_nav_path = level.enemy_nav.path(here, goal)
	# On to the next cell once it's well inside this one, so it turns corners rather than cutting them
	# (a body clips a one-tile passage's corner if it turns as soon as it's over the line).
	while _nav_path.size() > 1 and _nav_path[0] == here and Iso.ground_distance(global_position, Iso.cell_center(here)) < 0.45:
		_nav_path.remove_at(0)
	var next := target if _nav_path.is_empty() else Iso.cell_center(_nav_path[0])
	return Iso.ground_velocity(Iso.ground_dir_between(global_position, next), pace)


## Screen velocity that backs away from `threat` (screen position) at `speed` tiles/s: toward the
## reachable cell, within a few steps, that ends farthest from the threat, along its route (round a bend,
## even past the threat if that's the way out), so a wall or a corner never pins it. Getting nowhere
## (blocked by a body, say), it gives that way up and takes another.
func retreat_from(threat: Vector2, speed: float, delta: float) -> Vector2:
	_retreat_in -= delta
	if Iso.ground_distance(global_position, _retreat_last) > 0.3:
		_retreat_last = global_position
		_retreat_stuck = 0.0
	else:
		_retreat_stuck += delta
	if _retreat_stuck > 1.2 and _retreat_to != Vector2.INF:
		_retreat_avoid.append(Iso.world_to_cell(_retreat_to))
		_retreat_stuck = 0.0
		_retreat_in = 0.0
	if _retreat_to != Vector2.INF and Iso.ground_distance(global_position, _retreat_to) < 0.3:
		_retreat_avoid.clear()
		_retreat_in = 0.0
	if _retreat_in <= 0.0 or _retreat_to == Vector2.INF:
		_retreat_in = 0.6
		_retreat_to = _retreat_point(threat)
	if _retreat_to == Vector2.INF:
		return Vector2.ZERO
	return steer_to(_retreat_to, delta, speed)


const RETREAT_STEPS := 10


func _retreat_point(threat: Vector2) -> Vector2:
	if level == null or level.enemy_nav == null:
		return global_position + Iso.ground_velocity(Iso.ground_dir_between(threat, global_position), 1.0)
	var start := grid_cell()
	var steps: Dictionary[Vector2i, int] = {start: 0}
	var frontier: Array[Vector2i] = [start]
	var best := Vector2i(-1, -1)
	var best_score := Iso.ground_distance(global_position, threat) + 0.2
	var best_steps := RETREAT_STEPS + 1
	while not frontier.is_empty():
		var c: Vector2i = frontier.pop_front()
		var n := steps[c]
		if c != start and not _retreat_avoid.has(c):
			var score := Iso.ground_distance(Iso.cell_center(c), threat)
			if score > best_score + 0.01 or (absf(score - best_score) <= 0.01 and n < best_steps):
				best_score = score
				best = c
				best_steps = n
		if n >= RETREAT_STEPS:
			continue
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var next := c + d
			if not steps.has(next) and level.enemy_nav.is_open(next):
				steps[next] = n + 1
				frontier.append(next)
	return Iso.cell_center(best) if best.x >= 0 else Vector2.INF

func face_player() -> void:
	var p := player()
	if p != null:
		var d := Iso.ground_dir_between(global_position, p.global_position)
		if d != Vector2.ZERO:
			facing_ground = d


## What it puts on the ground: its shadow and its warnings (GroundMarks draws this, under every body).
func draw_ground(_ci: CanvasItem) -> void:
	pass


## Ground shadow every enemy shares.
func draw_shadow(rx: float, ry: float) -> void:
	shadow_on(self, rx, ry)


static func shadow_on(ci: CanvasItem, rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, Color(Palette.NEAR_BLACK, 0.45))


## Red-orange telegraph: a ground ring that closes in as the windup runs out.
func draw_windup_ring(reach_tiles: float) -> void:
	windup_ring_on(self, reach_tiles)


func windup_ring_on(ci: CanvasItem, reach_tiles: float, center: Vector2 = Vector2.ZERO) -> void:
	if state != State.WINDUP:
		return
	var k := windup_progress()
	ci.draw_polyline(_shifted(Fx.ground_ellipse(reach_tiles, 32), center), Color(Palette.DANGER, 0.25 + 0.5 * k), 2.0, true)
	ci.draw_polyline(_shifted(Fx.ground_ellipse(reach_tiles * (1.0 - k * 0.85) + 0.1, 32), center), Color(Palette.DANGER, 0.7), 3.0, true)


static func _shifted(points: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	if by == Vector2.ZERO:
		return points
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(p + by)
	return out


func hit_flash() -> float:
	return _flash / 0.12
