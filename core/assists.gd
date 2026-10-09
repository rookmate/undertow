class_name Assists
extends RefCounted
## What the Steward does for you right now (brief: the voice table). One pure function of the voice
## switch, the power cores carried (stronger assistance) and the overrides signed.

enum MapMode { STEWARD, HAND_SCAN }

const BASE_AIM_ASSIST := 0.55
const AIM_ASSIST_PER_POWER_CORE := 0.1
const MAX_AIM_ASSIST := 0.85
const BASE_SLOWMO_SECONDS := 0.35
const SLOWMO_PER_POWER_CORE := 0.08
const SLOWMO_TIME_SCALE := 0.35

var voice_on: bool = true
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


static func compute(voice: bool, cores_power: int, overrides: Array[String]) -> Assists:
	var a := Assists.new()
	a.voice_on = voice
	a.path_visible = voice
	a.map_mode = MapMode.STEWARD if voice else MapMode.HAND_SCAN
	a.threat_warnings_overridden = voice and overrides.has(Overrides.NO_TRAP_WARNINGS)
	a.threat_warnings = voice and not a.threat_warnings_overridden
	a.dodge_slowmo_seconds = (BASE_SLOWMO_SECONDS + SLOWMO_PER_POWER_CORE * cores_power) if voice else 0.0
	a.aim_assist = minf(MAX_AIM_ASSIST, BASE_AIM_ASSIST + AIM_ASSIST_PER_POWER_CORE * cores_power) if voice else 0.0
	a.weapons_forced_manual = not voice
	a.damage_taken_mult = CombatMath.damage_taken(1.0, voice)
	a.narration = voice
	return a
