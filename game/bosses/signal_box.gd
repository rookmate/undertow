class_name SignalBox
extends Enemy
## The junction's signal box: a lineside cabinet the Conductor switches its points through. Strike it
## while the Conductor is switching and the whole gantry stalls, open to you for a long moment. The
## Steward never mentions it and its tuned aim never picks it: you have to find it yourself.

var conductor: Conductor


func _ready() -> void:
	speed_tiles = 0.0
	scrap_value = 0
	steward_aims_at = false
	radius_tiles = 0.4


## The Conductor is down: the box is just a cabinet now, not something to fight.
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
	if conductor != null:
		conductor.on_signal_box_hit()


func _think(_delta: float) -> Vector2:
	return Vector2.ZERO


func _draw() -> void:
	draw_shadow(16.0, 8.0)
	var flash := hit_flash()
	draw_rect(Rect2(-12, -46, 24, 46), Palette.IRON_DARK.lerp(Palette.IVORY, flash))
	draw_rect(Rect2(-12, -46, 24, 6), Palette.IRON_VERDIGRIS)
	# Its lamp blinks while the points are moving: the tell, if you watch for it.
	var switching := conductor != null and conductor.is_switching()
	var lamp := Palette.HUMAN_CREAM if switching and fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.15 else Palette.GREY_DEEP
	draw_circle(Vector2(0, -32), 4.0, lamp, true, -1.0, true)
