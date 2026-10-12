class_name SignalJammer
extends Weapon
## Hand-built in Harbor Ward out of old jammer parts, taped in cyan, no asset tag: the one tool that isn't
## the city's. It jams machines: one it catches stops dead for a while, and a Warden loses you. Tuned:
## the Steward points it at the nearest machine and pulses, a short stun. Manual: hold to charge, release
## a jamming wave all round you, wider and longer the longer you held. Its pulse trips a boss's weak
## point from range, too (it strikes whatever machine it catches).

const TUNED_DELAY := 0.2
const TUNED_REACH := 4.5
const TUNED_ARC_DEG := 34.0
const TUNED_STUN := 1.4
const TUNED_DAMAGE := 10.0
const TUNED_COOLDOWN := 1.6

const CHARGE_FULL := 1.2
const WAVE_MIN := 1.4
const WAVE_MAX := 4.0
const STUN_MIN := 0.8
const STUN_MAX := 3.0
const DAMAGE_MIN := 6.0
const DAMAGE_MAX := 16.0
const MANUAL_COOLDOWN := 2.2

## Manual: seconds held (-1 when not charging).
var charge: float = -1.0
var _cooldown: float = 0.0
## Tuned: seconds until the pulse goes (-1 when none is coming).
var _pending: float = -1.0


func _ready() -> void:
	material = Emissive.unshaded_material()


func _tick(delta: float, pressed: bool, held: bool, released: bool) -> void:
	_cooldown -= delta
	if is_tuned():
		charge = -1.0
		if _pending >= 0.0:
			_pending -= delta
			if _pending < 0.0:
				_pulse_ahead()
		elif pressed and _cooldown <= 0.0:
			_pending = TUNED_DELAY
	else:
		_pending = -1.0
		if charge < 0.0:
			if pressed and _cooldown <= 0.0:
				charge = 0.0
		else:
			charge = minf(charge + delta, CHARGE_FULL)
			if released or not held:
				_wave(charge / CHARGE_FULL)
	queue_redraw()


func _idle(delta: float) -> void:
	_cooldown -= delta
	charge = -1.0
	_pending = -1.0
	queue_redraw()


## Tuned: a narrow pulse at the nearest machine the Steward will aim at.
func _pulse_ahead() -> void:
	_cooldown = TUNED_COOLDOWN
	var dir := attack_direction(TUNED_REACH)
	Sound.play(&"jammer_pulse", player.global_position)
	for e: Enemy in _machines_in(TUNED_REACH):
		if CombatMath.in_arc(player.global_position, dir, e.global_position, TUNED_REACH, TUNED_ARC_DEG, e.radius_tiles):
			_jam(e, TUNED_DAMAGE, TUNED_STUN)
	var lv := level()
	if lv != null:
		var fx := Fx.spawn(lv.fx_ground, player.global_position, Fx.Shape.ARC, Color(Palette.WARD_CYAN_HOT, 0.9), 0.3)
		fx.radius_tiles = TUNED_REACH
		fx.facing = dir
		fx.arc_deg = TUNED_ARC_DEG
	announce_fired()


## Manual: a jamming wave all round you, `k` (0..1) as charged.
func _wave(k: float) -> void:
	charge = -1.0
	_cooldown = MANUAL_COOLDOWN
	var radius := lerpf(WAVE_MIN, WAVE_MAX, k)
	Sound.play(&"jammer_wave", player.global_position)
	for e: Enemy in _machines_in(radius):
		if Iso.ground_distance(player.global_position, e.global_position) <= radius + e.radius_tiles:
			_jam(e, lerpf(DAMAGE_MIN, DAMAGE_MAX, k), lerpf(STUN_MIN, STUN_MAX, k))
	var lv := level()
	if lv != null:
		var fx := Fx.spawn(lv.fx_ground, player.global_position, Fx.Shape.RING, Color(Palette.WARD_CYAN_HOT, 0.9), 0.45)
		fx.radius_tiles = radius
		fx.width = 6.0
	announce_fired()


## Machines in reach with nothing tall between (a boss's weak point among them).
func _machines_in(reach: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node2D in targets_in_range(reach + 0.6):
		out.append(n as Enemy)
	return out


## A machine caught by it: struck, and stopped dead (a Warden loses you, too).
func _jam(e: Enemy, damage: float, stun: float) -> void:
	var dir := Iso.ground_dir_between(player.global_position, e.global_position)
	if e is Warden:
		e.take_hit(damage * damage_scale(), dir, 0.0, 0.0)
		(e as Warden).jam(stun)
	else:
		e.take_hit(damage * damage_scale(), dir, 0.0, stun)


func readiness() -> float:
	if charge >= 0.0:
		return clampf(charge / CHARGE_FULL, 0.0, 1.0)
	return clampf(1.0 - _cooldown / (TUNED_COOLDOWN if is_tuned() else MANUAL_COOLDOWN), 0.0, 1.0)


func status() -> String:
	if charge >= 0.0:
		return "FULL" if charge >= CHARGE_FULL else "CHARGING"
	return "" if _cooldown <= 0.0 else "COOLING"


func _draw() -> void:
	if charge < 0.0:
		return
	var k := charge / CHARGE_FULL
	var col := Palette.WARD_CYAN_HOT
	draw_polyline(Fx.ground_ellipse(lerpf(WAVE_MIN, WAVE_MAX, k), 36), Color(col, 0.7), 3.0, true)
	draw_polyline(Fx.ground_ellipse(WAVE_MAX, 36), Color(col, 0.15), 2.0, true)
	draw_circle(Vector2(0, -70), 5.0 + 4.0 * k, col, true, -1.0, true)
