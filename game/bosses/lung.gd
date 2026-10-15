class_name Lung
extends Boss
var _breath_phase: float = 0.0
## Greywater's boss: the master pump controller, still running a schedule for a city that isn't there
## (world bible). It floods the basin around it a quarter at a time (the quarter you're in first; three
## a cycle), each one called by the Steward; then it sends a pressure surge out across the basin, a ring
## of water you roll through; then it vents and is open. The manual solution: the old hand valve, turned
## while it's filling, chokes it.
## Three stages (DECISIONS 180): at two thirds the tide comes up and stays, the outer basin deep water
## that wears you down, and it fills faster; at one third the Marrow rolls in, thicker and closer: it
## can't see you (its floods fall where they fall) and neither can the Steward (no calls), only the
## grates' own red light.

enum Phase { IDLE, FILL, FLOOD, SURGE_WARN, SURGE, VENT, STALLED }
## The basin's quarters, as the Operator sees them on screen.
enum Quarter { LEFT, RIGHT, NEAR, FAR }

const MAX_INTEGRITY := 420.0
const FLOODS_PER_CYCLE := 3
const FILL_SECONDS := 1.2
## Muted, you read the grates yourself: the warning shows this much sooner.
const EARLY_FILL := 0.3
const FLOOD_SECONDS := 1.6
## How far into a flood it catches you.
const FLOOD_STRIKE := 0.3
const FLOOD_DAMAGE := 14.0
## A flooding quarter is the square this many tiles on a side out from the Lung (what's drawn is what
## floods: flood_rect()).
const FLOOD_TILES := 4.5
## How far the surge rings out.
const BASIN_TILES := 6.0
## How far out the deep water reaches (and is drawn): the basin's edge and a little of the quay.
const DEEP_OUTER := BASIN_TILES + 2.0
const SURGE_WARN_SECONDS := 1.0
const SURGE_SECONDS := 1.4
const SURGE_DAMAGE := 16.0
const SURGE_WIDTH := 0.7
const VENT_SECONDS := 3.5
const STALL_SECONDS := 6.0
## By stage (1, 2, 3): how long a quarter takes to fill; how far from the Lung the water's still
## shallow (beyond it, deep: 0 for none); how long it vents.
const STAGE_FILL: Array[float] = [1.2, 1.0, 0.85]
const STAGE_DEEP: Array[float] = [0.0, 4.0, 3.6]
const STAGE_VENT: Array[float] = [3.5, 3.5, 2.8]
## Standing in the deep water costs this much, this often (roll and it misses, like any hit).
const DEEP_DAMAGE := 6.0
const DEEP_TICK := 0.8
## The Marrow's edge in stage 3: past this, you see it as fog.
const MARROW_CLEAR_TILES := 2.6
const LINES: Dictionary[Quarter, String] = {
	Quarter.LEFT: "lung_left", Quarter.RIGHT: "lung_right", Quarter.NEAR: "lung_near", Quarter.FAR: "lung_far",
}

## Each warning, and how soon after it's called its hazard lands (seconds): the flood, the surge
## leaving the Lung. It has to be said by then.
## Its quarters are called in stages 1 and 2 only (the Marrow hides stage 3 from the Steward), so their
## leads are stage 2's, the shorter. A stage's word is said while the fight is paused.
const WARN_LEADS: Dictionary[String, float] = {
	"lung_left": 1.0 + FLOOD_STRIKE, "lung_right": 1.0 + FLOOD_STRIKE,
	"lung_near": 1.0 + FLOOD_STRIKE, "lung_far": 1.0 + FLOOD_STRIKE,
	"lung_surge": SURGE_WARN_SECONDS,
	"lung_rise": Boss.STAGE_TRANSITION, "lung_marrow": Boss.STAGE_TRANSITION,
}
## Each call, and the soonest the next can come (seconds).
const CALL_GAPS: Dictionary[String, float] = {
	"lung_left": 1.0 + FLOOD_SECONDS, "lung_right": 1.0 + FLOOD_SECONDS,
	"lung_near": 1.0 + FLOOD_SECONDS, "lung_far": 1.0 + FLOOD_SECONDS,
	"lung_surge": SURGE_WARN_SECONDS + SURGE_SECONDS,
	"lung_vent": VENT_SECONDS,
	"lung_rise": Boss.STAGE_TRANSITION, "lung_marrow": Boss.STAGE_TRANSITION,
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
var _deep_in: float = 0.0


func _ready() -> void:
	super()
	boss_name = "THE LUNG"
	radius_tiles = 1.2
	# The Marrow's fog in stage 3, drawn over what stands round it (the Lung itself keeps its place).
	var fog := LungFog.new()
	fog.lung = self
	fog.z_index = 3
	add_child(fog)


## Stage 3's fog: thick past arm's reach.
class LungFog:
	extends Node2D
	var lung: Lung

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if lung == null or not lung.in_the_marrow() or not lung.is_alive():
			return
		for k: int in 5:
			var r := MARROW_CLEAR_TILES + k * 0.9
			var ring := PackedVector2Array()
			for i: int in 33:
				ring.append(Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * r))
			draw_polyline(ring, Color(Palette.FOG, 0.18), 34.0, true)


