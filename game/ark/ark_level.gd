class_name ArkLevel
extends Level
## The Ark (hub): a civic emergency platform in the estuary, a concrete disc with a ring of gold floor
## lights, and the only charter clause the council never amended: the Steward may advise here and may
## not act. No enemies, no predicted path, no weapons. Buildings rise as districts' cores come home.
## Survivors you woke stand by the unbuilt Commons. Noor and Teo join after Act 1: the first time you
## come home after the Tideworks they arrive off the dock (once), and from then on they stand by the
## Archive.

const SURVIVOR_SPOTS := "s"
## Which map letters are which Ark building's plot. A plot is built only once that building has been
## restored by bringing a district's core home; until then it is an unbuilt slab.
const PLOTS: Dictionary[String, String] = {"A": "archive", "M": "signal_room", "I": "workshop", Tiles.CLINIC: "clinic", Tiles.PUMPHOUSE: "pumphouse"}
## The door belongs to the building it opens.
const DOORS: Dictionary[String, String] = {"a": "archive", "e": "signal_room", "z": "workshop", Tiles.CLINIC_DOOR: "clinic", Tiles.PUMPHOUSE_DOOR: "pumphouse"}
## What each building's door is.
const DOOR_KINDS: Dictionary[String, ArkFixture.Kind] = {
	"archive": ArkFixture.Kind.ARCHIVE_DOOR, "signal_room": ArkFixture.Kind.SIGNAL_DOOR, "workshop": ArkFixture.Kind.WORKSHOP_DOOR,
	"clinic": ArkFixture.Kind.CLINIC_DOOR, "pumphouse": ArkFixture.Kind.PUMPHOUSE_DOOR,
}

## The arrival lines, in order: who says it ("noor", "teo", or "steward" for its voiced line) and what.
const ARRIVAL: Array[Array] = [
	["noor", "So you're the one it woke. Keep a hand near that earpiece."],
	["teo", "Teo. I wrote some of its dispatch layer. It's still trying to help, you know."],
	["steward", "companions_arrive"],
	["noor", "Noor. Harbor Ward. We ran our own lights for ten years. We can run them again."],
]
const ARRIVAL_LINE_SECONDS := 4.5
## Where they come up onto the disc from the dock.
const ARRIVAL_WAYPOINT := Vector2i(18, 18)

var archive_screen: ArchiveScreen
## Noor and Teo, when they're here (null otherwise).
var noor: ArkFigure
var teo: ArkFigure
## Their arrival is playing.
var arriving: bool = false
var city_map: CityMap
var overrides_screen: OverridesScreen
var workshop_screen: WorkshopScreen
var clinic_screen: ClinicScreen


func is_hub() -> bool:
	return true


func location_key() -> String:
	return "ark"


func _populate() -> void:
	_add_floor_lights()
	var run := GameState.run
	noor = _figure(grid.first("N"), ArkFigure.Who.NOOR, "", run.companion_here(RunState.WHO_NOOR))
	teo = _figure(grid.first("Y"), ArkFigure.Who.TEO, "", run.companion_here(RunState.WHO_TEO))
	arriving = run.companions_joined() and not run.companions_met and (noor != null or teo != null)
	if arriving:
		# Off the dock, side by side: they walk up to where they'll stand from now on.
		var dock := grid.first("D")
		if noor != null:
			noor.position = Iso.cell_center(dock)
		if teo != null:
			teo.position = Iso.cell_center(dock + Vector2i(1, 0) if grid.is_walkable(dock + Vector2i(1, 0)) else dock)
	var survivors := GameState.run.survivor_ids
	var spots := survivor_cells(survivors.size())
	if spots.size() < survivors.size():
		# More people are home than the Ark has room to show: a content limit to raise (a bigger Commons),
		# reported loudly; everyone stays in the run, and nothing crashes.
		Diagnostics.error("Ark: room for %d survivors, %d are home" % [spots.size(), survivors.size()])
	for i: int in spots.size():
		_figure(spots[i], ArkFigure.Who.SURVIVOR, survivors[i], true)
	for marker: String in DOORS:
		if not GameState.run.buildings_restored.has(DOORS[marker]):
			continue
		for c: Vector2i in grid.cells_with(marker):
			var door := ArkFixture.new()
			door.setup(self, c, DOOR_KINDS[DOORS[marker]])
			door.used.connect(_on_fixture_used)
			world.add_child(door)
	for c: Vector2i in grid.cells_with("D"):
		var dock := ArkFixture.new()
		dock.setup(self, c, ArkFixture.Kind.DOCK)
		dock.used.connect(_on_fixture_used)
		world.add_child(dock)


func _add_steward_path() -> void:
	pass


