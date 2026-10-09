class_name LevelAudio
extends Node
## A level's sound: footsteps by surface, and the ambience layers. Rain everywhere above ground; the stacks
## close in (dry room tone, the rain far above); the Lattice hums only while the Steward is with you, so
## muting it (or walking off its hardware) is heard as well as seen. The Ark sits in the estuary wind.

## Ground tiles walked between footsteps.
const STEP_TILES := 0.62

var level: Level
var _walked: float = 0.0
var _last: Vector2 = Vector2.INF


func _process(_delta: float) -> void:
	if level == null or level.player == null:
		return
	_ambience()
	_footsteps()


func _ambience() -> void:
	if level.is_hub():
		Sound.set_ambience({&"estuary": 1.0, &"rain": 0.45})
		return
	var below := level.grid.floor_at(level.player.cell()) == LevelGrid.Floor.STACKS
	Sound.set_ambience({
		&"rain": 0.3 if below else 1.0,
		&"underground": 1.0 if below else 0.0,
		&"lattice_hum": 1.0 if Steward.assists().steward_present else 0.0,
	})


func _footsteps() -> void:
	var p := level.player
	var now := p.global_position
	if _last == Vector2.INF or not p.is_alive():
		_last = now
		return
	_walked += Iso.ground_distance(_last, now)
	_last = now
	if _walked < STEP_TILES:
		return
	_walked = 0.0
	if p.dodge.is_rolling():
		return
	Sound.play(step_cue(level.grid.floor_at(p.cell())), now)


## Wet stone outside; dry concrete and paper inside and on the Ark.
static func step_cue(floor_kind: LevelGrid.Floor) -> StringName:
	match floor_kind:
		LevelGrid.Floor.STACKS, LevelGrid.Floor.CONCRETE, LevelGrid.Floor.FOUNDATION:
			return &"step_dry"
	return &"step_wet"
