class_name Salvager
extends Enemy
## A Tideworks cargo drone that lost its manifest and now collects anything metal (world bible). It comes
## for your second weapon, snatches it, and flies off with it; take it down to get it back. If you only
## carry one weapon it never takes that: it lifts a few parts of scrap instead.

const MAX_INTEGRITY := 30.0
const SNATCH_REACH := 1.1
const WINDUP := 0.6
const FLEE_SPEED := 3.4
const SCRAP_TAKEN := 3

## What it's carrying off: {"id", "mode"} for a weapon, {"scrap": n} for parts, {} for nothing.
var loot: Dictionary = {}

var _hover: float = 0.0


func _ready() -> void:
	radius_tiles = 0.34
	speed_tiles = 2.6
	aggro_tiles = 5.0
	leash_tiles = 14.0
	scrap_value = 2
	_hover = randf() * TAU


func windup_seconds() -> float:
	return WINDUP * windup_scale


func _think(delta: float) -> Vector2:
	_hover += delta * 3.0
	var p := player()
	var player_ok := p != null and p.is_alive()
	if not loot.is_empty():
		# Away with it: back toward where it came from, past it if it can.
		var away := Iso.ground_dir_between(p.global_position, global_position) if player_ok else Vector2(0, -1)
		return Iso.ground_velocity(away, FLEE_SPEED) if distance_to_player() < leash_tiles else Vector2.ZERO
	match state:
		State.IDLE:
			if player_ok and distance_to_player() <= aggro_tiles:
				_enter(State.CHASE)
			return Vector2.ZERO
		State.CHASE:
			if not player_ok:
				_enter(State.IDLE)
				return Vector2.ZERO
			face_player()
			if distance_to_player() <= SNATCH_REACH:
				_enter(State.WINDUP)
				return Vector2.ZERO
			return steer_to(p.global_position, delta)
		State.WINDUP:
			face_player()
			if _state_time >= windup_seconds():
				_snatch(p)
				_enter(State.RECOVER)
			return Vector2.ZERO
		State.RECOVER:
			if _state_time >= 0.8:
				_enter(State.CHASE)
			return Vector2.ZERO
	return Vector2.ZERO


## Takes the second weapon if there is one (never the only one), else some scrap.
func _snatch(p: Operator) -> void:
	if p == null or not p.is_alive() or distance_to_player() > SNATCH_REACH + 0.4 or p.is_invulnerable():
		return
	if p.weapons.size() >= 2:
		loot = p.take_weapon(1)
	else:
		var n := mini(SCRAP_TAKEN, GameState.run.scrap)
		if n > 0:
			GameState.add_scrap(-n)
			loot = {"scrap": n}
	if not loot.is_empty():
		Sound.play(&"bale_throw", global_position)


func _die() -> void:
	# Whatever it took drops back to you.
	var p := player()
	if loot.has("id") and p != null:
		p.add_weapon(str(loot["id"]), loot["mode"])
	elif loot.has("scrap"):
		GameState.add_scrap(int(loot["scrap"]))
	loot = {}
	super()


func _draw() -> void:
	var lift := -46.0 + sin(_hover) * 4.0
	draw_shadow(14.0, 7.0)
	var flash := hit_flash()
	var body := Palette.CONTAINER_GREY.lerp(Palette.IVORY, flash)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, lift), Vector2(0, lift + 9), Vector2(18, lift), Vector2(0, lift - 9)]), body)
	for x: float in [-22.0, 22.0]:
		draw_line(Vector2(0, lift), Vector2(x, lift - 6), Palette.IRON_DARK, 2.0, true)
		draw_circle(Vector2(x, lift - 6), 7.0, Palette.IRON_DARK, false, 1.5, true)
	# Its claw, and anything in it.
	draw_line(Vector2(0, lift + 9), Vector2(0, lift + 22), Palette.IRON_DARK, 2.0, true)
	if loot.has("id"):
		draw_rect(Rect2(-10, lift + 22, 20, 8), Palette.GREY_COLD)
	elif loot.has("scrap"):
		draw_circle(Vector2(0, lift + 26), 5.0, Palette.GREY_COLD, true, -1.0, true)
	if state == State.WINDUP:
		draw_windup_ring(SNATCH_REACH)
