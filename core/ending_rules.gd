class_name EndingRules
extends RefCounted
## Which endings a run allows (brief, "Ending logic"). Reboot and Unplug are always available as the
## final choice. Rewrite unlocks only if Noor and Teo are both still present, the voice was on for a
## balanced share of play (the player both used the Steward and ignored it), and enough truth cores were
## kept. Thresholds live in Tunables.

class Condition:
	var label: String
	var met: bool
	var detail: String


class Result:
	var reboot: bool = true
	var unplug: bool = true
	var rewrite: bool = false
	var checklist: Array[Condition] = []


static func evaluate(run: RunState) -> Result:
	var r := Result.new()
	r.checklist.append(_cond(
		"Noor and Teo are both still with you",
		run.noor_present and run.teo_present,
		"Noor %s · Teo %s" % ["present" if run.noor_present else "gone", "present" if run.teo_present else "gone"]))
	var ratio := run.voice_on_ratio()
	var tracked := run.voice_tracked_seconds() > 0.0
	r.checklist.append(_cond(
		"You both used the Steward and ignored it",
		tracked and ratio >= Tunables.REWRITE_VOICE_RATIO_MIN and ratio <= Tunables.REWRITE_VOICE_RATIO_MAX,
		"voice on %d%% of play (needs %d–%d%%)" % [roundi(ratio * 100.0), roundi(Tunables.REWRITE_VOICE_RATIO_MIN * 100.0), roundi(Tunables.REWRITE_VOICE_RATIO_MAX * 100.0)]))
	r.checklist.append(_cond(
		"You kept enough of the truth",
		run.cores_truth() >= Tunables.REWRITE_MIN_TRUTH_CORES,
		"%d of %d truth cores" % [run.cores_truth(), Tunables.REWRITE_MIN_TRUTH_CORES]))
	r.rewrite = r.checklist.all(func(c: Condition) -> bool: return c.met)
	return r


static func _cond(label: String, met: bool, detail: String) -> Condition:
	var c := Condition.new()
	c.label = label
	c.met = met
	c.detail = detail
	return c