func is_vulnerable() -> bool:
	return phase == Phase.VENT or phase == Phase.STALLED


func stage_count() -> int:
	return 3


func stage_line(next_stage: int) -> String:
	return "lung_rise" if next_stage == 2 else "lung_marrow"


## Between stages it stops, and holds its breath.
func _on_stage_begins(_next_stage: int) -> void:
	phase = Phase.IDLE
	_phase_time = 0.0


func _on_stage(_now: int) -> void:
	_start_cycle()


## How long a quarter takes to fill in this stage, before reading the grates yourself muted.
func fill_seconds() -> float:
	return STAGE_FILL[stage - 1]


## Beyond this far from the Lung the basin's deep (0: it isn't).
func deep_tiles() -> float:
	return STAGE_DEEP[stage - 1]


## In stage 3 the Marrow is in: it can't see you, and the Steward can't see it.
func in_the_marrow() -> bool:
	return stage >= 3


## Whether a point (world) is out in the deep water.
func in_deep(at: Vector2) -> bool:
	if deep_tiles() <= 0.0:
		return false
	var d := Iso.ground_distance(global_position, at)
	# The basin's water, as drawn: not the quay beyond it, and nowhere below the street.
	var below := level != null and level.grid.floor_at(Iso.world_to_cell(at)) == LevelGrid.Floor.CULVERT
	return d > deep_tiles() and d <= DEEP_OUTER and not below


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
			# Muted you read the grates yourself (sooner); in the Marrow nobody calls it, so it's as if muted.
			_fill_for = fill_seconds() + (EARLY_FILL if not Steward.voice_on or in_the_marrow() else 0.0)
			var p := player()
			if p != null and _floods_left == FLOODS_PER_CYCLE and not in_the_marrow():
				quarter = quarter_of(p.global_position)
			else:
				quarter = ((int(quarter) + 1 + randi() % 3) % 4) as Quarter
			if not in_the_marrow():
				call_out(LINES[quarter])
			Sound.play(&"windup", global_position)
		Phase.FLOOD:
			Sound.play(&"tide_swell", global_position)
		Phase.SURGE_WARN:
			if not in_the_marrow():
				call_out("lung_surge")
			Sound.play(&"windup", global_position)
		Phase.SURGE:
			Sound.play(&"carriage_run", global_position)
		Phase.VENT:
			if not in_the_marrow():
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


## A quarter's flooding square, in grid space relative to the Lung: both the warning drawn and the
## water that hurts.
static func flood_rect(q: Quarter) -> Rect2:
	var sg := quarter_signs(q) * FLOOD_TILES
	return Rect2(Vector2(minf(sg.x, 0.0), minf(sg.y, 0.0)), sg.abs())


## Whether a point (world) is in the basin quarter that's flooding.
func in_flood(at: Vector2) -> bool:
	var rel := Iso.world_to_grid(at) - Iso.world_to_grid(global_position)
	var r := flood_rect(quarter)
	return quarter_of(at) == quarter and rel.x >= r.position.x and rel.x <= r.end.x and rel.y >= r.position.y and rel.y <= r.end.y


