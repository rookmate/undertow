extends TestCase
## From the Reliquary in the level to the card screen and back out, through the real scenes.


func before_each() -> void:
	GameState.new_run()
	Steward.set_voice(true)


func after_each() -> void:
	if not Steward.voice_on:
		Steward.set_voice(true)
	await wait_frames(2)


func _open_choice() -> Control:
	var scene := (load("res://ui/core_choice/core_choice.tscn") as PackedScene).instantiate() as Control
	add_child(scene)
	await wait_frames(2)
	return scene


func test_opening_the_reliquary_saves_and_points_continue_at_the_choice() -> void:
	var level := (load("res://game/level/vellum_street.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	level.remove_all_enemies()
	await wait_frames(2)
	var reliquary: Reliquary = null
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n is Reliquary and level.is_ancestor_of(n):
			reliquary = n
	check(reliquary != null, "the Reliquary stands past the press hall")
	level.player.position = Iso.cell_center(level.grid.first("R") + Vector2i(1, 0))
	await wait_frames(2)
	check(level.player.interact_target() == reliquary, "in reach")
	check_eq(reliquary.prompt_verb(), "OPEN THE RELIQUARY")
	# Interact without leaving the test scene: what SceneRouter would do is checked separately.
	GameState.set_location("reliquary:vellum")
	GameState.save()
	check_eq(SceneRouter.destination_for(SaveService.load_run().run.location), &"core_choice")
	level.queue_free()


func test_card_screen_offers_three_or_four_cards() -> void:
	var screen := await _open_choice()
	check_eq((screen.get("offered") as Array).size(), 3)
	screen.queue_free()
	await wait_frames(1)
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var screen2 := await _open_choice()
	check_eq((screen2.get("offered") as Array).size(), 4)
	screen2.queue_free()


func test_six_cards_fit_across_the_screen() -> void:
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	GameState.find_core("vellum_truth_vashti_office")
	GameState.find_core("vellum_truth_spiked")
	var screen := await _open_choice()
	var cards: Dictionary = screen.get("_cards")
	check_eq(cards.size(), 6, "the Vellum's three, both of Prem Vashti's notes and the spiked proofs")
	for b: Button in cards.values():
		var corner := b.get_global_transform() * b.size
		check(corner.x <= 1920.0 - 40.0 and corner.y <= 900.0, "a card ends at %s, on screen and above the buttons" % corner)
	screen.queue_free()


func test_steward_comments_only_while_listening() -> void:
	var screen := await _open_choice()
	var cards: Dictionary = screen.get("_cards")
	var any_card: Button = cards.values()[0]
	check(any_card.get_node_or_null(^"StewardComment") != null, "listening: it comments")
	screen.queue_free()
	await wait_frames(1)
	Steward.set_voice(false)
	var muted := await _open_choice()
	var muted_cards: Dictionary = muted.get("_cards")
	var muted_card: Button = muted_cards.values()[0]
	check(muted_card.get_node_or_null(^"StewardComment") == null, "muted: the cards speak for themselves")
	muted.queue_free()


func test_choosing_through_the_screen_applies_and_saves() -> void:
	GameState.find_core(ContentIds.CORE_TRUTH_STACKS)
	var screen := await _open_choice()
	var confirm: Button = screen.get("_confirm")
	check(confirm.disabled, "nothing picked yet")
	screen.call("_toggle", "vellum_power_feed")
	screen.call("_toggle", ContentIds.CORE_TRUTH_STACKS)
	check_false(confirm.disabled)
	screen.call("_toggle", "vellum_truth_0522")
	var picked: Array = screen.get("picked")
	check_eq(picked.size(), 2, "a third pick replaces the second, never three")
	confirm.emit_signal(&"pressed")
	await wait_frames(1)
	check_eq(GameState.run.cores_truth() + GameState.run.cores_power(), 2)
	check(SaveService.has_save())
	check_eq(SaveService.load_run().run.location, "ark", "the save resumes at the Ark")
	screen.queue_free()


func test_a_reliquary_with_no_real_choice_says_so_and_completes_nothing() -> void:
	GameState.set_location("reliquary:nowhere")
	var screen := await _open_choice()
	check_eq((screen.get("offered") as Array).size(), 0)
	check((screen.get("_summary") as Label).text.contains("broken"), "the screen says the Reliquary is broken")
	var confirm := screen.get("_confirm") as Button
	check_eq(confirm.text, "BACK TO THE TITLE", "the only way on is out")
	check(GameState.run.levels_completed.is_empty() and GameState.run.buildings_restored.is_empty(), "nothing completed")
	screen.queue_free()
