extends TestCase

const ALL_THREE: Array[String] = [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE, WeaponDefs.DEFIB]


func test_valid_pick_is_two_different_owned_weapons() -> void:
	check_eq(Loadout.validate([WeaponDefs.BATON, WeaponDefs.DEFIB], ALL_THREE), "")
	check(Loadout.validate([WeaponDefs.BATON], ALL_THREE) != "", "one is not enough when two are owned")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.RIOT_DRONE, WeaponDefs.DEFIB], ALL_THREE) != "", "three is too many")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.BATON], ALL_THREE) != "", "no duplicates")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.SIGNAL_JAMMER], ALL_THREE) != "", "the locked tool can't be carried")
	check(Loadout.validate([WeaponDefs.BATON, "spoon"], ALL_THREE) != "", "unknown ids rejected")


func test_only_found_weapons_can_be_carried() -> void:
	var baton_only: Array[String] = [WeaponDefs.BATON]
	check_eq(Loadout.slots_for(baton_only), 1, "with one weapon found, the loadout carries one")
	check_eq(Loadout.validate([WeaponDefs.BATON], baton_only), "")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.RIOT_DRONE], baton_only) != "", "the drone hasn't been found")
	check(Loadout.validate([WeaponDefs.RIOT_DRONE], baton_only) != "")
	check_eq(Loadout.default_for(baton_only), baton_only)
	var with_unknown: Array[String] = [WeaponDefs.BATON, "harpoon"]
	check_eq(Loadout.slots_for(with_unknown), 1, "a tool that isn't in the game doesn't count")


func test_muting_the_steward_forces_manual() -> void:
	check_eq(Loadout.effective_mode(Loadout.Mode.TUNED, true), Loadout.Mode.TUNED)
	check_eq(Loadout.effective_mode(Loadout.Mode.TUNED, false), Loadout.Mode.MANUAL)
	check_eq(Loadout.effective_mode(Loadout.Mode.MANUAL, true), Loadout.Mode.MANUAL)


func test_run_loadout_falls_back_to_default_when_invalid() -> void:
	var run := RunState.new()
	run.weapons_owned = ALL_THREE.duplicate()
	check_eq(Loadout.from_run(run), [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE])
	run.loadout = [WeaponDefs.DEFIB, WeaponDefs.BATON]
	check_eq(Loadout.from_run(run), [WeaponDefs.DEFIB, WeaponDefs.BATON])
	run.loadout = [WeaponDefs.DEFIB, WeaponDefs.DEFIB]
	check_eq(Loadout.from_run(run), [WeaponDefs.BATON, WeaponDefs.RIOT_DRONE])
	run.weapons_owned = [WeaponDefs.BATON]
	run.loadout = [WeaponDefs.DEFIB, WeaponDefs.BATON]
	check_eq(Loadout.from_run(run), [WeaponDefs.BATON], "a saved pick of weapons no longer owned falls back")


func test_modes_round_trip_through_save_keys() -> void:
	for m: Loadout.Mode in [Loadout.Mode.TUNED, Loadout.Mode.MANUAL]:
		check_eq(Loadout.mode_from_key(Loadout.mode_key(m)), m)
	var run := RunState.new()
	run.weapon_modes = {WeaponDefs.BATON: "manual"}
	check_eq(Loadout.chosen_mode(run, WeaponDefs.BATON), Loadout.Mode.MANUAL)
	check_eq(Loadout.chosen_mode(run, WeaponDefs.DEFIB), Loadout.Mode.TUNED, "unset means tuned")


## Brief: Steward-tuned is easier; manual is harder and stronger in skilled hands.
func test_every_weapon_is_easier_tuned_and_deeper_manual() -> void:
	for id: String in WeaponDefs.PLAYABLE:
		var tuned := WeaponDefs.mode_info(id, "tuned")
		var manual := WeaponDefs.mode_info(id, "manual")
		check(float(tuned["ease"]) > float(manual["ease"]), "%s tuned is easier" % id)
		check(float(manual["ceiling"]) > float(tuned["ceiling"]), "%s manual has the higher ceiling" % id)
		check(str(tuned["blurb"]) != "" and str(manual["blurb"]) != "", "%s describes both modes" % id)
		# Every reclaimed city tool keeps its asset tag; the Ward's hand-built jammer never had one (brief).
		var tag := "NO ASSET TAG" if id == WeaponDefs.SIGNAL_JAMMER else "PROPERTY OF THE CITY OF MERIDIAN"
		check(WeaponDefs.asset_tag(id).begins_with(tag), "%s: %s" % [id, WeaponDefs.asset_tag(id)])
