class_name DebugReadout
extends RefCounted
## Formats the debug overlay's text: every tracked variable from the brief, plus what feeds them.

static func text_for(run: RunState, voice_on: bool) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]UNDERTOW · TRACKED STATE[/b]   fps %d" % Engine.get_frames_per_second())
	lines.append("voice           %s   toggles %d" % ["ON" if voice_on else "MUTED", run.voice_toggle_count])
	var ratio := "—" if run.voice_tracked_seconds() <= 0.0 else "%.2f" % run.voice_on_ratio()
	lines.append("voice_on_ratio  %s   (on %.1fs / off %.1fs)" % [ratio, run.voice_on_seconds, run.voice_off_seconds])
	lines.append("cores_power     %d   %s" % [run.cores_power(), _list(run.power_core_ids)])
	lines.append("cores_truth     %d   %s" % [run.cores_truth(), _list(run.truth_core_ids)])
	lines.append("survivors_found %d   %s" % [run.survivors_found(), _list(run.survivor_ids)])
	lines.append("noor_trust      %+d   noor_present %s" % [run.noor_trust, _yes(run.noor_present)])
	lines.append("teo_trust       %+d   teo_present  %s" % [run.teo_trust, _yes(run.teo_present)])
	lines.append("active_overrides %s" % _list(run.active_overrides))
	var p := run.playstyle_profile
	lines.append("playstyle       risk %.1f  caution %.1f  lean %+.2f (%s)" % [p.risk, p.caution, p.lean(), p.dominant_tone()])
	lines.append("logs            unlocked %s  replayed %s" % [_list(run.logs_unlocked), _list(run.logs_replayed)])
	lines.append("loadout         %s" % _loadout(run))
	lines.append("restored        %s   completed %s" % [_list(run.buildings_restored), _list(run.levels_completed)])
	lines.append("location        %s   play %.0fs" % [run.location if run.location != "" else "—", run.play_seconds])
	return "\n".join(lines)


static func _list(items: Array[String]) -> String:
	return "—" if items.is_empty() else ", ".join(items)


static func _yes(b: bool) -> String:
	return "yes" if b else "no"


static func _loadout(run: RunState) -> String:
	if run.loadout.is_empty():
		return "—"
	var parts: PackedStringArray = []
	for id: String in run.loadout:
		parts.append("%s (%s)" % [id, run.weapon_modes.get(id, "tuned")])
	return ", ".join(parts)
