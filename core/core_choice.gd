class_name CoreChoice
extends RefCounted
## The end-of-level trade-off (brief, "Memory cores"): more cores than you can carry. The Reliquary's own
## cores plus any truth core found off the path; carry exactly two. What you leave behind is gone, and
## its memory log stays unrecovered in the Archive.

## Each level's Reliquary restores this Ark building (world bible, "The Ark").
const BUILDING_FOR_LEVEL: Dictionary[String, String] = {
	ContentIds.LEVEL_VELLUM: "archive",
}


## What the Reliquary offers: its own cores, then truth cores found off the path this level.
static func offer(level_id: String, run: RunState) -> Array[String]:
	var out: Array[String] = []
	for id: String in ContentDb.reliquary(level_id):
		if not run.power_core_ids.has(id) and not run.truth_core_ids.has(id):
			out.append(id)
	for id: String in run.found_core_ids:
		if not out.has(id):
			out.append(id)
	return out


## "" if `picks` is a valid choice from `offered`, otherwise why not.
static func validate(offered: Array[String], picks: Array[String]) -> String:
	if picks.size() != Tunables.CORES_CARRIED_PER_LEVEL:
		return "Carry exactly %d." % Tunables.CORES_CARRIED_PER_LEVEL
	if picks[0] == picks[1]:
		return "Two different cores."
	for id: String in picks:
		if not offered.has(id):
			return "%s isn't on offer." % id
	return ""


## Takes the picked cores, files their logs for the Archive, ends the level and restores its building.
static func apply(level_id: String, offered: Array[String], picks: Array[String]) -> String:
	var problem := validate(offered, picks)
	if problem != "":
		return problem
	for id: String in picks:
		GameState.take_core(id, ContentDb.is_truth(id))
		var log_id := str(ContentDb.core(id).get("log", ""))
		if log_id != "":
			GameState.unlock_log(log_id)
	GameState.clear_found_cores()
	GameState.complete_level(level_id)
	if BUILDING_FOR_LEVEL.has(level_id):
		GameState.restore_building(BUILDING_FOR_LEVEL[level_id])
	GameState.set_location("ark")
	return ""
