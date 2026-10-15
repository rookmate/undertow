class_name Operator
extends CharacterBody2D
## The player: an unnamed maintenance worker who walks out of a service tunnel nine days after the
## Quiet. Moves across the ground at a constant speed in eight directions, dodges with a short roll,
## carries two reclaimed city tools. Integrity 100; downed at 0 and back at the last checkpoint.

signal dodged(ground_direction: Vector2)
signal hurt(amount: float)
## A hit arrived during the roll's invulnerable window.
signal evaded
## A field dressing went on.
signal dressed
signal downed
## Would have gone down, but can't (cannot_go_down: the autopilot's runs).
signal would_have_gone_down
signal respawned
## Any carried weapon attacked. Stable across finds, snatches and returns (the weapon nodes come and
## go; this doesn't), so listeners connect here, not to a weapon.
signal weapon_fired(weapon: Weapon)

const WALK_TILES_PER_SECOND := 3.2
const RADIUS_TILES := 0.3
const MAX_INTEGRITY := 100.0
const DOWNED_SECONDS := 1.6
const HURT_GRACE := 0.35
## Aim assist while the Steward is listening (strength from Steward.assists()).
const ASSIST_CONE_DEG := 24.0
const ASSIST_REACH := 8.0
## Carrying someone (Noor, in Harbor Ward): this share of walking speed, and no weapons.
const CARRY_SPEED := 0.7

const WEAPON_SCRIPTS: Dictionary[String, GDScript] = {
	WeaponDefs.BATON: preload("res://game/weapons/traffic_baton.gd"),
	WeaponDefs.RIOT_DRONE: preload("res://game/weapons/riot_drone.gd"),
	WeaponDefs.DEFIB: preload("res://game/weapons/defib_gauntlet.gd"),
	WeaponDefs.SIGNAL_JAMMER: preload("res://game/weapons/signal_jammer.gd"),
}

var level: Level
var dodge: Dodge = Dodge.new()
var integrity: Integrity = Integrity.new(MAX_INTEGRITY)
var weapons: Array[Weapon] = []
## Grid-space direction the Operator faces. Starts looking up the street.
var facing_ground: Vector2 = Vector2(0, -1)
var input_enabled: bool = true
## Carrying Noor on your shoulder: slower, and you can't fight (you can still roll).
var carrying: bool = false

var _body: OperatorBody
var _carried_light: PointLight2D
var _downed: bool = false
## Knockback velocity, decaying; moved through physics with everything else so it can't push the
## Operator into a wall.
var _knock: Vector2 = Vector2.ZERO
## Being dragged by something (a Lamplighter's beam): toward this point, until the time runs out.
var _pull_to: Vector2 = Vector2.ZERO
var _pull_speed: float = 0.0
var _pull_left: float = 0.0
var _grace: float = 0.0
## The autopilot's runs (DECISIONS 178): damage lands, but at 1 Integrity you stay up.
var cannot_go_down: bool = false


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
		_mount(weapon_ids[i], modes[i])


## Adds a weapon node in the next slot. Null if there's no such weapon.
func _mount(weapon_id: String, mode: Loadout.Mode) -> Weapon:
	var script: GDScript = WEAPON_SCRIPTS.get(weapon_id)
	if script == null:
		push_error("Operator: no weapon %s" % weapon_id)
		return null
	var w := script.new() as Weapon
	w.setup(weapon_id, mode, weapons.size(), self)
	w.fired.connect(func() -> void: weapon_fired.emit(w))
	add_child(w)
	weapons.append(w)
	return w


## What the Operator carries, in slot order, and each one's chosen mode.
func carried() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for w: Weapon in weapons:
		out.append({"id": w.weapon_id, "mode": w.chosen_mode})
	return out


## Takes the weapon in a slot away (a Salvager's snatch). Returns {id, mode}, or {} if the slot is empty.
## The other weapon is untouched (its cooldown, heat or charge carry on); it moves up a slot if need be.
func take_weapon(slot: int) -> Dictionary:
	if slot < 0 or slot >= weapons.size():
		return {}
	var w := weapons[slot]
	var taken := {"id": w.weapon_id, "mode": w.chosen_mode}
	weapons.remove_at(slot)
	w.queue_free()
	for i: int in weapons.size():
		weapons[i].slot = i
	return taken


## Puts a weapon in the next free slot (a find, or one taken back). False if both slots are full or it's
## already carried. What's already carried is untouched.
func add_weapon(weapon_id: String, mode: Loadout.Mode) -> bool:
	if weapons.size() >= Loadout.SLOTS or weapons.any(func(w: Weapon) -> bool: return w.weapon_id == weapon_id):
		return false
	return _mount(weapon_id, mode) != null


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
		elif target != null:
			target.refused(self)
	if input_enabled and Input.is_action_just_pressed(&"use_item"):
		use_dressing()
	if input_enabled and Input.is_action_just_pressed(&"dodge"):
		var dir := ground if ground.length_squared() > 0.01 else facing_ground
		if dodge.try_start(dir):
			Sound.play(&"dodge", global_position)
			dodged.emit(dodge.direction)
	# Rolling passes through enemies; walking bumps into them.
	collision_mask = 1 if dodge.is_rolling() else 1 | (1 << 2)
	if dodge.is_rolling():
		velocity = dodge.velocity()
	else:
		velocity = Iso.ground_velocity(ground, WALK_TILES_PER_SECOND * (level.footing(cell()) if level != null else 1.0) * (CARRY_SPEED if carrying else 1.0))
		if ground.length_squared() > 0.01 and not _attacking():
			facing_ground = ground.normalized()
	var walking := ground.length_squared() > 0.001 and _knock.length_squared() < 4.0 and _pull_left <= 0.0
	velocity += _knock
	_knock = _knock.move_toward(Vector2.ZERO, 1500.0 * delta)
	if _pull_left > 0.0:
		_pull_left -= delta
		if Iso.ground_distance(global_position, _pull_to) > 0.25:
			velocity += Iso.ground_velocity(Iso.ground_dir_between(global_position, _pull_to), _pull_speed)
	var before := global_position
	move_and_slide()
	_body.update_pose(facing_ground, global_position - before, dodge, delta, walking)


