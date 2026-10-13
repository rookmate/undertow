class_name TheWaiting
extends Interactable
## A resident who never took the Lanyard off, standing still, waiting for the next instruction. The
## Steward says they're resting and to leave them. Muted, the Operator can wake them by speaking to them;
## they walk off toward the Ark and count as a survivor. Grey and unlit until woken.

const WOKEN_LINES: Array[String] = [
	"…What day is it? It stopped telling me.",
	"I was waiting for it to say I could go.",
	"Who are you? You're not in my Day.",
]

var survivor_id: String = ""
var woken: bool = false
var _leave: float = -1.0
var _line: String = ""
var _body: StaticBody2D


func setup(owner_level: Level, cell: Vector2i, id: String, is_off_path: bool) -> void:
	level = owner_level
	survivor_id = id
	off_path = is_off_path
	position = Iso.cell_center(cell)
	_line = WOKEN_LINES[absi(hash(id)) % WOKEN_LINES.size()]
	if GameState.run.survivor_ids.has(id):
		woken = true
		visible = false
		_leave = 99.0
		return
	# They stand still; the Operator walks around them.
	_body = StaticBody2D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 36.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	_body.add_child(shape)
	add_child(_body)


func is_present() -> bool:
	return super.is_present() and _leave < 3.0


func can_interact() -> bool:
	return is_present() and not woken and not Steward.voice_on


func still_to_find() -> bool:
	return not woken


func prompt_verb() -> String:
	return "WAKE"


func blocked_by_steward() -> bool:
	return true


func blocked_reason() -> String:
	if woken:
		return ""
	# The Steward's own words (its serif and its gold mark the speaker).
	return VoiceLines.fixed("waiting_refusal") if Steward.voice_on else ""


## Trying to wake them while it listens: it says so, out loud.
func refused(_player: Operator) -> void:
	if not woken and Steward.voice_on:
		Narrator.say_fixed("waiting_refusal")


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	woken = true
	_leave = 0.0
	Sound.play(&"wake", global_position)
	if _body != null:
		_body.queue_free()
		_body = null
	GameState.add_survivor(survivor_id)


func spoken_line() -> String:
	return _line if woken and _leave < 2.5 else ""


func _process(delta: float) -> void:
	if _leave >= 0.0 and _leave < 99.0:
		_leave += delta
		if _leave > 1.2:
			position += Iso.ground_velocity(Vector2(0, 1), 1.6) * delta
			modulate.a = clampf(1.0 - (_leave - 1.6) / 1.4, 0.0, 1.0)
	visible = is_present()
	queue_redraw()


func _draw() -> void:
	var shadow := PackedVector2Array()
	for i: int in 14:
		var a := TAU * i / 14.0
		shadow.append(Vector2(cos(a) * 24.0, sin(a) * 10.0))
	draw_colored_polygon(shadow, Color(Palette.NEAR_BLACK, 0.4))
	# Woken: lit by human warmth. Waiting: grey and unlit.
	var body := Palette.HUMAN_CREAM.darkened(0.45) if woken else Palette.WAITING_GREY
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -4), Vector2(18, -4), Vector2(15, -118), Vector2(-15, -118)]), body)
	draw_circle(Vector2(0, -134), 13.0, body.darkened(0.1), true, -1.0, true)
	draw_rect(Rect2(-24, -112, 8, 54), body.darkened(0.15))
	draw_rect(Rect2(16, -112, 8, 54), body.darkened(0.15))
	# The Lanyard: a sliver of the Steward at the ear. Dark once they've been woken.
	var lanyard := Palette.GREY_DEEP if woken else Color(Palette.STEWARD_GOLD, 0.8)
	draw_circle(Vector2(-11, -134), 3.0, lanyard, true, -1.0, true)
