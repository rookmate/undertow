class_name StewardWatch
extends Node
## The Steward quietly profiling how the Operator plays (brief, "Adaptive narration"), and saying
## something about it. Listens to gameplay, feeds the playstyle profile while the voice is on (muted, it
## isn't listening), and passes events to the Narrator.

## Seconds into a district before the Steward says its line about it.
const ENTER_DELAY := 1.4
const MULTI_KILL_WINDOW := 2.0
const IDLE_SECONDS := 9.0
const RELIQUARY_TILES := 4.0
const MODE_REPORT_EVERY := 4.0
## Within this of a place (tiles), the Steward remarks on it.
const PLACE_TILES := 2.5

var level: Level
var _last_kill_at: float = -INF
## How near the last kill was ("close", "far" or ""), and what it was ("custodian", "salvager"...).
var _last_kill_reach: String = ""
var _last_kill_kind: String = ""
var _clock: float = 0.0
var _idle: float = 0.0
var _was_indexed: bool = true
var _reliquary_said: bool = false
var _checkpoint_said: bool = false
var _mode_reported: Dictionary[String, float] = {}
var _places_done: Dictionary[Vector2i, bool] = {}


func setup(owner_level: Level) -> void:
	level = owner_level
	var p := level.player
	p.dodged.connect(_on_dodged)
	p.hurt.connect(_on_hurt)
	p.respawned.connect(func() -> void: _say(&"respawn"))
	level.slow_mo.started.connect(func(_s: float) -> void:
		_record(&"perfect_dodge")
		_say(&"dodge_close"))
	p.weapon_fired.connect(_on_fired)
	level.enemy_died.connect(_on_enemy_died)
	_was_indexed = level.grid.is_indexed(p.cell())
	if not level.is_hub():
		_say_later(&"level_enter", ENTER_DELAY)


func _say_later(event: StringName, seconds: float) -> void:
	await Wait.seconds(self, seconds)
	_say(event)


## `seen`: what it saw of the moment, for the lines that say so (LineSelector.fits: "reach").
func _say(event: StringName, seen: Dictionary = {}) -> void:
	Narrator.notify(event, level.level_id, seen)


## The Steward only profiles what it can perceive: voice on, Lattice in reach, and not on the Ark (where
## rolling around is just walking, not a combat choice). Under "Stop praising me" it stops learning what
## you like to hear.
func _record(event: StringName, weight: float = 1.0) -> void:
	if Steward.assists().steward_present and not level.is_hub() and not GameState.has_override(Overrides.NO_PRAISE):
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
	# The Ark has no Lattice: nothing to step off or back onto.
	if level.is_hub():
		return
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
	if not _checkpoint_said and cell != level.grid.start_cell() and cell == level.checkpoint_cell:
		_checkpoint_said = true
		_say(&"checkpoint")
	# The places it has something to say about.
	for c: Vector2i in level.grid.places:
		if not _places_done.has(c) and Iso.ground_distance(p.global_position, Iso.cell_center(c)) <= PLACE_TILES:
			if Narrator.say_place(level.grid.places[c]):
				_places_done[c] = true
	if not _reliquary_said and Iso.ground_distance(p.global_position, Iso.cell_center(level.grid.first("R"))) < RELIQUARY_TILES:
		# Said once, when it can be (not over a line being heard out).
		_reliquary_said = not Narrator.in_full_in_progress()
		if _reliquary_said:
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
	if not Steward.assists().steward_present:
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
	# A boss's end is its own line (boss_down), and no part of a pair.
	if e is Boss:
		return
	# Up close or at range, its lines can say so; in between, they don't say. What it was (a Custodian, a
	# Salvager), for the lines about its job. Two at once: each only if both were.
	var reach := "close" if close else ("far" if dist >= 3.0 else "")
	var kind := String(e.get_script().get_global_name()).to_lower()
	var seen := {}
	if _clock - _last_kill_at <= MULTI_KILL_WINDOW:
		# Two quick kills only read as risk when they were up close.
		if close:
			_record(&"multi_kill")
		if reach != "" and reach == _last_kill_reach:
			seen["reach"] = reach
		if kind == _last_kill_kind:
			seen["kind"] = kind
		_say(&"multi_kill", seen)
	else:
		seen["kind"] = kind
		if reach != "":
			seen["reach"] = reach
		_say(&"kill", seen)
	_last_kill_at = _clock
	_last_kill_reach = reach
	_last_kill_kind = kind
