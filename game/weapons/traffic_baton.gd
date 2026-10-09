class_name TrafficBaton
extends Weapon
## A traffic-control baton with a lit tip. Tuned: finds the nearest threat and swings, holding chains
## the combo. Manual: swings where you aim; press on the beat to chain, and the third hit on the beat
## lands hard.

const SWING_SECONDS := 0.3
const COMBO_RESET := 0.75

const TUNED_RANGE := 1.65
const TUNED_SEEK := 2.6
const TUNED_ARC := 150.0
const TUNED_DAMAGE: Array[float] = [9.0, 9.0, 14.0]

const MANUAL_RANGE := 1.55
const MANUAL_ARC := 105.0
const MANUAL_DAMAGE: Array[float] = [11.0, 11.0, 17.0]
## Seconds after a swing starts in which the next press counts as on the beat.
const BEAT_EARLIEST := 0.16
const BEAT_LATEST := 0.45
const ON_BEAT_FINISHER := 1.6

var _since_swing: float = INF
var _combo: int = 0
var _queued: bool = false
var _queued_on_beat: bool = false
var _swing_dir: Vector2 = Vector2(0, -1)
var _last_on_beat: bool = false


func _ready() -> void:
	material = Emissive.unshaded_material()


func _tick(delta: float, pressed: bool, held: bool, _released: bool) -> void:
	_since_swing += delta
	if _since_swing > COMBO_RESET:
		_combo = 0
	if is_tuned():
		_queued = false
		if (pressed or held) and _since_swing >= SWING_SECONDS:
			_swing(true)
	else:
		if pressed and _since_swing >= BEAT_EARLIEST:
			_queued = true
			_queued_on_beat = _combo > 0 and _since_swing <= BEAT_LATEST
		if _queued and _since_swing >= SWING_SECONDS:
			_queued = false
			_swing(_queued_on_beat)
	queue_redraw()


func _idle(delta: float) -> void:
	_since_swing += delta
	_queued = false
	queue_redraw()


func _swing(continues_combo: bool) -> void:
	if not continues_combo:
		_combo = 0
	var tuned := is_tuned()
	var reach := TUNED_RANGE if tuned else MANUAL_RANGE
	_swing_dir = attack_direction(TUNED_SEEK if tuned else MANUAL_RANGE)
	player.face(_swing_dir)
	var index := _combo
	var damage: float = TUNED_DAMAGE[index] if tuned else MANUAL_DAMAGE[index]
	var finisher := index == 2
	_last_on_beat = not tuned and continues_combo
	if finisher and _last_on_beat:
		damage *= ON_BEAT_FINISHER
	var arc := TUNED_ARC if tuned else MANUAL_ARC
	Sound.play(&"baton_swing", player.global_position)
	for e: Node2D in targets_in_range(reach + 0.5):
		var enemy := e as Enemy
		if CombatMath.in_arc(player.global_position, _swing_dir, enemy.global_position, reach, arc, enemy.radius_tiles):
			enemy.take_hit(damage, _swing_dir, 0.9 if finisher else 0.45, 0.4 if finisher else 0.12)
			Sound.play(&"baton_hit", enemy.global_position)
	var lv := level()
	if lv != null:
		var fx := Fx.spawn(lv.fx_ground, player.global_position, Fx.Shape.ARC, Color(glow_color(), 0.55), 0.22)
		fx.facing = _swing_dir
		fx.arc_deg = arc
		fx.radius_tiles = reach
		fx.grow = false
	_combo = (index + 1) % TUNED_DAMAGE.size()
	_since_swing = 0.0
	announce_fired()


func readiness() -> float:
	return clampf(_since_swing / SWING_SECONDS, 0.0, 1.0)


func status() -> String:
	if not is_tuned() and _combo > 0 and _since_swing >= BEAT_EARLIEST and _since_swing <= BEAT_LATEST:
		return "ON THE BEAT"
	return ""


func _draw() -> void:
	var swinging := _since_swing < SWING_SECONDS
	var screen_dir := Iso.grid_to_world(_swing_dir if swinging else player_facing()).normalized()
	var hand := Vector2(signf(screen_dir.x) * 26.0, -78.0)
	var angle := screen_dir.angle()
	if swinging:
		var arc := deg_to_rad((TUNED_ARC if is_tuned() else MANUAL_ARC) * 0.5)
		angle += lerpf(-arc, arc, _since_swing / SWING_SECONDS)
	else:
		angle = PI * 0.5 + signf(screen_dir.x) * -0.4
	var tip := hand + Vector2.from_angle(angle) * 62.0
	draw_line(hand, tip, Palette.IRON_DARK, 7.0, true)
	draw_line(hand.lerp(tip, 0.35), tip, WeaponGlow.hot(is_tuned()), 4.0, true)


func player_facing() -> Vector2:
	return player.facing_ground if player != null else Vector2(0, -1)
