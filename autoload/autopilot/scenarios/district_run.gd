extends AutopilotScenario
## One district from its loadout to the Ark after it. "slice" starts it from New Game (Kestrel Heights,
## the 30-second run from the main scene); "loop", "tideworks" and "vellum" from a prepared run, the
## run as it would arrive there (AutopilotRoute.prepare()).

var route: AutopilotRoute
var from_new_game: bool = false


func _init(district: String, new_game: bool) -> void:
	route = AutopilotRoute.for_district(district)
	from_new_game = new_game


func problem() -> String:
	return "" if route != null else "no autopilot route loads for this district"


func expected() -> Array[String]:
	route.long_run = long_run
	var out := super()
	out.append_array(route.tagged_checks())
	return out


func on_title(_title: Node, _gen: int) -> void:
	if from_new_game:
		# New Game has focus; accept it the way a controller or keyboard would.
		Autopilot.tap(&"ui_accept")
	else:
		SceneRouter.goto(&"loadout", route.prepare)


func on_loadout(screen: Node, gen: int) -> void:
	route.loadout(screen, gen)


func on_level(level: Level, gen: int) -> void:
	if level.level_id == route.id:
		route.drive(level, gen)


func on_core_choice(screen: Node, gen: int) -> void:
	route.choose(screen, gen)


func on_ark(ark: ArkLevel, gen: int) -> void:
	route.at_ark(ark, gen)
