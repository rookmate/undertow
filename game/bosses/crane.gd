class_name Crane
extends Boss
## The Tideworks' boss: the last gantry crane, still trying to finish its last lift with you in the way
## (world bible). It lifts a container, swings its jib over you and drops it (three times), then swings
## the load round in a ring (stay inside it, or roll through), then rests with its cab lowered: open to
## blows. With the voice on, the Steward calls each move. The manual solution: throw the hoist brake
## while it's lifting and the load drops back onto its own trolley; it stalls, open for longer.
## Three stages (DECISIONS 183): at two thirds it lifts two loads at once, the second beside the first
## (step out along the jib, not across it); at one third a leg buckles and it goes over across the pier
## along a line it shows you first (off the line, or it lands on you), and lying there it drops quicker
## and rests less.

enum Phase { IDLE, LIFT, AIM, DROP, SWING_WARN, SWING, REST, STALLED }

const MAX_INTEGRITY := 420.0
const DROPS_PER_CYCLE := 3
const LIFT_SECONDS := 1.0
const AIM_SECONDS := 0.9
## Muted, you read the marker yourself: it shows this much sooner.
const EARLY_MARK := 0.3
const DROP_SECONDS := 0.25
## After a drop lands, before the hook lifts again (or it swings).
const DROP_SETTLE := 0.4
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
## Stage 2: the second load hangs this far beside the first (tiles, across the jib).
const SECOND_LOAD := 2.2
## Stage 3: the fall's line (how long, how wide, tiles), what it does to you; then its quicker aim and
## shorter rest.
const FALL_LENGTH := 9.0
const FALL_WIDTH := 1.6
const FALL_DAMAGE := 30.0
const FALLEN_AIM := 0.75
const FALLEN_REST := 2.8

## Each warning, and how soon after it's called its hazard lands (seconds): the load coming down, the
## swing. It has to be said by then.
const WARN_LEADS: Dictionary[String, float] = {
	"crane_drop": FALLEN_AIM + DROP_SECONDS,
	"crane_swing": SWING_WARN_SECONDS,
	"crane_double": Boss.STAGE_TRANSITION,
	"crane_buckle": Boss.STAGE_TRANSITION,
}
## Each call, and the soonest the next can come (seconds): after the last drop it swings at once.
const CALL_GAPS: Dictionary[String, float] = {
	"crane_drop": FALLEN_AIM + DROP_SECONDS + DROP_SETTLE,
	"crane_swing": SWING_WARN_SECONDS + SWING_SECONDS,
	"crane_rest": FALLEN_REST,
	"crane_double": Boss.STAGE_TRANSITION,
	"crane_buckle": Boss.STAGE_TRANSITION,
}

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
## Stage 2: the second load's spot. Stage 3: the line it falls along (ground direction), and whether
## it's down.
var _mark2: Vector2 = Vector2.ZERO
var fall_dir: Vector2 = Vector2(1, 0)
var fallen: bool = false
var _motion_from: Vector2 = Vector2.ZERO
var _height_from: float = 0.0


func _ready() -> void:
	super()
	boss_name = "THE CRANE"
	radius_tiles = 1.0
	load_at = global_position + Iso.ground_velocity(Vector2(1, 0), 2.5)


func is_vulnerable() -> bool:
	return phase == Phase.REST or phase == Phase.STALLED


func stage_count() -> int:
	return 3


func stage_line(next_stage: int) -> String:
	return "crane_double" if next_stage == 2 else "crane_buckle"


func _on_stage_begins(next_stage: int) -> void:
	phase = Phase.IDLE
	_phase_time = 0.0
	if next_stage == 3:
		# A leg buckles: it'll go over toward you, along a line it shows you first.
		var p := player()
		if p != null and Iso.ground_distance(global_position, p.global_position) > 0.2:
			fall_dir = Iso.ground_dir_between(global_position, p.global_position)


func _on_stage(now: int) -> void:
	if now == 3:
		fallen = true
		Sound.play(&"container_drop", global_position)
		var p := player()
		if p != null and p.is_alive() and on_fall_line(p.global_position):
			p.take_hit(FALL_DAMAGE, global_position)
	_start_cycle()


