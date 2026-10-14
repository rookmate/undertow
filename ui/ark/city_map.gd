class_name CityMap
extends CanvasLayer
## The Loop map, from the Ark's dock: Meridian on its delta, the Loop's ring of route lights (the
## Steward's, so gold), every district with how far you've got with it, and the Ark in the estuary.
## Pick an open district and the skiff takes you to its loadout. The run summary (and the endings) is a
## button away.

signal closed

const MAP_RECT := Rect2(560, 150, 1240, 800)

## The district picked, waiting for "GO" ("" if none).
## Noor going ahead to the Ward, while she says so (null otherwise).
## A companion's turn at the dock before setting off (NoorDeparture, TeoTurn), while it's open.
var departure: CanvasLayer
var chosen: String = ""

var _buttons: Dictionary[String, Button] = {}
var _detail: Label
var _go: Button
var _summary_button: Button
var _back: Button


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Palette.NEAR_BLACK
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var map := _MapDrawing.new()
	map.position = MAP_RECT.position
	map.size = MAP_RECT.size
	add_child(map)
	var title := _label("MERIDIAN · THE LOOP", UiFonts.heading(), 64, Palette.IVORY)
	title.position = Vector2(100, 60)
	add_child(title)
	var sub := _label("Where the skiff can take you.", UiFonts.label(), 26, Palette.IVORY_DIM)
	sub.position = Vector2(104, 140)
	add_child(sub)
	for d: Dictionary in LevelCatalog.CITY:
		_district_button(d)
	_detail = _label("", UiFonts.label(), 26, Palette.IVORY)
	_detail.position = Vector2(104, 230)
	_detail.size = Vector2(420, 400)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_detail)
	_go = Button.new()
	_go.text = "TAKE THE SKIFF"
	_go.position = Vector2(100, 700)
	_go.custom_minimum_size = Vector2(360, 60)
	_go.pressed.connect(_go_to_chosen)
	add_child(_go)
	_summary_button = Button.new()
	_summary_button.text = "THE RUN SO FAR"
	_summary_button.position = Vector2(100, 790)
	_summary_button.custom_minimum_size = Vector2(360, 56)
	_summary_button.pressed.connect(open_summary)
	add_child(_summary_button)
	_back = Button.new()
	_back.text = "BACK"
	_back.position = Vector2(100, 870)
	_back.custom_minimum_size = Vector2(360, 56)
	_back.pressed.connect(close)
	add_child(_back)
	Modals.push(self)
	var open := LevelCatalog.open_districts(GameState.run)
	# Nothing new open: the districts you can go back to (DECISIONS 187).
	if open.is_empty():
		for d: Dictionary in LevelCatalog.CITY:
			if LevelCatalog.can_revisit(GameState.run, str(d["id"])):
				open.append(str(d["id"]))
	if open.is_empty():
		var to_come := still_to_come()
		if to_come.is_empty():
			_detail.text = "THE SKIFF ISN'T READY\n\nEvery district is behind you."
		else:
			_detail.text = "THE SKIFF ISN'T READY\n\nEvery district built so far is behind you. Still to come: %s." % ", ".join(to_come)
		_go.disabled = true
		_summary_button.grab_focus()
	else:
		choose(open[0])
		_buttons[open[0]].grab_focus()


func _label(text: String, font: Font, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font)
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", col)
	return l


## The districts of Meridian not built yet, by name (Harbor Ward and the Spire, Act 3).
static func still_to_come() -> PackedStringArray:
	var out := PackedStringArray()
	for d: Dictionary in LevelCatalog.CITY:
		if not LevelCatalog.has_level(str(d["id"])):
			out.append(str(d["name"]))
	return out


## How far the run has got with a district: "done", "open", "locked" (built, not reached yet), "unbuilt".
static func state_of(run: RunState, id: String) -> String:
	if run.levels_completed.has(id):
		return "done"
	if not LevelCatalog.has_level(id):
		return "unbuilt"
	return "open" if LevelCatalog.is_open(run, id) else "locked"


func _district_button(d: Dictionary) -> void:
	var id := str(d["id"])
	var state := state_of(GameState.run, id)
	var b := Button.new()
	b.text = str(d["name"]).to_upper()
	b.flat = state != "open"
	b.disabled = state == "unbuilt" or state == "locked"
	b.add_theme_font_size_override(&"font_size", 22)
	b.add_theme_color_override(&"font_color", Palette.IVORY if state == "open" else Palette.IVORY_DIM)
	b.add_theme_color_override(&"font_disabled_color", Color(Palette.GREY_COLD, 0.7))
	if state == "done":
		b.text += " · DONE"
	b.custom_minimum_size = Vector2(240, 44)
	var at: Vector2 = d["at"]
	b.position = MAP_RECT.position + Vector2(at.x * MAP_RECT.size.x, at.y * MAP_RECT.size.y) + Vector2(-120, 16)
	b.focus_entered.connect(func() -> void: choose(id))
	b.pressed.connect(func() -> void:
		choose(id)
		_go_to_chosen())
	add_child(b)
	_buttons[id] = b


