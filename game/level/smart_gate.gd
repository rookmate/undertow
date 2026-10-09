class_name SmartGate
extends StaticBody2D
## An automated garden gate in gilded wrought iron (Kestrel Heights). It answers to the Steward: open
## while it listens, and it swings shut when you mute it (never on top of you: it waits until you're
## clear). Muting has a cost here.

## Seconds after muting before the gate swings shut.
const CLOSE_DELAY := 0.6

var cell: Vector2i
var level: Level
var open: bool = true
var _shape: CollisionShape2D
## Muted: the gate shuts once this runs out and the Operator is clear.
var _closing: bool = false
var _closing_in: float = 0.0


func setup(owner_level: Level, at: Vector2i) -> void:
	level = owner_level
	cell = at
	position = Iso.cell_center(at)
	collision_layer = 1
	collision_mask = 0
	_shape = CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	var pts := PackedVector2Array()
	for p: Vector2 in Iso.cell_diamond(at):
		pts.append(p - position)
	poly.points = pts
	_shape.shape = poly
	add_child(_shape)
	Steward.voice_changed.connect(_on_voice)
	_set_open(Steward.voice_on)


func _exit_tree() -> void:
	if Steward.voice_changed.is_connected(_on_voice):
		Steward.voice_changed.disconnect(_on_voice)


func _on_voice(on: bool) -> void:
	if on:
		_closing = false
		_set_open(true)
	else:
		_closing = true
		_closing_in = CLOSE_DELAY


func _physics_process(delta: float) -> void:
	if not _closing:
		return
	_closing_in -= delta
	if _closing_in > 0.0:
		return
	# Never shut on the Operator: wait until they're clear of the gate.
	if level != null and level.player != null and Iso.ground_distance(level.player.global_position, global_position) < 0.95:
		return
	_closing = false
	_set_open(false)
	Sound.play(&"gate_shut", global_position)


func _set_open(value: bool) -> void:
	open = value
	_shape.set_deferred(&"disabled", open)
	queue_redraw()


func _draw() -> void:
	var h := 96.0
	var hw := Iso.HALF_W * 0.48
	var hh := Iso.HALF_H * 0.48
	var a := Vector2(-hw, -hh * 0.0)
	var b := Vector2(hw, 0.0)
	# Posts either side; the leaves swing back against them when open.
	for p: Vector2 in [a, b]:
		draw_rect(Rect2(p + Vector2(-5, -h - 10), Vector2(10, h + 10)), Palette.IRON_DARK)
		draw_circle(p + Vector2(0, -h - 14), 7.0, Palette.IRON_DARK, true, -1.0, true)
	var gilt := Palette.STEWARD_GOLD if Steward.voice_on else Palette.GREY_COLD
	if open:
		for p: Vector2 in [a, b]:
			draw_line(p + Vector2(0, -8), p + Vector2(0, -h + 8), Palette.IRON_DARK, 6.0, true)
		return
	# Shut: two leaves of whiplash ironwork across the walk.
	for k: int in 9:
		var u := k / 8.0
		var x := a.lerp(b, u)
		draw_line(x + Vector2(0, -6), x + Vector2(0, -h + 14 + sin(u * PI) * 10.0), Palette.IRON_DARK, 3.0, true)
	draw_line(a + Vector2(0, -h * 0.55), b + Vector2(0, -h * 0.55), Palette.IRON_DARK, 4.0, true)
	draw_arc(a.lerp(b, 0.5) + Vector2(0, -h + 26), hw * 0.9, PI, TAU, 16, gilt, 2.0, true)
