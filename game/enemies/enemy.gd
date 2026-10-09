class_name Enemy
extends CharacterBody2D
## Base for the Steward's bodies still running their last instruction. A small state machine: idle at
## home, chase the Operator along the ground, wind up an attack (telegraphed in red-orange, the colour
## of danger and nothing else), attack, recover. Knockback and stun interrupt it.

signal died(enemy: Enemy)
## Fired when an attack starts winding up: the Steward's threat warnings listen for this.
signal attack_windup(enemy: Enemy, seconds: float)

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, STUNNED, DEAD }

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

var _state_time: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _stun_left: float = 0.0
var _flash: float = 0.0
var _nav_path: Array[Vector2i] = []
var _repath_in: float = 0.0


func setup(owner_level: Level, cell: Vector2i, max_integrity: float) -> void:
	level = owner_level
	position = Iso.cell_center(cell)
	home = position
	integrity = Integrity.new(max_integrity)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 2)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 40.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	add_child(shape)
	add_to_group(&"enemies")


func is_alive() -> bool:
	return state != State.DEAD


func grid_cell() -> Vector2i:
	return Iso.world_to_cell(global_position)


func player() -> Operator:
	return level.player if level != null else null


func distance_to_player() -> float:
	var p := player()
	if p == null:
		return INF
	return Iso.ground_distance(global_position, p.global_position)


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
	velocity = move + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	move_and_slide()
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
	remove_from_group(&"enemies")
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)


## Screen velocity that walks toward `target` (screen position) around obstacles.
func steer_to(target: Vector2, delta: float) -> Vector2:
	_repath_in -= delta
	var here := Iso.world_to_cell(global_position)
	var goal := Iso.world_to_cell(target)
	if Iso.ground_distance(global_position, target) < 1.2 or level == null:
		return Iso.ground_velocity(Iso.ground_dir_between(global_position, target), speed_tiles)
	if _repath_in <= 0.0 or _nav_path.is_empty():
		_repath_in = 0.35
		_nav_path = level.enemy_nav.path(here, goal)
	while _nav_path.size() > 1 and _nav_path[0] == here:
		_nav_path.remove_at(0)
	var next := target if _nav_path.is_empty() else Iso.cell_center(_nav_path[0])
	return Iso.ground_velocity(Iso.ground_dir_between(global_position, next), speed_tiles)


func face_player() -> void:
	var p := player()
	if p != null:
		var d := Iso.ground_dir_between(global_position, p.global_position)
		if d != Vector2.ZERO:
			facing_ground = d


## Ground shadow every enemy shares.
func draw_shadow(rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, Color(Palette.NEAR_BLACK, 0.45))


## Red-orange telegraph: a ground ring that closes in as the windup runs out.
func draw_windup_ring(reach_tiles: float) -> void:
	if state != State.WINDUP:
		return
	var k := windup_progress()
	draw_polyline(Fx.ground_ellipse(reach_tiles, 32), Color(Palette.DANGER, 0.25 + 0.5 * k), 2.0, true)
	draw_polyline(Fx.ground_ellipse(reach_tiles * (1.0 - k * 0.85) + 0.1, 32), Color(Palette.DANGER, 0.7), 3.0, true)


func hit_flash() -> float:
	return _flash / 0.12