## Shows a district's details; only an open one can be travelled to.
func choose(id: String) -> void:
	var state := state_of(GameState.run, id)
	var city: Dictionary = {}
	for d: Dictionary in LevelCatalog.CITY:
		if d["id"] == id:
			city = d
	var lines := PackedStringArray([str(city.get("name", id)).to_upper(), "ACT %d" % int(city.get("act", 0))])
	match state:
		"done":
			if LevelCatalog.can_revisit(GameState.run, id):
				lines.append("Done. The skiff can take you back.")
				lines.append(Hardening.describe(Hardening.step(GameState.run, id)))
			else:
				lines.append("Done. Its Reliquary has given up its cores.")
		"open":
			lines.append("Open. The skiff can take you.")
		"locked":
			lines.append("Not yet: the Loop doesn't reach it until more of the city is done.")
		"unbuilt":
			lines.append("Not built yet.")
	_detail.text = "\n\n".join(lines)
	chosen = id if state == "open" or (state == "done" and LevelCatalog.can_revisit(GameState.run, id)) else ""
	_go.disabled = chosen == ""


func _go_to_chosen() -> void:
	if chosen == "":
		return
	var target := chosen
	departure = turn_before(target)
	if departure != null:
		departure.closed.connect(func() -> void: _set_off(target))
		get_parent().add_child(departure)
		return
	_set_off(target)


## A companion's turn, played at the dock before setting off for `target` (design/act-3.md), or null:
## setting off for the Ward with Noor still on the Ark, she goes ahead; for the Spire with Teo on the
## Ark, he has his say, once.
func turn_before(target: String) -> CanvasLayer:
	# Going back to a district you've done is only going back.
	if GameState.run.levels_completed.has(target):
		return null
	if target == "harbor" and GameState.run.companion_here(RunState.WHO_NOOR):
		return NoorDeparture.new()
	if target == "spire" and GameState.run.companion_here(RunState.WHO_TEO) and not GameState.run.teo_turn_had:
		return TeoTurn.new()
	return null


func _set_off(target: String) -> void:
	SceneRouter.goto(&"loadout", func() -> void:
		GameState.set_location("loadout:" + target)
		SaveFlow.checkpoint(get_tree()))


func open_summary() -> RunSummary:
	var summary := RunSummary.new()
	summary.closed.connect(func() -> void:
		if is_instance_valid(_summary_button):
			_summary_button.grab_focus())
	get_parent().add_child(summary)
	return summary


func _unhandled_input(event: InputEvent) -> void:
	if Modals.is_top(self) and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	Sound.play(&"ui_back")
	Modals.pop(self)
	closed.emit()
	queue_free()


## The map itself: water, the delta's land, the Loop's ring of route lights, the Ark.
class _MapDrawing:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _at(u: float, v: float) -> Vector2:
		return Vector2(u * size.x, v * size.y)

	func _draw() -> void:
		ArtCatalog.paint(self, "city_map", Rect2(Vector2.ZERO, size))
		# The Loop: an elevated ring through every district but one, its route lights still blinking.
		var centre := _at(0.5, 0.45)
		var radii := Vector2(size.x * 0.33, size.y * 0.33)
		for i: int in 48:
			var a := TAU * i / 48.0
			var p := centre + Vector2(cos(a) * radii.x, sin(a) * radii.y)
			draw_circle(p, 3.0, Color(Palette.STEWARD_GOLD, 0.75), true, -1.0, true)
		# The Ark in the estuary.
		var ark := _at(LevelCatalog.ARK_AT.x, LevelCatalog.ARK_AT.y)
		draw_arc(ark, 16.0, 0.0, TAU, 28, Palette.IVORY, 2.0, true)
		draw_string(UiFonts.mono_medium(), ark + Vector2(24, 6), "THE ARK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.IVORY_DIM)
		for d: Dictionary in LevelCatalog.CITY:
			var at: Vector2 = d["at"]
			var state := CityMap.state_of(GameState.run, str(d["id"]))
			var col := Palette.IVORY if state == "open" else (Palette.IVORY_DIM if state == "done" else Color(Palette.GREY_COLD, 0.6))
			draw_circle(_at(at.x, at.y), 7.0, col, true, -1.0, true)
