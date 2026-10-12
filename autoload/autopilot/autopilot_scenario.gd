class_name AutopilotScenario
extends RefCounted
## One thing the autopilot can do from launch: the checks it must pass (registered up front, so a run
## that stops early can't pass) and what it does in each scene. How a district is played belongs to its
## route (AutopilotRoute); a scenario only decides which districts, in what order, from what run.
## Scenarios are made by Autopilot.make_scenario(); a name it doesn't know is refused before the run.

## Every scenario starts on the title with its save folder isolated.
const TITLE_CHECKS: Array[String] = ["save_isolated", "title_shown", "title_ring_present"]

## Runs of Autopilot.LONG_RUN_SECONDS or more play their districts through.
var long_run: bool = false


func expected() -> Array[String]:
	return TITLE_CHECKS.duplicate()


## Why this scenario can't run ("" if it can): a district with no route, or a route that doesn't load.
## The autopilot refuses the run rather than pass with only the title checked.
func problem() -> String:
	return ""


## The title is up (its own checks already made and photographed).
func on_title(_title: Node, _gen: int) -> void:
	pass


func on_ring_gallery(_gen: int) -> void:
	pass


func on_loadout(_screen: Node, _gen: int) -> void:
	pass


func on_level(_level: Level, _gen: int) -> void:
	pass


func on_core_choice(_screen: Node, _gen: int) -> void:
	pass


func on_ark(_ark: ArkLevel, _gen: int) -> void:
	pass


func on_epilogue(_screen: Epilogue, _gen: int) -> void:
	pass
