class_name Operator
extends CharacterBody2D
## The player: an unnamed maintenance worker who walks out of a service tunnel nine days after the
## Quiet. Moves across the ground at a constant speed in eight directions and dodges with a short roll.

signal dodged(ground_direction: Vector2)

const WALK_TILES_PER_SECOND := 3.2

var dodge: Dodge = Dodge.new()
## Grid-space direction the Operator faces. Starts looking up the street.
var facing_ground: Vector2 = Vector2(0, -1)
var input_enabled: bool = true

var _body: OperatorBody


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1 << 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 46.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	add_child(shape)
	_body = OperatorBody.new()
	add_child(_body)
	add_to_group(&"player")


func _physics_process(delta: float) -> void:
	dodge.update(delta)
	var input := Controls.move_vector() if input_enabled else Vector2.ZERO
	var ground := Iso.input_to_ground(input)
	if input_enabled and Input.is_action_just_pressed(&"dodge"):
		var dir := ground if ground.length_squared() > 0.01 else facing_ground
		if dodge.try_start(dir):
			dodged.emit(dodge.direction)
	if dodge.is_rolling():
		velocity = dodge.velocity()
	else:
		velocity = Iso.ground_velocity(ground, WALK_TILES_PER_SECOND)
		if ground.length_squared() > 0.01:
			facing_ground = ground.normalized()
	move_and_slide()
	_body.update_pose(facing_ground, velocity, dodge, delta)


func cell() -> Vector2i:
	return Iso.world_to_cell(global_position)


func is_invulnerable() -> bool:
	return dodge.is_invulnerable()
