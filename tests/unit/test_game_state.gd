extends TestCase


func before_each() -> void:
	GameState.new_run()


func test_trust_changes_are_clamped() -> void:
	GameState.change_trust(RunState.WHO_NOOR, 50)
	check_eq(GameState.run.noor_trust, Tunables.TRUST_MAX)
	GameState.change_trust(RunState.WHO_TEO, -50)
	check_eq(GameState.run.teo_trust, Tunables.TRUST_MIN)


func test_cores_are_counted_once_by_kind() -> void:
	GameState.take_core("p1", false)
	GameState.take_core("p1", false)
	GameState.take_core("t1", true)
	check_eq(GameState.run.cores_power(), 1)
	check_eq(GameState.run.cores_truth(), 1)


func test_survivors_are_counted_once() -> void:
	check(GameState.add_survivor("w1"))
	check_false(GameState.add_survivor("w1"))
	check_eq(GameState.run.survivors_found(), 1)


func test_logs_replay_only_counts_first_time() -> void:
	GameState.unlock_log("log_a")
	check(GameState.mark_log_replayed("log_a"))
	check_false(GameState.mark_log_replayed("log_a"))


func test_overrides_sign_and_revoke() -> void:
	GameState.set_override("no_trap_warnings", true)
	check(GameState.has_override("no_trap_warnings"))
	GameState.set_override("no_trap_warnings", true)
	check_eq(GameState.run.active_overrides.size(), 1)
	GameState.set_override("no_trap_warnings", false)
	check_false(GameState.has_override("no_trap_warnings"))


func test_voice_time_accumulates_by_state() -> void:
	GameState.add_voice_time(2.0, true)
	GameState.add_voice_time(6.0, false)
	GameState.add_voice_time(-1.0, false)
	check_near(GameState.run.voice_on_ratio(), 0.25)


func test_changes_emit_state_changed() -> void:
	var seen: Array[StringName] = []
	var listener := func(key: StringName) -> void: seen.append(key)
	GameState.state_changed.connect(listener)
	GameState.change_trust(RunState.WHO_NOOR, 1)
	GameState.add_survivor("w9")
	GameState.state_changed.disconnect(listener)
	check(seen.has(&"noor_trust") and seen.has(&"survivors_found"), "got %s" % [seen])
