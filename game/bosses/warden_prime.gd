class_name WardenPrime
extends Boss
## Harbor Ward's boss, at the border: the curfew enforcer, the Warden network's own (world bible). Its
## searchlight sweeps the border plaza: caught in the beam a moment, you're marked and it fires a volley
## at you. Then it lines up a charge and rams across the plaza: step aside, and if it hits a wall it's
## dazed and open. The manual solution: strike the relay mast that links it while it sweeps, and it
## loses its link and stalls.
## Three stages (DECISIONS 184): at two thirds it calls two Wardens in off the border and its light
## sweeps faster; at one third the relay mast burns out (no stalling it now): blind, it stops sweeping
## and comes at you, charge after charge.

enum Phase { IDLE, SWEEP, VOLLEY, CHARGE_WARN, CHARGE, RECOVER, DAZED, STALLED }

const MAX_INTEGRITY := 440.0
const SWEEP_SECONDS := 3.2
const LIGHT_TILES := 8.0
const LIGHT_DEG := 40.0
## The beam swings across this much, centred on where you stood when it began.
const SWEEP_SPAN_DEG := 130.0
## In the beam this long, all told, and you're marked.
const MARK_SECONDS := 0.7
const VOLLEY_WARN := 0.5
const VOLLEY_SHOTS := 3
const VOLLEY_GAP := 0.3
const BOLT_DAMAGE := 11.0
const BOLT_SPEED := 9.0
const CHARGE_WARN_SECONDS := 1.1
## Muted, you read it yourself: the line shows this much sooner.
const EARLY_WARN := 0.3
const CHARGE_SPEED := 9.0
const CHARGE_TILES := 9.0
const CHARGE_DAMAGE := 20.0
const RECOVER_SECONDS := 0.9
const DAZE_SECONDS := 3.5
const STALL_SECONDS := 6.0
## Stage 2: its light's sweep; stage 3: its charges' warning.
const CALLED_SWEEP := 2.6
const BLIND_CHARGE_WARN := 1.0

## Each warning, and how soon after it's called its hazard lands (seconds): the volley (once you've
## been in the beam long enough), the charge.
const WARN_LEADS: Dictionary[String, float] = {
	"warden_prime_light": MARK_SECONDS + VOLLEY_WARN,
	"warden_prime_charge": BLIND_CHARGE_WARN,
	"warden_prime_called": Boss.STAGE_TRANSITION,
	"warden_prime_blind": Boss.STAGE_TRANSITION,
}
## Each call, and the soonest the next can come (seconds): after the light, a volley and then the charge;
## after the charge, a wall at once (dazed).
const CALL_GAPS: Dictionary[String, float] = {
	"warden_prime_light": MARK_SECONDS + VOLLEY_WARN + VOLLEY_SHOTS * VOLLEY_GAP,
	"warden_prime_charge": BLIND_CHARGE_WARN,
	"warden_prime_dazed": DAZE_SECONDS,
	"warden_prime_called": Boss.STAGE_TRANSITION,
	"warden_prime_blind": Boss.STAGE_TRANSITION,
}

var phase: Phase = Phase.IDLE
## Times stalled through the relay mast (the manual solution).
var stalls: int = 0
## The searchlight's direction now (ground), and the charge's line.
var beam_dir: Vector2 = Vector2(0, -1)
var charge_dir: Vector2 = Vector2(0, -1)

var _phase_time: float = 0.0
var _warn_for: float = CHARGE_WARN_SECONDS
var _in_light: float = 0.0
var _sweep_from: float = 0.0
var _shots_left: int = 0
var _shot_in: float = 0.0
var _charged: float = 0.0
var _struck: bool = false
var _stalled_this_cycle: bool = false


func _ready() -> void:
	super()
	boss_name = "THE WARDEN-PRIME"
	radius_tiles = 0.9


func is_vulnerable() -> bool:
	return phase == Phase.DAZED or phase == Phase.STALLED


func stage_count() -> int:
	return 3


func stage_line(next_stage: int) -> String:
	return "warden_prime_called" if next_stage == 2 else "warden_prime_blind"


func _on_stage_begins(next_stage: int) -> void:
	phase = Phase.IDLE
	_phase_time = 0.0
	if next_stage == 2 and level != null:
		# Two Wardens in off the border, hunting you (gone with it if the fight starts over).
		var b := level.grid.first("B")
		for off: Vector2i in [Vector2i(-4, -1), Vector2i(4, -1)]:
			var c := b + off
			if not level.grid.is_walkable(c):
				continue
			var w := level.spawn_kind("warden", c)
			if w != null:
				w.add_to_group(&"boss_parts")
	if next_stage == 3 and weak_point != null and is_instance_valid(weak_point):
		# The relay mast burns out: no stalling it now.
		weak_point.retire()


