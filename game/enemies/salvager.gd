class_name Salvager
extends Enemy
## A Tideworks cargo drone that lost its manifest and now collects anything metal (world bible). It comes
## for your second weapon, snatches it, and flies off with it; take it down to get it back. If you only
## carry one weapon it never takes that: it lifts a few parts of scrap instead.

const MAX_INTEGRITY := 30.0
## It closes to this, then winds up; at the snatch it takes what's within catch_reach() (the ring it
## draws while winding up) and in its sight.
const SNATCH_REACH := 1.1
const WINDUP := 0.6
const FLEE_SPEED := 3.4
const SCRAP_TAKEN := 3

## What it's carrying off: {"id", "mode"} for a weapon, {"scrap": n} for parts, {} for nothing.
var loot: Dictionary = {}

var _hover: float = 0.0
var _claw_extension: float = 0.0


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
		# Away with it, round whatever's in the way rather than into it.
		if not player_ok or distance_to_player() >= leash_tiles:
			return Vector2.ZERO
		return retreat_from(p.global_position, FLEE_SPEED, delta)
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
			if distance_to_player() <= SNATCH_REACH and level.grid.line_clear(global_position, p.global_position):
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


## How far its claw catches you at the snatch: your body inside its ring.
static func catch_reach() -> float:
	return SNATCH_REACH + Operator.RADIUS_TILES


## Takes the second weapon if there is one (never the only one), else some scrap.
func _snatch(p: Operator) -> void:
	if p == null or not p.is_alive() or distance_to_player() > catch_reach() or p.is_invulnerable():
		return
	if level != null and not level.grid.line_clear(global_position, p.global_position):
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


func visual_facing() -> Vector2:
	return gait.direction if not loot.is_empty() else facing_ground


func _physics_process(delta: float) -> void:
	super(delta)
	var reach := windup_progress() if state == State.WINDUP else (0.35 if not loot.is_empty() else 0.0)
	_claw_extension = move_toward(_claw_extension, reach, delta * 8.0)


## Its painting is dark teal on dark streets: drawn a little larger and lifted, so it reads.
const DRAW_HEIGHT := 64.0
const BRIGHTNESS := 1.45


func draw_ground(ci: CanvasItem) -> void:
	shadow_on(ci, 15.0, 7.0)
	windup_ring_on(ci, catch_reach())


func _draw() -> void:
	var lift := -46.0 + sin(_hover) * 4.0
	# The claw reaches for you; carrying, it hangs with what it took.
	var aim := Vector2(0, 1)
	var p := player()
	if loot.is_empty() and p != null:
		aim = (p.global_position - Vector2(0, Projectile.CHEST_HEIGHT * 0.5) - (global_position + Vector2(0, lift))).normalized()
	var tips := PaintedHover.paint(self, "salvager", visual_facing(), DRAW_HEIGHT, Vector2(0, lift + 26.0), hit_flash(), _claw_extension, not loot.is_empty(), aim, BRIGHTNESS)
	if not loot.is_empty():
		ArtCatalog.paint(self, "crate", Rect2(tips[0] - Vector2(10, 5), Vector2(20, 12)))
