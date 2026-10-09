class_name ArkLevel
extends Level
## The Ark (hub): a civic emergency platform in the estuary, a concrete disc with a ring of gold floor
## lights, and the only charter clause the council never amended: the Steward may advise here and may
## not act. No enemies, no predicted path, no weapons. Buildings rise as districts' cores come home; in
## the slice, the Archive. Noor and Teo wait by it; survivors you woke stand by the unbuilt Commons.

const SURVIVOR_SPOTS := "s"
## Which map letters are which Ark building's plot. A plot is built only once that building has been
## restored by bringing a district's core home; until then it is an unbuilt slab.
const PLOTS: Dictionary[String, String] = {"A": "archive"}
## The door belongs to the building it opens.
const DOORS: Dictionary[String, String] = {"a": "archive"}

var archive_screen: ArchiveScreen
var end_panel: EndOfSlice


func is_hub() -> bool:
	return true


func location_key() -> String:
	return "ark"


func _populate() -> void:
	_add_floor_lights()
	for c: Vector2i in grid.cells_with("N"):
		_figure(c, ArkFigure.Who.NOOR, "", GameState.run.noor_present)
	for c: Vector2i in grid.cells_with("Y"):
		_figure(c, ArkFigure.Who.TEO, "", GameState.run.teo_present)
	var survivors := GameState.run.survivor_ids
	var spots := survivor_cells(survivors.size())
	for i: int in survivors.size():
		_figure(spots[i], ArkFigure.Who.SURVIVOR, survivors[i], true)
	for marker: String in DOORS:
		if not GameState.run.buildings_restored.has(DOORS[marker]):
			continue
		for c: Vector2i in grid.cells_with(marker):
			var door := ArkFixture.new()
			door.setup(self, c, ArkFixture.Kind.ARCHIVE_DOOR)
			door.used.connect(_on_fixture_used)
			world.add_child(door)
	for c: Vector2i in grid.cells_with("D"):
		var dock := ArkFixture.new()
		dock.setup(self, c, ArkFixture.Kind.DOCK)
		dock.used.connect(_on_fixture_used)
		world.add_child(dock)


func _add_steward_path() -> void:
	pass


func _building_standing(ch: String) -> bool:
	return not PLOTS.has(ch) or GameState.run.buildings_restored.has(PLOTS[ch])


## Where `count` survivors stand: the marked spots by the Commons plot first, then the nearest free
## concrete around them, so everyone you bring home is there to talk to.
func survivor_cells(count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = grid.cells_with(SURVIVOR_SPOTS)
	if out.size() >= count or out.is_empty():
		return out.slice(0, count)
	var keep_clear: Array[Vector2i] = []
	for marker: String in ["a", "D", "p"]:
		for c: Vector2i in grid.cells_with(marker):
			keep_clear.append(c)
	var queue: Array[Vector2i] = out.duplicate()
	var seen: Dictionary[Vector2i, bool] = {}
	for c: Vector2i in out:
		seen[c] = true
	while not queue.is_empty() and out.size() < count:
		var c: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
			var n := c + d
			if seen.has(n) or not grid.is_walkable(n) or grid.is_occupied(n):
				continue
			seen[n] = true
			queue.append(n)
			var crowded := false
			for k: Vector2i in keep_clear:
				crowded = crowded or n.distance_to(k) < 2.0
			if not crowded and grid.floor_at(n) == LevelGrid.Floor.CONCRETE:
				out.append(n)
				if out.size() >= count:
					break
	return out


func _on_ready_extra() -> void:
	_arrive_line()


func _arrive_line() -> void:
	await Wait.seconds(self, 1.2)
	Narrator.notify(&"ark_arrive")


func _figure(cell: Vector2i, who: ArkFigure.Who, id: String, present: bool) -> void:
	if not present:
		return
	var f := ArkFigure.new()
	f.setup(self, cell, who, id)
	world.add_child(f)


## The ring of gold floor lights round the disc's edge.
func _add_floor_lights() -> void:
	var lights := Emissive.new()
	lights.z_index = -13
	var ops := DrawOps.new()
	for c: Vector2i in grid.cells_with("G"):
		var p := Iso.cell_center(c)
		ops.circle(p, 9.0, Palette.STEWARD_GOLD_HOT)
		ops.circle(p, 20.0, Color(Palette.STEWARD_GOLD, 0.18))
		var glow := PointLight2D.new()
		glow.texture = LightTextures.radial()
		glow.color = Palette.STEWARD_GOLD
		glow.energy = 0.9
		glow.texture_scale = 1.1
		glow.scale = Vector2(1.0, Iso.SQUASH)
		glow.position = p
		add_child(glow)
	lights.layers = [ops]
	add_child(lights)


func _on_fixture_used(kind: ArkFixture.Kind) -> void:
	if kind == ArkFixture.Kind.ARCHIVE_DOOR:
		open_archive()
	else:
		open_end_panel()


## The Archive and the end panel pause the Ark through Modals (they own the pause while open).
func open_archive() -> ArchiveScreen:
	if archive_screen != null:
		return archive_screen
	archive_screen = ArchiveScreen.new()
	archive_screen.closed.connect(func() -> void: archive_screen = null)
	add_child(archive_screen)
	return archive_screen


func open_end_panel() -> EndOfSlice:
	if end_panel != null:
		return end_panel
	end_panel = EndOfSlice.new()
	add_child(end_panel)
	return end_panel