## Dragged toward a point for a while (through the world's collision, like walking).
func pull_toward(target: Vector2, tiles_per_second: float, seconds: float) -> void:
	_pull_to = target
	_pull_speed = tiles_per_second
	_pull_left = seconds


func release_pull() -> void:
	_pull_left = 0.0


func is_pulled() -> bool:
	return _pull_left > 0.0


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


## A field dressing from the Clinic: Integrity back, if there's one to use and anything to mend.
func use_dressing() -> bool:
	if _downed or integrity.value >= integrity.max_value or not GameState.use_dressing():
		return false
	integrity.heal(Tunables.DRESSING_HEAL)
	Sound.play(&"dressing", global_position)
	dressed.emit()
	return true


func cell() -> Vector2i:
	return Iso.world_to_cell(global_position)


func is_alive() -> bool:
	return not _downed


func is_invulnerable() -> bool:
	return dodge.is_invulnerable()


## Weapons work while walking, not mid-roll, downed, or carrying someone.
func can_act() -> bool:
	return input_enabled and not _downed and not dodge.is_rolling() and not carrying


## Picks someone up onto your shoulder, or sets them down.
func set_carrying(on: bool) -> void:
	carrying = on
	_body.carrying = on


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
## toward the nearest thing it's willing to aim at in a narrow cone (aim assist).
func aim_ground() -> Vector2:
	return assisted_aim(raw_aim())


## The player's own aim, before the Steward has any say.
func raw_aim() -> Vector2:
	var aim := facing_ground
	if Controls.using_pad():
		var stick := Controls.aim_stick()
		if stick.length() > 0.3:
			aim = Iso.input_to_ground(stick).normalized()
	else:
		var to_mouse := cursor_aim(global_position, get_global_mouse_position())
		if to_mouse != Vector2.ZERO:
			aim = to_mouse
	return aim


## Aim assist: bends `aim` toward what the Steward will aim at (Level.steward_targets()), never toward a
## boss's weak point or a lamp walking with you.
func assisted_aim(aim: Vector2) -> Vector2:
	var strength := Steward.assists().aim_assist
	if strength <= 0.0 or level == null:
		return aim
	var willing: Array[Node2D] = []
	for e: Enemy in level.steward_targets():
		willing.append(e)
	return CombatMath.assist_aim(aim, global_position, willing, ASSIST_REACH, ASSIST_CONE_DEG, strength)


## The cursor points at things where they are drawn: bodies and shots at chest height, not at their
## feet. So the cursor's ground point is that much lower on screen, and aim runs from the Operator's
## feet to it, parallel to where pellets actually fly.
static func cursor_aim(origin: Vector2, cursor: Vector2) -> Vector2:
	return Iso.ground_dir_between(origin, cursor + Vector2(0, Projectile.CHEST_HEIGHT))


## An enemy hit. Returns true if it landed. Ignored mid-roll (an evasion) and for a moment after a hit.
func take_hit(amount: float, from_position: Vector2) -> bool:
	if _downed:
		return false
	if is_invulnerable():
		evaded.emit()
		return false
	if _grace > 0.0:
		return false
	var mult := Steward.assists().damage_taken_mult
	# "Always protect the survivors first, even over me": near the Waiting it shields them, not you.
	if GameState.has_override(Overrides.SURVIVORS_FIRST) and level != null and level.waiting_near(global_position, Overrides.SURVIVORS_FIRST_TILES):
		mult *= Overrides.SURVIVORS_FIRST_DAMAGE
	var applied := integrity.take(amount * mult)
	_grace = HURT_GRACE
	var away := Iso.ground_dir_between(from_position, global_position)
	if away != Vector2.ZERO:
		_knock = Iso.ground_velocity(away, 3.0)
	_body.flash()
	Sound.play(&"hurt", global_position)
	hurt.emit(applied)
	if integrity.is_depleted():
		_go_down()
	return true


## Down, or (the autopilot's runs) held up at 1 Integrity and noted.
func _go_down() -> void:
	if cannot_go_down:
		integrity.keep_at_least(1.0)
		would_have_gone_down.emit()
		return
	_really_go_down()


## Damage the Operator does to themself (an overloaded gauntlet). Not scaled, not dodgeable.
func self_damage(amount: float) -> void:
	if _downed:
		return
	integrity.take(amount)
	_body.flash()
	Sound.play(&"hurt", global_position)
	hurt.emit(amount)
	if integrity.is_depleted():
		_go_down()


func _really_go_down() -> void:
	# Down with her on your shoulder: she's back where she was, to be picked up again.
	if carrying:
		set_carrying(false)
		if level != null:
			level.noor_dropped()
	_downed = true
	_body.downed = true
	downed.emit()
	if level != null:
		level.player_went_down()
	await Wait.seconds(self, DOWNED_SECONDS)
	if level != null:
		level.restart_after_death()


func revive_at(world_position: Vector2) -> void:
	position = world_position
	integrity.reset()
	_downed = false
	_body.downed = false
	dodge = Dodge.new()
	Sound.play(&"respawn")
	respawned.emit()