## Whether a point (world) lies on the line it falls along (stage 3).
func on_fall_line(at: Vector2) -> bool:
	var rel := Iso.world_to_grid(at) - Iso.world_to_grid(global_position)
	var along := rel.dot(fall_dir)
	return along >= 0.0 and along <= FALL_LENGTH and absf(rel.cross(fall_dir)) <= FALL_WIDTH * 0.5


## Stage 2 on: a second load beside the first (null spot before).
func second_mark() -> Vector2:
	return _mark2


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
	_motion_from = load_at
	_height_from = load_height
	phase = next
	_phase_time = 0.0
	_struck = false
	match next:
		Phase.AIM:
			_aim_for = (FALLEN_AIM if fallen else AIM_SECONDS) + (EARLY_MARK if not Steward.voice_on else 0.0)
			# Marked from its first frame: where you are now (it follows you for most of the aim), and the
			# second load's spot beside it.
			var p := player()
			if p != null:
				_mark = _reach(p.global_position)
			_mark2 = _beside(_mark)
			call_out("crane_drop")
		Phase.SWING_WARN:
			call_out("crane_swing")
			Sound.play(&"windup", global_position)
		Phase.REST:
			call_out("crane_rest")
			Sound.play(&"vent_hiss", global_position)


## Where the second load hangs (from stage 2): beside `at`, across the jib.
func _beside(at: Vector2) -> Vector2:
	var out := Iso.ground_dir_between(global_position, at)
	return at + Iso.ground_velocity(Vector2(-out.y, out.x), SECOND_LOAD)


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
			load_height = lerpf(_height_from, HOOK_HEIGHT, clampf(_phase_time / LIFT_SECONDS, 0.0, 1.0))
			if _phase_time >= LIFT_SECONDS:
				_drops_left -= 1
				_enter_phase(Phase.AIM)
		Phase.AIM:
			if p != null:
				_mark = _reach(p.global_position) if _phase_time < _aim_for * 0.7 else _mark
			if stage >= 2:
				_mark2 = _beside(_mark)
			load_at = load_at.lerp(_mark, clampf(delta * 6.0, 0.0, 1.0))
			if _phase_time >= _aim_for:
				load_at = _mark
				_enter_phase(Phase.DROP)
		Phase.DROP:
			load_height = lerpf(HOOK_HEIGHT, 0.0, clampf(_phase_time / DROP_SECONDS, 0.0, 1.0))
			if not _struck and _phase_time >= DROP_SECONDS:
				_struck = true
				Sound.play(&"container_drop", load_at)
				if p != null and p.is_alive() and (Iso.ground_distance(p.global_position, load_at) <= DROP_RADIUS \
						or (stage >= 2 and Iso.ground_distance(p.global_position, _mark2) <= DROP_RADIUS)):
					p.take_hit(DROP_DAMAGE, load_at)
			if _phase_time >= DROP_SECONDS + DROP_SETTLE:
				_enter_phase(Phase.LIFT if _drops_left > 0 else Phase.SWING_WARN)
		Phase.SWING_WARN:
			var prepare := smoothstep(0.0, SWING_WARN_SECONDS, _phase_time)
			var start := global_position + Iso.ground_velocity(Vector2.RIGHT, (SWING_INNER + SWING_OUTER) * 0.5)
			load_at = _motion_from.lerp(start, prepare)
			load_height = lerpf(_height_from, 60.0, prepare)
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
			load_height = lerpf(_height_from, 0.0, smoothstep(0.0, 0.35, _phase_time))
			if _phase_time >= (FALLEN_REST if fallen else REST_SECONDS):
				_start_cycle()
		Phase.STALLED:
			var settle := smoothstep(0.0, 0.3, _phase_time)
			load_height = lerpf(_height_from, 0.0, settle)
			load_at = _motion_from.lerp(global_position + Iso.ground_velocity(Vector2(1, 1).normalized(), 1.0), settle)
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


