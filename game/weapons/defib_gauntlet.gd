class_name DefibGauntlet
extends Weapon
## An EMS defibrillator rebuilt as a gauntlet. Tuned: charges to the safe level and discharges around
## you. Manual: hold to charge, release in the window for a wide shock; hold too long and it bites you.

const TUNED_CHARGE := 0.6
const TUNED_RADIUS := 1.8
const TUNED_DAMAGE := 20.0
const TUNED_STUN := 0.6

const SWEET_START := 0.5
const SWEET_END := 0.8
const OVERLOAD_AT := 1.1
const WEAK_RADIUS := 1.2
const WEAK_DAMAGE := 10.0
const SWEET_RADIUS := 2.3
const SWEET_DAMAGE := 30.0
const SWEET_STUN := 1.0
const OVERLOAD_SELF_DAMAGE := 8.0
const OVERLOAD_RADIUS := 1.0
const OVERLOAD_DAMAGE := 8.0

const COOLDOWN := 1.2

var charge: float = -1.0
var _cooldown: float = 0.0


func _ready() -> void:
	material = Emissive.unshaded_material()


func _tick(delta: float, pressed: bool, held: bool, released: bool) -> void:
	_cooldown -= delta
	if charge < 0.0:
		if pressed and _cooldown <= 0.0:
			charge = 0.0
		queue_redraw()
		return
	charge += delta
	if is_tuned():
		if charge >= TUNED_CHARGE:
			_discharge(TUNED_RADIUS, TUNED_DAMAGE, TUNED_STUN)
	else:
		if charge >= OVERLOAD_AT:
			_overload()
		elif released or not held:
			if charge >= SWEET_START and charge <= SWEET_END:
				_discharge(SWEET_RADIUS, SWEET_DAMAGE, SWEET_STUN)
			else:
				_discharge(WEAK_RADIUS, WEAK_DAMAGE, 0.2)
	queue_redraw()


func _idle(delta: float) -> void:
	_cooldown -= delta
	charge = -1.0
	queue_redraw()


func _discharge(radius: float, damage: float, stun: float, cue: StringName = &"gauntlet_zap") -> void:
	charge = -1.0
	_cooldown = COOLDOWN
	Sound.play(cue, player.global_position)
	for e: Node2D in targets_in_range(radius + 0.6):
		var enemy := e as Enemy
		if Iso.ground_distance(player.global_position, enemy.global_position) <= radius + enemy.radius_tiles:
			enemy.take_hit(damage * damage_scale(), Iso.ground_dir_between(player.global_position, enemy.global_position), 0.7, stun)
	var lv := level()
	if lv != null:
		var ring := Fx.spawn(lv.fx_ground, player.global_position, Fx.Shape.DISC, Color(WeaponGlow.hot(is_tuned()), 0.9), 0.35)
		ring.radius_tiles = radius
		ring.width = 5.0
	announce_fired()


func _overload() -> void:
	_discharge(OVERLOAD_RADIUS, OVERLOAD_DAMAGE, 0.2, &"gauntlet_overload")
	player.self_damage(OVERLOAD_SELF_DAMAGE)
	var lv := level()
	if lv != null:
		var fx := Fx.spawn(lv.fx_ground, player.global_position, Fx.Shape.RING, Palette.DANGER, 0.4)
		fx.radius_tiles = 0.8


func is_in_sweet_spot() -> bool:
	return charge >= SWEET_START and charge <= SWEET_END


func readiness() -> float:
	if charge >= 0.0:
		return clampf(charge / SWEET_END, 0.0, 1.0)
	return clampf(1.0 - _cooldown / COOLDOWN, 0.0, 1.0)


func status() -> String:
	if charge < 0.0:
		return ""
	if is_tuned():
		return "CHARGING"
	if charge > SWEET_END:
		return "OVERLOAD"
	return "RELEASE" if is_in_sweet_spot() else "CHARGING"


func _draw() -> void:
	if charge < 0.0:
		return
	var tuned := is_tuned()
	var target := TUNED_RADIUS if tuned else SWEET_RADIUS
	var k := charge / (TUNED_CHARGE if tuned else SWEET_END)
	var col := WeaponGlow.hot(tuned)
	if not tuned and charge > SWEET_END:
		col = Palette.DANGER
	elif not tuned and is_in_sweet_spot():
		col = Color(col.r * 1.3, col.g * 1.3, col.b * 1.3)
	draw_polyline(Fx.ground_ellipse(target * clampf(k, 0.0, 1.0), 36), Color(col, 0.8), 3.0, true)
	draw_polyline(Fx.ground_ellipse(target, 36), Color(col, 0.18), 2.0, true)
	draw_circle(Vector2(0, -70), 6.0 + 4.0 * clampf(k, 0.0, 1.0), col, true, -1.0, true)
