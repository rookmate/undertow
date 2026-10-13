class_name Editor
extends Boss
## The Vellum's boss: the press-room unit that prints and pulps the same page forever (the page the Post
## never printed: BRIDGE WARNING IGNORED, SAYS AUDITOR). Its rollers sweep the press hall's floor, one
## from the press toward the door, then one across, each with a gap to stand in (the Steward calls them
## and lights the gap); it pulps the page; it turns the Feed on you (look away: FeedBlind) and throws the
## bales it made; then it re-inks, open to blows. The manual solution: knock the bale stack into the
## pulper while it's pulping, and it jams.
## Three stages (DECISIONS 184): at two thirds its rollers leave the headlines wet behind them, pools of
## ink on the floor that sting you while you stand in them; at one third its presses run backwards (the
## rollers come back from the door toward it), three rolls a cycle.

enum Phase { IDLE, ROLL_WARN, ROLL, PULP, FEED_WARN, FEED, INK, JAMMED }
## Which way a roller runs: from the press toward the door (down the grid's y), or across the hall
## (along its x).
enum Sweep { DOWN, ACROSS }

const MAX_INTEGRITY := 420.0
## The hall the rollers sweep, in cells from the Editor's own: x from -HALF_WIDTH to +HALF_WIDTH, y from
## BACK to FRONT.
const HALF_WIDTH := 4
const BACK := -1
const FRONT := 8
const ROLLS_PER_CYCLE := 2
const ROLL_WARN_SECONDS := 1.4
## Muted, you read the roller yourself: its track shows this much sooner.
const EARLY_WARN := 0.3
const ROLL_SECONDS := 1.8
const ROLL_DAMAGE := 16.0
## Half the roller's thickness (tiles), and the gap left in it (cells).
const ROLLER_HALF := 0.5
const GAP_CELLS := 2
## How far along the roller the gap opens from where you stand (tiles): you have to move, and can.
const GAP_NEAR := 2.0
const GAP_FAR := 4.0
const PULP_SECONDS := 1.6
const FEED_WARN_SECONDS := 1.0
const FEED_SECONDS := 0.6
const FEED_REACH := 12.0
const FEED_BLIND := 2.0
const BALES := 3
const BALE_SPREAD_DEG := 18.0
const BALE_DAMAGE := 10.0
const BALE_SPEED := 6.5
const INK_SECONDS := 3.5
const JAM_SECONDS := 6.0
## Stage 2: pools of ink left after each roll, how long they stay wet, what they do.
const INK_POOLS := 3
const INK_POOL_SECONDS := 8.0
const INK_POOL_DAMAGE := 5.0
const INK_POOL_TICK := 0.6

## Each warning, and how soon after it's called its hazard lands (seconds): the rollers setting off,
## the Feed. It has to be said by then.
const WARN_LEADS: Dictionary[String, float] = {
	"editor_rollers": ROLL_WARN_SECONDS,
	"editor_feed": FEED_WARN_SECONDS,
	"editor_headlines": Boss.STAGE_TRANSITION,
	"editor_backwards": Boss.STAGE_TRANSITION,
}
## Each call, and the soonest the next can come (seconds).
const CALL_GAPS: Dictionary[String, float] = {
	"editor_rollers": ROLL_WARN_SECONDS + ROLL_SECONDS,
	"editor_feed": FEED_WARN_SECONDS + FEED_SECONDS,
	"editor_ink": INK_SECONDS,
	"editor_headlines": Boss.STAGE_TRANSITION,
	"editor_backwards": Boss.STAGE_TRANSITION,
}

var phase: Phase = Phase.IDLE
var sweep: Sweep = Sweep.DOWN
## Across the hall, which way the roller runs along x (+1 or -1); it turns about each cycle.
var across_dir: int = -1
## The gap's first cell along the roller (grid x for DOWN, grid y for ACROSS), GAP_CELLS wide.
var gap_start: int = 0
## Times jammed with the bale stack (the manual solution).
var jams: int = 0

var _phase_time: float = 0.0
var _warn_for: float = ROLL_WARN_SECONDS
var _struck: bool = false
var _rolls_left: int = 0
var _jammed_this_cycle: bool = false
## Stage 2 on: wet ink on the floor (cell -> seconds left).
var ink_pools: Dictionary[Vector2i, float] = {}
var _ink_tick: float = 0.0


