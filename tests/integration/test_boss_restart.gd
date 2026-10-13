extends TestCase
## Dying in a boss fight restarts it (DECISIONS 177), for every boss in the game: the one you hurt is
## gone with its weak point, its lanes or rollers and whatever it had in the air; a fresh one stands
## where it was built, at full strength, not yet engaged. It doesn't introduce itself again and gives you
## a moment at the checkpoint by the arena before it engages. Its barriers stay shut.

var level: Level


func before_each() -> void:
	GameState.new_run()
	for district: String in ["kestrel", "loop", "tideworks", "mercy", "vellum", "greywater"]:
		GameState.complete_level(district)
	GameState.meet_companions()
	GameState.noor_leaves_for_ward()
	Steward.set_voice(true)
	Steward.set_coverage(true)
	Sound.hush()


func after_each() -> void:
	Modals.clear()
	get_tree().paused = false
	if level != null:
		level.queue_free()
		level = null
	await wait_frames(2)
	Steward.set_coverage(true)


func _districts_with_bosses() -> Array[String]:
	var out: Array[String] = []
	for id: String in LevelCatalog.LEVELS:
		if LevelCatalog.boss_of(id) != "":
			out.append(id)
	return out


func _enemy_shots() -> int:
	var n := 0
	for c: Node in level.world.get_children():
		if c is Projectile and (c as Projectile).team == Projectile.Team.ENEMY and not c.is_queued_for_deletion():
			n += 1
	return n


func test_every_boss_fight_starts_over_when_you_die() -> void:
	var ids := _districts_with_bosses()
	check(ids.size() >= 6, "every boss: %s" % [ids])
	for id: String in ids:
		await _die_against(id)


func _die_against(id: String) -> void:
	# A first visit: back in a district you've done, its boss stays beaten (DECISIONS 187).
	GameState.run.levels_completed.erase(id)
	level = (load(LevelCatalog.scene_of(id)) as PackedScene).instantiate() as Level
	add_child(level)
	await wait_frames(3)
	var first := level.boss
	check(first != null, "%s: its boss" % id)
	if first == null:
		return
	var parts := get_tree().get_nodes_in_group(&"boss_parts").filter(func(n: Node) -> bool: return level.is_ancestor_of(n)).size()
	# The checkpoint at the arena's door, on your side of its barrier, is where you come back: whichever
	# checkpoint you last touched (here none: you walked straight in from the start).
	var door := level.grid.arena_checkpoint()
	check(door.x >= 0, "%s: a checkpoint by its arena's door" % id)
	level.player.position = first.global_position + Iso.ground_velocity(Vector2(0, 1), 3.0)
	await wait_physics_frames(3)
	check(first.is_engaged, "%s: engaged" % id)
	Sound.hush()
	await wait_physics_frames(30)
	# Deep into the fight: into its next stage if it has one, half its strength gone.
	if first.stage_count() > 1:
		first.call(&"_begin_stage", 2)
	first.integrity.take(first.integrity.max_value * 0.5)
	level.player.self_damage(10000.0)
	await wait_seconds(Operator.DOWNED_SECONDS + 0.2)
	var again := level.boss
	check(again != null and again != first and is_instance_valid(again), "%s: a fresh boss" % id)
	if again == null or again == first:
		return
	check_false(is_instance_valid(first) and not first.is_queued_for_deletion(), "%s: the one you hurt is gone" % id)
	check_eq(again.integrity.value, again.integrity.max_value, "%s: at full strength" % id)
	check_eq(again.stage, 1, "%s: its first stage" % id)
	check_false(again.is_engaged, "%s: not yet engaged" % id)
	check(again.weak_point == null or (is_instance_valid(again.weak_point) and again.weak_point.boss == again), "%s: its own weak point" % id)
	check_eq(get_tree().get_nodes_in_group(&"boss_parts").filter(func(n: Node) -> bool: return level.is_ancestor_of(n) and not n.is_queued_for_deletion()).size(), parts, "%s: its lanes or rollers, once" % id)
	check_eq(_enemy_shots(), 0, "%s: nothing of the old fight in the air" % id)
	check(level.player.is_alive() and Iso.world_to_cell(level.player.global_position) == door, "%s: you're back by the arena's door" % id)
	check_eq(level.living_enemies().filter(func(e: Enemy) -> bool: return e is Boss).size(), 1, "%s: one boss" % id)
	# A moment to get your feet under you, even within reach.
	level.player.position = again.global_position + Iso.ground_velocity(Vector2(0, 1), 3.0)
	await wait_physics_frames(30)
	check_false(again.is_engaged, "%s: it waits a moment" % id)
	await wait_seconds(Boss.RETRY_GRACE)
	check(again.is_engaged and not again.introducing(), "%s: then engages, without its introduction" % id)
	level.queue_free()
	level = null
	await wait_frames(2)


## Going down settles the fight (BossEncounter): a shot you'd already fired, landing while you're down,
## can't finish the boss and skip the restart.
func test_a_shot_still_in_the_air_cant_finish_it_once_youre_down() -> void:
	level = (load("res://tests/fixtures/conductor_arena.tscn") as PackedScene).instantiate() as Level
	# A first visit (back in a district you've done, its boss stays beaten).
	GameState.run.levels_completed.erase(level.level_id)
	add_child(level)
	await wait_frames(3)
	var c := level.boss as Conductor
	level.player.position = c.global_position + Iso.ground_velocity(Vector2(0, 1), 3.0)
	await wait_physics_frames(3)
	check(c.is_engaged, "engaged")
	Sound.hush()
	c.call(&"_enter_phase", Conductor.Phase.VENT)
	check(c.is_vulnerable(), "open")
	level.player.self_damage(10000.0)
	await wait_physics_frames(2)
	c.take_hit(c.integrity.max_value * 10.0, Vector2(1, 0), 0.0, 0.0)
	check(c.is_alive(), "the blow that lands after you've gone down doesn't finish it")
	await wait_seconds(Operator.DOWNED_SECONDS + 0.2)
	check(level.boss != null and level.boss != c and level.boss.is_alive() and level.boss.retrying, "the fight starts over")

