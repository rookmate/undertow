class_name CoreChoice
extends RefCounted
## The end-of-level trade-off (brief, "Memory cores"): more cores than you can carry. The Reliquary's own
## cores plus any truth core found off the path; carry exactly two. What you leave behind is gone, and
## its memory log stays unrecovered in the Archive.

## What the Reliquary offers: its own cores, then truth cores found off the path this level.
static func offer(level_id: String, run: RunState) -> Array[String]:
	var out: Array[String] = []
	for id: String in ContentDb.reliquary(level_id):
		if not run.power_core_ids.has(id) and not run.truth_core_ids.has(id):
			out.append(id)
	for id: String in run.found_core_ids:
		if not out.has(id) and not ContentDb.core(id).is_empty():
			out.append(id)
	return out


## "" if the offer is a real choice: more cores than can be carried. Otherwise the Reliquary's content is
## broken, and the level can't be completed from it (never a free pass with fewer cores).
static func offer_problem(offered: Array[String]) -> String:
	if offered.size() <= Tunables.CORES_CARRIED_PER_LEVEL:
		return "This Reliquary is broken: it offers %d cores, and there must be more than %d." % [offered.size(), Tunables.CORES_CARRIED_PER_LEVEL]
	return ""


## "" if `picks` is a valid choice from `offered`, otherwise why not.
static func validate(offered: Array[String], picks: Array[String]) -> String:
	var broken := offer_problem(offered)
	if broken != "":
		return broken
	if picks.size() != Tunables.CORES_CARRIED_PER_LEVEL:
		return "Carry exactly %d." % Tunables.CORES_CARRIED_PER_LEVEL
	for i: int in picks.size():
		if not offered.has(picks[i]):
			return "%s isn't on offer." % picks[i]
		if picks.find(picks[i]) != i:
			return "Different cores."
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
	var building := LevelCatalog.restores(level_id)
	if building != "":
		GameState.restore_building(building)
	GameState.set_location("ark")
	return ""
