extends "res://autoload/autopilot/scenarios/district_run.gd"
## Back to a district you've done (DECISIONS 187): Mercy General from a prepared run, done once without
## going down to the morgue (autoload/autopilot/routes/revisit_route.gd).


func _init() -> void:
	super("mercy", false)
	route = (load("res://autoload/autopilot/routes/revisit_route.gd") as GDScript).new() as AutopilotRoute
	route.id = "mercy"