## The Ark needs somewhere for Noor, Teo and the survivors to stand and a dock to leave from.
func _map_problems() -> PackedStringArray:
	var problems := super()
	for marker: String in [SURVIVOR_SPOTS, "N", "Y", "D"]:
		if grid.cells_with(marker).is_empty():
			problems.append("the Ark needs at least one '%s'" % marker)
	if not grid.is_walkable(ARRIVAL_WAYPOINT):
		problems.append("Noor and Teo come up off the dock through %s, which isn't walkable" % ARRIVAL_WAYPOINT)
	return problems


func _building_standing(ch: String) -> bool:
	return not PLOTS.has(ch) or GameState.run.buildings_restored.has(PLOTS[ch])


## Where `count` survivors stand: the marked spots by the Commons plot first, then the nearest free
## concrete around them, so everyone you bring home is there to talk to. Returns fewer cells than asked
## only when the Ark is full.
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
	# Home, with the Clinic standing: it stocks you up for the next district.
	GameState.restock_dressings()
	if arriving:
		_companions_arrive()
	else:
		_arrive_line()


## Noor and Teo come up off the dock, say who they are, and the Steward says what it thinks of them.
func _companions_arrive() -> void:
	GameState.meet_companions()
	var steps := 0
	for f: ArkFigure in [noor, teo]:
		if f != null:
			# Up past the landing (round the Operator, who comes off the same skiff) and across the disc.
			var points: Array[Vector2] = [Iso.cell_center(ARRIVAL_WAYPOINT), Iso.cell_center(grid.first("N" if f == noor else "Y"))]
			f.walk_along(points, 3.0, 0.6 + 1.2 * steps)
			steps += 1
	await Wait.seconds(self, 4.4)
	for line: Array in ARRIVAL:
		var who := str(line[0])
		if who == "steward":
			Narrator.say_fixed(str(line[1]))
		else:
			var f: ArkFigure = noor if who == "noor" else teo
			if f == null:
				continue
			f.say(str(line[1]), ARRIVAL_LINE_SECONDS)
		await Wait.seconds(self, ARRIVAL_LINE_SECONDS)
	arriving = false
	SaveFlow.checkpoint(get_tree())


func _arrive_line() -> void:
	await Wait.seconds(self, 1.2)
	Narrator.notify(&"ark_arrive")


func _figure(cell: Vector2i, who: ArkFigure.Who, id: String, present: bool) -> ArkFigure:
	if not present:
		return null
	var f := ArkFigure.new()
	f.setup(self, cell, who, id)
	world.add_child(f)
	return f


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
	match kind:
		ArkFixture.Kind.ARCHIVE_DOOR:
			open_archive()
		ArkFixture.Kind.SIGNAL_DOOR:
			open_overrides()
		ArkFixture.Kind.WORKSHOP_DOOR:
			open_workshop()
		ArkFixture.Kind.CLINIC_DOOR:
			open_clinic()
		ArkFixture.Kind.PUMPHOUSE_DOOR:
			# Run by people again; the Steward has its say about that.
			Narrator.say_fixed("pumphouse_note")
		_:
			open_city_map()


## The Archive and the end panel pause the Ark through Modals (they own the pause while open).
func open_archive() -> ArchiveScreen:
	if archive_screen != null:
		return archive_screen
	archive_screen = ArchiveScreen.new()
	archive_screen.closed.connect(func() -> void: archive_screen = null)
	add_child(archive_screen)
	return archive_screen


## The Workshop: weapon upgrades for scrap.
func open_workshop() -> WorkshopScreen:
	if workshop_screen != null:
		return workshop_screen
	workshop_screen = WorkshopScreen.new()
	workshop_screen.closed.connect(func() -> void: workshop_screen = null)
	add_child(workshop_screen)
	return workshop_screen


## The Clinic: field dressings, and the triage records.
func open_clinic() -> ClinicScreen:
	if clinic_screen != null:
		return clinic_screen
	clinic_screen = ClinicScreen.new()
	clinic_screen.closed.connect(func() -> void: clinic_screen = null)
	add_child(clinic_screen)
	return clinic_screen


## The Signal Room: the standing orders.
func open_overrides() -> OverridesScreen:
	if overrides_screen != null:
		return overrides_screen
	overrides_screen = OverridesScreen.new()
	overrides_screen.closed.connect(func() -> void: overrides_screen = null)
	add_child(overrides_screen)
	return overrides_screen


## The dock: the skiff and the Loop map.
func open_city_map() -> CityMap:
	if city_map != null:
		return city_map
	city_map = CityMap.new()
	city_map.closed.connect(func() -> void: city_map = null)
	add_child(city_map)
	return city_map
