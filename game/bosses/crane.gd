class_name Crane
extends Boss
## The Tideworks' boss: the last gantry crane, still trying to finish its last lift with you in the way
## (world bible). It lifts a container, swings its jib over you and drops it (three times), then swings
## the load round in a ring (stay inside it, or roll through), then rests with its cab lowered: open to
## blows. With the voice on, the Steward calls each move. The manual solution: throw the hoist brake
## while it's lifting and the load drops back onto its own trolley; it stalls, open for longer.

enum Phase { IDLE, LIFT, AIM, DROP, SWING_WARN, SWING, REST, STALLED }

const MAX_INTEGRITY := 420.0
const DROPS_PER_CYCLE := 3
const LIFT_SECONDS := 1.0
const AIM_SECONDS := 0.9
## Muted, you read the marker yourself: it shows this much sooner.
const EARLY_MARK := 0.3
const DROP_SECONDS := 0.25
const DROP_DAMAGE := 22.0
const DROP_RADIUS := 1.15
const SWING_WARN_SECONDS := 1.0
const SWING_SECONDS := 0.9
const SWING_INNER := 2.2
const SWING_OUTER := 4.2
const SWING_DAMAGE := 18.0
const REST_SECONDS := 3.5
const STALL_SECONDS := 6.0
const HOOK_HEIGHT := 220.0
const MIN_REACH := 1.6
const MAX_REACH := 5.0

var phase: Phase = Phase.IDLE
## Ground point (world) the load hangs over, and its height above the ground (px).
var load_at: Vector2 = Vector2.ZERO
var load_height: float = 0.0
## Times stalled through the brake (the manual solution).
var stalls: int = 0

var _phase_time: float = 0.0
var _drops_left: int = 0
var _mark: Vector2 = Vector2.ZERO
var _aim_for: float = AIM_SECONDS
var _struck: bool = false
var _stalled_this_cycle: bool = false


func _ready() -> void:
	super()
	boss_name = "THE CRANE"
	radius_tiles = 1.0
	load_at = global_position + Iso.ground_velocity(Vector2(1, 0), 2.5)


func is_vulnerable() -> bool:
	return phase == Phase.REST or phase == Phase.STALLED


## The hoist is lifting: the window for the brake.
func is_switching() -> bool:
	return phase == Phase.LIFT


func _on_engaged() -> void:
	_start_cycle()


func _start_cycle() -> void:
	_drops_left = DROPS_PER_CYCLE
	_stalled_this_cycle = false
	_enter_phase(Phase.LIFT)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_struck = false
	match next:
		Phase.AIM:
			_aim_for = AIM_SECONDS + (EARLY_MARK if not Steward.voice_on else 0.0)
			call_out("crane_drop")
		Phase.SWING_WARN:
			call_out("crane_swing")
			Sound.play(&"windup", global_position)
		Phase.REST:
			call_out("crane_rest")
			Sound.play(&"vent_hiss", global_position)


