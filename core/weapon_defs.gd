class_name WeaponDefs
extends RefCounted
## Reclaimed city tools (brief, "Weapons"). Each has a Steward-tuned mode (semi-automatic, easier) and a
## manual mode (harder, stronger in skilled hands). Ratings feed the loadout screen's ease and
## skill-ceiling bars. Combat numbers live in each weapon's script next to the code that uses them.

const BATON := "baton"
const RIOT_DRONE := "riot_drone"
const DEFIB := "defib_gauntlet"
const SIGNAL_JAMMER := "signal_jammer"

## The loadout grid, in order. Weapons are found in the city (design/act-1.md); the grid shows the ones
## not found yet as locked. The Signal Jammer is hand-built in Harbor Ward (Act 3) and has no code yet.
const GRID: Array[String] = [BATON, RIOT_DRONE, DEFIB, SIGNAL_JAMMER]
## Weapons that exist in code (can be carried).
const PLAYABLE: Array[String] = [BATON, RIOT_DRONE, DEFIB]
## What a new run owns: a maintenance worker's traffic baton. The rest are found in the city.
const STARTING: Array[String] = [BATON]
## What a version-1 save (the vertical slice) owned.
const SLICE_SET: Array[String] = [BATON, RIOT_DRONE, DEFIB]

const ALL: Dictionary[String, Dictionary] = {
	BATON: {
		"name": "Traffic Baton",
		"tag": "PROPERTY OF THE CITY OF MERIDIAN · TRAFFIC DIV. 0417-B",
		"tuned": {"ease": 0.85, "ceiling": 0.35, "blurb": "Finds the nearest threat and swings for you. Hold to keep the combo going."},
		"manual": {"ease": 0.35, "ceiling": 0.85, "blurb": "Swings where you aim. Press on the beat to chain; the third hit on the beat lands hard."},
	},
	RIOT_DRONE: {
		"name": "Riot Drone",
		"tag": "PROPERTY OF THE CITY OF MERIDIAN · WARDEN DEPOT 12",
		"tuned": {"ease": 0.9, "ceiling": 0.3, "blurb": "Locks on to the nearest threat and manages its own heat. Hold to fire."},
		"manual": {"ease": 0.4, "ceiling": 0.8, "blurb": "Fires where you aim. Heavier pellets pierce, but hold too long and it overheats."},
	},
	DEFIB: {
		"name": "Defib Gauntlet",
		"tag": "PROPERTY OF THE CITY OF MERIDIAN · MERCY GENERAL EMS",
		"tuned": {"ease": 0.8, "ceiling": 0.4, "blurb": "Charges to the safe level and discharges around you. Press once."},
		"manual": {"ease": 0.3, "ceiling": 0.9, "blurb": "Hold to charge, release in the window for a wide shock. Hold too long and it bites you."},
	},
	SIGNAL_JAMMER: {
		"name": "???",
		"tag": "NO ASSET TAG",
		"tuned": {"ease": 0.0, "ceiling": 0.0, "blurb": "Not recovered."},
		"manual": {"ease": 0.0, "ceiling": 0.0, "blurb": "Not recovered."},
	},
}


static func is_known(weapon_id: String) -> bool:
	return ALL.has(weapon_id)


static func is_playable(weapon_id: String) -> bool:
	return PLAYABLE.has(weapon_id)


static func display_name(weapon_id: String) -> String:
	return str(ALL.get(weapon_id, {}).get("name", weapon_id))


static func asset_tag(weapon_id: String) -> String:
	return str(ALL.get(weapon_id, {}).get("tag", ""))


## Ease / ceiling / blurb for a mode ("tuned" or "manual").
static func mode_info(weapon_id: String, mode_key: String) -> Dictionary:
	var def: Dictionary = ALL.get(weapon_id, {})
	return def.get(mode_key, {})