func _ready() -> void:
	super()
	boss_name = "THE EDITOR"
	radius_tiles = 1.1


func is_vulnerable() -> bool:
	return phase == Phase.INK or phase == Phase.JAMMED


func stage_count() -> int:
	return 3


func stage_line(next_stage: int) -> String:
	return "editor_headlines" if next_stage == 2 else "editor_backwards"


func _on_stage_begins(_next_stage: int) -> void:
	phase = Phase.IDLE
	_phase_time = 0.0


func _on_stage(_now: int) -> void:
	_start_cycle()


## Stage 3: its presses run backwards.
func backwards() -> bool:
	return stage >= 3


func in_ink(at: Vector2) -> bool:
	return ink_pools.has(Iso.world_to_cell(at))


## Pulping the page: the window for the bale stack.
func is_switching() -> bool:
	return phase == Phase.PULP


func _on_engaged() -> void:
	_start_cycle()


func _start_cycle() -> void:
	_rolls_left = ROLLS_PER_CYCLE + (1 if backwards() else 0)
	_jammed_this_cycle = false
	sweep = Sweep.DOWN
	_enter_phase(Phase.ROLL_WARN)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_struck = false
	match next:
		Phase.ROLL_WARN:
			_warn_for = ROLL_WARN_SECONDS + (EARLY_WARN if not Steward.voice_on else 0.0)
			_pick_gap()
			call_out("editor_rollers")
			Sound.play(&"windup", global_position)
		Phase.ROLL:
			Sound.play(&"press_roll", global_position)
		Phase.PULP:
			Sound.play(&"pulp_churn", global_position)
		Phase.FEED_WARN:
			call_out("editor_feed")
			Sound.play(&"windup", global_position)
		Phase.FEED:
			Sound.play(&"feed_flash", global_position)
			if level != null:
				level.flash_feed(global_position, FEED_REACH, FEED_BLIND)
			_throw_bales()
		Phase.INK:
			call_out("editor_ink")
			Sound.play(&"vent_hiss", global_position)
		Phase.JAMMED:
			Sound.play(&"container_drop", global_position)


# --- The rollers (grid space) ------------------------------------------------------------------------
## The hall the rollers sweep, whole cells.
func hall() -> Rect2:
	var c := grid_cell()
	return Rect2(Vector2(c.x - HALF_WIDTH, c.y + BACK), Vector2(HALF_WIDTH * 2 + 1, FRONT - BACK + 1))


## The roller's length runs from `lo` to `hi` (x for DOWN, y for ACROSS).
func roller_span() -> Vector2:
	var h := hall()
	return Vector2(h.position.x, h.end.x) if sweep == Sweep.DOWN else Vector2(h.position.y, h.end.y)


## Where its run starts and ends (y for DOWN, x for ACROSS). Down the hall, it comes out of the press.
func run_span() -> Vector2:
	var h := hall()
	var run: Vector2
	if sweep == Sweep.DOWN:
		run = Vector2(grid_cell().y + 1.0, h.end.y)
	else:
		run = Vector2(h.end.x, h.position.x) if across_dir < 0 else Vector2(h.position.x, h.end.x)
	# Backwards (stage 3): the same run, the other way.
	return Vector2(run.y, run.x) if backwards() else run


## Where the roller is now along its run.
func roller_at() -> float:
	var run := run_span()
	var k := clampf(_phase_time / ROLL_SECONDS, 0.0, 1.0) if phase == Phase.ROLL else 0.0
	return lerpf(run.x, run.y, k)


## A grid point's place along the roller's length, and along its run.
func _along(g: Vector2) -> float:
	return g.x if sweep == Sweep.DOWN else g.y


func _run_of(g: Vector2) -> float:
	return g.y if sweep == Sweep.DOWN else g.x


func in_gap(g: Vector2) -> bool:
	var a := _along(g)
	return a >= gap_start and a < gap_start + GAP_CELLS


## The roller, where it is now, runs over this grid point.
func roller_over(g: Vector2) -> bool:
	var span := roller_span()
	var a := _along(g)
	if a < span.x or a >= span.y or in_gap(g):
		return false
	return absf(_run_of(g) - roller_at()) <= ROLLER_HALF


