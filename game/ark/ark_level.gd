class_name ArkLevel
extends Level
## The Ark (hub): a civic emergency platform in the estuary, a concrete disc with a ring of gold floor
## lights, and the only charter clause the council never amended: the Steward may advise here and may
## not act. No enemies, no predicted path, no weapons. Buildings rise as districts' cores come home; in
## the slice, the Archive. Noor and Teo wait by it; survivors you woke stand by the unbuilt Commons.

const SURVIVOR_SPOTS := "s"

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
	var spots := grid.cells_with(SURVIVOR_SPOTS)
	var survivors := GameState.run.survivor_ids
	for i: int in mini(spots.size(), survivors.size()):
		_figure(spots[i], ArkFigure.Who.SURVIVOR, survivors[i], true)
	for c: Vector2i in grid.cells_with("a"):
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


func open_archive() -> ArchiveScreen:
	if archive_screen != null:
		return archive_screen
	get_tree().paused = true
	archive_screen = ArchiveScreen.new()
	archive_screen.closed.connect(func() -> void:
		archive_screen = null
		get_tree().paused = false)
	add_child(archive_screen)
	return archive_screen


func open_end_panel() -> EndOfSlice:
	if end_panel != null:
		return end_panel
	get_tree().paused = true
	end_panel = EndOfSlice.new()
	add_child(end_panel)
	return end_panel
