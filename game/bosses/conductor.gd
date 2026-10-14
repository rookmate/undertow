class_name Conductor
extends Boss
## The Loop's boss: a train-management unit at the north junction that keeps trying to clear the line,
## with you on it (world bible). It sends runaway carriages down its three lanes, three runs at a time,
## then vents and is open to blows. Each run is warned by the lane's lights; with the voice on the
## Steward calls the lane first ("Left track."). Muted, the lights flicker a beat earlier if you watch
## them yourself. The manual solution: strike the signal box while it's switching and the whole gantry
## stalls, open for longer (the Steward never mentions the box).
## Two stages (DECISIONS 183): at half, it runs express: two lanes at once, the lane you're on and
## another, faster carriages, and the Steward calls the one that's clear instead.

enum Phase { IDLE, WARN, RUN, GAP, VENT, STALLED }

const MAX_INTEGRITY := 360.0
const RUNS_PER_CYCLE := 3
const WARN_SECONDS := 1.1
## Muted, the lights start flickering this much earlier.
const EARLY_FLICKER := 0.35
const GAP_SECONDS := 0.5
const VENT_SECONDS := 3.0
const STALL_SECONDS := 6.0
## Stage 2: how much faster its carriages run, and how long two lanes' lights show.
const EXPRESS := 1.5
const EXPRESS_WARN := 1.3

## Each warning, and how soon after it's called its hazard lands (seconds): the carriage. It has to be
## said by then. Stage 2's calls are the clear lane's.
const WARN_LEADS: Dictionary[String, float] = {
	"conductor_left": WARN_SECONDS, "conductor_middle": WARN_SECONDS, "conductor_right": WARN_SECONDS,
	"conductor_clear_left": EXPRESS_WARN, "conductor_clear_middle": EXPRESS_WARN, "conductor_clear_right": EXPRESS_WARN,
	"conductor_express": Boss.STAGE_TRANSITION,
}
## Each call, and the soonest the next can come (seconds): the next track's, after this one's carriage
## has run and the gap.
const CALL_GAPS: Dictionary[String, float] = {
	"conductor_left": WARN_SECONDS + ShuntLane.CARRIAGE_SECONDS + GAP_SECONDS,
	"conductor_middle": WARN_SECONDS + ShuntLane.CARRIAGE_SECONDS + GAP_SECONDS,
	"conductor_right": WARN_SECONDS + ShuntLane.CARRIAGE_SECONDS + GAP_SECONDS,
	"conductor_clear_left": EXPRESS_WARN + ShuntLane.CARRIAGE_SECONDS / EXPRESS + GAP_SECONDS,
	"conductor_clear_middle": EXPRESS_WARN + ShuntLane.CARRIAGE_SECONDS / EXPRESS + GAP_SECONDS,
	"conductor_clear_right": EXPRESS_WARN + ShuntLane.CARRIAGE_SECONDS / EXPRESS + GAP_SECONDS,
	"conductor_vent": VENT_SECONDS,
	"conductor_express": Boss.STAGE_TRANSITION,
}

var phase: Phase = Phase.IDLE
var lanes: Array[ShuntLane] = []
## Times stalled through the signal box (the manual solution).
var stalls: int = 0

var _phase_time: float = 0.0
var _runs_left: int = 0
var _lane: ShuntLane
## Stage 2: the lanes running this time (two), and the one that's clear.
var _running: Array[ShuntLane] = []
var _clear: ShuntLane
var _warn_for: float = WARN_SECONDS
var _stalled_this_cycle: bool = false


func _ready() -> void:
	super()
	boss_name = "THE CONDUCTOR"
	radius_tiles = 1.0


func is_vulnerable() -> bool:
	return phase == Phase.VENT or phase == Phase.STALLED


func stage_count() -> int:
	return 2


func stage_line(_next_stage: int) -> String:
	return "conductor_express"


func _on_stage_begins(_next_stage: int) -> void:
	for l: ShuntLane in lanes:
		l.warn(-1.0)
		l.speed = EXPRESS
	_enter_phase(Phase.IDLE)


func _on_stage(_now: int) -> void:
	_start_cycle()


## The lanes being warned or running now (stage 1: one; stage 2: two).
func running_lanes() -> Array[ShuntLane]:
	return _running


## Stage 2: the lane that's clear this run (null in stage 1).
func clear_lane() -> ShuntLane:
	return _clear


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
	_warn_for = (EXPRESS_WARN if stage >= 2 else WARN_SECONDS) + (EARLY_FLICKER if not Steward.voice_on else 0.0)
	_running = [_lane]
	_clear = null
	if stage >= 2 and lanes.size() >= 3:
		# Express: yours and another; the Steward calls the one that's clear.
		var others := lanes.filter(func(l: ShuntLane) -> bool: return l != _lane)
		_running.append(others[randi() % others.size()])
		for l: ShuntLane in lanes:
			if not _running.has(l):
				_clear = l
	_enter_phase(Phase.WARN)
	call_out("conductor_clear_" + _clear.side if _clear != null else "conductor_" + _lane.side)
	Sound.play(&"windup", global_position)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	queue_redraw()


func _fight(delta: float) -> void:
	_phase_time += delta
	match phase:
		Phase.WARN:
			for l: ShuntLane in _running:
				l.warn(clampf(_phase_time / _warn_for, 0.0, 1.0))
			if _phase_time >= _warn_for:
				for l: ShuntLane in _running:
					l.fire()
				_enter_phase(Phase.RUN)
		Phase.RUN:
			if _running.all(func(l: ShuntLane) -> bool: return not l.is_running()):
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
	for l: ShuntLane in _running:
		l.warn(-1.0)
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
	var gantry := Rect2(-78, -164, 156, 164)
	# The housing travels between the painted pillars. Keep the fixed centre clear.
	ArtCatalog.slice(self, "conductor", Rect2(-78, -164, 41, 164), Rect2(0, 0, 0.26, 1))
	ArtCatalog.slice(self, "conductor", Rect2(39, -164, 39, 164), Rect2(0.75, 0, 0.25, 1))
	ArtCatalog.slice(self, "conductor", Rect2(-37, -164, 76, 61), Rect2(0.26, 0, 0.49, 0.37))
	for i: int in 3:
		var anchor_id: String = ["signal_left", "signal_middle", "signal_right"][i]
		var lamp_pos := ArtCatalog.anchor("conductor", anchor_id, gantry)
		var lit := phase == Phase.WARN and i < lanes.size() and _running.has(lanes[i])
		draw_circle(lamp_pos, 5.0, Palette.DANGER if lit else Palette.GREY_DEEP, true, -1.0, true)
	var drop := 60.0 if is_vulnerable() else 0.0
	var body := Rect2(-30, -130 + drop, 60, 54)
	var core := ArtCatalog.anchor("conductor_housing", "lens", body)
	if is_vulnerable():
		draw_circle(core, 6.0, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
		for k: int in 5:
			var a := TAU * k / 5.0 + _phase_time * 3.0
			draw_circle(core + Vector2(cos(a), sin(a)) * 30.0 + Vector2(0, -20), 9.0, Color(Palette.FOG, 0.35), true, -1.0, true)
	else:
		draw_circle(core, 5.0, Palette.STEWARD_GOLD.darkened(0.4), true, -1.0, true)
	ArtCatalog.paint(self, "conductor_housing", body, Color.WHITE * (1.0 + flash))