## A gap you have to move to and can reach: GAP_NEAR to GAP_FAR tiles from where you stand, along the
## roller (anywhere, if there's nowhere like that).
func _pick_gap() -> void:
	var span := roller_span()
	var lo := int(span.x)
	var hi := int(span.y) - GAP_CELLS
	var at := (span.x + span.y) * 0.5
	var p := player()
	if p != null:
		at = _along(Iso.world_to_grid(p.global_position))
	var picks: Array[int] = []
	for s: int in range(lo, hi + 1):
		var d := absf(s + GAP_CELLS * 0.5 - at)
		if d >= GAP_NEAR and d <= GAP_FAR:
			picks.append(s)
	gap_start = int(picks.pick_random()) if not picks.is_empty() else randi_range(lo, hi)


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	var player_ok := p != null and p.is_alive()
	# The wet ink: it dries, and while it's wet it stings whoever stands in it.
	for c: Vector2i in ink_pools.keys():
		ink_pools[c] -= delta
		if ink_pools[c] <= 0.0:
			ink_pools.erase(c)
	_ink_tick -= delta
	if player_ok and in_ink(p.global_position) and _ink_tick <= 0.0:
		_ink_tick = INK_POOL_TICK
		p.take_hit(INK_POOL_DAMAGE, p.global_position)
	match phase:
		Phase.ROLL_WARN:
			if _phase_time >= _warn_for:
				_enter_phase(Phase.ROLL)
		Phase.ROLL:
			if not _struck and player_ok:
				var g := Iso.world_to_grid(p.global_position)
				if roller_over(g):
					var behind := g - (Vector2(0, 1) if sweep == Sweep.DOWN else Vector2(across_dir, 0))
					# take_hit misses mid-roll: roll through it.
					if p.take_hit(ROLL_DAMAGE, Iso.grid_to_world(behind)) or p.is_invulnerable():
						_struck = true
			if _phase_time >= ROLL_SECONDS:
				_rolls_left -= 1
				if stage >= 2:
					_spill_ink()
				if _rolls_left > 0:
					sweep = Sweep.ACROSS if sweep == Sweep.DOWN else Sweep.DOWN
					across_dir = -across_dir
					_enter_phase(Phase.ROLL_WARN)
				else:
					_enter_phase(Phase.PULP)
		Phase.PULP:
			if _phase_time >= PULP_SECONDS:
				_enter_phase(Phase.FEED_WARN)
		Phase.FEED_WARN:
			if _phase_time >= FEED_WARN_SECONDS:
				_enter_phase(Phase.FEED)
		Phase.FEED:
			if _phase_time >= FEED_SECONDS:
				_enter_phase(Phase.INK)
		Phase.INK:
			if _phase_time >= INK_SECONDS:
				_start_cycle()
		Phase.JAMMED:
			if _phase_time >= JAM_SECONDS:
				_start_cycle()


## Stage 2 on: the headlines left wet behind the roller, a few pools of ink on the hall floor (never on
## the Editor, never in the gap you stood in).
func _spill_ink() -> void:
	var h := hall()
	var tries := 0
	var spilled := 0
	while spilled < INK_POOLS and tries < 40:
		tries += 1
		var c := Vector2i(randi_range(int(h.position.x), int(h.end.x) - 1), randi_range(int(h.position.y) + 2, int(h.end.y) - 1))
		if level == null or not level.grid.is_walkable(c) or in_gap(Vector2(c)) or ink_pools.has(c):
			continue
		ink_pools[c] = INK_POOL_SECONDS
		spilled += 1


## The bales it made of the page, thrown in a fan at you.
func _throw_bales() -> void:
	var p := player()
	if p == null or level == null:
		return
	var aim := Iso.ground_dir_between(global_position, p.global_position)
	for k: int in BALES:
		var bale := Projectile.new()
		bale.team = Projectile.Team.ENEMY
		bale.level = level
		bale.direction = aim.rotated(deg_to_rad(BALE_SPREAD_DEG * (k - (BALES - 1) * 0.5)))
		bale.speed_tiles = BALE_SPEED
		bale.damage = BALE_DAMAGE
		bale.radius_tiles = 0.35
		bale.max_tiles = FEED_REACH
		bale.color = Palette.PAPER
		bale.size = 14.0
		bale.tumbling = true
		bale.position = global_position + Iso.ground_velocity(bale.direction, radius_tiles + 0.3)
		level.world.add_child(bale)


