extends TestCase


func test_defaults_match_the_brief_start() -> void:
	var s := RunState.new()
	check_eq(s.cores_power(), 0)
	check_eq(s.cores_truth(), 0)
	check_eq(s.survivors_found(), 0)
	check_eq(s.noor_trust, 0)
	check_eq(s.teo_trust, 0)
	check(s.noor_present, "Noor present at start (slice decision)")
	check(s.teo_present, "Teo present at start (slice decision)")
	check(s.active_overrides.is_empty())
	check_eq(s.playstyle_profile.lean(), 0.0)


func test_voice_on_ratio_is_zero_before_any_tracking() -> void:
	var s := RunState.new()
	check_eq(s.voice_on_ratio(), 0.0)
	check_eq(s.voice_tracked_seconds(), 0.0)


func test_voice_on_ratio_is_share_of_tracked_time() -> void:
	var s := RunState.new()
	s.voice_on_seconds = 30.0
	s.voice_off_seconds = 90.0
	check_near(s.voice_on_ratio(), 0.25)
	s.voice_off_seconds = 0.0
	check_near(s.voice_on_ratio(), 1.0)


func test_counts_derive_from_id_lists() -> void:
	var s := RunState.new()
	s.power_core_ids = ["a", "b"]
	s.truth_core_ids = ["c"]
	s.survivor_ids = ["w1", "w2", "w3"]
	check_eq(s.cores_power(), 2)
	check_eq(s.cores_truth(), 1)
	check_eq(s.survivors_found(), 3)


func test_round_trip_preserves_every_field() -> void:
	var s := RunState.new()
	s.voice_on_seconds = 12.5
	s.voice_off_seconds = 7.25
	s.voice_toggle_count = 4
	s.power_core_ids = ["vellum_power_lattice"]
	s.truth_core_ids = ["vellum_truth_0522"]
	s.survivor_ids = ["waiting_doorway"]
	s.logs_unlocked = ["log_0522"]
	s.logs_replayed = ["log_0522"]
	s.noor_trust = 3
	s.teo_trust = -2
	s.noor_present = false
	s.active_overrides = ["no_trap_warnings"]
	s.playstyle_profile.risk = 4.5
	s.playstyle_profile.caution = 1.0
	s.loadout = ["baton", "riot_drone"]
	s.weapon_modes = {"baton": "manual", "riot_drone": "tuned"}
	s.buildings_restored = ["archive"]
	s.levels_completed = ["vellum"]
	s.location = "ark"
	s.play_seconds = 99.0
	var json := JSON.stringify(s.to_dict())
	var back := RunState.from_dict(JSON.parse_string(json))
	check(back != null, "round trip produced a state")
	check_eq(JSON.stringify(back.to_dict()), json, "serialised forms match")
	check_eq(back.cores_power(), 1)
	check_eq(back.teo_trust, -2)
	check_false(back.noor_present)
	check_eq(back.weapon_modes.get("baton", ""), "manual")


func test_from_dict_tolerates_missing_and_mistyped_fields() -> void:
	var s := RunState.from_dict({"version": 1, "noor_trust": "lots", "survivor_ids": ["a", 5, "a", "b"], "teo_present": "yes"})
	check(s != null)
	check_eq(s.noor_trust, 0, "non-numeric trust falls back to 0")
	check_eq(s.survivor_ids, ["a", "b"], "non-strings and duplicates dropped")
	check_false(s.teo_present, "non-bool presence falls back to false")
	check_eq(s.voice_on_ratio(), 0.0)


func test_from_dict_clamps_trust() -> void:
	var s := RunState.from_dict({"version": 1, "noor_trust": 99, "teo_trust": -99})
	check_eq(s.noor_trust, Tunables.TRUST_MAX)
	check_eq(s.teo_trust, Tunables.TRUST_MIN)


func test_from_dict_rejects_saves_from_newer_versions() -> void:
	check(RunState.from_dict({"version": RunState.SAVE_VERSION + 1}) == null)


## A save that owns nothing playable (only the Signal Jammer, which isn't in the game yet) still carries
## the starting tools, so the loadout always has something to pick.
func test_a_save_owning_nothing_playable_keeps_the_starting_weapons() -> void:
	var s := RunState.from_dict({"version": RunState.SAVE_VERSION, "weapons_owned": [WeaponDefs.SIGNAL_JAMMER]})
	check(s.weapons_owned.has(WeaponDefs.BATON))
	check(s.weapons_owned.has(WeaponDefs.SIGNAL_JAMMER), "what it did own stays")
	check_eq(Loadout.from_run(s), [WeaponDefs.BATON])