## From its second stage the second load hangs beside the first while it's aimed, falls and lands with it,
## and goes back up with it.
func second_load_shown() -> bool:
	return stage >= 2 and (phase == Phase.AIM or phase == Phase.DROP or phase == Phase.LIFT)


## Where the second load is (from stage 2): coming up beside the first while it lifts, then at its mark.
## Worked out from the first, never left over from before.
func second_load_at() -> Vector2:
	return _beside(load_at) if phase == Phase.LIFT else _mark2


func _die() -> void:
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


func _physics_process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	draw_shadow(54.0, 26.0)
	var tint := Color.WHITE * (1.0 + hit_flash())
	var h := 280.0
	ArtCatalog.paint(self, "crane_tower", Rect2(-48, -h, 96, h + 24), tint)
	var cab_y := lerpf(-h + 30.0, -h * 0.35, visual_open)
	ArtCatalog.paint(self, "crane_cab", Rect2(-30, cab_y, 60, 46), tint)
	if is_vulnerable():
		draw_circle(Vector2(0, cab_y + 30), 12.0, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
	var to := load_at - global_position
	var jib_tip := to + Vector2(0, -h)
	ArtCatalog.link(self, "crane_jib", Vector2(0, -h), jib_tip, 14.0, tint)
	draw_line(Vector2(0, -h + 2), jib_tip + Vector2(0, 2), Palette.STEWARD_GOLD.darkened(0.3), 1.5, true)
	var load_pos := to + Vector2(0, -load_height)
	ArtCatalog.link(self, "pipe", jib_tip, load_pos + Vector2(0, -40), 2.0)
	ArtCatalog.paint(self, "crane_load", Rect2(load_pos + Vector2(-34, -40), Vector2(68, 40)))
	if second_load_shown():
		var second := second_load_at() - global_position + Vector2(0, -load_height)
		ArtCatalog.link(self, "pipe", jib_tip, second + Vector2(0, -40), 2.0)
		ArtCatalog.paint(self, "crane_load", Rect2(second + Vector2(-34, -40), Vector2(68, 40)))
	# Danger marks: the drop's spot (two from stage 2), the swing's ring, the line it falls along
	# (red-orange: danger and nothing else).
	if phase == Phase.AIM:
		_ring(_mark - global_position, DROP_RADIUS * clampf(_phase_time / _aim_for, 0.2, 1.0), Color(Palette.DANGER, 0.85))
		if stage >= 2:
			_ring(_mark2 - global_position, DROP_RADIUS * clampf(_phase_time / _aim_for, 0.2, 1.0), Color(Palette.DANGER, 0.85))
	if in_transition() and stage == 3:
		var k := 1.0 - _transition_left / Boss.STAGE_TRANSITION
		var side := Vector2(-fall_dir.y, fall_dir.x) * FALL_WIDTH * 0.5
		var strip := PackedVector2Array([Iso.grid_to_world(side), Iso.grid_to_world(side + fall_dir * FALL_LENGTH), Iso.grid_to_world(-side + fall_dir * FALL_LENGTH), Iso.grid_to_world(-side)])
		draw_colored_polygon(strip, Color(Palette.DANGER, 0.15 + 0.35 * k))
		strip.append(strip[0])
		draw_polyline(strip, Color(Palette.DANGER, 0.9), 3.0, true)
	if fallen:
		# The jib down across the pier.
		ArtCatalog.link(self, "crane_jib", Vector2.ZERO, Iso.grid_to_world(fall_dir * FALL_LENGTH), 12.0, tint)
	if phase == Phase.SWING_WARN or phase == Phase.SWING:
		_ring(Vector2.ZERO, SWING_INNER, Color(Palette.DANGER, 0.5))
		_ring(Vector2.ZERO, SWING_OUTER, Color(Palette.DANGER, 0.85))


## A circle of `tiles` radius on the ground, centred at `at` (local).
func _ring(at: Vector2, tiles: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		pts.append(at + Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * tiles))
	draw_polyline(pts, col, 3.0, true)