## The surge's ring: how far out it is now (tiles).
func surge_radius() -> float:
	return lerpf(radius_tiles, BASIN_TILES, clampf(_phase_time / SURGE_SECONDS, 0.0, 1.0))


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	var player_ok := p != null and p.is_alive()
	# The deep water past the shallows wears you down while you stand in it.
	if player_ok and in_deep(p.global_position):
		_deep_in += delta
		if _deep_in >= DEEP_TICK:
			_deep_in = 0.0
			p.take_hit(DEEP_DAMAGE, global_position)
	else:
		_deep_in = 0.0
	match phase:
		Phase.FILL:
			if _phase_time >= _fill_for:
				_floods_left -= 1
				_enter_phase(Phase.FLOOD)
		Phase.FLOOD:
			if not _struck and _phase_time >= FLOOD_STRIKE and player_ok and in_flood(p.global_position):
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
			if _phase_time >= STAGE_VENT[stage - 1]:
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
	if state != State.DEAD:
		_breath_phase = fposmod(_breath_phase + delta * (6.0 if is_vulnerable() else 1.6), TAU)
	queue_redraw()


func _draw() -> void:
	draw_shadow(58.0, 26.0)
	var tint := Color.WHITE * (1.0 + hit_flash())
	var breath := sin(_breath_phase) * 8.0
	ArtCatalog.paint(self, "lung", Rect2(-50, -96, 100, 114), tint)
	ArtCatalog.paint(self, "lung_bellows", Rect2(-30, -128 - breath, 60, 44 + breath), tint)
	# Its gauge: the Steward's (gold); open, the needle drops and it glows.
	var gauge := Vector2(0, -58)
	var needle := Vector2(0, -6).rotated(-0.7 if is_vulnerable() else 0.7)
	draw_line(gauge, gauge + needle, Palette.STEWARD_GOLD_HOT, 1.5, true)
	draw_circle(gauge, 2.0, Palette.STEWARD_GOLD_HOT if is_vulnerable() else Palette.STEWARD_GOLD, true, -1.0, true)
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
	# The tide up: the deep water past the shallows, its edge in red-orange.
	if deep_tiles() > 0.0:
		# Deep water like the tide's: dark, with a sheen on it.
		_band(deep_tiles(), DEEP_OUTER, Color(Palette.WATER_DEEP, 0.7))
		for k: int in 4:
			_ring(deep_tiles() + 0.45 + k * 0.6, Color(Palette.WATER_SHEEN, 0.75 - k * 0.12))
		_ring(deep_tiles(), Color(Palette.DANGER, 0.6))
	# Between stages: a swell rings out from it (no flash).
	if in_transition():
		var k := 1.0 - _transition_left / Boss.STAGE_TRANSITION
		_ring(lerpf(radius_tiles, BASIN_TILES, k), Color(Palette.WATER_SHEEN, 0.7 * (1.0 - k)))


## The quarter that's filling, as its square of the basin on the ground (local points).
func _quarter_points() -> PackedVector2Array:
	var r := flood_rect(quarter)
	return PackedVector2Array([Iso.grid_to_world(r.position), Iso.grid_to_world(Vector2(r.end.x, r.position.y)), Iso.grid_to_world(r.end), Iso.grid_to_world(Vector2(r.position.x, r.end.y))])


func _quarter_outline(col: Color) -> void:
	var pts := _quarter_points()
	pts.append(pts[0])
	draw_polyline(pts, col, 3.0, true)


func _quarter_fill(col: Color) -> void:
	draw_colored_polygon(_quarter_points(), col)


## The ground between two circles round the Lung, filled.
func _band(inner: float, outer: float, col: Color) -> void:
	for i: int in 32:
		var a0 := Vector2.from_angle(TAU * i / 32.0)
		var a1 := Vector2.from_angle(TAU * (i + 1) / 32.0)
		draw_colored_polygon(PackedVector2Array([Iso.grid_to_world(a0 * inner), Iso.grid_to_world(a0 * outer), Iso.grid_to_world(a1 * outer), Iso.grid_to_world(a1 * inner)]), col)


## A circle of `tiles` radius round the Lung, on the ground.
func _ring(tiles: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		pts.append(Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * tiles))
	draw_polyline(pts, col, 3.0, true)
