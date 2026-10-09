class_name CombatMath
extends RefCounted
## Pure combat rules shared by weapons, enemies and tests. Directions are grid-space ("ground") vectors;
## positions are screen positions converted with Iso.

## Damage the Operator takes. With the voice off nothing warns you and enemies hit harder (brief: voice
## table; HUD mock: "DMG TAKEN ×1.4").
static func damage_taken(base: float, voice_on: bool) -> float:
	return base * (1.0 if voice_on else Tunables.MUTED_DAMAGE_TAKEN_MULT)


## Whether `target` (screen position) is within `range_tiles` of `origin` and inside an arc of
## `arc_deg` centred on `facing` (ground direction). `target_radius` widens the reach for big targets.
static func in_arc(origin: Vector2, facing: Vector2, target: Vector2, range_tiles: float, arc_deg: float, target_radius: float = 0.0) -> bool:
	var to := Iso.world_to_grid(target) - Iso.world_to_grid(origin)
	var dist := to.length()
	if dist > range_tiles + target_radius:
		return false
	if dist < 0.0001:
		return true
	return absf(rad_to_deg(facing.angle_to(to))) <= arc_deg * 0.5


## Nearest node within `max_tiles` of `origin`, or null.
static func nearest(origin: Vector2, candidates: Array[Node2D], max_tiles: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_tiles
	for c: Node2D in candidates:
		var d := Iso.ground_distance(origin, c.global_position)
		if d <= best_d:
			best = c
			best_d = d
	return best


## Aim assist: bends `aim` (ground direction) toward the candidate closest to it inside `cone_deg`,
## by `strength` (0 = none, 1 = snap). Returns the aim unchanged if nothing is in the cone.
static func assist_aim(aim: Vector2, origin: Vector2, candidates: Array[Node2D], max_tiles: float, cone_deg: float, strength: float) -> Vector2:
	if strength <= 0.0 or aim.length_squared() < 0.0001:
		return aim
	var best_dir := Vector2.ZERO
	var best_angle := cone_deg * 0.5
	for c: Node2D in candidates:
		var to := Iso.world_to_grid(c.global_position) - Iso.world_to_grid(origin)
		if to.length() > max_tiles or to.length() < 0.0001:
			continue
		var angle := absf(rad_to_deg(aim.angle_to(to)))
		if angle <= best_angle:
			best_angle = angle
			best_dir = to.normalized()
	if best_dir == Vector2.ZERO:
		return aim
	return aim.normalized().slerp(best_dir, clampf(strength, 0.0, 1.0)).normalized()
