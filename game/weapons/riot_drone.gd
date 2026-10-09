class_name RiotDrone
extends Weapon
## A riot-control drone from a Warden depot, hovering at the Operator's shoulder. Tuned: locks on to
## the nearest threat and manages its own heat. Manual: fires where you aim, heavier pellets pierce,
## but hold too long and it overheats.

const TUNED_RATE := 4.0
const TUNED_DAMAGE := 4.0
const TUNED_RANGE := 7.0
const MANUAL_RATE := 3.4
const MANUAL_DAMAGE := 6.5
const MANUAL_RANGE := 9.0
const MANUAL_PIERCE := 1
const SHOT_SPEED := 15.0
const HEAT_PER_SHOT := 0.085
const COOL_PER_SECOND := 0.5
const COOL_DELAY := 0.25
## Tuned holds fire above this heat, so it never overheats.
const TUNED_HEAT_CEILING := 0.75
const OVERHEAT_LOCK := 1.4

var heat: float = 0.0
var _cooldown: float = 0.0
var _locked: float = 0.0
var _bob: float = 0.0


func _ready() -> void:
	material = Emissive.unshaded_material()


func _tick(delta: float, pressed: bool, held: bool, _released: bool) -> void:
	_cool(delta)
	if _locked > 0.0:
		return
	if (pressed or held) and _cooldown <= 0.0:
		var tuned := is_tuned()
		if tuned and heat >= TUNED_HEAT_CEILING:
			return
		_shoot(tuned)


func _idle(delta: float) -> void:
	_cool(delta)


func _cool(delta: float) -> void:
	_bob += delta
	_cooldown -= delta
	_locked = maxf(0.0, _locked - delta)
	# Heat only bleeds off once the trigger has been quiet for a moment.
	if _cooldown < -COOL_DELAY:
		heat = maxf(0.0, heat - COOL_PER_SECOND * delta)
	queue_redraw()


func _shoot(tuned: bool) -> void:
	var lv := level()
	if lv == null:
		return
	var dir := attack_direction(TUNED_RANGE if tuned else MANUAL_RANGE)
	player.face(dir)
	var p := Projectile.new()
	p.team = Projectile.Team.PLAYER
	p.level = lv
	p.direction = dir
	p.speed_tiles = SHOT_SPEED
	p.damage = TUNED_DAMAGE if tuned else MANUAL_DAMAGE
	p.max_tiles = TUNED_RANGE if tuned else MANUAL_RANGE
	p.pierce = 0 if tuned else MANUAL_PIERCE
	p.color = WeaponGlow.hot(tuned)
	p.size = 5.0
	p.position = player.global_position + Iso.ground_velocity(dir, 0.35)
	lv.world.add_child(p)
	_cooldown = 1.0 / (TUNED_RATE if tuned else MANUAL_RATE)
	heat = minf(1.0, heat + HEAT_PER_SHOT)
	if heat >= 1.0:
		_locked = OVERHEAT_LOCK
	announce_fired()


func is_overheated() -> bool:
	return _locked > 0.0


func readiness() -> float:
	return 1.0 - heat


func status() -> String:
	return "OVERHEAT" if is_overheated() else ""


func _draw() -> void:
	var side := 1.0 if (player == null or Iso.grid_to_world(player.facing_ground).x >= 0.0) else -1.0
	var c := Vector2(-side * 44.0, -150.0 + sin(_bob * 3.0) * 4.0)
	draw_colored_polygon(_ellipse(Vector2(c.x, 4.0), 14.0, 6.0), Color(Palette.NEAR_BLACK, 0.3))
	draw_colored_polygon(_ellipse(c, 20.0, 8.0), Palette.IRON_DARK)
	draw_colored_polygon(_ellipse(c + Vector2(0, -4), 14.0, 6.0), Palette.CUSTODIAN_PANEL.darkened(0.4))
	for k: int in 2:
		var r := c + Vector2(-22.0 + k * 44.0, -6.0)
		draw_line(r + Vector2(-10, 0), r + Vector2(10, 0), Color(Palette.GREY_COLD, 0.6), 2.0)
	var lamp := Palette.DANGER if is_overheated() else WeaponGlow.hot(is_tuned())
	draw_circle(c + Vector2(0, 3), 4.0, lamp, true, -1.0, true)


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 14:
		var a := TAU * i / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
