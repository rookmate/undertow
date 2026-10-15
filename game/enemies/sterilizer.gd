class_name Sterilizer
extends Enemy
## A hospital drone that treats you as contamination (world bible). It drifts close, winds up (its
## nozzles glow red-orange), and lets go a sterilizing mist (SterileCloud) that hangs and drains
## Integrity; then it backs off to let the mist work. Light, slow, persistent.

const MAX_INTEGRITY := 30.0
const WINDUP := 0.8
const RELEASE_TILES := 1.6
const RECOVER := 1.8
const HOVER := 52.0

var _bob: float = 0.0
## Where its mist will go down, fixed as it begins to wind up (and drawn there as the warning).
var deploy_at: Vector2 = Vector2.ZERO


func _ready() -> void:
	radius_tiles = 0.34
	speed_tiles = 1.7
	aggro_tiles = 4.5
	leash_tiles = 10.0
	scrap_value = 2
	_bob = randf() * TAU


func windup_seconds() -> float:
	return WINDUP * windup_scale


func _think(delta: float) -> Vector2:
	_bob += delta * 2.4
	var p := player()
	var player_ok := p != null and p.is_alive()
	var dist := distance_to_player()
	match state:
		State.IDLE:
			if player_ok and dist <= aggro_tiles:
				_enter(State.CHASE)
			return Vector2.ZERO
		State.CHASE:
			if not player_ok or dist > leash_tiles:
				_enter(State.IDLE)
				return steer_to(home, delta) if Iso.ground_distance(global_position, home) > 0.5 else Vector2.ZERO
			face_player()
			if dist <= RELEASE_TILES and level.grid.line_clear(global_position, p.global_position):
				deploy_at = _deploy_point(p)
				_enter(State.WINDUP)
				return Vector2.ZERO
			return steer_to(p.global_position, delta)
		State.WINDUP:
			face_player()
			if _state_time >= windup_seconds():
				_release()
				_enter(State.RECOVER)
			return Vector2.ZERO
		State.RECOVER:
			if _state_time >= RECOVER:
				_enter(State.CHASE if player_ok else State.IDLE)
				return Vector2.ZERO
			# Back off and let the mist do the work.
			if player_ok and dist < 2.6:
				return retreat_from(p.global_position, speed_tiles * 0.7, delta)
			return Vector2.ZERO
	return Vector2.ZERO


## Its mist goes down between it and you, most of the way to where you stood as it began: a place it
## commits to and shows you, so stepping out of the drawn mist before it falls escapes it.
func _deploy_point(p: Operator) -> Vector2:
	return global_position.lerp(p.global_position, 0.7)


func _release() -> void:
	if level == null or not level.grid.line_clear(global_position, deploy_at):
		return
	var cloud := SterileCloud.new()
	cloud.setup(level, deploy_at)
	level.fx_ground.add_child(cloud)
	Sound.play(&"sterile_hiss", deploy_at)


func draw_ground(ci: CanvasItem) -> void:
	shadow_on(ci, 16.0, 7.0)
	# The warning is the mist itself: where it will go down, its edge closing as the windup runs out.
	windup_ring_on(ci, SterileCloud.RADIUS_TILES, deploy_at - global_position)


func _draw() -> void:
	var lift := -HOVER + sin(_bob) * 4.0
	var deployment := windup_progress() if state == State.WINDUP else (1.0 - smoothstep(0.0, 0.45, _state_time) if state == State.RECOVER else 0.0)
	# Its nozzles turn to where the mist goes.
	var aim := (deploy_at - (global_position + Vector2(0, lift))).normalized() if deployment > 0.0 else Vector2(0, 1)
	var tips := PaintedHover.paint(self, "sterilizer", visual_facing(), 45.0, Vector2(0, lift + 18.0), hit_flash(), deployment, false, aim)
	if state == State.WINDUP:
		for tip: Vector2 in tips:
			draw_circle(tip, 3.0, Palette.DANGER, true, -1.0, true)
		draw_circle(Vector2(0, lift + 22), 8.0 + windup_progress() * 10.0, Color(Palette.STERILE_MIST, 0.3), true, -1.0, true)
