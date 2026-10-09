class_name Operator
extends CharacterBody2D
## The player: an unnamed maintenance worker who walks out of a service tunnel nine days after the
## Quiet. Moves across the ground at a constant speed in eight directions, dodges with a short roll,
## carries two reclaimed city tools. Integrity 100; downed at 0 and back at the last checkpoint.

signal dodged(ground_direction: Vector2)
signal hurt(amount: float)
## A hit arrived during the roll's invulnerable window.
signal evaded
signal downed
signal respawned

const WALK_TILES_PER_SECOND := 3.2
const RADIUS_TILES := 0.3
const MAX_INTEGRITY := 100.0
const DOWNED_SECONDS := 1.6
const HURT_GRACE := 0.35
## Aim assist while the Steward is listening (strength from Steward.assists()).
const ASSIST_CONE_DEG := 24.0
const ASSIST_REACH := 8.0

const WEAPON_SCRIPTS: Dictionary[String, GDScript] = {
	WeaponDefs.BATON: preload("res://game/weapons/traffic_baton.gd"),
	WeaponDefs.RIOT_DRONE: preload("res://game/weapons/riot_drone.gd"),
	WeaponDefs.DEFIB: preload("res://game/weapons/defib_gauntlet.gd"),
}

var level: Level
var dodge: Dodge = Dodge.new()
var integrity: Integrity = Integrity.new(MAX_INTEGRITY)
var weapons: Array[Weapon] = []
## Grid-space direction the Operator faces. Starts looking up the street.
var facing_ground: Vector2 = Vector2(0, -1)
var input_enabled: bool = true

var _body: OperatorBody
var _carried_light: PointLight2D
var _downed: bool = false
var _grace: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 13.0
	capsule.height = 46.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	add_child(shape)
	_body = OperatorBody.new()
	add_child(_body)
	# A maintenance hand lamp: what you carry when the Steward's lamps are dark.
	_carried_light = PointLight2D.new()
	_carried_light.texture = LightTextures.radial()
	_carried_light.color = Palette.IVORY
	_carried_light.energy = 1.15
	_carried_light.texture_scale = 2.6
	_carried_light.scale = Vector2(1.0, Iso.SQUASH)
	_carried_light.position = Vector2(0, -10)
	_carried_light.enabled = false
	add_child(_carried_light)
	add_to_group(&"player")


func equip(weapon_ids: Array[String], modes: Array[Loadout.Mode]) -> void:
	for w: Weapon in weapons:
		w.queue_free()
	weapons.clear()
	for i: int in weapon_ids.size():
		var script: GDScript = WEAPON_SCRIPTS.get(weapon_ids[i])
		if script == null:
			push_error("Operator.equip: no weapon %s" % weapon_ids[i])
			continue
		var w := script.new() as Weapon
		w.setup(weapon_ids[i], modes[i], i, self)
		add_child(w)
		weapons.append(w)


func _physics_process(delta: float) -> void:
	dodge.update(delta)
	_grace = maxf(0.0, _grace - delta)
	if _downed:
		velocity = Vector2.ZERO
		_body.update_pose(facing_ground, velocity, dodge, delta)
		return
	var input := Controls.move_vector() if input_enabled else Vector2.ZERO
	var ground := Iso.input_to_ground(input)
	if input_enabled and Input.is_action_just_pressed(&"interact"):
		var target := interact_target()
		if target != null and target.can_interact():
			target.interact(self)
	if input_enabled and Input.is_action_just_pressed(&"dodge"):
		var dir := ground if ground.length_squared() > 0.01 else facing_ground
		if dodge.try_start(dir):
			dodged.emit(dodge.direction)
	# Rolling passes through enemies; walking bumps into them.
	collision_mask = 1 if dodge.is_rolling() else 1 | (1 << 2)
	if dodge.is_rolling():
		velocity = dodge.velocity()
	else:
		velocity = Iso.ground_velocity(ground, WALK_TILES_PER_SECOND)
		if ground.length_squared() > 0.01 and not _attacking():
			facing_ground = ground.normalized()
	move_and_slide()
	_body.update_pose(facing_ground, velocity, dodge, delta)


func set_carried_light(on: bool) -> void:
	if _carried_light != null:
		_carried_light.enabled = on


func carried_light_on() -> bool:
	return _carried_light != null and _carried_light.enabled


## What Interact would act on (or explain), if anything is close enough.
func interact_target() -> Interactable:
	if level == null or _downed:
		return null
	return level.nearest_interactable(global_position)


func cell() -> Vector2i:
	return Iso.world_to_cell(global_position)


func is_alive() -> bool:
	return not _downed


func is_invulnerable() -> bool:
	return dodge.is_invulnerable()


## Weapons work while walking, not mid-roll or downed.
func can_act() -> bool:
	return input_enabled and not _downed and not dodge.is_rolling()


func face(ground_dir: Vector2) -> void:
	if ground_dir.length_squared() > 0.0001:
		facing_ground = ground_dir.normalized()


func _attacking() -> bool:
	for w: Weapon in weapons:
		if Input.is_action_pressed(w.action()):
			return true
	return false


## Where the player is aiming, as a ground direction: the right stick on a pad, the mouse otherwise,
## the facing direction when neither says anything. With the Steward listening, the aim is bent a little
## toward the nearest threat in a narrow cone (aim assist).
func aim_ground() -> Vector2:
	var aim := facing_ground
	if Controls.using_pad():
		var stick := Controls.aim_stick()
		if stick.length() > 0.3:
			aim = Iso.input_to_ground(stick).normalized()
	else:
		var to_mouse := Iso.ground_dir_between(global_position, get_global_mouse_position())
		if to_mouse != Vector2.ZERO:
			aim = to_mouse
	var strength := Steward.assists().aim_assist
	if strength > 0.0 and level != null:
		var threats: Array[Node2D] = []
		for e: Enemy in level.living_enemies():
			threats.append(e)
		aim = CombatMath.assist_aim(aim, global_position, threats, ASSIST_REACH, ASSIST_CONE_DEG, strength)
	return aim


## An enemy hit. Returns true if it landed. Ignored mid-roll (an evasion) and for a moment after a hit.
func take_hit(amount: float, from_position: Vector2) -> bool:
	if _downed:
		return false
	if is_invulnerable():
		evaded.emit()
		return false
	if _grace > 0.0:
		return false
	var applied := integrity.take(CombatMath.damage_taken(amount, Steward.voice_on))
	_grace = HURT_GRACE
	var away := Iso.ground_dir_between(from_position, global_position)
	if away != Vector2.ZERO:
		position += Iso.ground_velocity(away, 0.25)
	_body.flash()
	hurt.emit(applied)
	if integrity.is_depleted():
		_go_down()
	return true


## Damage the Operator does to themself (an overloaded gauntlet). Not scaled, not dodgeable.
func self_damage(amount: float) -> void:
	if _downed:
		return
	integrity.take(amount)
	_body.flash()
	hurt.emit(amount)
	if integrity.is_depleted():
		_go_down()


func _go_down() -> void:
	_downed = true
	_body.downed = true
	downed.emit()
	await Wait.seconds(self, DOWNED_SECONDS)
	if level != null:
		level.respawn_player()


func revive_at(world_position: Vector2) -> void:
	position = world_position
	integrity.reset()
	_downed = false
	_body.downed = false
	dodge = Dodge.new()
	respawned.emit()
