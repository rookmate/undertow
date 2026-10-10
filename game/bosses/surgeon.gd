class_name Surgeon
extends Boss
## Mercy General's boss: a surgical unit at the operating table, still completing its last procedure
## (world bible). Its guide light marks an incision across the theatre floor, laid through where you
## stand, and the beam cuts along it (three times); then it floods the theatre with sterilizing mist,
## all but close to the table; then it bends over the table to suture: open to blows. With the voice on,
## the Steward calls each move. The manual solution: throw the theatre lamp's switch while it's marking
## a line; it loses its guide and stalls, open for longer.

enum Phase { IDLE, MARK, CUT, MIST_WARN, MIST, SUTURE, STALLED }

const MAX_INTEGRITY := 400.0
const CUTS_PER_CYCLE := 3
const MARK_SECONDS := 1.0
## Muted, you read the guide line yourself: it shows this much sooner.
const EARLY_MARK := 0.3
const CUT_SECONDS := 0.35
## How close to the line the beam catches you, and how far out from the table it reaches (tiles).
const CUT_WIDTH := 0.6
const CUT_LENGTH := 6.5
const CUT_DAMAGE := 18.0
const MIST_WARN_SECONDS := 1.1
const MIST_SECONDS := 2.6
## Close to the table the mist doesn't reach (tiles).
const MIST_SAFE := 2.0
const MIST_TICK := 0.35
const MIST_DAMAGE := 4.0
const SUTURE_SECONDS := 3.5
const STALL_SECONDS := 6.0
const ARM_HEIGHT := 150.0

var phase: Phase = Phase.IDLE
## Times stalled through the lamp switch (the manual solution).
var stalls: int = 0
## The incision: a ground direction through the table.
var cut_dir: Vector2 = Vector2(1, 0)

var _phase_time: float = 0.0
var _cuts_left: int = 0
var _mark_for: float = MARK_SECONDS
var _struck: bool = false
var _tick: float = 0.0
var _stalled_this_cycle: bool = false
var _lamp: PointLight2D


func _ready() -> void:
	super()
	boss_name = "THE SURGEON"
	radius_tiles = 1.1
	# The operating lamp: the Steward's light over the table (gold), dark while it stalls.
	_lamp = PointLight2D.new()
	_lamp.texture = LightTextures.radial()
	_lamp.color = Palette.STEWARD_GOLD
	_lamp.energy = 1.6
	_lamp.texture_scale = 2.4
	_lamp.scale = Vector2(1.0, Iso.SQUASH)
	add_child(_lamp)


func is_vulnerable() -> bool:
	return phase == Phase.SUTURE or phase == Phase.STALLED


## It's lining up a cut: the window for the lamp switch.
func is_switching() -> bool:
	return phase == Phase.MARK


func _on_engaged() -> void:
	_start_cycle()


func _start_cycle() -> void:
	_cuts_left = CUTS_PER_CYCLE
	_stalled_this_cycle = false
	_enter_phase(Phase.MARK)


func _enter_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_struck = false
	match next:
		Phase.MARK:
			_mark_for = MARK_SECONDS + (EARLY_MARK if not Steward.voice_on else 0.0)
			_aim_at_player()
			call_out("surgeon_incision")
			Sound.play(&"windup", global_position)
		Phase.CUT:
			Sound.play(&"signal_zap", global_position)
		Phase.MIST_WARN:
			call_out("surgeon_mist")
			Sound.play(&"windup", global_position)
		Phase.MIST:
			_tick = 0.0
			Sound.play(&"sterile_hiss", global_position)
		Phase.SUTURE:
			call_out("surgeon_suture")
			Sound.play(&"vent_hiss", global_position)
	if _lamp != null:
		_lamp.energy = 0.2 if next == Phase.STALLED else 1.6


func _aim_at_player() -> void:
	var p := player()
	if p != null and Iso.ground_distance(global_position, p.global_position) > 0.2:
		cut_dir = Iso.ground_dir_between(global_position, p.global_position)


## Whether a point (world) lies on the incision line.
func on_line(at: Vector2) -> bool:
	var rel := Iso.world_to_grid(at) - Iso.world_to_grid(global_position)
	return absf(rel.dot(cut_dir)) <= CUT_LENGTH and absf(rel.cross(cut_dir)) <= CUT_WIDTH


## Whether a point (world) is out in the mist (too far from the table).
func in_mist(at: Vector2) -> bool:
	return Iso.ground_distance(global_position, at) > MIST_SAFE


