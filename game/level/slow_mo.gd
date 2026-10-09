class_name SlowMo
extends Node
## Slowed time on a well-timed dodge, a Steward assist (voice on only). A dodge counts when it starts
## close to an enemy winding up or an incoming bale, or when a hit lands inside the roll's
## invulnerability. Timed in unscaled time, so the slowdown can't stretch itself.

signal started(seconds: float)

const NEAR_THREAT_TILES := 2.4

var level: Level
## Unscaled seconds of slow-mo left.
var _left: float = 0.0


func setup(owner_level: Level) -> void:
	level = owner_level
	process_mode = Node.PROCESS_MODE_ALWAYS
	level.player.dodged.connect(_on_dodged)
	level.player.evaded.connect(_on_evaded)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func is_active() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta / maxf(Engine.time_scale, 0.01)
	if _left <= 0.0:
		_left = 0.0
		Engine.time_scale = 1.0


func _on_dodged(_dir: Vector2) -> void:
	if _threat_near():
		trigger()


func _on_evaded() -> void:
	trigger()


func trigger() -> void:
	var seconds := Steward.assists().dodge_slowmo_seconds
	if seconds <= 0.0 or is_active():
		return
	_left = seconds
	Engine.time_scale = Assists.SLOWMO_TIME_SCALE
	started.emit(seconds)
	GameState.record_playstyle(&"perfect_dodge")


func _threat_near() -> bool:
	var p := level.player.global_position
	for e: Enemy in level.living_enemies():
		if e.state == Enemy.State.WINDUP and Iso.ground_distance(p, e.global_position) <= NEAR_THREAT_TILES:
			return true
	for n: Node in level.world.get_children():
		var proj := n as Projectile
		if proj != null and proj.team == Projectile.Team.ENEMY and Iso.ground_distance(p, proj.position) <= NEAR_THREAT_TILES:
			return true
	return false
