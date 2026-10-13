extends TestCase
## The Warden-Prime (Harbor Ward's boss), in a test arena: its searchlight marks you and it fires a
## volley; it lines up a charge and rams, dazed if it hits a wall, open while it's dazed; the relay mast
## struck while it sweeps stalls it. And Noor's turn after it: carry her to the boat (no weapons, slower,
## the curfew patrol after you; downed, you drop her) and she comes home; leave her, or have her refuse
## you, and she's gone from the run.

var level: Level
var prime: WardenPrime


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	GameState.noor_leaves_for_ward()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()
	level = (load("res://tests/fixtures/warden_prime_arena.tscn") as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	prime = level.boss as WardenPrime


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	level.queue_free()
	await wait_frames(2)


func _stand(cell: Vector2i) -> void:
	level.player.position = Iso.cell_center(cell)
	await wait_physics_frames(2)
	# Past the Steward's introduction, as if cut short: the fight starts at once.
	Sound.hush()
	await wait_physics_frames(1)


func test_its_light_marks_you_and_the_volley_comes() -> void:
	check(prime != null and prime.weak_point is RelayMast, "the Warden-Prime, and the relay mast")
	await _stand(Vector2i(8, 10))
	check(prime.is_fighting, "fighting")
	check_eq(prime.phase, WardenPrime.Phase.SWEEP, "its light sweeps")
	# The beam's edge on you as it starts, so it passes right over you.
	var at := Iso.ground_dir_between(prime.global_position, level.player.global_position).angle()
	prime.set("_sweep_from", at - deg_to_rad(WardenPrime.LIGHT_DEG * 0.5))
	var before := level.player.integrity.value
	var marked := false
	for k: int in roundi((WardenPrime.MARK_SECONDS + WardenPrime.VOLLEY_WARN + 1.8) * 60.0):
		await wait_physics_frames(1)
		marked = marked or prime.phase == WardenPrime.Phase.VOLLEY
	check(marked, "caught in its light, marked")
	check(level.player.integrity.value < before, "and shot")


func test_a_charge_into_a_wall_dazes_it_and_it_is_open() -> void:
	await _stand(Vector2i(8, 5))
	var full := prime.integrity.value
	prime.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(prime.integrity.value, full, "armoured while it sweeps")
	prime.call(&"_enter_phase", WardenPrime.Phase.CHARGE_WARN)
	check_eq(Sound.voice_line, "warden_prime_charge", "the Steward calls the charge")
	await wait_physics_frames(roundi(WardenPrime.CHARGE_WARN_SECONDS * 0.8 * 60.0))
	level.player.position = Iso.cell_center(Vector2i(13, 8))
	var dazed := false
	for k: int in 120:
		await wait_physics_frames(1)
		if prime.phase == WardenPrime.Phase.DAZED:
			dazed = true
			break
	check(dazed, "it ran on into the barrier and is dazed")
	check(prime.is_vulnerable(), "open")
	prime.take_hit(40.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(prime.integrity.value, full - 40.0, "it takes the blow")


func test_the_relay_struck_while_it_sweeps_stalls_it() -> void:
	await _stand(Vector2i(12, 6))
	check(prime.is_switching(), "sweeping")
	prime.weak_point.take_hit(5.0, Vector2(1, 0), 0.0, 0.0)
	check_eq(prime.phase, WardenPrime.Phase.STALLED, "it loses its link")
	check(prime.is_vulnerable())
	check_false(prime.weak_point.steward_aims_at, "and the Steward never points you at it")


func _beat_it() -> void:
	await _stand(Vector2i(4, 9))
	# Through its stages: each blow stops at the next threshold, and it pauses before the next.
	for k: int in prime.stage_count():
		prime.call(&"_enter_phase", WardenPrime.Phase.DAZED)
		prime.take_hit(WardenPrime.MAX_INTEGRITY, Vector2(1, 0), 0.0, 0.0)
		if prime.in_transition():
			await wait_until(func() -> bool: return not prime.in_transition(), Boss.STAGE_TRANSITION + Boss.STAGE_CALL_WAIT + 0.5)
	await wait_physics_frames(3)


func _noor() -> NoorDown:
	return level.noor_down


func test_noor_waits_for_the_fight_then_you_carry_her_home() -> void:
	check(_noor() != null, "Noor's down by the fence")
	await _stand(Vector2i(2, 9))
	check_false(_noor().can_interact(), "not while it's on its feet")
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	check(level.player.interact_target() == _noor() and _noor().can_interact(), "now you can go to her")
	_noor().interact(level.player)
	await wait_frames(2)
	var choice := level.noor_choice
	check(choice != null and choice.get("_carry") != null, "carry her, or leave her")
	choice.carry()
	await wait_frames(2)
	check(level.player.carrying, "on your shoulder")
	check_false(level.player.can_act(), "no weapons while you carry her")
	var patrol := 0
	for e: Enemy in level.living_enemies():
		if e is Warden and (e as Warden).hunting:
			patrol += 1
	check_eq(patrol, 2, "the curfew patrol comes in after you, hunting")
	var boat: WardBoat = null
	for n: Node in level.world.get_children():
		if n is WardBoat:
			boat = n
	boat.interact(level.player)
	check_false(level.player.carrying, "set down in the boat")
	check(GameState.run.noor_present and not GameState.run.noor_away, "she's coming home")
	check_eq(GameState.run.noor_trust, 2, "and she won't forget it")


func test_accept_on_the_choice_carries_her() -> void:
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	var carry := level.noor_choice.get("_carry") as Button
	check(carry != null and carry.has_focus(), "carrying her is the first answer, focused")
	var down := InputEventAction.new()
	down.action = &"ui_accept"
	down.pressed = true
	Input.parse_input_event(down)
	await wait_frames(1)
	var up := InputEventAction.new()
	up.action = &"ui_accept"
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(2)
	check(level.player.carrying, "Enter / A: she's on your shoulder")
	check(level.noor_choice == null, "and the screen's gone")


func test_carrying_her_the_reliquary_waits_for_the_boat() -> void:
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	level.noor_choice.carry()
	await wait_frames(2)
	var reliquary: Reliquary = null
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n is Reliquary and level.is_ancestor_of(n):
			reliquary = n
	check(reliquary != null, "the depot's Reliquary")
	check_false(reliquary.can_interact(), "not with her on your shoulder: that would be leaving her")
	check(reliquary.blocked_reason() != "", "and it says why")
	level.player.set_carrying(false)
	check(reliquary.can_interact(), "set down, it opens")


func test_downed_while_you_carry_her_you_drop_her() -> void:
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	level.noor_choice.carry()
	await wait_frames(2)
	level.player.self_damage(500.0)
	await wait_physics_frames(2)
	check_false(level.player.carrying, "down: she's not on your shoulder")
	check_false(_noor().carried, "she's back by the fence, to be picked up again")
	check(GameState.run.noor_away, "still undecided")


func test_leave_her_and_she_is_gone_from_the_run() -> void:
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	level.noor_choice.leave()
	check_false(GameState.run.noor_present, "she stays in the Ward")
	check_false(EndingRules.evaluate(GameState.run).rewrite, "and Rewrite can't be had")


func test_with_her_trust_at_the_bottom_she_refuses_your_hand() -> void:
	GameState.run.noor_trust = NoorDown.REFUSES_AT
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	check(level.noor_choice.get("_carry") == null, "no carrying her: only leaving")
	level.noor_choice.carry()
	check(GameState.run.noor_away, "carry does nothing when she refuses")


func test_leaving_the_ward_without_her_is_leaving_her() -> void:
	GameState.complete_level("harbor")
	check_false(GameState.run.noor_present, "undecided at the end: she stayed")
	check_false(GameState.run.noor_away)


func test_carried_again_the_same_patrol_comes_after_you() -> void:
	await _beat_it()
	level.player.position = Iso.cell_center(Vector2i(2, 10))
	await wait_physics_frames(2)
	_noor().interact(level.player)
	await wait_frames(2)
	level.noor_choice.carry()
	await wait_frames(2)
	check_eq(level.curfew_patrol().size(), 2, "the curfew patrol, two of them")
	var wardens := level.living_enemies().size()
	level.player.self_damage(500.0)
	await wait_physics_frames(2)
	level.respawn_player()
	await wait_physics_frames(2)
	for w: Warden in level.curfew_patrol():
		w.hunting = false
	_noor().interact(level.player)
	await wait_frames(2)
	if level.noor_choice != null:
		level.noor_choice.carry()
	await wait_frames(2)
	check_eq(level.curfew_patrol().size(), 2, "picked up again: the same two, no more")
	check_eq(level.living_enemies().size(), wardens, "nobody new")
	check(level.curfew_patrol().all(func(w: Warden) -> bool: return w.hunting), "and they're after you again")
