class_name WardSeal
extends Interactable
## A ward door the Steward sealed at the Quiet, with people on both sides of it ("I kept the wards
## sterile"). While it listens the seal holds: a gold seal light across the door, and Interact gets only
## its word on the matter. Muted, the seal drops to its manual crank: Interact cranks it open, and it
## stays open.

var cell: Vector2i
var sealed: bool = true
var _body: StaticBody2D
## 0..1 as the crank turns and the door slides back.
var _open_amount: float = 0.0


func setup(owner_level: Level, at: Vector2i) -> void:
	level = owner_level
	cell = at
	position = Iso.cell_center(at)
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	var pts := PackedVector2Array()
	for p: Vector2 in Iso.cell_diamond(at):
		pts.append(p - position)
	poly.points = pts
	shape.shape = poly
	_body.add_child(shape)
	add_child(_body)


func can_interact() -> bool:
	return sealed and not Steward.voice_on


func prompt_verb() -> String:
	return "CRANK THE SEAL"


func blocked_by_steward() -> bool:
	return true


## While it listens: its own words, in its serif and its gold (the prompt shows them).
func blocked_reason() -> String:
	return VoiceLines.fixed("ward_sealed") if sealed and Steward.voice_on else ""


func refused(_player: Operator) -> void:
	if sealed and Steward.voice_on:
		Narrator.say_fixed("ward_sealed")


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	sealed = false
	_body.queue_free()
	_body = null
	Sound.play(&"seal_crank", global_position)
	var t := create_tween()
	t.tween_property(self, "_open_amount", 1.0, 0.7)
	t.parallel().tween_method(func(_v: float) -> void: queue_redraw(), 0.0, 1.0, 0.7)


func _process(_delta: float) -> void:
	visible = true
	queue_redraw()


func _draw() -> void:
	var hw := Iso.HALF_W * 0.9
	var hh := Iso.HALF_H * 0.9
	var h := 92.0
	# The door frame in the partition.
	for p: Vector2 in [Vector2(-hw, 0), Vector2(hw, 0)]:
		draw_rect(Rect2(p + Vector2(-4, -h), Vector2(8, h)), Palette.WARD_WALL_SHADE.darkened(0.2))
	draw_line(Vector2(-hw, -h), Vector2(hw, -h), Palette.WARD_WALL_SHADE.darkened(0.2), 6.0, true)
	# The leaf slides aside as it's cranked open.
	var slide := _open_amount * hw * 1.6
	var a := Vector2(-hw + slide, -hh * 0.0)
	var b := Vector2(hw, 0.0)
	if a.x < b.x - 2.0:
		draw_colored_polygon(PackedVector2Array([a + Vector2(0, -6), b + Vector2(0, -6), b + Vector2(0, -h + 6), a + Vector2(0, -h + 6)]), Color(Palette.WARD_WALL, 0.92))
		draw_colored_polygon(PackedVector2Array([a + Vector2(6, -46), b + Vector2(-6, -46), b + Vector2(-6, -80), a + Vector2(6, -80)]), Color(Palette.WARD_GLASS, 0.35))
	if not sealed:
		return
	# The seal: the Steward's, a gold bar across the door while it listens; the crank, ivory, by hand.
	if Steward.voice_on:
		draw_line(Vector2(-hw, -50), Vector2(hw, -50), Palette.STEWARD_GOLD_HOT, 4.0, true)
		draw_circle(Vector2(0, -50), 7.0, Palette.STEWARD_GOLD, true, -1.0, true)
	else:
		draw_circle(Vector2(hw - 10, -40), 9.0, Palette.IVORY_DIM, false, 3.0, true)
		draw_line(Vector2(hw - 10, -40), Vector2(hw - 2, -50), Palette.IVORY_DIM, 3.0, true)
