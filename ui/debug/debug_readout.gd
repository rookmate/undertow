class_name DebugReadout
extends RefCounted
## The debug overlay's text: every tracked variable from the brief, what feeds them, what the Steward is
## doing for you right now, and which endings this run would allow.

## Brief variables that must always appear (tests/unit/test_tracked_state.gd checks this list).
const BRIEF_VARIABLES: Array[String] = [
	"voice_on_ratio", "cores_power", "cores_truth", "survivors_found", "noor_trust", "teo_trust",
	"noor_present", "teo_present", "active_overrides", "playstyle_profile",
]


static func text_for(run: RunState, voice_on: bool) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]UNDERTOW · TRACKED STATE[/b]   fps %d" % Engine.get_frames_per_second())
	var ratio := "—" if run.voice_tracked_seconds() <= 0.0 else "%.2f" % run.voice_on_ratio()
	lines.append("voice_on_ratio     %s   (on %.1fs / off %.1fs, %s now, %d toggles)" % [ratio, run.voice_on_seconds, run.voice_off_seconds, "ON" if voice_on else "MUTED", run.voice_toggle_count])
	lines.append("cores_power        %d   %s" % [run.cores_power(), _list(run.power_core_ids)])
	lines.append("cores_truth        %d   %s" % [run.cores_truth(), _list(run.truth_core_ids)])
	lines.append("survivors_found    %d   %s" % [run.survivors_found(), _list(run.survivor_ids)])
	lines.append("noor_trust         %+d   noor_present %s%s" % [run.noor_trust, _yes(run.noor_present), "   (away in the Ward)" if run.noor_away else ""])
	lines.append("teo_trust          %+d   teo_present  %s" % [run.teo_trust, _yes(run.teo_present)])
	lines.append("active_overrides   %s" % _list(run.active_overrides))
	var p := run.playstyle_profile
	lines.append("playstyle_profile  risk %.1f  caution %.1f  lean %+.2f (%s)" % [p.risk, p.caution, p.lean(), p.dominant_tone()])
	var heard := Narrator.tone_counts
	lines.append("narration heard    bold %d  cautious %d  neutral %d   last %s" % [heard.get(&"bold", 0), heard.get(&"cautious", 0), heard.get(&"neutral", 0), Narrator.last_line_id if Narrator.last_line_id != "" else "—"])
	lines.append("")
	var a := Assists.compute(voice_on, run.cores_power(), run.active_overrides)
	lines.append("assists            path %s  map %s  threats %s  slow-mo %.2fs  aim %.2f  dmg ×%.1f" % [
		_yes(a.path_visible), "steward" if a.map_mode == Assists.MapMode.STEWARD else "hand scan",
		_yes(a.threat_warnings), a.dodge_slowmo_seconds, a.aim_assist, a.damage_taken_mult])
	lines.append("logs               unlocked %s  replayed %s" % [_list(run.logs_unlocked), _list(run.logs_replayed)])
	lines.append("found cores        %s" % _list(run.found_core_ids))
	lines.append("loadout            %s" % _loadout(run))
	lines.append("restored           %s   completed %s" % [_list(run.buildings_restored), _list(run.levels_completed)])
	lines.append("location           %s   play %.0fs" % [run.location if run.location != "" else "—", run.play_seconds])
	lines.append("")
	var endings := EndingRules.evaluate(run)
	lines.append("[b]ENDINGS[/b]   REBOOT yes   UNPLUG yes   REWRITE %s" % ("UNLOCKED" if endings.rewrite else "locked"))
	for c: EndingRules.Condition in endings.checklist:
		lines.append("  %s %s · %s" % ["+" if c.met else "-", c.label, c.detail])
	lines.append("")
	lines.append("F5 sign/revoke \"%s\"   F6 \"%s\"" % [Overrides.order_text(Overrides.NO_TRAP_WARNINGS), Overrides.order_text(Overrides.SURVIVORS_FIRST)])
	lines.append("F7 Noor present on/off   F8 Teo present on/off   F3 hide")
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
