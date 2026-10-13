extends "res://autoload/autopilot/scenarios/district_run.gd"
## Back to Kestrel Heights with the Signal Jammer, for what its gatehouse keeps
## (autoload/autopilot/routes/tool_door_route.gd).


func _init() -> void:
	super("kestrel", false)
	route = (load("res://autoload/autopilot/routes/tool_door_route.gd") as GDScript).new() as AutopilotRoute
	route.id = "kestrel"
