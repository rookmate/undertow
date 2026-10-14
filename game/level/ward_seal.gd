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
	ArtCatalog.door(self, "ward_seal", Rect2(-hw, -92, hw * 2, 92), _open_amount)
	if not sealed:
		return
	if Steward.voice_on:
		draw_line(Vector2(-hw, -50), Vector2(hw, -50), Palette.STEWARD_GOLD_HOT, 4.0, true)
		draw_circle(Vector2(0, -50), 7.0, Palette.STEWARD_GOLD, true, -1.0, true)
	else:
		ArtCatalog.paint(self, "valve_wheel", Rect2(hw - 19, -49, 18, 18))
