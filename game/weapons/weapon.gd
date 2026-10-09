class_name Weapon
extends Node2D
## Base for the Operator's two carried weapons. Slot 0 fires on attack_primary (LMB / RT), slot 1 on
## attack_secondary (RMB / LT). The chosen mode only applies while the Steward is listening; muted,
## every weapon is manual. Tuned weapons glow Steward gold; manual ones glow ivory.

signal fired

var weapon_id: String = ""
var chosen_mode: Loadout.Mode = Loadout.Mode.TUNED
var slot: int = 0
var player: Operator


func setup(id: String, chosen: Loadout.Mode, slot_index: int, owner_player: Operator) -> void:
	weapon_id = id
	chosen_mode = chosen
	slot = slot_index
	player = owner_player


func action() -> StringName:
	return &"attack_primary" if slot == 0 else &"attack_secondary"


## Tuned only while the Steward can actually run the tool (voice on and the Lattice reaching you).
func mode() -> Loadout.Mode:
	return Loadout.effective_mode(chosen_mode, not Steward.assists().weapons_forced_manual)


func is_tuned() -> bool:
	return mode() == Loadout.Mode.TUNED


## Light colour of the tool right now: gold when the Steward runs it, ivory when you do.
func glow_color() -> Color:
	return WeaponGlow.color(is_tuned())


func _physics_process(delta: float) -> void:
	if player == null or not player.can_act():
		_idle(delta)
		return
	var act := action()
	_tick(delta, Input.is_action_just_pressed(act), Input.is_action_pressed(act), Input.is_action_just_released(act))


## Called every physics frame while the Operator can act.
func _tick(_delta: float, _pressed: bool, _held: bool, _released: bool) -> void:
	pass


## Called while the Operator can't act (rolling, downed): cancel charges, cool down.
func _idle(_delta: float) -> void:
	pass


## 0..1 readiness for the HUD (cooldown, heat or charge).
func readiness() -> float:
	return 1.0


## Short status for the HUD ("READY", "OVERHEAT", "CHARGING"…).
func status() -> String:
	return ""


# --- Helpers ------------------------------------------------------------------------------------
## Subclasses call this once per attack.
func announce_fired() -> void:
	fired.emit()


## How much harder this weapon hits in the mode it's running in now (Workshop upgrades).
func damage_scale() -> float:
	return Upgrades.damage_mult(GameState.run, weapon_id, Loadout.mode_key(mode()))


func level() -> Level:
	return player.level if player != null else null


## Enemies within reach that nothing tall stands in front of: tuned targeting and close-range hits
## both use this, so nothing is chosen or struck through a wall, the kiosk or the tram.
func targets_in_range(max_tiles: float) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var lv := level()
	if lv == null:
		return out
	for e: Enemy in lv.living_enemies():
		if Iso.ground_distance(player.global_position, e.global_position) <= max_tiles and lv.grid.line_clear(player.global_position, e.global_position):
			out.append(e)
	return out


## Tuned weapons pick their own target: the nearest one in reach the Steward is willing to aim at (it
## never aims at a boss's weak point it would rather you didn't know about). Falls back to the player's
## aim.
func tuned_direction(max_tiles: float) -> Vector2:
	var willing := targets_in_range(max_tiles).filter(func(e: Node2D) -> bool: return (e as Enemy).steward_aims_at)
	var target := CombatMath.nearest(player.global_position, willing, max_tiles)
	if target != null:
		return Iso.ground_dir_between(player.global_position, target.global_position)
	return player.aim_ground()


func attack_direction(max_tiles: float) -> Vector2:
	return tuned_direction(max_tiles) if is_tuned() else player.aim_ground()
