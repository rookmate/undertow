class_name Boss
extends Enemy
## A district's last order, embodied (world bible, "What still lives here"). A set piece rather than a
## chaser: it stays where it was built, it's armoured except in its openings, it has a bar on the HUD,
## and its fight has two solutions. The Steward-tuned one: with the voice on, the Steward calls each
## move before it comes. The manual one: a weakness the Steward never mentions (and never aims at), which
## makes the fight shorter and harder. Taking it apart opens the way on (BossBarrier) and gives up a lot
## of scrap.

signal engaged
signal defeated
## A new stage begins (2, 3): the transition starts.
signal stage_began(stage: int)

const ENGAGE_TILES := 7.0
## Its fight waits while the Steward introduces it (the boss_engaged line, said aloud), never longer than
## this: its first call would otherwise cut the introduction off mid-word. Muted, or cut short, it starts
## at once.
const OPENING_MAX := 6.0
## Restarted after you died (Level.restart_boss_fight): it won't engage for this long after it's back, so
## you get your feet under you at the checkpoint.
const RETRY_GRACE := 2.0
## Stages (DECISIONS 179). A boss with more than one gets harder as it's taken apart: at each threshold of
## its integrity (two thirds and one third for three stages, half for two) it stops for this long (it
## can't be hurt; the Steward says what's changed, if it can see it), then fights its next stage. One
## blow never carries it past a threshold.
const STAGE_TRANSITION := 3.2

## Shown on the HUD bar.
var boss_name: String = "BOSS"
## True once the Operator has come within reach; the fight doesn't start before.
var is_engaged: bool = false
## True once the introduction is over and the fight has begun.
var is_fighting: bool = false
## A restarted fight: no introduction this time.
var retrying: bool = false
## Its stage (1 to stage_count()), and how long the transition into it has left.
var stage: int = 1
var _transition_left: float = 0.0
var _since_built: float = 0.0
## The introduction being said ("" if none), and how long it's been going.
var _intro: String = ""
var _opening: float = 0.0


func _ready() -> void:
	speed_tiles = 0.0
	scrap_value = 20
	add_to_group(&"bosses")


## Its weak point (WeakPoint), if it has one.
var weak_point: WeakPoint


## Only true in its openings; otherwise blows ring off its armour.
func is_vulnerable() -> bool:
	return false


## How many stages its fight has (1: none).
func stage_count() -> int:
	return 1


## The integrity ratios at which each next stage begins (highest first).
func stage_thresholds() -> Array[float]:
	match stage_count():
		2:
			return [0.5]
		3:
			return [2.0 / 3.0, 1.0 / 3.0]
	return []


## Between stages: it can't be hurt, and it isn't fighting.
func in_transition() -> bool:
	return _transition_left > 0.0


## The Steward's word as a stage begins ("" for none). Listed in CALL_GAPS like any call.
func stage_line(_next_stage: int) -> String:
	return ""


## A stage is beginning: stop whatever it was doing (the transition is a pause, not an attack).
func _on_stage_begins(_next_stage: int) -> void:
	pass


## The transition is over: start fighting this stage.
func _on_stage(_now: int) -> void:
	pass


## The window for its weak point.
func is_switching() -> bool:
	return false


## Its weak point was struck (only matters while switching).
func on_weak_point_hit() -> void:
	pass


func take_hit(amount: float, from_dir: Vector2, _knock_tiles: float, _stun_seconds: float) -> void:
	if state == State.DEAD:
		return
	if in_transition() or not is_vulnerable():
		Sound.play(&"armour_clang", global_position)
		_flash = 0.05
		return
	# Bosses don't get knocked about or stunned by ordinary blows; their own openings are the stun. A blow
	# stops at the next stage's threshold.
	var floor_value := _next_threshold() * integrity.max_value
	integrity.take(minf(amount, integrity.value - floor_value) if floor_value > 0.0 else amount)
	_flash = 0.12
	Sound.play(&"machine_hit", global_position)
	if integrity.is_depleted():
		_die()
	elif floor_value > 0.0 and integrity.value <= floor_value + 0.001:
		_begin_stage(stage + 1)
	_on_hurt(amount, from_dir)


## The ratio at which the next stage begins, or 0 if this is the last.
func _next_threshold() -> float:
	var thresholds := stage_thresholds()
	return thresholds[stage - 1] if stage - 1 < thresholds.size() else 0.0


func _begin_stage(next_stage: int) -> void:
	stage = next_stage
	_transition_left = STAGE_TRANSITION
	_on_stage_begins(next_stage)
	var line := stage_line(next_stage)
	if line != "":
		call_out(line)
	Sound.play(&"container_drop", global_position)
	stage_began.emit(next_stage)


func _on_hurt(_amount: float, _from_dir: Vector2) -> void:
	pass


func _think(_delta: float) -> Vector2:
	var p := player()
	_since_built += _delta
	var ready_again := not retrying or _since_built >= RETRY_GRACE
	if not is_engaged and ready_again and p != null and p.is_alive() and distance_to_player() <= ENGAGE_TILES:
		is_engaged = true
		engaged.emit()
		if not retrying:
			_intro = Narrator.notify(&"boss_engaged", level.level_id if level != null else "")
	if is_engaged and not is_fighting:
		_opening += _delta
		if introducing() and _opening < OPENING_MAX:
			return Vector2.ZERO
		is_fighting = true
		_on_engaged()
	if is_fighting:
		if in_transition():
			_transition_left -= _delta
			if not in_transition():
				_on_stage(stage)
			return Vector2.ZERO
		_fight(_delta)
	return Vector2.ZERO


## The Steward is still saying its introduction.
func introducing() -> bool:
	return _intro != "" and Sound.voice_line == _intro and Sound.voice_left() > 0.0


func _on_engaged() -> void:
	pass


## One frame of the fight once engaged.
func _fight(_delta: float) -> void:
	pass


## The Steward calls a move: only if it's with you (voice on and on its hardware) and no signed order
## forbids it (its warnings fall silent under "Never warn me about traps"). Voiced, subtitled. Each boss
## lists its calls in CALL_GAPS with the soonest the next call can come, and a test keeps every
## recording short enough to be said in full.
func call_out(line_id: String) -> void:
	Narrator.say_fixed(line_id, true)


func _die() -> void:
	if weak_point != null:
		weak_point.retire()
	super()
	defeated.emit()
	for n: Node in get_tree().get_nodes_in_group(&"boss_barriers"):
		if level != null and level.is_ancestor_of(n):
			(n as BossBarrier).open_up()
