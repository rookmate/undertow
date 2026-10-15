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
	gait.configure(1.3, 7.0)
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
				return retreat_from(p.global_position, speed_tiles, delta)
			if dist > FAR:
				return steer_to(p.global_position, delta)
			return Vector2.ZERO
		State.WINDUP:
			face_player()
			if _state_time >= windup_seconds():
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
	# From its hand: over the ground point under it, at its height, if that has a clear line to you;
	# otherwise from where it stands (where its warning line ran). Aimed from wherever it leaves.
	var at := hand_at_release()
	var start := global_position + Vector2(at.x, 0.0)
	if not (level.grid.line_clear(global_position, start) and level.grid.line_clear(start, p.global_position)):
		start = global_position
	bale.position = start
	bale.height = clampf(-at.y, 24.0, 140.0)
	bale.direction = Iso.ground_dir_between(start, p.global_position)
	bale.speed_tiles = BALE_SPEED
	bale.damage = BALE_DAMAGE
	bale.radius_tiles = 0.35
	bale.max_tiles = 9.0
	bale.color = Palette.PAPER
	bale.size = 13.0
	bale.tumbling = true
	level.world.add_child(bale)


func draw_ground(ci: CanvasItem) -> void:
	shadow_on(ci, 26.0, 11.0)
	if state == State.WINDUP and not flash_next and level != null and level.player != null:
		var reach := Iso.world_to_grid(level.player.global_position) - Iso.world_to_grid(global_position)
		var k := windup_progress()
		ci.draw_line(Vector2.ZERO, Iso.grid_to_world(reach), Color(Palette.DANGER, 0.2 + 0.5 * k), 2.0 + 3.0 * k, true)


## Its throwing hand at the moment of release (screen offset from its feet), from the rig itself rather
## than from whatever was last drawn. Seen from behind (the original rear painting), its shoulder.
func hand_at_release() -> Vector2:
	if _seen_from_behind():
		return Vector2(0, -138.0 * 0.62 + gait.bob())
	return PaintedBiped.weapon_at("clerk", gait, visual_facing(), 138.0, 1.0)


func _seen_from_behind() -> bool:
	return Iso.grid_to_world(visual_facing()).y < -0.25


func _draw() -> void:
	if _seen_from_behind():
		# Seen from behind: the rig's rear parts are painted with a face, so its back is the original
		# rear painting, carried on its stride. Winding up the Feed, its screen faces you and away from
		# us: the light spills round its head, behind it, whitening as it builds.
		var bob := Vector2(0, gait.bob())
		if state == State.WINDUP and flash_next:
			var k := windup_progress()
			var glow := body_anchor("clerk", "screen", 138.0, bob)
			draw_circle(glow, 16.0 + 14.0 * k, Color(Palette.FEED_WHITE, 0.15 + 0.45 * k), true, -1.0, true)
			draw_circle(glow, 8.0 + 8.0 * k, Color(Palette.FEED_WHITE, 0.3 + 0.5 * k), true, -1.0, true)
		paint_body("clerk", 138.0, bob)
		return
	var throwing := (state == State.WINDUP and not flash_next) or (state == State.RECOVER and flash_next)
	var joints := PaintedBiped.paint(self, "clerk", gait, visual_facing(), 138.0, hit_flash(), attack_pose() if throwing else 0.0)
	if state == State.WINDUP and flash_next:
		var screen := joints["screen"]
		draw_rect(Rect2(screen - Vector2(9, 13), Vector2(18, 26)), Color(Palette.FEED_WHITE, windup_progress()))
