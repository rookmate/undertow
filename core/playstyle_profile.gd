class_name PlaystyleProfile
extends RefCounted
## The Steward's quiet model of how the player plays (brief: adaptive narration). Two scores that only
## grow; what matters is which one leads. `lean()` is -1 (all caution) .. +1 (all risk).

## Score added per observed behaviour. Keys are the event names gameplay reports.
const RISK_EVENTS: Dictionary[StringName, float] = {
	&"kill_close": 1.0,
	&"kill_low_health": 2.0,
	&"hit_taken_no_dodge": 0.5,
	&"manual_mode_used": 0.5,
	&"left_path": 1.0,
	&"multi_kill": 1.5,
}
const CAUTION_EVENTS: Dictionary[StringName, float] = {
	&"dodge": 0.5,
	&"perfect_dodge": 1.0,
	&"kill_at_range": 1.0,
	&"retreat": 1.0,
	&"returned_to_path": 1.0,
	&"tuned_mode_used": 0.5,
}
## Keeps early play from swinging the lean to ±1 after a single event.
const LEAN_SOFTENING := 6.0

var risk: float = 0.0
var caution: float = 0.0


## Returns true if the event changed the profile.
func record(event: StringName, weight: float = 1.0) -> bool:
	if RISK_EVENTS.has(event):
		risk += RISK_EVENTS[event] * weight
		return true
	if CAUTION_EVENTS.has(event):
		caution += CAUTION_EVENTS[event] * weight
		return true
	return false


func lean() -> float:
	return clampf((risk - caution) / (risk + caution + LEAN_SOFTENING), -1.0, 1.0)


func dominant_tone() -> StringName:
	var l := lean()
	if l > 0.15:
		return &"bold"
	if l < -0.15:
		return &"cautious"
	return &"neutral"


func to_dict() -> Dictionary:
	return {"risk": risk, "caution": caution}


static func from_dict(d: Dictionary) -> PlaystyleProfile:
	var p := PlaystyleProfile.new()
	p.risk = maxf(0.0, _num(d.get("risk", 0.0)))
	p.caution = maxf(0.0, _num(d.get("caution", 0.0)))
	return p


static func _num(v: Variant) -> float:
	if v is float or v is int:
		return float(v)
	return 0.0
