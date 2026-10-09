class_name Assists
extends RefCounted
## What the Steward does for you right now (brief: the voice table). One pure function of the voice
## switch, whether its hardware reaches you (world bible: "the Steward's light reaches exactly as far as
## its hardware does"; off the Lattice it can't see you, so the voice being on buys you nothing), the
## power cores carried (stronger assistance) and the overrides signed.

enum MapMode { STEWARD, HAND_SCAN }

const BASE_AIM_ASSIST := 0.55
const AIM_ASSIST_PER_POWER_CORE := 0.1
const MAX_AIM_ASSIST := 0.85
const BASE_SLOWMO_SECONDS := 0.35
const SLOWMO_PER_POWER_CORE := 0.08
const SLOWMO_TIME_SCALE := 0.35

var voice_on: bool = true
## The voice is on and the Lattice reaches the Operator: the Steward can actually help.
var steward_present: bool = true
## The voice is on but the Operator is off the Lattice: it is talking to no one.
var signal_lost: bool = false
var path_visible: bool = true
var map_mode: MapMode = MapMode.STEWARD
var threat_warnings: bool = true
## Why threat warnings are off while the voice is on (an override), or "".
var threat_warnings_overridden: bool = false
var dodge_slowmo_seconds: float = BASE_SLOWMO_SECONDS
var aim_assist: float = BASE_AIM_ASSIST
var weapons_forced_manual: bool = false
var damage_taken_mult: float = 1.0
var narration: bool = true
## Off because of a signed order (the Signal Room), not because the Steward is absent.
var path_overridden: bool = false
var slowmo_overridden: bool = false
var aim_overridden: bool = false


static func compute(voice: bool, cores_power: int, overrides: Array[String], covered: bool = true) -> Assists:
	var a := Assists.new()
	var present := voice and covered
	a.voice_on = voice
	a.steward_present = present
	a.signal_lost = voice and not covered
	a.path_overridden = present and overrides.has(Overrides.NO_PATH)
	a.path_visible = present and not a.path_overridden
	a.map_mode = MapMode.STEWARD if voice else MapMode.HAND_SCAN
	a.threat_warnings_overridden = present and overrides.has(Overrides.NO_TRAP_WARNINGS)
	a.threat_warnings = present and not a.threat_warnings_overridden
	a.slowmo_overridden = present and overrides.has(Overrides.NO_SLOWMO)
	a.dodge_slowmo_seconds = (BASE_SLOWMO_SECONDS + SLOWMO_PER_POWER_CORE * cores_power) if present and not a.slowmo_overridden else 0.0
	a.aim_overridden = present and overrides.has(Overrides.LET_ME_AIM)
	a.aim_assist = minf(MAX_AIM_ASSIST, BASE_AIM_ASSIST + AIM_ASSIST_PER_POWER_CORE * cores_power) if present and not a.aim_overridden else 0.0
	a.weapons_forced_manual = not present
	a.damage_taken_mult = CombatMath.damage_taken(1.0, present)
	a.narration = present
	return a