func _on_stage(_now: int) -> void:
	_enter_phase(Phase.CHARGE_WARN if blind() else Phase.SWEEP)


## Stage 3: the mast's gone; it doesn't sweep, it comes at you.
func blind() -> bool:
	return stage >= 3


func sweep_seconds() -> float:
	return CALLED_SWEEP if stage >= 2 else SWEEP_SECONDS


## Sweeping: the window for the relay mast.
func is_switching() -> bool:
	return phase == Phase.SWEEP


## It's the Steward's: it sees you only on its Lattice (in the Ward, the border and the plaza past it),
## never out on the Wardfolk's lanes across the fence, however close (DECISIONS 191).
func _may_engage(p: Operator) -> bool:
	return level != null and level.grid.is_indexed(p.cell())


func _on_engaged() -> void:
	_enter_phase(Phase.SWEEP)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_struck = false
	var p := player()
	match next:
		Phase.SWEEP:
			_stalled_this_cycle = false
			_in_light = 0.0
			var at := Iso.ground_dir_between(global_position, p.global_position) if p != null else beam_dir
			_sweep_from = at.angle() - deg_to_rad(SWEEP_SPAN_DEG * 0.5)
			beam_dir = Vector2.from_angle(_sweep_from)
			call_out("warden_prime_light")
			Sound.play(&"warden_alert", global_position)
		Phase.VOLLEY:
			_shots_left = VOLLEY_SHOTS
			_shot_in = VOLLEY_WARN
		Phase.CHARGE_WARN:
			_warn_for = (BLIND_CHARGE_WARN if blind() else CHARGE_WARN_SECONDS) + (EARLY_WARN if not Steward.voice_on else 0.0)
			_aim_charge()
			call_out("warden_prime_charge")
			Sound.play(&"windup", global_position)
		Phase.CHARGE:
			_charged = 0.0
			Sound.play(&"carriage_run", global_position)
		Phase.DAZED:
			call_out("warden_prime_dazed")
			Sound.play(&"container_drop", global_position)


func _aim_charge() -> void:
	var p := player()
	if p != null and Iso.ground_distance(global_position, p.global_position) > 0.2:
		charge_dir = Iso.ground_dir_between(global_position, p.global_position)


## The beam has a point (world) in it: in its cone and in plain sight.
func in_light(at: Vector2) -> bool:
	return phase == Phase.SWEEP and CombatMath.in_arc(global_position, beam_dir, at, LIGHT_TILES, LIGHT_DEG) \
		and level != null and level.grid.line_clear(global_position, at)


func _think(delta: float) -> Vector2:
	super(delta)
	if is_fighting and phase == Phase.CHARGE:
		return Iso.ground_velocity(charge_dir, CHARGE_SPEED)
	return Vector2.ZERO


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	var player_ok := p != null and p.is_alive()
	match phase:
		Phase.SWEEP:
			var k := clampf(_phase_time / sweep_seconds(), 0.0, 1.0)
			beam_dir = Vector2.from_angle(_sweep_from + deg_to_rad(SWEEP_SPAN_DEG) * k)
			if player_ok and in_light(p.global_position):
				_in_light += delta
				if _in_light >= MARK_SECONDS:
					_enter_phase(Phase.VOLLEY)
					return
			if _phase_time >= sweep_seconds():
				_enter_phase(Phase.CHARGE_WARN)
		Phase.VOLLEY:
			_shot_in -= delta
			if _shot_in <= 0.0 and _shots_left > 0:
				_shots_left -= 1
				_shot_in = VOLLEY_GAP
				_fire_bolt()
			if _shots_left == 0 and _shot_in <= 0.0:
				_enter_phase(Phase.CHARGE_WARN)
		Phase.CHARGE_WARN:
			if _phase_time < _warn_for * 0.7:
				_aim_charge()
			if _phase_time >= _warn_for:
				_enter_phase(Phase.CHARGE)
		Phase.CHARGE:
			_charged += CHARGE_SPEED * delta
			if not _struck and player_ok and Iso.ground_distance(global_position, p.global_position) <= radius_tiles + 0.35:
				# take_hit misses mid-roll: roll through it.
				if p.take_hit(CHARGE_DAMAGE, global_position) or p.is_invulnerable():
					_struck = true
			if get_slide_collision_count() > 0 and _phase_time > 0.05:
				_enter_phase(Phase.DAZED)
			elif _charged >= CHARGE_TILES:
				_enter_phase(Phase.RECOVER)
		Phase.RECOVER:
			if _phase_time >= RECOVER_SECONDS:
				_enter_phase(Phase.CHARGE_WARN if blind() else Phase.SWEEP)
		Phase.DAZED:
			if _phase_time >= DAZE_SECONDS:
				_enter_phase(Phase.CHARGE_WARN if blind() else Phase.SWEEP)
		Phase.STALLED:
			if _phase_time >= STALL_SECONDS:
				_enter_phase(Phase.SWEEP)


