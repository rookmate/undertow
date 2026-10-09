class_name Conductor
extends Boss
## The Loop's boss: a train-management unit at the north junction that keeps trying to clear the line,
## with you on it (world bible). It sends runaway carriages down its three lanes, three runs at a time,
## then vents and is open to blows. Each run is warned by the lane's lights; with the voice on the
## Steward calls the lane first ("Left track."). Muted, the lights flicker a beat earlier if you watch
## them yourself. The manual solution: strike the signal box while it's switching and the whole gantry
## stalls, open for longer (the Steward never mentions the box).

enum Phase { IDLE, WARN, RUN, GAP, VENT, STALLED }

const MAX_INTEGRITY := 360.0
const RUNS_PER_CYCLE := 3
const WARN_SECONDS := 1.1
## Muted, the lights start flickering this much earlier.
const EARLY_FLICKER := 0.35
const GAP_SECONDS := 0.5
const VENT_SECONDS := 3.0
const STALL_SECONDS := 6.0

var phase: Phase = Phase.IDLE
var lanes: Array[ShuntLane] = []
## Times stalled through the signal box (the manual solution).
var stalls: int = 0

var _phase_time: float = 0.0
var _runs_left: int = 0
var _lane: ShuntLane
var _warn_for: float = WARN_SECONDS
var _stalled_this_cycle: bool = false


func _ready() -> void:
	super()
	boss_name = "THE CONDUCTOR"
	radius_tiles = 1.0


func is_vulnerable() -> bool:
	return phase == Phase.VENT or phase == Phase.STALLED


## The points are moving: the window for the signal box (its weak point).
func is_switching() -> bool:
	return phase == Phase.WARN


func _on_engaged() -> void:
	_start_cycle()


func _start_cycle() -> void:
	_runs_left = RUNS_PER_CYCLE
	_stalled_this_cycle = false
	_next_run()


## The lane under the Operator first, then the others: it's trying to clear the line of you.
func _next_run() -> void:
	_runs_left -= 1
	var p := player()
	_lane = null
	if p != null:
		for l: ShuntLane in lanes:
			if l.has_cell(p.cell()):
				_lane = l
	if _lane == null or (_runs_left < RUNS_PER_CYCLE - 1 and randf() < 0.5):
		_lane = lanes[randi() % lanes.size()]
	_warn_for = WARN_SECONDS + (EARLY_FLICKER if not Steward.voice_on else 0.0)
	_enter_phase(Phase.WARN)
	call_out("conductor_" + _lane.side)
	Sound.play(&"windup", global_position)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	queue_redraw()


func _fight(delta: float) -> void:
	_phase_time += delta
	match phase:
		Phase.WARN:
			_lane.warn(clampf(_phase_time / _warn_for, 0.0, 1.0))
			if _phase_time >= _warn_for:
				_lane.fire()
				_enter_phase(Phase.RUN)
		Phase.RUN:
			if not _lane.is_running():
				_enter_phase(Phase.GAP)
		Phase.GAP:
			if _phase_time >= GAP_SECONDS:
				if _runs_left > 0:
					_next_run()
				else:
					_enter_phase(Phase.VENT)
					call_out("conductor_vent")
					Sound.play(&"vent_hiss", global_position)
		Phase.VENT:
			if _phase_time >= VENT_SECONDS:
				_start_cycle()
		Phase.STALLED:
			if _phase_time >= STALL_SECONDS:
				_start_cycle()


## The signal box struck: while switching, the gantry stalls (once a cycle).
func on_weak_point_hit() -> void:
	if not is_switching() or _stalled_this_cycle or state == State.DEAD:
		return
	_stalled_this_cycle = true
	stalls += 1
	_lane.warn(-1.0)
	_enter_phase(Phase.STALLED)
	Sound.play(&"vent_hiss", global_position)


func _die() -> void:
	for l: ShuntLane in lanes:
		l.warn(-1.0)
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


func _physics_process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	draw_shadow(46.0, 22.0)
	var flash := hit_flash()
	var iron := Palette.IRON_DARK.lerp(Palette.IVORY, flash)
	var h := 150.0
	# Two legs and a crossbar: a signal gantry over the junction.
	for x: float in [-46.0, 46.0]:
		draw_rect(Rect2(x - 6, -h, 12, h), iron)
	draw_rect(Rect2(-56, -h - 14, 112, 18), iron)
	# Three lamps, one per lane; the warned lane's burns red-orange (danger).
	for i: int in 3:
		var lamp_pos := Vector2(-34 + i * 34, -h - 5)
		var lit := phase == Phase.WARN and _lane != null and lanes.find(_lane) == i
		draw_circle(lamp_pos, 7.0, Palette.DANGER if lit else Palette.GREY_DEEP, true, -1.0, true)
	# The shunting arm and its housing: the core shows when it vents or stalls.
	var drop := 60.0 if is_vulnerable() else 0.0
	var body := Rect2(-30, -h + 20 + drop, 60, 54)
	draw_rect(body, iron.lightened(0.08))
	var core := body.get_center()
	if is_vulnerable():
		draw_circle(core, 14.0, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
		for k: int in 5:
			var a := TAU * k / 5.0 + _phase_time * 3.0
			draw_circle(core + Vector2(cos(a), sin(a)) * 30.0 + Vector2(0, -20), 9.0, Color(Palette.FOG, 0.35), true, -1.0, true)
	else:
		draw_circle(core, 10.0, Palette.STEWARD_GOLD.darkened(0.4), true, -1.0, true)
