class_name Lamplighter
extends Enemy
## A Lattice lamp on legs (world bible, "What still lives here"). While the Steward listens it walks a
## little ahead of you on the path and lights it: harmless, and not something your weapons aim at.
## Muted, it hunts you with its light: it winds up (red-orange, danger), then hooks you with a beam and
## drags you back toward the Lattice for a moment. Break its line of sight or hit it to get free.

const MAX_INTEGRITY := 34.0
const HOOK_RANGE := 6.0
const WINDUP := 0.9
const HOOK_SECONDS := 1.8
## Ground tiles per second it drags you.
const PULL_SPEED := 2.4
const HOOK_DAMAGE := 3.0
const RECOVER := 1.8
const LEG_HEIGHT := 112.0
## How far ahead of you on the path it walks while lighting the way (tiles).
const LEAD_TILES := 2.5

var hunting: bool = false
## True while its beam has hold of the Operator.
var hooking: bool = false

var _light: PointLight2D
var _hook_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	radius_tiles = 0.34
	speed_tiles = 2.0
	aggro_tiles = HOOK_RANGE
	leash_tiles = 12.0
	scrap_value = 3
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial()
	_light.color = Palette.STEWARD_GOLD
	_light.energy = 1.6
	_light.texture_scale = 1.8
	_light.scale = Vector2(1.0, Iso.SQUASH)
	add_child(_light)
	Steward.voice_changed.connect(_on_voice)
	_on_voice(Steward.voice_on)


func _exit_tree() -> void:
	if Steward.voice_changed.is_connected(_on_voice):
		Steward.voice_changed.disconnect(_on_voice)
	_release()


func windup_seconds() -> float:
	return WINDUP


## Voice on: a lamp that walks with you (not a target). Muted: it hunts.
func _on_voice(on: bool) -> void:
	hunting = not on
	if hunting:
		add_to_group(&"enemies")
	else:
		remove_from_group(&"enemies")
		_release()
		if state != State.DEAD:
			_enter(State.IDLE)


func take_hit(amount: float, from_dir: Vector2, knock_tiles: float, stun_seconds: float) -> void:
	# Hitting it breaks its hold, whatever else the blow does.
	_release()
	super(amount, from_dir, maxf(knock_tiles, 0.3), maxf(stun_seconds, 0.35))


func _die() -> void:
	_release()
	super()


func _think(delta: float) -> Vector2:
	var p := player()
	if p == null or not p.is_alive():
		_release()
		return Vector2.ZERO
	if not hunting:
		return _light_the_way(delta)
	var dist := distance_to_player()
	var sees := dist <= HOOK_RANGE and level.grid.line_clear(global_position, p.global_position)
	match state:
		State.IDLE, State.CHASE:
			if sees:
				face_player()
				_enter(State.WINDUP)
				return Vector2.ZERO
			if dist <= leash_tiles:
				return steer_to(p.global_position, delta) * 0.6
			return steer_to(home, delta) if Iso.ground_distance(global_position, home) > 0.5 else Vector2.ZERO
		State.WINDUP:
			face_player()
			if not sees:
				_enter(State.RECOVER)
			elif _state_time >= WINDUP:
				_hook(p)
			return Vector2.ZERO
		State.ATTACK:
			# Holding: the beam drags them while it can see them.
			if not hooking:
				_enter(State.RECOVER)
			elif not sees or _state_time >= HOOK_SECONDS:
				_release()
				_enter(State.RECOVER)
			return Vector2.ZERO
		State.RECOVER:
			if _state_time >= RECOVER:
				_enter(State.IDLE)
			return Vector2.ZERO
	return Vector2.ZERO


## Voice on: stand a little ahead of the Operator along the Steward's path, lamp lit.
func _light_the_way(delta: float) -> Vector2:
	var target := home
	var path := level.predicted_path
	if path != null and not path.shown.is_empty():
		var ahead: Vector2i = path.shown[path.shown.size() - 1]
		var dir := Iso.ground_dir_between(player().global_position, Iso.cell_center(ahead))
		target = player().global_position + Iso.ground_velocity(dir, LEAD_TILES)
	if Iso.ground_distance(home, target) > leash_tiles:
		target = home
	if Iso.ground_distance(global_position, target) < 0.6:
		return Vector2.ZERO
	return steer_to(target, delta) * 0.8


## The beam takes hold: the Operator is dragged toward the nearest lit cell of the Lattice (or into the
## lamp's own light, if they're already on it).
func _hook(p: Operator) -> void:
	_enter(State.ATTACK)
	hooking = true
	var cell := p.cell()
	_hook_target = global_position
	if not level.grid.is_indexed(cell):
		var nearest := _nearest_indexed(cell)
		if nearest.x >= 0:
			_hook_target = Iso.cell_center(nearest)
	p.take_hit(HOOK_DAMAGE, global_position)
	p.pull_toward(_hook_target, PULL_SPEED, HOOK_SECONDS)
	Sound.play(&"lamp_hook", global_position)


func _release() -> void:
	if not hooking:
		return
	hooking = false
	var p := player()
	if p != null:
		p.release_pull()


func _nearest_indexed(from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for dy: int in range(-6, 7):
		for dx: int in range(-6, 7):
			var c := from + Vector2i(dx, dy)
			if level.grid.is_indexed(c) and level.grid.is_walkable(c):
				var d := Vector2(dx, dy).length()
				if d < best_d:
					best_d = d
					best = c
	return best


func _physics_process(delta: float) -> void:
	super(delta)
	if _light != null:
		_light.position = Vector2(0, -LEG_HEIGHT * 0.2)
		_light.energy = (2.4 if state == State.ATTACK else 1.6) if state != State.DEAD else 0.0


func _draw() -> void:
	draw_shadow(16.0, 8.0)
	var head := Vector2(0, -LEG_HEIGHT)
	var flash := hit_flash()
	# Three thin legs, a lamp head: Lattice hardware, iron and lens.
	for k: int in 3:
		var a := TAU * k / 3.0 + 0.4
		var foot := Vector2(cos(a) * 18.0, sin(a) * 9.0)
		draw_line(foot, head + Vector2(0, 18), Palette.IRON_DARK.lerp(Palette.IVORY, flash), 3.0, true)
	draw_circle(head, 15.0, Palette.IRON_DARK, true, -1.0, true)
	var lens := Palette.STEWARD_GOLD_HOT if state != State.DEAD else Palette.GREY_DEEP
	draw_circle(head, 10.0, lens, true, -1.0, true)
	if hunting and state == State.WINDUP:
		draw_windup_ring(HOOK_RANGE * 0.25)
		draw_arc(head, 22.0 + windup_progress() * 10.0, 0.0, TAU, 24, Palette.DANGER, 2.0, true)
	if hooking and player() != null:
		var to := player().global_position - global_position + Vector2(0, -Projectile.CHEST_HEIGHT)
		draw_line(head, to, Color(Palette.STEWARD_GOLD_HOT, 0.85), 4.0, true)
		draw_line(head, to, Color(Palette.IVORY, 0.6), 1.5, true)
