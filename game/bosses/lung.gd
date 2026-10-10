class_name Lung
extends Boss
## Greywater's boss: the master pump controller, still running a schedule for a city that isn't there
## (world bible). It floods the basin around it a quarter at a time (the quarter you're in first; three
## a cycle), each one called by the Steward; then it sends a pressure surge out across the basin, a ring
## of water you roll through; then it vents and is open. The manual solution: the old hand valve, turned
## while it's filling, chokes it.

enum Phase { IDLE, FILL, FLOOD, SURGE_WARN, SURGE, VENT, STALLED }
## The basin's quarters, as the Operator sees them on screen.
enum Quarter { LEFT, RIGHT, NEAR, FAR }

const MAX_INTEGRITY := 420.0
const FLOODS_PER_CYCLE := 3
const FILL_SECONDS := 1.2
## Muted, you read the grates yourself: the warning shows this much sooner.
const EARLY_FILL := 0.3
const FLOOD_SECONDS := 1.6
const FLOOD_DAMAGE := 14.0
const BASIN_TILES := 6.0
const SURGE_WARN_SECONDS := 1.0
const SURGE_SECONDS := 1.4
const SURGE_DAMAGE := 16.0
const SURGE_WIDTH := 0.7
const VENT_SECONDS := 3.5
const STALL_SECONDS := 6.0
const LINES: Dictionary[Quarter, String] = {
	Quarter.LEFT: "lung_left", Quarter.RIGHT: "lung_right", Quarter.NEAR: "lung_near", Quarter.FAR: "lung_far",
}

var phase: Phase = Phase.IDLE
## Times choked through the hand valve (the manual solution).
var stalls: int = 0
## The quarter filling or flooding now.
var quarter: Quarter = Quarter.LEFT

var _phase_time: float = 0.0
var _floods_left: int = 0
var _fill_for: float = FILL_SECONDS
var _struck: bool = false
var _stalled_this_cycle: bool = false


func _ready() -> void:
	super()
	boss_name = "THE LUNG"
	radius_tiles = 1.2


func is_vulnerable() -> bool:
	return phase == Phase.VENT or phase == Phase.STALLED


## Filling a quarter: the window for the hand valve.
func is_switching() -> bool:
	return phase == Phase.FILL


func _on_engaged() -> void:
	_start_cycle()


func _start_cycle() -> void:
	_floods_left = FLOODS_PER_CYCLE
	_stalled_this_cycle = false
	_enter_phase(Phase.FILL)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_struck = false
	match next:
		Phase.FILL:
			_fill_for = FILL_SECONDS + (EARLY_FILL if not Steward.voice_on else 0.0)
			var p := player()
			if p != null and _floods_left == FLOODS_PER_CYCLE:
				quarter = quarter_of(p.global_position)
			else:
				quarter = ((int(quarter) + 1 + randi() % 3) % 4) as Quarter
			call_out(LINES[quarter])
			Sound.play(&"windup", global_position)
		Phase.FLOOD:
			Sound.play(&"tide_swell", global_position)
		Phase.SURGE_WARN:
			call_out("lung_surge")
			Sound.play(&"windup", global_position)
		Phase.SURGE:
			Sound.play(&"carriage_run", global_position)
		Phase.VENT:
			call_out("lung_vent")
			Sound.play(&"vent_hiss", global_position)


## Which quarter of the basin a point (world) is in, as seen on screen around the Lung. Split by the
## iso diamond's diagonals, the screen's quarters are exactly the grid's quadrants.
func quarter_of(at: Vector2) -> Quarter:
	var rel := Iso.world_to_grid(at) - Iso.world_to_grid(global_position)
	if rel.x > 0.0 and rel.y <= 0.0:
		return Quarter.RIGHT
	if rel.x <= 0.0 and rel.y > 0.0:
		return Quarter.LEFT
	return Quarter.NEAR if rel.x > 0.0 else Quarter.FAR


## The grid signs (x, y) of a quarter.
static func quarter_signs(q: Quarter) -> Vector2:
	match q:
		Quarter.RIGHT:
			return Vector2(1, -1)
		Quarter.LEFT:
			return Vector2(-1, 1)
		Quarter.NEAR:
			return Vector2(1, 1)
	return Vector2(-1, -1)


## Whether a point (world) is in the basin quarter that's flooding.
func in_flood(at: Vector2) -> bool:
	return Iso.ground_distance(global_position, at) <= BASIN_TILES and quarter_of(at) == quarter


