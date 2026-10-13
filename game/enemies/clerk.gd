class_name Clerk
extends Enemy
## A Vellum sorting unit. Keeps its distance and attacks in turn: a paper bale (a red line to it as it
## winds up), then the Feed (its black-mirror screen whitening as it winds up, then turned on you full:
## look at it and the world washes out for a moment, FeedBlind; look away, or roll). Tall, narrow,
## paper-grey.

const MAX_INTEGRITY := 40.0
const WINDUP := 0.75
const RECOVER := 0.45
const ATTACK_EVERY := 2.4
const BALE_DAMAGE := 10.0
const BALE_SPEED := 6.0
const NEAR := 3.5
const FAR := 5.5
## The Feed's reach, and how long it washes the world out.
const FLASH_REACH := 7.0
const BLIND_SECONDS := 1.4

var _since_attack: float = 1.2
## The next attack is the Feed, not a bale (they take turns, a bale first).
var flash_next: bool = false


func _ready() -> void:
	scrap_value = 2
	radius_tiles = 0.32
	speed_tiles = 1.8
	aggro_tiles = 6.5
	leash_tiles = 11.0


func windup_seconds() -> float:
	return WINDUP * windup_scale


func _think(delta: float) -> Vector2:
	var p := player()
	var dist := distance_to_player()
	var player_ok := p != null and p.is_alive()
	_since_attack += delta
	match state:
		State.IDLE:
			if player_ok and dist <= aggro_tiles:
				_enter(State.CHASE)
			return Vector2.ZERO
		State.CHASE:
			if not player_ok or dist > leash_tiles:
				_enter(State.IDLE)
				return Vector2.ZERO
			face_player()
			if _since_attack >= ATTACK_EVERY and dist <= FAR + 1.0:
				_enter(State.WINDUP)
				return Vector2.ZERO
			if dist < NEAR:
				return Iso.ground_velocity(-facing_ground, speed_tiles)
			if dist > FAR:
				return steer_to(p.global_position, delta)
			return Vector2.ZERO
		State.WINDUP:
			face_player()
			if _state_time >= WINDUP:
				if flash_next:
					_flash_feed()
				else:
					_throw()
				flash_next = not flash_next
				_enter(State.RECOVER)
			return Vector2.ZERO
		State.RECOVER:
			if _state_time >= RECOVER:
				_enter(State.CHASE)
			return Vector2.ZERO
	return Vector2.ZERO


func _flash_feed() -> void:
	_since_attack = 0.0
	Sound.play(&"feed_flash", global_position)
	if level != null:
		level.flash_feed(global_position, FLASH_REACH, BLIND_SECONDS)


func _throw() -> void:
	_since_attack = 0.0
	Sound.play(&"bale_throw", global_position)
	var p := player()
	if p == null or level == null:
		return
	var bale := Projectile.new()
	bale.team = Projectile.Team.ENEMY
	bale.level = level
	bale.direction = Iso.ground_dir_between(global_position, p.global_position)
	bale.speed_tiles = BALE_SPEED
	bale.damage = BALE_DAMAGE
	bale.radius_tiles = 0.35
	bale.max_tiles = 9.0
	bale.color = Palette.PAPER
	bale.size = 13.0
	bale.tumbling = true
	bale.position = global_position + Iso.ground_velocity(bale.direction, 0.5)
	level.world.add_child(bale)


func _draw() -> void:
	draw_shadow(26.0, 11.0)
	if state == State.WINDUP and not flash_next and level != null and level.player != null:
		var reach := Iso.world_to_grid(level.player.global_position) - Iso.world_to_grid(global_position)
		var k := windup_progress()
		draw_line(Vector2.ZERO, Iso.grid_to_world(reach), Color(Palette.DANGER, 0.2 + 0.5 * k), 2.0 + 3.0 * k, true)
	var shell := Palette.CLERK_SHELL.lerp(Palette.IVORY, hit_flash())
	var legs := Palette.IRON_DARK
	draw_line(Vector2(-10, -40), Vector2(-14, 0), legs, 5.0)
	draw_line(Vector2(10, -40), Vector2(14, 0), legs, 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -40), Vector2(20, -40), Vector2(18, -132), Vector2(-18, -132)]), shell)
	draw_rect(Rect2(-16, -58, 32, 6), Palette.IRON_DARK)
	var screen := Rect2(-13, -122, 26, 40)
	var screen_col := Palette.BLACK_MIRROR
	if state == State.WINDUP and flash_next:
		screen_col = Palette.BLACK_MIRROR.lerp(Palette.FEED_WHITE, windup_progress())
	draw_rect(screen, screen_col)
	draw_rect(Rect2(-22, -138, 44, 8), Palette.STONE_OLD)