func _fire_bolt() -> void:
	var p := player()
	if p == null or level == null:
		return
	var bolt := Projectile.new()
	bolt.team = Projectile.Team.ENEMY
	bolt.level = level
	bolt.direction = Iso.ground_dir_between(global_position, p.global_position)
	bolt.speed_tiles = BOLT_SPEED
	bolt.damage = BOLT_DAMAGE
	bolt.radius_tiles = 0.25
	bolt.max_tiles = 12.0
	bolt.color = Palette.DANGER
	bolt.size = 8.0
	bolt.position = global_position + Iso.ground_velocity(bolt.direction, radius_tiles + 0.2)
	level.world.add_child(bolt)
	Sound.play(&"warden_strike", global_position)


## The relay mast struck while it sweeps: it loses its link and stalls (once a cycle).
func on_weak_point_hit() -> void:
	if not is_switching() or _stalled_this_cycle or state == State.DEAD:
		return
	_stalled_this_cycle = true
	stalls += 1
	_enter_phase(Phase.STALLED)


func _die() -> void:
	# The Wardens it called in are linked through it: they drop with it.
	for n: Node in get_tree().get_nodes_in_group(&"boss_parts"):
		if n is Warden and (n as Warden).is_alive() and level != null and level.is_ancestor_of(n):
			n.call(&"_die")
	super()
	Narrator.notify(&"boss_down", level.level_id if level != null else "")


func _draw() -> void:
	# Its searchlight on the ground: the Steward's light (gold), edged in danger once it's on you.
	if phase == Phase.SWEEP:
		var pts := PackedVector2Array([Vector2.ZERO])
		var half := deg_to_rad(LIGHT_DEG * 0.5)
		for k: int in 11:
			pts.append(Iso.grid_to_world(Vector2.from_angle(beam_dir.angle() - half + half * 2.0 * k / 10.0) * LIGHT_TILES))
		draw_colored_polygon(pts, Color(Palette.STEWARD_GOLD, 0.14))
		var edge := pts.duplicate()
		edge.append(pts[0])
		draw_polyline(edge, Color(Palette.DANGER if _in_light > 0.0 else Palette.STEWARD_GOLD, 0.55), 2.0, true)
	if phase == Phase.VOLLEY or (phase == Phase.CHARGE_WARN):
		var p := player()
		if p != null:
			var d := Iso.ground_dir_between(global_position, p.global_position) if phase == Phase.VOLLEY else charge_dir
			var reach := 6.0 if phase == Phase.VOLLEY else CHARGE_TILES
			var k := clampf(_phase_time / (VOLLEY_WARN if phase == Phase.VOLLEY else _warn_for), 0.0, 1.0)
			draw_line(Vector2.ZERO, Iso.grid_to_world(d * reach), Color(Palette.DANGER, 0.3 + 0.5 * k), 3.0 + 4.0 * k, true)
	draw_shadow(46.0, 20.0)
	var tint := Color.WHITE * (1.0 + hit_flash())
	var reel := 0.0 if phase != Phase.DAZED else sin(_phase_time * 9.0) * 6.0
	var body_facing := charge_dir if phase in [Phase.CHARGE_WARN, Phase.CHARGE] else beam_dir
	var joints := PaintedBiped.paint(self, "warden_prime", gait, body_facing, 112.0, hit_flash())
	var mast_bounds := Rect2(-15 + reel, -168 + gait.bob(), 30, 58)
	ArtCatalog.slice(self, "warden_mast", Rect2(mast_bounds.position + Vector2(0, 15), Vector2(30, 43)), Rect2(0, 0.26, 1, 0.74))
	var pivot := Vector2(reel, -153 + gait.bob())
	var lamp_dir := Iso.grid_to_world(beam_dir if phase == Phase.SWEEP else body_facing).normalized()
	var lens := pivot + lamp_dir * 12.0
	PaintedParts.segment(self, "warden_mast_head", pivot, lens, 12.0, tint)
	var lamp := Palette.STEWARD_GOLD_HOT if phase == Phase.SWEEP else Palette.GREY_DEEP
	draw_circle(lens, 4.0, lamp, true, -1.0, true)
	var eye := Palette.GREY_DEEP if is_vulnerable() else Palette.DANGER_HOT
	draw_circle(joints["eye"], 3.0, eye, true, -1.0, true)
