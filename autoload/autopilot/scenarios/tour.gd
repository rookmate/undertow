extends AutopilotScenario
## Straight into one district (--autopilot-level=ID) to look at it: its start, each checkpoint, each
## find and the Reliquary, then muted.

const CHECKS: Array[String] = ["tour_level_reached", "tour_done"]

var district: String = ""


func _init(level_id: String) -> void:
	district = level_id


func expected() -> Array[String]:
	var out := super()
	out.append_array(CHECKS)
	return out


func on_title(_title: Node, _gen: int) -> void:
	if not LevelCatalog.has_level(district):
		push_error("Autopilot: tour needs --autopilot-level=<district id> (got '%s')" % district)
		return
	var target := district
	SceneRouter.goto_level(target, func() -> void:
		GameState.new_run()
		GameState.set_location("level:" + target))


func on_level(level: Level, gen: int) -> void:
	Autopilot.check(level.level_id == district, "tour_level_reached")
	if not await Autopilot.wait(2.5, gen):
		return
	await Autopilot.snap("tour_start")
	var spots: Array[Vector2i] = []
	for marker: String in ["C", "W", "T", "U", "V", "R"]:
		for c: Vector2i in level.grid.cells_with(marker):
			spots.append(c)
	for c: Vector2i in spots:
		level.player.position = Iso.cell_center(_beside(level, c))
		if not await Autopilot.wait(1.8, gen):
			return
		await Autopilot.snap("tour_%s_%d_%d" % [level.grid.char_at(c), c.x, c.y])
	level.player.position = Iso.cell_center(level.grid.start_cell())
	Autopilot.tap(&"voice_toggle")
	if not await Autopilot.wait(2.5, gen):
		return
	await Autopilot.snap("tour_muted")
	Autopilot.tap(&"voice_toggle")
	Autopilot.check(true, "tour_done")


## A walkable cell next to `c` (or `c` itself) to stand on.
static func _beside(level: Level, c: Vector2i) -> Vector2i:
	if level.grid.is_walkable(c) and not level.grid.is_occupied(c):
		return c
	for d: Vector2i in [Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if level.grid.is_walkable(c + d) and not level.grid.is_occupied(c + d):
			return c + d
	return c