func _fight(delta: float) -> void:
	_phase_time += delta
	var p := player()
	var player_ok := p != null and p.is_alive()
	match phase:
		Phase.MARK:
			# It follows you at first, then commits to the line.
			if _phase_time < _mark_for * 0.6:
				_aim_at_player()
			if _phase_time >= _mark_for:
				_cuts_left -= 1
				_enter_phase(Phase.CUT)
		Phase.CUT:
			if not _struck and _phase_time >= CUT_SECONDS * 0.5:
				_struck = true
				if player_ok and on_line(p.global_position):
					p.take_hit(CUT_DAMAGE, global_position)
			if _phase_time >= CUT_SECONDS + 0.3:
				_enter_phase(Phase.MARK if _cuts_left > 0 else Phase.MIST_WARN)
		Phase.MIST_WARN:
			if _phase_time >= MIST_WARN_SECONDS:
				_enter_phase(Phase.MIST)
		Phase.MIST:
			_tick -= delta
			if _tick <= 0.0 and player_ok and in_mist(p.global_position):
				_tick = MIST_TICK
				p.take_hit(MIST_DAMAGE, global_position)
			if _phase_time >= MIST_SECONDS:
				_enter_phase(Phase.SUTURE)
		Phase.SUTURE:
			if _phase_time >= SUTURE_SECONDS:
				_start_cycle()
		Phase.STALLED:
			if _phase_time >= STALL_SECONDS:
				_start_cycle()


## The lamp switch thrown while it's marking: it loses its guide and stalls (once a cycle).
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
	draw_shadow(52.0, 24.0)
	var flash := hit_flash()
	var shell := Palette.AMBULANCE_WHITE.darkened(0.2).lerp(Palette.IVORY, flash)
	# The operating table, and the last procedure under its sheet.
	var t := PackedVector2Array([Vector2(-56, 0), Vector2(0, 28), Vector2(56, 0), Vector2(0, -28)])
	for k: int in t.size():
		t[k] += Vector2(0, -34)
	draw_colored_polygon(PackedVector2Array([Vector2(-56, -34), Vector2(0, -6), Vector2(0, 0), Vector2(-56, -28)]), Palette.WARD_WALL_SHADE.darkened(0.4))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(56, -34), Vector2(56, -28), Vector2(0, 0)]), Palette.WARD_WALL_SHADE.darkened(0.2))
	draw_colored_polygon(t, Palette.WARD_WALL_SHADE)
	draw_colored_polygon(PackedVector2Array([Vector2(-34, -40), Vector2(-4, -26), Vector2(30, -44), Vector2(0, -58)]), Palette.AMBULANCE_WHITE.darkened(0.15))
	# The column from the ceiling, its arms over the table: bent low while it sutures.
	var low := is_vulnerable()
	var hub := Vector2(0, -ARM_HEIGHT - (40.0 if not low else 0.0))
	draw_line(Vector2(0, -ARM_HEIGHT - 120.0), hub, shell.darkened(0.25), 10.0, true)
	draw_circle(hub, 18.0, shell, true, -1.0, true)
	for k: int in 4:
		var a := TAU * k / 4.0 + 0.4 + (0.0 if phase != Phase.CUT else _phase_time * 4.0)
		var elbow := hub + Vector2(cos(a) * 46.0, sin(a) * 20.0 + 26.0)
		var tip := elbow + Vector2(cos(a) * 20.0, (70.0 if low else 44.0))
		draw_line(hub, elbow, shell, 6.0, true)
		draw_line(elbow, tip, shell.darkened(0.15), 4.0, true)
		draw_circle(tip, 4.0, Palette.DANGER if phase == Phase.CUT else Palette.GREY_DEEP, true, -1.0, true)
	# The operating lamp: the Steward's light (dark while it stalls).
	var lamp_at := Vector2(0, -ARM_HEIGHT - 150.0)
	draw_circle(lamp_at, 26.0, Palette.GREY_DEEP, true, -1.0, true)
	if phase != Phase.STALLED:
		draw_circle(lamp_at + Vector2(0, 6), 18.0, Palette.STEWARD_GOLD_HOT, true, -1.0, true)
	# The guide line it lays for the cut (its own light, gold), and the cut itself (red-orange: danger).
	var a_end := Iso.ground_velocity(cut_dir, 1.0) * CUT_LENGTH
	if phase == Phase.MARK:
		var k := clampf(_phase_time / _mark_for, 0.2, 1.0)
		_dashed(-a_end, a_end, Color(Palette.STEWARD_GOLD, 0.35 + 0.5 * k))
	if phase == Phase.CUT:
		draw_line(-a_end, a_end, Color(Palette.DANGER, 0.9), 6.0, true)
		draw_line(-a_end, a_end, Color(Palette.IVORY, 0.6), 2.0, true)
	# The mist's edge: inside this ring the table keeps you clear.
	if phase == Phase.MIST_WARN or phase == Phase.MIST:
		_ring(MIST_SAFE, Color(Palette.DANGER, 0.85))
		if phase == Phase.MIST:
			_ring(MIST_SAFE + 3.5, Color(Palette.STERILE_MIST, 0.25))


func _dashed(from: Vector2, to: Vector2, col: Color) -> void:
	var n := 18
	for i: int in n:
		if i % 2 == 0:
			draw_line(from.lerp(to, float(i) / n), from.lerp(to, float(i + 1) / n), col, 4.0, true)


## A circle of `tiles` radius round the table, on the ground.
func _ring(tiles: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 33:
		pts.append(Iso.grid_to_world(Vector2.from_angle(TAU * i / 32.0) * tiles))
	draw_polyline(pts, col, 3.0, true)
