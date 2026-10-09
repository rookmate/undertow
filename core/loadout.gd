class_name Loadout
extends RefCounted
## The two weapons carried into a level and the mode chosen for each (brief: "The player picks two
## weapons before each level"). With the voice off there is no Steward to tune anything, so every
## weapon runs manual regardless of the choice.

enum Mode { TUNED, MANUAL }

const SLOTS := 2
const DEFAULT_WEAPONS: Array[String] = [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE]


## "" if the pick is valid, otherwise why not.
static func validate(weapon_ids: Array[String]) -> String:
	if weapon_ids.size() != SLOTS:
		return "Pick exactly %d weapons." % SLOTS
	if weapon_ids[0] == weapon_ids[1]:
		return "Pick two different weapons."
	for id: String in weapon_ids:
		if not WeaponDefs.is_known(id):
			return "Unknown weapon %s." % id
		if not WeaponDefs.is_unlocked(id):
			return "%s hasn't been recovered yet." % WeaponDefs.display_name(id)
	return ""


static func mode_key(mode: Mode) -> String:
	return "manual" if mode == Mode.MANUAL else "tuned"


static func mode_from_key(key: String) -> Mode:
	return Mode.MANUAL if key == "manual" else Mode.TUNED


## The mode a weapon actually runs in right now.
static func effective_mode(chosen: Mode, voice_on: bool) -> Mode:
	return chosen if voice_on else Mode.MANUAL


## The run's saved loadout, or the default if it isn't valid.
static func from_run(run: RunState) -> Array[String]:
	if validate(run.loadout) == "":
		return run.loadout.duplicate()
	return DEFAULT_WEAPONS.duplicate()


static func chosen_mode(run: RunState, weapon_id: String) -> Mode:
	return mode_from_key(run.weapon_modes.get(weapon_id, "tuned"))
