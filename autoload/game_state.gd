extends Node
## Owns the RunState. Every change to tracked state goes through these methods so it is signalled
## (HUD, debug overlay) and saved at the right moments.

signal state_changed(key: StringName)
signal run_replaced

var run: RunState = RunState.new()


## How the game quits once a close request is settled (tests replace it).
var quit_handler: Callable
var _closing: bool = false


func _ready() -> void:
	# Closing the window mid-run saves first; if that fails the player is asked, not silently dropped.
	get_tree().auto_accept_quit = false
	quit_handler = func() -> void: Sound.quit()
	# Every district's map and content are checked once at boot. Problems are engine errors (the gate
	# fails on them); a broken Reliquary also refuses to complete its level, never a free pass.
	for p: String in LevelCatalog.check_all():
		Diagnostics.error("Content: %s" % p)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_requested()


func _close_requested() -> void:
	# One close at a time: pressing close again while the save question is up doesn't ask twice.
	if _closing:
		return
	_closing = true
	if run.location != "":
		var safe: bool = await SaveFlow.before_leaving(get_tree())
		if not safe:
			_closing = false
			return
	quit_handler.call()
	_closing = false


func new_run() -> void:
	run = RunState.new()
	run_replaced.emit()


func replace_run(state: RunState) -> void:
	run = state
	run_replaced.emit()


func save() -> Error:
	return SaveService.save_run(run)


# --- Voice -------------------------------------------------------------------------------------------
## Called every gameplay frame by the Steward while a level is running.
func add_voice_time(delta: float, voice_on: bool) -> void:
	if delta <= 0.0:
		return
	if voice_on:
		run.voice_on_seconds += delta
	else:
		run.voice_off_seconds += delta


func count_voice_toggle() -> void:
	run.voice_toggle_count += 1
	state_changed.emit(&"voice_toggle_count")


func add_play_time(delta: float) -> void:
	run.play_seconds += maxf(delta, 0.0)


# --- Cores, survivors, logs ----------------------------------------------------------------------------
func take_core(core_id: String, is_truth: bool) -> void:
	var list := run.truth_core_ids if is_truth else run.power_core_ids
	if list.has(core_id):
		return
	list.append(core_id)
	state_changed.emit(&"cores_truth" if is_truth else &"cores_power")


## A core picked up during a level (off the path). It is offered at the Reliquary with the others.
func find_core(core_id: String) -> void:
	if run.found_core_ids.has(core_id):
		return
	run.found_core_ids.append(core_id)
	state_changed.emit(&"found_core_ids")


## The Reliquary has made its offer; found cores were either carried or left behind.
func clear_found_cores() -> void:
	if run.found_core_ids.is_empty():
		return
	run.found_core_ids.clear()
	state_changed.emit(&"found_core_ids")


## Returns false if this survivor was already counted.
func add_survivor(survivor_id: String) -> bool:
	if run.survivor_ids.has(survivor_id):
		return false
	run.survivor_ids.append(survivor_id)
	state_changed.emit(&"survivors_found")
	return true


func unlock_log(log_id: String) -> void:
	if run.logs_unlocked.has(log_id):
		return
	run.logs_unlocked.append(log_id)
	state_changed.emit(&"logs_unlocked")


## Returns true the first time a log is replayed (reactions and trust apply only then).
func mark_log_replayed(log_id: String) -> bool:
	if run.logs_replayed.has(log_id):
		return false
	run.logs_replayed.append(log_id)
	state_changed.emit(&"logs_replayed")
	return true


# --- Companions --------------------------------------------------------------------------------------------
func change_trust(who: StringName, amount: int) -> void:
	if who == RunState.WHO_NOOR:
		run.noor_trust = clampi(run.noor_trust + amount, Tunables.TRUST_MIN, Tunables.TRUST_MAX)
		state_changed.emit(&"noor_trust")
	elif who == RunState.WHO_TEO:
		run.teo_trust = clampi(run.teo_trust + amount, Tunables.TRUST_MIN, Tunables.TRUST_MAX)
		state_changed.emit(&"teo_trust")
	else:
		push_error("GameState.change_trust: unknown companion %s" % who)


## Uses a field dressing if there's one. Returns whether there was.
func use_dressing() -> bool:
	if run.dressings <= 0:
		return false
	run.dressings -= 1
	state_changed.emit(&"dressings")
	return true


## The Clinic stocks you up (only once it stands).
func restock_dressings() -> void:
	if run.buildings_restored.has("clinic") and run.dressings < Tunables.DRESSINGS_MAX:
		run.dressings = Tunables.DRESSINGS_MAX
		state_changed.emit(&"dressings")


