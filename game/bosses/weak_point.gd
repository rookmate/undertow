class_name WeakPoint
extends Enemy
## A boss's weakness the Steward never mentions and its tuned aim never picks (the Conductor's signal box,
## the Crane's hoist brake): strike it while the boss is switching and the boss stalls, open for a long
## moment. Never a threat; once the boss falls it's just a fitting (retire()).

var boss: Boss


func _ready() -> void:
	speed_tiles = 0.0
	scrap_value = 0
	steward_aims_at = false
	is_threat = false
	radius_tiles = 0.4


## The boss is down: nothing to strike any more.
func retire() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	remove_from_group(&"enemies")
	queue_redraw()


func take_hit(_amount: float, _from_dir: Vector2, _knock_tiles: float, _stun_seconds: float) -> void:
	if state == State.DEAD:
		return
	_flash = 0.12
	Sound.play(&"signal_zap", global_position)
	if boss != null:
		boss.on_weak_point_hit()


func _think(_delta: float) -> Vector2:
	return Vector2.ZERO


## Its tell: a lamp that blinks while the boss is switching, if you watch for it.
func tell_on() -> bool:
	return boss != null and boss.is_switching() and fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.15
