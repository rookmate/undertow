class_name RunState
extends RefCounted
## Everything Undertow tracks across a run (design brief, "Tracked state"). GameState is the only
## writer; everything else reads. Brief variables that are counts are derived from ID lists so the
## count and the list can never disagree.

## 2: weapons are found (weapons_owned), scrap and upgrades.
## 3: the run remembers the cores each Reliquary offered and you left (cores_left), the holds done and
## the doors opened (milestone 5).
const SAVE_VERSION := 3
## Saves from before this can't tell a truth you left at a Reliquary from one you never found.
const REMEMBERS_LEFT_FROM := 3

const WHO_NOOR := &"noor"
const WHO_TEO := &"teo"

# --- Voice ---------------------------------------------------------------------------------------------
var voice_on_seconds: float = 0.0
var voice_off_seconds: float = 0.0
var voice_toggle_count: int = 0
## The voice switch as the player last left it.
var voice_on: bool = true

# --- Cores, survivors, logs ------------------------------------------------------------------------
var power_core_ids: Array[String] = []
var truth_core_ids: Array[String] = []
var survivor_ids: Array[String] = []
var logs_unlocked: Array[String] = []
var logs_replayed: Array[String] = []
## Cores picked up in the current level and not yet chosen at the Reliquary (off-path truth cores).
var found_core_ids: Array[String] = []
## Cores a Reliquary offered that you didn't carry: gone, for good (they aren't there on a revisit).
var cores_left: Array[String] = []

# --- Companions ----------------------------------------------------------------------------------------
var noor_trust: int = 0
var teo_trust: int = 0
## Still with you (the endings ask this). They only join once Act 1 is done: companions_joined().
var noor_present: bool = true
var teo_present: bool = true
## Noor and Teo have arrived on the Ark (their arrival plays once).
var companions_met: bool = false
## Act 2 districts talked over with them (Conversations), in the order you had them.
var conversations_had: Array[String] = []
## Noor has gone ahead to Harbor Ward (her turn, design/act-3.md): not on the Ark until she comes home.
var noor_away: bool = false
## Teo has had his say at the dock, setting off for the Spire (his turn, design/act-3.md).
var teo_turn_had: bool = false
## Holds done (design/deeper-districts.md): what they opened stays open for the rest of the run.
var holds_done: Array[String] = []
## Doors the Ark's tools opened (ToolDoors): they stay open.
var doors_opened: Array[String] = []
## The final choice, once made (Endings: "reboot", "unplug", "rewrite"); "" until then. A run with an
## ending is finished: kept, but not continued.
var ending: String = ""

# --- Steward --------------------------------------------------------------------------------------------
var active_overrides: Array[String] = []
var playstyle_profile: PlaystyleProfile = PlaystyleProfile.new()

# --- Progress ---------------------------------------------------------------------------------------------
## Weapons recovered so far (the loadout only offers these).
var weapons_owned: Array[String] = WeaponDefs.STARTING.duplicate()
## Parts taken from machines and crates; spent at the Workshop.
var scrap: int = 0
## Field dressings carried (the Clinic stocks them up whenever you're home).
var dressings: int = 0
## Workshop upgrades bought: "<weapon>:<mode>" -> level.
var upgrades: Dictionary[String, int] = {}
var loadout: Array[String] = []
var weapon_modes: Dictionary[String, String] = {}
var buildings_restored: Array[String] = []
var levels_completed: Array[String] = []
## Where Continue resumes: "" (nothing yet), "level:<id>", or "ark".
var location: String = ""
var play_seconds: float = 0.0


# --- Brief variables (derived) ---------------------------------------------------------------------
## Share of tracked play time with the voice on. 0 when nothing has been tracked yet.
func voice_on_ratio() -> float:
	var total := voice_on_seconds + voice_off_seconds
	if total <= 0.0:
		return 0.0
	return voice_on_seconds / total


