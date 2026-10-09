extends TestCase
## The brief's voice table as rules.


func test_voice_on_gives_every_assist() -> void:
	var a := Assists.compute(true, 0, [])
	check(a.path_visible)
	check_eq(a.map_mode, Assists.MapMode.STEWARD)
	check(a.threat_warnings)
	check(a.dodge_slowmo_seconds > 0.0)
	check(a.aim_assist > 0.0)
	check_false(a.weapons_forced_manual)
	check_eq(a.damage_taken_mult, 1.0)
	check(a.narration)


func test_voice_off_takes_them_all_away_and_hits_harder() -> void:
	var a := Assists.compute(false, 3, [])
	check_false(a.path_visible)
	check_eq(a.map_mode, Assists.MapMode.HAND_SCAN)
	check_false(a.threat_warnings)
	check_eq(a.dodge_slowmo_seconds, 0.0)
	check_eq(a.aim_assist, 0.0)
	check(a.weapons_forced_manual)
	check_near(a.damage_taken_mult, 1.4)
	check_false(a.narration)


func test_power_cores_strengthen_assistance_with_a_cap() -> void:
	var none := Assists.compute(true, 0, [])
	var two := Assists.compute(true, 2, [])
	var many := Assists.compute(true, 20, [])
	check(two.aim_assist > none.aim_assist and two.dodge_slowmo_seconds > none.dodge_slowmo_seconds)
	check_near(many.aim_assist, Assists.MAX_AIM_ASSIST)


func test_never_warn_me_override_silences_threat_warnings_only() -> void:
	var signed: Array[String] = [Overrides.NO_TRAP_WARNINGS]
	var a := Assists.compute(true, 0, signed)
	check_false(a.threat_warnings)
	check(a.threat_warnings_overridden, "the HUD can say why")
	check(a.path_visible and a.aim_assist > 0.0, "everything else stays")
	check_false(Assists.compute(false, 0, signed).threat_warnings_overridden, "muted, there's nothing to override")
