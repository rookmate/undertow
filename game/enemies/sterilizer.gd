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
			if dist <= RELEASE_TILES:
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
				return Iso.ground_velocity(Iso.ground_dir_between(p.global_position, global_position), speed_tiles * 0.7)
			return Vector2.ZERO
	return Vector2.ZERO


## The mist goes down between it and you, where you're standing if you're close.
func _release() -> void:
	var p := player()
	var at := global_position
	if p != null:
		at = global_position.lerp(p.global_position, 0.7)
	var cloud := SterileCloud.new()
	cloud.setup(level, at)
	level.fx_ground.add_child(cloud)
	Sound.play(&"sterile_hiss", at)


func _draw() -> void:
	var lift := -HOVER + sin(_bob) * 4.0
	draw_shadow(16.0, 7.0)
	var deployment := windup_progress() if state == State.WINDUP else (1.0 - smoothstep(0.0, 0.45, _state_time) if state == State.RECOVER else 0.0)
	var tips := PaintedHover.paint(self, "sterilizer", visual_facing(), 45.0, Vector2(0, lift + 18.0), hit_flash(), deployment, false)
	if state == State.WINDUP:
		for tip: Vector2 in tips:
			draw_circle(tip, 3.0, Palette.DANGER, true, -1.0, true)
		draw_windup_ring(RELEASE_TILES)
		draw_circle(Vector2(0, lift + 22), 8.0 + windup_progress() * 10.0, Color(Palette.STERILE_MIST, 0.3), true, -1.0, true)