func voice_tracked_seconds() -> float:
	return voice_on_seconds + voice_off_seconds


func cores_power() -> int:
	return power_core_ids.size()


func cores_truth() -> int:
	return truth_core_ids.size()


func survivors_found() -> int:
	return survivor_ids.size()


func trust_of(who: StringName) -> int:
	return noor_trust if who == WHO_NOOR else teo_trust


func is_present(who: StringName) -> bool:
	return noor_present if who == WHO_NOOR else teo_present


## Noor and Teo join in Act 2, once the Tideworks is done (design/act-2.md); before that the Ark is yours
## alone.
func companions_joined() -> bool:
	return levels_completed.has(LevelCatalog.COMPANIONS_JOIN_AFTER)


## On the Ark, reacting to the logs, with trust to win or lose: joined, still with you, and not away.
func companion_here(who: StringName) -> bool:
	return companions_joined() and is_present(who) and not (who == WHO_NOOR and noor_away)


## The conversation waiting for the next time you talk to Noor or Teo: the first district you've done
## that has one not yet had, while both of them are here ("" if none).
func pending_conversation() -> String:
	if not (companion_here(WHO_NOOR) and companion_here(WHO_TEO)):
		return ""
	for district: String in levels_completed:
		if Conversations.has(district) and not conversations_had.has(district):
			return district
	return ""


# --- Serialisation ----------------------------------------------------------------------------------
func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"voice_on_seconds": voice_on_seconds,
		"voice_off_seconds": voice_off_seconds,
		"voice_toggle_count": voice_toggle_count,
		"voice_on": voice_on,
		"power_core_ids": power_core_ids.duplicate(),
		"truth_core_ids": truth_core_ids.duplicate(),
		"survivor_ids": survivor_ids.duplicate(),
		"logs_unlocked": logs_unlocked.duplicate(),
		"logs_replayed": logs_replayed.duplicate(),
		"found_core_ids": found_core_ids.duplicate(),
		"cores_left": cores_left.duplicate(),
		"noor_trust": noor_trust,
		"teo_trust": teo_trust,
		"noor_present": noor_present,
		"teo_present": teo_present,
		"companions_met": companions_met,
		"conversations_had": conversations_had.duplicate(),
		"noor_away": noor_away,
		"teo_turn_had": teo_turn_had,
		"holds_done": holds_done.duplicate(),
		"doors_opened": doors_opened.duplicate(),
		"ending": ending,
		"active_overrides": active_overrides.duplicate(),
		"playstyle_profile": playstyle_profile.to_dict(),
		"weapons_owned": weapons_owned.duplicate(),
		"scrap": scrap,
		"dressings": dressings,
		"upgrades": upgrades.duplicate(),
		"loadout": loadout.duplicate(),
		"weapon_modes": weapon_modes.duplicate(),
		"buildings_restored": buildings_restored.duplicate(),
		"levels_completed": levels_completed.duplicate(),
		"location": location,
		"play_seconds": play_seconds,
	}


