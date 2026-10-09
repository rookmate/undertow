extends TestCase


func test_known_events_move_the_right_score() -> void:
	var p := PlaystyleProfile.new()
	check(p.record(&"kill_low_health"))
	check(p.risk > 0.0 and p.caution == 0.0)
	check(p.record(&"perfect_dodge"))
	check(p.caution > 0.0)


func test_unknown_events_are_ignored() -> void:
	var p := PlaystyleProfile.new()
	check_false(p.record(&"made_tea"))
	check_eq(p.risk, 0.0)
	check_eq(p.caution, 0.0)


func test_lean_is_bounded_and_signed() -> void:
	var p := PlaystyleProfile.new()
	for i: int in 200:
		p.record(&"kill_close")
	check(p.lean() > 0.9 and p.lean() <= 1.0, "all risk leans to +1")
	check_eq(p.dominant_tone(), &"bold")
	var q := PlaystyleProfile.new()
	for i: int in 200:
		q.record(&"dodge")
	check(q.lean() < -0.9 and q.lean() >= -1.0, "all caution leans to -1")
	check_eq(q.dominant_tone(), &"cautious")


func test_one_event_does_not_flip_the_profile() -> void:
	var p := PlaystyleProfile.new()
	p.record(&"dodge")
	check_eq(p.dominant_tone(), &"neutral")


func test_round_trip() -> void:
	var p := PlaystyleProfile.new()
	p.risk = 3.0
	p.caution = 2.0
	var q := PlaystyleProfile.from_dict(p.to_dict())
	check_eq(q.risk, 3.0)
	check_eq(q.caution, 2.0)
	check_eq(PlaystyleProfile.from_dict({"risk": -5}).risk, 0.0, "negative scores clamp to 0")
