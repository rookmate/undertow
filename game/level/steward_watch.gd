class_name StewardWatch
extends Node
## The Steward quietly profiling how the Operator plays (brief, "Adaptive narration"), and saying
## something about it. Listens to gameplay, feeds the playstyle profile while the voice is on (muted, it
## isn't listening), and passes events to the Narrator.

const MULTI_KILL_WINDOW := 2.0
const IDLE_SECONDS := 9.0
const RELIQUARY_TILES := 4.0
const MODE_REPORT_EVERY := 4.0

var level: Level
var _last_kill_at: float = -INF
var _clock: float = 0.0
var _idle: float = 0.0
var _was_indexed: bool = true
var _reliquary_said: bool = false
var _checkpoint_said: bool = false
var _mode_reported: Dictionary[String, float] = {}


func setup(owner_level: Level) -> void:
	level = owner_level
	var p := level.player
	p.dodged.connect(_on_dodged)
	p.hurt.connect(_on_hurt)
	p.respawned.connect(func() -> void: _say(&"respawn"))
	level.slow_mo.started.connect(func(_s: float) -> void:
		_record(&"perfect_dodge")
		_say(&"dodge_close"))
	for w: Weapon in p.weapons:
		w.fired.connect(_on_fired.bind(w))
	level.enemy_died.connect(_on_enemy_died)
	_was_indexed = level.grid.is_indexed(p.cell())
	_say_later(&"level_enter", 1.4)


func _say_later(event: StringName, seconds: float) -> void:
	await Wait.seconds(self, seconds)
	_say(event)


func _say(event: StringName) -> void:
	Narrator.notify(event)


func _record(event: StringName, weight: float = 1.0) -> void:
	if Steward.voice_on:
		GameState.record_playstyle(event, weight)


func _process(delta: float) -> void:
	if get_tree().paused or level.player == null:
		return
	_clock += delta
	var p := level.player
	# Idle: no movement or attacks for a while.
	if p.velocity.length_squared() > 4.0 or Input.is_action_pressed(&"attack_primary") or Input.is_action_pressed(&"attack_secondary"):
		_idle = 0.0
	else:
		_idle += delta
		if _idle > IDLE_SECONDS:
			_idle = 0.0
			_say(&"idle")
	# Stepping off the Lattice and back.
	var cell := p.cell()
	if level.grid.is_walkable(cell):
		var indexed := level.grid.is_indexed(cell)
		if indexed != _was_indexed:
			_was_indexed = indexed
			if indexed:
				_record(&"returned_to_path")
				_say(&"path_returned")
			else:
				_record(&"left_path")
				_say(&"path_left")
	if not _checkpoint_said and cell != level.grid.first("P") and cell == level.checkpoint_cell:
		_checkpoint_said = true
		_say(&"checkpoint")
	if not _reliquary_said and Iso.ground_distance(p.global_position, Iso.cell_center(level.grid.first("R"))) < RELIQUARY_TILES:
		_reliquary_said = true
		_say(&"reliquary_near")


func _on_dodged(ground_dir: Vector2) -> void:
	_record(&"dodge")
	var nearest: Enemy = null
	var best := 3.0
	for e: Enemy in level.living_enemies():
		var d := Iso.ground_distance(level.player.global_position, e.global_position)
		if d < best:
			best = d
			nearest = e
	if nearest != null and ground_dir.dot(Iso.ground_dir_between(level.player.global_position, nearest.global_position)) < 0.0:
		_record(&"retreat")


func _on_hurt(_amount: float) -> void:
	if not level.player.dodge.is_rolling():
		_record(&"hit_taken_no_dodge")
	if level.player.integrity.ratio() < 0.35:
		_say(&"low_integrity")
	else:
		_say(&"hurt")


func _on_fired(w: Weapon) -> void:
	if not Steward.voice_on:
		return
	if _clock - float(_mode_reported.get(w.weapon_id, -INF)) < MODE_REPORT_EVERY:
		return
	_mode_reported[w.weapon_id] = _clock
	if w.is_tuned():
		_record(&"tuned_mode_used")
	else:
		_record(&"manual_mode_used")
		_say(&"weapon_manual")


func _on_enemy_died(e: Enemy) -> void:
	var p := level.player
	var dist := Iso.ground_distance(p.global_position, e.global_position)
	var close := dist <= 1.8
	if close:
		_record(&"kill_close")
	elif dist >= 3.0:
		_record(&"kill_at_range")
	if p.integrity.ratio() < 0.35:
		_record(&"kill_low_health")
	if _clock - _last_kill_at <= MULTI_KILL_WINDOW:
		# Two quick kills only read as risk when they were up close.
		if close:
			_record(&"multi_kill")
		_say(&"multi_kill")
	else:
		_say(&"kill")
	_last_kill_at = _clock