## Builds a RunState from saved data. Missing or mistyped fields fall back to defaults so an old or
## hand-edited save still loads. Returns null only for saves written by a newer version of the game.
static func from_dict(d: Dictionary) -> RunState:
	var version := _int(d.get("version", 0))
	if version > SAVE_VERSION:
		return null
	var s := RunState.new()
	s.voice_on_seconds = maxf(0.0, _float(d.get("voice_on_seconds", 0.0)))
	s.voice_off_seconds = maxf(0.0, _float(d.get("voice_off_seconds", 0.0)))
	s.voice_toggle_count = maxi(0, _int(d.get("voice_toggle_count", 0)))
	var voice: Variant = d.get("voice_on", true)
	s.voice_on = voice if voice is bool else true
	s.power_core_ids = _strings(d.get("power_core_ids", []))
	s.truth_core_ids = _strings(d.get("truth_core_ids", []))
	s.survivor_ids = _strings(d.get("survivor_ids", []))
	s.logs_unlocked = _strings(d.get("logs_unlocked", []))
	s.logs_replayed = _strings(d.get("logs_replayed", []))
	s.found_core_ids = _strings(d.get("found_core_ids", []))
	# A save from before the run remembered what it left (DECISIONS 190): nothing counts as left, so a
	# truth you found and left at a Reliquary then can be found again on a revisit. Better that than losing
	# one you never found.
	s.cores_left = _strings(d.get("cores_left", []) if version >= REMEMBERS_LEFT_FROM else [])
	s.noor_trust = clampi(_int(d.get("noor_trust", 0)), Tunables.TRUST_MIN, Tunables.TRUST_MAX)
	s.teo_trust = clampi(_int(d.get("teo_trust", 0)), Tunables.TRUST_MIN, Tunables.TRUST_MAX)
	s.noor_present = _bool(d.get("noor_present", true))
	s.teo_present = _bool(d.get("teo_present", true))
	s.companions_met = _bool(d.get("companions_met", false))
	s.conversations_had = _strings(d.get("conversations_had", []))
	s.noor_away = _bool(d.get("noor_away", false))
	s.teo_turn_had = _bool(d.get("teo_turn_had", false))
	s.holds_done = _strings(d.get("holds_done", []))
	s.doors_opened = _strings(d.get("doors_opened", []))
	var chosen := str(d.get("ending", ""))
	s.ending = chosen if Endings.ALL.has(chosen) else ""
	s.active_overrides = _strings(d.get("active_overrides", []))
	var profile: Variant = d.get("playstyle_profile", {})
	s.playstyle_profile = PlaystyleProfile.from_dict(profile if profile is Dictionary else {})
	# Saves from before weapons were found (version 1, the vertical slice) had all three from the start.
	var owned: Variant = d.get("weapons_owned", null)
	s.weapons_owned = _strings(owned) if owned is Array else WeaponDefs.SLICE_SET.duplicate()
	s.weapons_owned = s.weapons_owned.filter(func(id: String) -> bool: return WeaponDefs.is_known(id))
	# Never a run with nothing to carry: the Operator always has the tools they started with.
	if not s.weapons_owned.any(func(id: String) -> bool: return WeaponDefs.is_playable(id)):
		for id: String in WeaponDefs.STARTING:
			if not s.weapons_owned.has(id):
				s.weapons_owned.append(id)
	s.scrap = maxi(0, _int(d.get("scrap", 0)))
	s.dressings = clampi(_int(d.get("dressings", 0)), 0, Tunables.DRESSINGS_MAX)
	var ups: Variant = d.get("upgrades", {})
	if ups is Dictionary:
		for key: Variant in ups:
			if key is String and (ups[key] is int or ups[key] is float):
				s.upgrades[key] = clampi(int(ups[key]), 0, Tunables.UPGRADE_LEVELS)
	s.loadout = _strings(d.get("loadout", []))
	var modes: Variant = d.get("weapon_modes", {})
	if modes is Dictionary:
		for key: Variant in modes:
			var value: Variant = modes[key]
			if key is String and value is String:
				s.weapon_modes[key] = value
	s.buildings_restored = _strings(d.get("buildings_restored", []))
	s.levels_completed = _strings(d.get("levels_completed", []))
	var loc: Variant = d.get("location", "")
	s.location = loc if loc is String else ""
	s.play_seconds = maxf(0.0, _float(d.get("play_seconds", 0.0)))
	return s


static func _float(v: Variant) -> float:
	return float(v) if (v is float or v is int) else 0.0


static func _int(v: Variant) -> int:
	return int(v) if (v is float or v is int) else 0


static func _bool(v: Variant) -> bool:
	return v if v is bool else false


## Unique strings only, in order; anything that isn't a string is dropped.
static func _strings(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for item: Variant in v:
			if item is String and not out.has(item):
				out.append(item)
	return out
