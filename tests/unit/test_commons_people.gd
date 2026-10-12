extends TestCase
## The Commons' people's words (data/companions/commons.json): every district with someone to wake has
## lines for them, each person always says the same one of their own district's, and the Wardfolk talk
## about Noor whichever way her turn went.


func test_the_words_are_all_there() -> void:
	var problems := CommonsPeople.problems()
	check(problems.is_empty(), "%s" % [problems])


func test_a_survivor_says_one_of_their_districts_lines_always_the_same() -> void:
	check_eq(CommonsPeople.district_of("loop_waiting_carriage_1"), "loop")
	var line := CommonsPeople.survivor_line("loop_waiting_carriage_1")
	check(line != "", "the Loop's people have lines")
	check_eq(CommonsPeople.survivor_line("loop_waiting_carriage_1"), line, "the same one each time")
	check(CommonsPeople.survivor_line("mercy_waiting_night_nurse") != line, "Mercy's people have their own")
	check_eq(CommonsPeople.survivor_line("nowhere_waiting_at_all"), "", "nobody from nowhere")


func test_the_wardfolk_talk_about_noor() -> void:
	var run := RunState.new()
	run.noor_present = true
	var home := CommonsPeople.wardfolk_line(0, run)
	run.noor_present = false
	var stayed := CommonsPeople.wardfolk_line(0, run)
	check(home != "" and stayed != "" and home != stayed, "Noor home, or staying in the Ward: %s / %s" % [home, stayed])
	check(CommonsPeople.wardfolk_line(0, run) != CommonsPeople.wardfolk_line(1, run), "two of them, two things to say")