## The surge's ring: how far out it is now (tiles).
func surge_radius() -> float:
	return lerpf(radius_tiles, BASIN_TILES, clampf(_phase_time / SURGE_SECONDS, 0.0, 1.0))


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	var player_ok := p != null and p.is_alive()
	match phase:
		Phase.FILL:
			if _phase_time >= _fill_for:
				_floods_left -= 1
				_enter_phase(Phase.FLOOD)
		Phase.FLOOD:
			if not _struck and _phase_time >= 0.3 and player_ok and in_flood(p.global_position):
				_struck = true
				p.take_hit(FLOOD_DAMAGE, global_position)
			if _phase_time >= FLOOD_SECONDS:
				_enter_phase(Phase.FILL if _floods_left > 0 else Phase.SURGE_WARN)
		Phase.SURGE_WARN:
			if _phase_time >= SURGE_WARN_SECONDS:
				_enter_phase(Phase.SURGE)
		Phase.SURGE:
			if not _struck and player_ok and absf(Iso.ground_distance(global_position, p.global_position) - surge_radius()) <= SURGE_WIDTH:
				# take_hit misses mid-roll: roll through the ring.
				if p.take_hit(SURGE_DAMAGE, global_position) or p.is_invulnerable():
					_struck = true
			if _phase_time >= SURGE_SECONDS:
				_enter_phase(Phase.VENT)
		Phase.VENT:
			if _phase_time >= VENT_SECONDS:
				_start_cycle()
		Phase.STALLED:
			if _phase_time >= STALL_SECONDS:
				_start_cycle()


## The hand valve turned while it fills: it chokes (once a cycle).
func on_weak_point_hit() -> void:
	if not is_switching() or _stalled_this_cycle or state == State.DEAD:
		return
	_stalled_this_cycle = true
	stalls += 1
	_enter_phase(Phase.STALLED)


func _die() -> void:
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


func _physics_process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	draw_shadow(58.0, 26.0)
	var flash := hit_flash()
	var body := Palette.PUMP_CONCRETE.lerp(Palette.IVORY, flash)
	# The controller: a squat drum with a bellows on top that breathes with the schedule.
	var breath := sin(Time.get_ticks_msec() / 1000.0 * (6.0 if is_vulnerable() else 1.6)) * 8.0
	draw_colored_polygon(PackedVector2Array([Vector2(-50, -8), Vector2(0, 18), Vector2(50, -8), Vector2(50, -70), Vector2(0, -44), Vector2(-50, -70)]), body.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-50, -70), Vector2(0, -44), Vector2(50, -70), Vector2(0, -96)]), body)
	draw_colored_polygon(PackedVector2Array([Vector2(-30, -84), Vector2(30, -84), Vector2(22, -120 - breath), Vector2(-22, -120 - breath)]), Palette.PUMP_ROOF)
	for k: int in 3:
		draw_line(Vector2(-26 + k * 2, -94 - k * 9), Vector2(26 - k * 2, -94 - k * 9), Palette.IRON_DARK, 2.0, true)
	# Its gauge: the Steward's (gold); open, the needle drops and it glows.
	draw_circle(Vector2(0, -58), 10.0, Palette.IRON_DARK, true, -1.0, true)
	draw_circle(Vector2(0, -58), 6.0, Palette.STEWARD_GOLD_HOT if is_vulnerable() else Palette.STEWARD_GOLD, true, -1.0, true)
	# The quarter about to flood: its edge in red-orange (danger); flooding, the water over it.
	if phase == Phase.FILL or phase == Phase.FLOOD:
		_quarter_outline(Color(Palette.DANGER, 0.9 if phase == Phase.FILL else 0.4))
	if phase == Phase.FLOOD:
		_quarter_fill(Color(Palette.WATER_SHEEN, 0.55))
	if phase == Phase.SURGE_WARN:
		_ring(radius_tiles + 0.4, Color(Palette.DANGER, 0.85))
	if phase == Phase.SURGE:
		_ring(surge_radius(), Color(Palette.WATER_SHEEN, 0.9))
		_ring(surge_radius(), Color(Palette.DANGER, 0.6))


## The quarter that's filling, as a square of the basin on the ground (local points).
func _quarter_points() -> PackedVector2Array:
	var sg := quarter_signs(quarter) * BASIN_TILES * 0.72
	return PackedVector2Array([Vector2.ZERO, Iso.grid_to_world(Vector2(sg.x, 0)), Iso.grid_to_world(sg), Iso.grid_to_world(Vector2(0, sg.y))])


func _quarter_outline(col: Color) -> void:
	var pts := _quarter_points()
	pts.append(pts[0])
	draw_polyline(pts, col, 3.0, true)


func _quarter_fill(col: Color) -> void:
	draw_colored_polygon(_quarter_points(), col)


## A circle of `tiles` radius round the Lung, on the ground.
func _ring(tiles: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		pts.append(Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * tiles))
	draw_polyline(pts, col, 3.0, true)
