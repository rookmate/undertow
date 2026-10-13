extends TestCase
## Whose words a blocked prompt is: only the Steward's refusals take its serif and its gold (the seals it
## holds, the Waiting it won't wake). A shut hatch, a locked door, a boat, the Reliquary and Noor say
## why in plain type.


func test_only_the_stewards_refusals_are_its() -> void:
	var stewards: Array[Interactable] = [WardSeal.new(), TheWaiting.new()]
	var places: Array[Interactable] = [Passage.new(), ToolDoor.new(), Reliquary.new(), NoorDown.new(), WardBoat.new(), Hold.new(), TruthCache.new()]
	for it: Interactable in stewards:
		check(it.blocked_by_steward(), "%s: the Steward's" % it.get_script().resource_path.get_file())
	for it: Interactable in places:
		check_false(it.blocked_by_steward(), "%s: the place's" % it.get_script().resource_path.get_file())
	for it: Interactable in stewards + places:
		it.free()


func test_a_places_reason_is_plain() -> void:
	check(HudView.reason_font(false) != UiFonts.narration(), "not the Steward's serif")
	check(HudView.reason_color(false) != Palette.STEWARD_GOLD, "not its gold")
	check(HudView.reason_font(true) == UiFonts.narration() and HudView.reason_color(true) == Palette.STEWARD_GOLD, "its own refusals are")
