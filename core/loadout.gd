class_name Loadout
extends RefCounted
## The weapons carried into a level and the mode chosen for each (brief: "The player picks two weapons
## before each level"): two, or one while only one has been found. With the voice off there is no Steward
## to tune anything, so every weapon runs manual regardless of the choice.

enum Mode { TUNED, MANUAL }

const SLOTS := 2


## How many weapons a loadout carries with these weapons owned.
static func slots_for(owned: Array[String]) -> int:
	return mini(SLOTS, owned.filter(func(id: String) -> bool: return WeaponDefs.is_playable(id)).size())


## "" if the pick is valid for what's owned, otherwise why not.
static func validate(weapon_ids: Array[String], owned: Array[String]) -> String:
	var n := slots_for(owned)
	if weapon_ids.size() != n:
		return "Pick %d weapon%s." % [n, "" if n == 1 else "s"]
	for i: int in weapon_ids.size():
		var id := weapon_ids[i]
		if not WeaponDefs.is_known(id):
			return "Unknown weapon %s." % id
		if not owned.has(id) or not WeaponDefs.is_playable(id):
			return "%s hasn't been recovered yet." % WeaponDefs.display_name(id)
		if weapon_ids.find(id) != i:
			return "Pick different weapons."
	return ""


## The first weapons owned, in grid order: what a fresh loadout starts with.
static func default_for(owned: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id: String in WeaponDefs.GRID:
		if out.size() < slots_for(owned) and owned.has(id) and WeaponDefs.is_playable(id):
			out.append(id)
	return out


static func mode_key(mode: Mode) -> String:
	return "manual" if mode == Mode.MANUAL else "tuned"


static func mode_from_key(key: String) -> Mode:
	return Mode.MANUAL if key == "manual" else Mode.TUNED


## The mode a weapon actually runs in right now.
static func effective_mode(chosen: Mode, voice_on: bool) -> Mode:
	return chosen if voice_on else Mode.MANUAL


## The run's saved loadout, or the default if it isn't valid (any more) for what's owned.
static func from_run(run: RunState) -> Array[String]:
	if validate(run.loadout, run.weapons_owned) == "":
		return run.loadout.duplicate()
	return default_for(run.weapons_owned)


static func chosen_mode(run: RunState, weapon_id: String) -> Mode:
	return mode_from_key(run.weapon_modes.get(weapon_id, "tuned"))