## Where the jib can reach: the player's spot, kept within its arm.
func _reach(target: Vector2) -> Vector2:
	var d := Iso.ground_distance(global_position, target)
	var dir := Iso.ground_dir_between(global_position, target)
	return global_position + Iso.ground_velocity(dir, clampf(d, MIN_REACH, MAX_REACH))


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	match phase:
		Phase.LIFT:
			load_height = lerpf(0.0, HOOK_HEIGHT, clampf(_phase_time / LIFT_SECONDS, 0.0, 1.0))
			if _phase_time >= LIFT_SECONDS:
				_drops_left -= 1
				_enter_phase(Phase.AIM)
		Phase.AIM:
			if p != null:
				_mark = _reach(p.global_position) if _phase_time < _aim_for * 0.7 else _mark
			load_at = load_at.lerp(_mark, clampf(delta * 6.0, 0.0, 1.0))
			if _phase_time >= _aim_for:
				load_at = _mark
				_enter_phase(Phase.DROP)
		Phase.DROP:
			load_height = lerpf(HOOK_HEIGHT, 0.0, clampf(_phase_time / DROP_SECONDS, 0.0, 1.0))
			if not _struck and _phase_time >= DROP_SECONDS:
				_struck = true
				Sound.play(&"container_drop", load_at)
				if p != null and p.is_alive() and Iso.ground_distance(p.global_position, load_at) <= DROP_RADIUS:
					p.take_hit(DROP_DAMAGE, load_at)
			if _phase_time >= DROP_SECONDS + 0.4:
				_enter_phase(Phase.LIFT if _drops_left > 0 else Phase.SWING_WARN)
		Phase.SWING_WARN:
			load_height = 60.0
			if _phase_time >= SWING_WARN_SECONDS:
				_enter_phase(Phase.SWING)
				Sound.play(&"carriage_run", global_position)
		Phase.SWING:
			var a := TAU * clampf(_phase_time / SWING_SECONDS, 0.0, 1.0)
			load_at = global_position + Iso.ground_velocity(Vector2.from_angle(a), (SWING_INNER + SWING_OUTER) * 0.5)
			if p != null and p.is_alive() and not _struck:
				var d := Iso.ground_distance(global_position, p.global_position)
				if d >= SWING_INNER and d <= SWING_OUTER and Iso.ground_distance(load_at, p.global_position) < 1.2:
					_struck = true
					p.take_hit(SWING_DAMAGE, load_at)
			if _phase_time >= SWING_SECONDS:
				_enter_phase(Phase.REST)
		Phase.REST:
			load_height = 0.0
			if _phase_time >= REST_SECONDS:
				_start_cycle()
		Phase.STALLED:
			load_height = 0.0
			load_at = global_position + Iso.ground_velocity(Vector2(1, 1).normalized(), 1.0)
			if _phase_time >= STALL_SECONDS:
				_start_cycle()


## The brake thrown: while lifting, the load drops back onto the trolley and it stalls (once a cycle).
func on_weak_point_hit() -> void:
	if not is_switching() or _stalled_this_cycle or state == State.DEAD:
		return
	_stalled_this_cycle = true
	stalls += 1
	Sound.play(&"container_drop", global_position)
	_enter_phase(Phase.STALLED)


func _die() -> void:
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


func _physics_process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	draw_shadow(54.0, 26.0)
	var flash := hit_flash()
	var iron := Palette.RUST.lerp(Palette.IVORY, flash)
	var h := 280.0
	# The tower and its machinery house; the cab lowers when it rests or stalls.
	draw_rect(Rect2(-14, -h, 28, h), iron.darkened(0.2))
	var cab_y := -h * 0.35 if is_vulnerable() else -h + 30.0
	draw_rect(Rect2(-30, cab_y, 60, 46), iron)
	draw_rect(Rect2(-22, cab_y + 8, 44, 16), Palette.BLACK_MIRROR)
	if is_vulnerable():
		draw_circle(Vector2(0, cab_y + 30), 12.0, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
	# The jib out to the load, the cable down to it.
	var to := load_at - global_position
	var jib_tip := to + Vector2(0, -h)
	draw_line(Vector2(0, -h), jib_tip, iron, 7.0, true)
	draw_line(Vector2(0, -h + 2), jib_tip + Vector2(0, 2), Palette.STEWARD_GOLD.darkened(0.3), 1.5, true)
	var load_pos := to + Vector2(0, -load_height)
	draw_line(jib_tip, load_pos + Vector2(0, -40), Palette.IRON_DARK, 1.5, true)
	draw_rect(Rect2(load_pos + Vector2(-34, -40), Vector2(68, 40)), Palette.CONTAINER_TEAL)
	# Danger marks: the drop's spot, the swing's ring (red-orange: danger and nothing else).
	if phase == Phase.AIM:
		_ring(_mark - global_position, DROP_RADIUS * clampf(_phase_time / _aim_for, 0.2, 1.0), Color(Palette.DANGER, 0.85))
	if phase == Phase.SWING_WARN or phase == Phase.SWING:
		_ring(Vector2.ZERO, SWING_INNER, Color(Palette.DANGER, 0.5))
		_ring(Vector2.ZERO, SWING_OUTER, Color(Palette.DANGER, 0.85))


## A circle of `tiles` radius on the ground, centred at `at` (local).
func _ring(at: Vector2, tiles: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		pts.append(at + Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * tiles))
	draw_polyline(pts, col, 3.0, true)
