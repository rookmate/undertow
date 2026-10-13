extends TestCase
## The loadout screen with every tool found: each card's words stay on its card.


func test_every_cards_words_stay_on_it() -> void:
	GameState.new_run()
	for w: String in [WeaponDefs.RIOT_DRONE, WeaponDefs.DEFIB, WeaponDefs.SIGNAL_JAMMER]:
		GameState.give_weapon(w)
	var screen := (load("res://ui/loadout/loadout.tscn") as PackedScene).instantiate() as Control
	add_child(screen)
	await wait_frames(3)
	var cards: Dictionary = screen.get("_cards")
	check_eq(cards.size(), WeaponDefs.GRID.size())
	for id: String in cards:
		var card: Button = cards[id]
		for n: Node in card.get_children():
			if n is Label and (n as Label).text != "":
				var r := (n as Label).get_global_rect()
				check(card.get_global_rect().encloses(r), "%s: '%s' on its card (%s in %s)" % [id, (n as Label).text, r, card.get_global_rect()])
	screen.queue_free()
	await wait_frames(1)
