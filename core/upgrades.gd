class_name Upgrades
extends RefCounted
## Workshop upgrades (the world bible: "Weapon upgrades, Tuned/Manual tuning"): each weapon's tuned mode
## and its manual mode upgrade separately, a level at a time, paid for with scrap. Each level makes that
## mode hit harder. Saved in RunState.upgrades as "<weapon>:<mode>" -> level.

## Scrap for the first level, the second.
const COSTS: Array[int] = [6, 12]
const DAMAGE_PER_LEVEL := 0.2


static func key(weapon_id: String, mode_key: String) -> String:
	return "%s:%s" % [weapon_id, mode_key]


static func level(run: RunState, weapon_id: String, mode_key: String) -> int:
	return clampi(run.upgrades.get(key(weapon_id, mode_key), 0), 0, Tunables.UPGRADE_LEVELS)


## What the next level costs, or -1 if it's already at the top.
static func next_cost(run: RunState, weapon_id: String, mode_key: String) -> int:
	var at := level(run, weapon_id, mode_key)
	return COSTS[at] if at < mini(COSTS.size(), Tunables.UPGRADE_LEVELS) else -1


## "" if the next level can be bought now, otherwise why not.
static func why_not(run: RunState, weapon_id: String, mode_key: String) -> String:
	if not run.weapons_owned.has(weapon_id) or not WeaponDefs.is_playable(weapon_id):
		return "Not recovered."
	if mode_key != "tuned" and mode_key != "manual":
		return "No such mode."
	var cost := next_cost(run, weapon_id, mode_key)
	if cost < 0:
		return "As good as it gets."
	if run.scrap < cost:
		return "Needs %d scrap." % cost
	return ""


## How much harder a weapon in a mode hits.
static func damage_mult(run: RunState, weapon_id: String, mode_key: String) -> float:
	return 1.0 + DAMAGE_PER_LEVEL * level(run, weapon_id, mode_key)
