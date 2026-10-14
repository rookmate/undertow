class_name Warden
extends Enemy
## A riot-control drone still enforcing the last curfew at the Harbor Ward border (no entry after 22:00).
## The only thing in the city that hunts: it walks its beat, and once its red eye has you (a cone ahead
## of it, line of sight, SIGHT_TILES; or anything within EARSHOT) it follows you anywhere, for as long as
## it keeps seeing you and LOSE_SECONDS after. Then it searches where it last saw you, and goes back to its
## beat. Up close it winds up a shock baton.

const MAX_INTEGRITY := 70.0
const SIGHT_TILES := 7.0
const SIGHT_DEG := 110.0
## It hears you this close, whichever way it's facing.
const EARSHOT := 1.8
const LOSE_SECONDS := 4.0
const SEARCH_SECONDS := 2.5
const BEAT_CELLS := 5
const PATROL_SPEED := 1.3
const HUNT_SPEED := 2.5
const REACH := 1.25
const WINDUP := 0.55
const RECOVER := 0.6
const DAMAGE := 14.0

## Following you (or searching for you): no leash while it is.
var hunting: bool = false
## Where it last saw you (screen position), while hunting.
var last_seen: Vector2 = Vector2.ZERO

var _beat: Array[Vector2] = []
var _beat_at: int = 1
var _unseen_for: float = 0.0
var _searching: float = -1.0


func _ready() -> void:
	scrap_value = 3
	radius_tiles = 0.36
	speed_tiles = PATROL_SPEED
	leash_tiles = INF
	_plan_beat()


func windup_seconds() -> float:
	return WINDUP * windup_scale


## Its beat: from where it was posted to the end of the longest straight walk (up to BEAT_CELLS) it can
## make from there, and back.
func _plan_beat() -> void:
	var start := grid_cell()
	var best := start
	for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var c := start
		for k: int in BEAT_CELLS:
			if level == null or not level.grid.is_walkable(c + d) or level.grid.is_occupied(c + d):
				break
			c += d
		if c.distance_to(start) > best.distance_to(start):
			best = c
	_beat = [Iso.cell_center(start), Iso.cell_center(best)]


## Its eye has you: in its cone and in sight, or close enough to hear.
func sees(at: Vector2) -> bool:
	if level == null:
		return false
	var d := Iso.ground_distance(global_position, at)
	if d <= EARSHOT:
		return true
	return CombatMath.in_arc(global_position, facing_ground, at, SIGHT_TILES, SIGHT_DEG) and level.grid.line_clear(global_position, at)


## Struck by something that jams it (the Signal Jammer): it loses you, and stands stunned for a while.
func jam(seconds: float) -> void:
	if state == State.DEAD:
		return
	hunting = false
	_searching = -1.0
	_stun_left = seconds
	_enter(State.STUNNED)


func _think(delta: float) -> Vector2:
	var p := player()
	var player_ok := p != null and p.is_alive()
	if player_ok and state != State.WINDUP and state != State.RECOVER and sees(p.global_position):
		if not hunting:
			Sound.play(&"warden_alert", global_position)
		hunting = true
		_searching = -1.0
		_unseen_for = 0.0
		last_seen = p.global_position
	elif hunting:
		_unseen_for += delta
	match state:
		State.IDLE, State.CHASE:
			if hunting and player_ok:
				return _hunt(p, delta)
			return _walk_beat(delta)
		State.WINDUP:
			face_player()
			if _state_time >= windup_seconds():
				if player_ok and distance_to_player() <= REACH + 0.25:
					p.take_hit(DAMAGE, global_position)
				Sound.play(&"warden_strike", global_position)
				_enter(State.RECOVER)
			return Vector2.ZERO
		State.RECOVER:
			if _state_time >= RECOVER:
				_enter(State.CHASE)
			return Vector2.ZERO
	return Vector2.ZERO


func _hunt(p: Operator, delta: float) -> Vector2:
	speed_tiles = HUNT_SPEED * speed_scale
	if _unseen_for <= 0.0 and distance_to_player() <= REACH:
		_enter(State.WINDUP)
		return Vector2.ZERO
	if _unseen_for < LOSE_SECONDS:
		var to := Iso.ground_dir_between(global_position, p.global_position if _unseen_for <= 0.0 else last_seen)
		if to != Vector2.ZERO:
			facing_ground = to
		return steer_to(p.global_position if _unseen_for <= 0.0 else last_seen, delta)
	# Lost you: go to where it last saw you and look about, then back to its beat.
	if Iso.ground_distance(global_position, last_seen) > 0.4:
		facing_ground = Iso.ground_dir_between(global_position, last_seen)
		return steer_to(last_seen, delta)
	if _searching < 0.0:
		_searching = 0.0
	_searching += delta
	facing_ground = facing_ground.rotated(delta * 2.4)
	if _searching >= SEARCH_SECONDS:
		hunting = false
		_searching = -1.0
	return Vector2.ZERO


func _walk_beat(delta: float) -> Vector2:
	speed_tiles = PATROL_SPEED * speed_scale
	if _beat.size() < 2:
		return Vector2.ZERO
	var target := _beat[_beat_at]
	if Iso.ground_distance(global_position, target) < 0.2:
		_beat_at = 1 - _beat_at
		target = _beat[_beat_at]
	var to := Iso.ground_dir_between(global_position, target)
	if to != Vector2.ZERO:
		facing_ground = to
	return steer_to(target, delta)


func _draw() -> void:
	draw_shadow(22.0, 10.0)
	if not hunting and state != State.STUNNED:
		var pts := PackedVector2Array([Vector2.ZERO])
		var half := deg_to_rad(SIGHT_DEG * 0.5)
		for k: int in 9:
			var a := facing_ground.angle() - half + half * 2.0 * k / 8.0
			pts.append(Iso.grid_to_world(Vector2.from_angle(a) * SIGHT_TILES * 0.55))
		draw_colored_polygon(pts, Color(Palette.DANGER, 0.06))
	draw_windup_ring(REACH)
	var bob := sin(Time.get_ticks_msec() / 300.0 + float(get_instance_id() % 7)) * 3.0
	paint_body("warden", 90.0, Vector2(0, bob))
	if state == State.WINDUP:
		draw_circle(body_anchor("warden", "baton", 90.0, Vector2(0, bob)), 4.0 + 3.0 * windup_progress(), Palette.DANGER, true, -1.0, true)
	var eye := Palette.DANGER_HOT if hunting else Palette.DANGER
	if state == State.STUNNED:
		eye = Palette.GREY_DEEP
	draw_circle(body_anchor("warden", "eye", 90.0, Vector2(0, bob)), 2.5, eye, true, -1.0, true)
