class_name FeedBlind
extends CanvasLayer
## The Feed's flash: a Vellum screen turned on you at full white (a Clerk's). Look at one as it flashes
## and the world washes out for a moment; look away, or roll, and nothing happens. Never a strobe: it
## rises over a tenth of a second, holds a moment and fades over the rest, and a second flash only ever
## brightens it.
## It sits over the world and under the HUD, so the subtitles stay readable.

## A screen catches you if it's within this many degrees of where you're facing (either side).
const LOOK_DEG := 70.0
const RISE := 0.1
const HOLD := 0.3
const PEAK := 0.88
## With "Reduce flashing" on (Options): it comes up over most of a second and only half as bright.
const GENTLE_RISE := 0.6
const GENTLE_PEAK := 0.45

var _rect: ColorRect
var _alpha: float = 0.0
var _rising: bool = false
var _hold_left: float = 0.0
var _fade_rate: float = 1.0


func _ready() -> void:
	layer = 9
	_rect = ColorRect.new()
	_rect.color = Color(Palette.FEED_WHITE, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	set_process(false)


## Someone at `at`, facing `facing` (a ground direction), sees a screen at `source` no more than
## `reach_tiles` away. Walls are the caller's to check.
static func catches(at: Vector2, facing: Vector2, source: Vector2, reach_tiles: float) -> bool:
	return CombatMath.in_arc(at, facing, source, reach_tiles, LOOK_DEG * 2.0)


## Washes the world out, fading over about `seconds`.
func blind(seconds: float) -> void:
	_rising = true
	_fade_rate = peak() / maxf(0.2, seconds - rise() - HOLD)
	set_process(true)


## How white it gets, and how long it takes to get there (gentler with "Reduce flashing").
static func peak() -> float:
	return GENTLE_PEAK if Options.reduce_flashing else PEAK


static func rise() -> float:
	return GENTLE_RISE if Options.reduce_flashing else RISE


## How white the world is now, 0..peak().
func amount() -> float:
	return _alpha


func is_blinding() -> bool:
	return _rising or _alpha > 0.0


func _process(delta: float) -> void:
	if _rising:
		_alpha = minf(peak(), _alpha + peak() / rise() * delta)
		_rising = _alpha < peak()
		if not _rising:
			_hold_left = HOLD
	elif _hold_left > 0.0:
		_hold_left -= delta
	else:
		_alpha = maxf(0.0, _alpha - _fade_rate * delta)
	_rect.color = Color(Palette.FEED_WHITE, _alpha)
	if not is_blinding():
		set_process(false)
