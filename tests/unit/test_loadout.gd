extends TestCase


func test_valid_pick_is_two_different_unlocked_weapons() -> void:
	check_eq(Loadout.validate([WeaponDefs.BATON, WeaponDefs.DEFIB]), "")
	check(Loadout.validate([WeaponDefs.BATON]) != "", "one is not enough")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.RIOT_DRONE, WeaponDefs.DEFIB]) != "", "three is too many")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.BATON]) != "", "no duplicates")
	check(Loadout.validate([WeaponDefs.BATON, WeaponDefs.SIGNAL_JAMMER]) != "", "the locked tool can't be carried")
	check(Loadout.validate([WeaponDefs.BATON, "spoon"]) != "", "unknown ids rejected")


func test_muting_the_steward_forces_manual() -> void:
	check_eq(Loadout.effective_mode(Loadout.Mode.TUNED, true), Loadout.Mode.TUNED)
	check_eq(Loadout.effective_mode(Loadout.Mode.TUNED, false), Loadout.Mode.MANUAL)
	check_eq(Loadout.effective_mode(Loadout.Mode.MANUAL, true), Loadout.Mode.MANUAL)


func test_run_loadout_falls_back_to_default_when_invalid() -> void:
	var run := RunState.new()
	check_eq(Loadout.from_run(run), Loadout.DEFAULT_WEAPONS)
	run.loadout = [WeaponDefs.DEFIB, WeaponDefs.BATON]
	check_eq(Loadout.from_run(run), [WeaponDefs.DEFIB, WeaponDefs.BATON])
	run.loadout = [WeaponDefs.DEFIB, WeaponDefs.DEFIB]
	check_eq(Loadout.from_run(run), Loadout.DEFAULT_WEAPONS)


func test_modes_round_trip_through_save_keys() -> void:
	for m: Loadout.Mode in [Loadout.Mode.TUNED, Loadout.Mode.MANUAL]:
		check_eq(Loadout.mode_from_key(Loadout.mode_key(m)), m)
	var run := RunState.new()
	run.weapon_modes = {WeaponDefs.BATON: "manual"}
	check_eq(Loadout.chosen_mode(run, WeaponDefs.BATON), Loadout.Mode.MANUAL)
	check_eq(Loadout.chosen_mode(run, WeaponDefs.DEFIB), Loadout.Mode.TUNED, "unset means tuned")


## Brief: Steward-tuned is easier; manual is harder and stronger in skilled hands.
func test_every_weapon_is_easier_tuned_and_deeper_manual() -> void:
	for id: String in WeaponDefs.SLICE_WEAPONS:
		var tuned := WeaponDefs.mode_info(id, "tuned")
		var manual := WeaponDefs.mode_info(id, "manual")
		check(float(tuned["ease"]) > float(manual["ease"]), "%s tuned is easier" % id)
		check(float(manual["ceiling"]) > float(tuned["ceiling"]), "%s manual has the higher ceiling" % id)
		check(str(tuned["blurb"]) != "" and str(manual["blurb"]) != "", "%s describes both modes" % id)
		check(WeaponDefs.asset_tag(id).begins_with("PROPERTY OF THE CITY OF MERIDIAN"), "%s keeps its asset tag" % id)
