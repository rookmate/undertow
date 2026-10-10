class_name Tide
extends Node
## The tide in Greywater (world bible: with no one running the pumps, the low streets flood on a cycle).
## Low water, then the swell (the water rising; while it listens, the Steward warns you and its path
## moves to high ground), then high water: anyone standing in the low streets wades at half speed and
## is stung by the cold every second. Then the ebb. With the Pumphouse rebuilt on the Ark, high water is
## lower and shorter and doesn't sting (it still slows you).

signal phase_changed(phase: Phase)

enum Phase { LOW, SWELL, HIGH, EBB }

const LOW_SECONDS := 30.0
const SWELL_SECONDS := 6.0
const HIGH_SECONDS := 14.0
const EBB_SECONDS := 4.0
## With the Pumphouse rebuilt.
const PUMPED_HIGH_SECONDS := 6.0
const STING := 5.0
const STING_EVERY := 1.0
## Wading at high water, as a share of walking speed.
const WADE := 0.5

var level: Level
var phase: Phase = Phase.LOW
## The cells that flood (Greywater's low streets, kelp and all).
var cells: Array[Vector2i] = []
var _lookup: Dictionary[Vector2i, bool] = {}
var _phase_time: float = 0.0
var _sting_in: float = 0.0


func setup(owner_level: Level, floodable: Array[Vector2i]) -> void:
	level = owner_level
	cells = floodable
	for c: Vector2i in cells:
		_lookup[c] = true


## The Pumphouse on the Ark lowers the tide hazard citywide.
static func pumped() -> bool:
	return GameState.run.buildings_restored.has("pumphouse")


func high_seconds() -> float:
	return PUMPED_HIGH_SECONDS if pumped() else HIGH_SECONDS


func floods(cell: Vector2i) -> bool:
	return _lookup.has(cell)


## The water's over this cell now.
func is_flooded(cell: Vector2i) -> bool:
	return phase == Phase.HIGH and _lookup.has(cell)


## 0 (low water) .. 1 (high water), for drawing the water and reading the gauges.
func water_level() -> float:
	match phase:
		Phase.SWELL:
			return clampf(_phase_time / SWELL_SECONDS, 0.0, 1.0)
		Phase.HIGH:
			return 1.0
		Phase.EBB:
			return 1.0 - clampf(_phase_time / EBB_SECONDS, 0.0, 1.0)
	return 0.0


## A boss is fighting in this district now.
func boss_fighting() -> bool:
	return level != null and is_instance_valid(level.boss) and level.boss.is_fighting and level.boss.is_alive()


## How fast you can move on this cell (1 on dry ground).
func footing(cell: Vector2i) -> float:
	return WADE if is_flooded(cell) else 1.0


func enter(next: Phase) -> void:
	phase = next
	_phase_time = 0.0
	_sting_in = 0.0
	if next == Phase.SWELL:
		# While a boss fights, its calls have the Steward's voice (the Lung's island is high ground).
		if not boss_fighting():
			Narrator.say_fixed("tide_swell")
		Sound.play(&"tide_swell")
	phase_changed.emit(next)


func _physics_process(delta: float) -> void:
	_phase_time += delta
	match phase:
		Phase.LOW:
			if _phase_time >= LOW_SECONDS:
				enter(Phase.SWELL)
		Phase.SWELL:
			if _phase_time >= SWELL_SECONDS:
				enter(Phase.HIGH)
		Phase.HIGH:
			_sting(delta)
			if _phase_time >= high_seconds():
				enter(Phase.EBB)
		Phase.EBB:
			if _phase_time >= EBB_SECONDS:
				enter(Phase.LOW)


## High water stings the Operator standing in it (unless the Pumphouse has calmed it).
func _sting(delta: float) -> void:
	var p := level.player if level != null else null
	if p == null or not p.is_alive() or pumped() or not is_flooded(p.cell()):
		_sting_in = 0.0
		return
	_sting_in -= delta
	if _sting_in <= 0.0:
		_sting_in = STING_EVERY
		p.take_hit(STING, p.global_position + Iso.ground_velocity(Vector2(0, 1), 1.0))
