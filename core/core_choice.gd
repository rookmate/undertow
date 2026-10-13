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


## "" if this district's Reliquary is a real choice. Its own definition must offer more cores than can be
## carried: cores found off the path add to it and never stand in for a missing or rejected one. And
## what's on the table now must too. Otherwise the content is broken and the level can't be completed
## from it.
static func offer_problem(level_id: String, offered: Array[String]) -> String:
	var carried := Tunables.CORES_CARRIED_PER_LEVEL
	if not LevelCatalog.has_level(level_id):
		return "This Reliquary is broken: %s isn't a district." % level_id
	var own := ContentDb.reliquary(level_id).size()
	if own <= carried:
		return "This Reliquary is broken: it holds %d cores of its own, and there must be more than %d." % [own, carried]
	if offered.size() <= carried:
		return "This Reliquary is broken: it offers %d cores, and there must be more than %d." % [offered.size(), carried]
	return ""


## "" if `picks` is a valid choice from what `level_id`'s Reliquary offers, otherwise why not.
static func validate(level_id: String, offered: Array[String], picks: Array[String]) -> String:
	var broken := offer_problem(level_id, offered)
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
	var problem := validate(level_id, offered, picks)
	if problem != "":
		return problem
	var left: Array[String] = []
	for id: String in offered:
		if not picks.has(id):
			left.append(id)
	for id: String in picks:
		GameState.take_core(id, ContentDb.is_truth(id))
		var log_id := str(ContentDb.core(id).get("log", ""))
		if log_id != "":
			GameState.unlock_log(log_id)
	GameState.leave_cores(left)
	GameState.clear_found_cores()
	GameState.complete_level(level_id)
	var building := LevelCatalog.restores(level_id)
	if building != "":
		GameState.restore_building(building)
	GameState.set_location("ark")
	return ""
