class_name Projectile
extends Node2D
## A pellet or a paper bale, moving across the ground and drawn at chest height. Depth-sorted with
## the world by its ground position. Hits are resolved in ground space, not with physics.

enum Team { PLAYER, ENEMY }

const CHEST_HEIGHT := 64.0

var team: Team = Team.PLAYER
var level: Level
var direction: Vector2 = Vector2(0, -1)
var speed_tiles: float = 12.0
var damage: float = 4.0
var radius_tiles: float = 0.18
var max_tiles: float = 8.0
var pierce: int = 0
var knock_tiles: float = 0.15
var color: Color = Color.WHITE
var size: float = 5.0
## Paper bales tumble; pellets streak.
var tumbling: bool = false

var _travelled: float = 0.0
var _hit: Array[Node] = []


func _ready() -> void:
	material = Emissive.unshaded_material() if team == Team.PLAYER else null


## Moves one tick, testing the whole swept segment: walls and bodies are resolved in the order the shot
## reaches them, so nothing is skipped at speed and nothing is hit through a corner.
func _physics_process(delta: float) -> void:
	if level == null:
		queue_free()
		return
	var step_world := Iso.ground_velocity(direction, speed_tiles) * delta
	var from := Iso.world_to_grid(position)
	var to := Iso.world_to_grid(position + step_world)
	var wall_t := level.grid.first_block(from, to)
	if wall_t < 0.0:
		wall_t = INF
	var hits: Array[Array] = []
	if team == Team.PLAYER:
		for e: Enemy in level.living_enemies():
			if _hit.has(e):
				continue
			var t := CombatMath.segment_hit(from, to, Iso.world_to_grid(e.global_position), radius_tiles + e.radius_tiles)
			if t >= 0.0 and t <= wall_t:
				hits.append([t, e])
	else:
		var p := level.player
		if p != null and p.is_alive() and not _hit.has(p):
			var t := CombatMath.segment_hit(from, to, Iso.world_to_grid(p.global_position), radius_tiles + Operator.RADIUS_TILES)
			if t >= 0.0 and t <= wall_t:
				hits.append([t, p])
	hits.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	for h: Array in hits:
		if _strike(h[1]):
			position += step_world * float(h[0])
			queue_free()
			return
	if wall_t != INF:
		queue_free()
		return
	position += step_world
	_travelled += speed_tiles * delta
	if _travelled > max_tiles:
		queue_free()
		return
	queue_redraw()


## Applies a hit. Returns true if the projectile is spent.
func _strike(target: Node) -> bool:
	_hit.append(target)
	if target is Enemy:
		(target as Enemy).take_hit(damage, direction, knock_tiles, 0.0)
		if pierce <= 0:
			return true
		pierce -= 1
		return false
	var p := target as Operator
	# A bale that meets a roll's invulnerability passes through.
	return p.take_hit(damage, global_position - Iso.ground_velocity(direction, 1.0))


func _draw() -> void:
	var lift := Vector2(0, -CHEST_HEIGHT)
	draw_colored_polygon(_shadow(), Color(Palette.NEAR_BLACK, 0.3))
	if tumbling:
		var a := _travelled * 6.0
		var corners := PackedVector2Array()
		for i: int in 4:
			corners.append(lift + Vector2.from_angle(a + i * TAU / 4.0) * size)
		draw_colored_polygon(corners, color)
		draw_polyline(PackedVector2Array([corners[0], corners[2]]), Color(Palette.NEAR_BLACK, 0.4), 1.5)
	else:
		var tail := Iso.ground_velocity(direction, 1.0).normalized() * -size * 3.0
		draw_line(lift, lift + tail, Color(color, 0.45), size * 0.8, true)
		draw_circle(lift, size * 0.6, color, true, -1.0, true)


func _shadow() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 10:
		var a := TAU * i / 10.0
		pts.append(Vector2(cos(a) * size, sin(a) * size * 0.5))
	return pts