## The bale stack knocked into the pulper while it pulps: it jams (once a cycle).
func on_weak_point_hit() -> void:
	if not is_switching() or _jammed_this_cycle or state == State.DEAD:
		return
	_jammed_this_cycle = true
	jams += 1
	_enter_phase(Phase.JAMMED)


func _die() -> void:
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


## A grid offset from the Editor's feet, on screen (local).
func _g(x: float, y: float, up: float = 0.0) -> Vector2:
	return Iso.grid_to_world(Vector2(x, y)) + Vector2(0, -up)


func _draw() -> void:
	draw_shadow(78.0, 34.0)
	var flash := hit_flash()
	var body := Palette.NEWS_DESK.lightened(0.18).lerp(Palette.IVORY, flash)
	var open := is_vulnerable()
	var h := 92.0
	var ex := 1.0
	var ey := 0.55
	# The press: a long iron body along the hall's width.
	draw_colored_polygon(PackedVector2Array([_g(-ex, ey), _g(ex, ey), _g(ex, ey, h), _g(-ex, ey, h)]), body.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([_g(ex, -ey), _g(ex, ey), _g(ex, ey, h), _g(ex, -ey, h)]), body.darkened(0.45))
	draw_colored_polygon(PackedVector2Array([_g(-ex, -ey, h), _g(ex, -ey, h), _g(ex, ey, h), _g(-ex, ey, h)]), body)
	# Its rollers on top: inked black, lifted clear while it re-inks.
	var lift := 16.0 if open else 0.0
	for y: float in [-0.22, 0.22]:
		var a := _g(-ex * 0.9, y, h + 12.0 + lift)
		var b := _g(ex * 0.9, y, h + 12.0 + lift)
		draw_line(a, b, Palette.BLACK_MIRROR, 20.0, true)
		draw_line(a + Vector2(0, -7), b + Vector2(0, -7), Palette.IRON_DARK.lightened(0.3), 3.0, true)
	# The page running out of it, down its face to the floor.
	var web_top := _g(-0.35, ey, h)
	var web_low := _g(0.35, ey, h)
	draw_colored_polygon(PackedVector2Array([web_top, web_low, _g(0.35, ey + 0.6), _g(-0.35, ey + 0.6)]), Palette.PAPER)
	for k: int in 3:
		var t := 0.25 + k * 0.2
		draw_line(web_top.lerp(_g(-0.35, ey + 0.6), t) + Vector2(6, 0), web_low.lerp(_g(0.35, ey + 0.6), t) - Vector2(6, 0), Color(Palette.NEAR_BLACK, 0.5), 2.0, true)
	# Its screen, on the near face: the Feed, whitening as it turns it on you.
	var screen_col := Palette.BLACK_MIRROR
	if phase == Phase.FEED_WARN:
		screen_col = Palette.BLACK_MIRROR.lerp(Palette.FEED_WHITE, clampf(_phase_time / FEED_WARN_SECONDS, 0.0, 1.0))
	elif phase == Phase.FEED:
		screen_col = Palette.FEED_WHITE
	draw_colored_polygon(PackedVector2Array([_g(-0.9, ey, 24.0), _g(-0.45, ey, 24.0), _g(-0.45, ey, 76.0), _g(-0.9, ey, 76.0)]), screen_col)
	# Its editorial core, on the far face: the Steward's (gold); open, it burns hot.
	draw_circle(_g(ex, 0.0, 52.0), 9.0, Palette.IRON_DARK, true, -1.0, true)
	draw_circle(_g(ex, 0.0, 52.0), 5.5, Palette.STEWARD_GOLD_HOT if open else Palette.STEWARD_GOLD, true, -1.0, true)
	if phase == Phase.PULP or phase == Phase.JAMMED:
		# Shreds of the page going into the pulper (or stuck in it).
		for k: int in 4:
			var at := _g(-ex - 0.2, -0.3 + k * 0.15, 30.0 + float(k * 7) - fmod(_phase_time * 40.0, 20.0))
			draw_rect(Rect2(at, Vector2(8, 5)), Palette.PAPER)