## Noor and Teo have arrived on the Ark.
## Talks a district over with Noor and Teo, answering `side` (one of Conversations.SIDES): their trust
## moves (Conversations.TRUST) and it's kept. False, changing nothing, unless the district is done, its
## talk is waiting (both of them here, not had yet) and the answer is on offer.
func have_conversation(district: String, side: String) -> bool:
	if not run.levels_completed.has(district) or run.conversations_had.has(district) or not Conversations.SIDES.has(side):
		return false
	if not (run.companion_here(RunState.WHO_NOOR) and run.companion_here(RunState.WHO_TEO)) or not Conversations.has(district):
		return false
	run.conversations_had.append(district)
	change_trust(RunState.WHO_NOOR, Conversations.trust_change(side, "noor"))
	change_trust(RunState.WHO_TEO, Conversations.trust_change(side, "teo"))
	state_changed.emit(&"conversations_had")
	return true


## Noor, carried to the Wardfolk's boat at the border: she comes home, and she won't forget it.
func noor_comes_home() -> void:
	if run.noor_away:
		run.noor_away = false
		change_trust(RunState.WHO_NOOR, 2)
		state_changed.emit(&"noor_away")


## Noor left at the border (or refusing your hand): she stays in the Ward, gone from the run.
func noor_stays_in_ward() -> void:
	if run.noor_away or run.noor_present:
		run.noor_away = false
		run.noor_present = false
		state_changed.emit(&"noor_present")


## Teo's turn, had at the dock setting off for the Spire: he stays, or (`leaves`) he's gone from the run.
func teo_turn(leaves: bool) -> void:
	run.teo_turn_had = true
	if leaves and run.teo_present:
		run.teo_present = false
		state_changed.emit(&"teo_present")


## Noor goes ahead to Harbor Ward (her turn): off the Ark until she comes home, if she does.
func noor_leaves_for_ward() -> void:
	if not run.noor_away:
		run.noor_away = true
		state_changed.emit(&"noor_away")


func meet_companions() -> void:
	if not run.companions_met:
		run.companions_met = true
		state_changed.emit(&"companions_met")


func set_present(who: StringName, present: bool) -> void:
	if who == RunState.WHO_NOOR:
		run.noor_present = present
		state_changed.emit(&"noor_present")
	elif who == RunState.WHO_TEO:
		run.teo_present = present
		state_changed.emit(&"teo_present")
	else:
		push_error("GameState.set_present: unknown companion %s" % who)


# --- Overrides ----------------------------------------------------------------------------------------------
func has_override(override_id: String) -> bool:
	return run.active_overrides.has(override_id)


func set_override(override_id: String, signed: bool) -> void:
	if not Overrides.is_known(override_id):
		Diagnostics.error("GameState.set_override: no such order %s" % override_id)
		return
	if signed == has_override(override_id):
		return
	if signed:
		run.active_overrides.append(override_id)
	else:
		run.active_overrides.erase(override_id)
	state_changed.emit(&"active_overrides")


# --- Playstyle ------------------------------------------------------------------------------------------------
func record_playstyle(event: StringName, weight: float = 1.0) -> void:
	if run.playstyle_profile.record(event, weight):
		state_changed.emit(&"playstyle_profile")


# --- Progress ----------------------------------------------------------------------------------------------------
func set_loadout(weapon_ids: Array[String], modes: Dictionary[String, String]) -> void:
	run.loadout = weapon_ids.duplicate()
	run.weapon_modes = modes.duplicate()
	state_changed.emit(&"loadout")


## A weapon recovered in the city: from now on the loadout offers it.
func give_weapon(weapon_id: String) -> void:
	if run.weapons_owned.has(weapon_id) or not WeaponDefs.is_known(weapon_id):
		return
	run.weapons_owned.append(weapon_id)
	state_changed.emit(&"weapons_owned")


## Buys the next Workshop level for a weapon's mode. Returns "" or why not (nothing changes then).
func buy_upgrade(weapon_id: String, mode_key: String) -> String:
	var problem := Upgrades.why_not(run, weapon_id, mode_key)
	if problem != "":
		return problem
	run.scrap -= Upgrades.next_cost(run, weapon_id, mode_key)
	var k := Upgrades.key(weapon_id, mode_key)
	run.upgrades[k] = Upgrades.level(run, weapon_id, mode_key) + 1
	state_changed.emit(&"upgrades")
	state_changed.emit(&"scrap")
	return ""


func add_scrap(amount: int) -> void:
	if amount == 0:
		return
	run.scrap = maxi(0, run.scrap + amount)
	state_changed.emit(&"scrap")


## Noor's Mast on the Commons roof: it marks unindexed places on the map, in every district.
const MAST := "mast"


func restore_building(building_id: String) -> void:
	if run.buildings_restored.has(building_id):
		return
	run.buildings_restored.append(building_id)
	state_changed.emit(&"buildings_restored")


func complete_level(level_id: String) -> void:
	if run.levels_completed.has(level_id):
		return
	run.levels_completed.append(level_id)
	state_changed.emit(&"levels_completed")
	# Leaving the Ward without carrying her home is leaving her (design/act-3.md); home with you, she
	# wires the Mast on the Ark. (Harbor Ward can only be set off for with her going ahead: still here at
	# its end, she came home.)
	if level_id == "harbor":
		if run.noor_away:
			noor_stays_in_ward()
		elif run.noor_present:
			restore_building(MAST)


func set_location(where: String) -> void:
	run.location = where
	state_changed.emit(&"location")
