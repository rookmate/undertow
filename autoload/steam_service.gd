extends Node
## The only place Undertow talks to Steam. When the GodotSteam extension isn't loaded, or Steam isn't
## running, every call here quietly does nothing, so the game runs the same without Steam.
## GodotSteam is not vendored yet (DECISIONS.md #12); calls go through `call()` so this file compiles
## with or without it.

signal overlay_toggled(active: bool)

var available: bool = false
var _steam: Object = null


func _ready() -> void:
	if not Engine.has_singleton("Steam"):
		print("[steam] GodotSteam not present; running without Steam.")
		set_process(false)
		return
	_steam = Engine.get_singleton("Steam")
	if _steam.has_method("steamInitEx"):
		var result: Variant = _steam.call("steamInitEx")
		available = result is Dictionary and int((result as Dictionary).get("status", 1)) == 0
	if not available:
		print("[steam] Steam not running or init failed; running without Steam.")
		set_process(false)
		return
	if _steam.has_signal("overlay_toggled"):
		_steam.connect("overlay_toggled", _on_overlay_toggled)


func _process(_delta: float) -> void:
	_steam.call("run_callbacks")


func unlock_achievement(achievement_id: String) -> void:
	if not available:
		return
	_steam.call("setAchievement", achievement_id)
	_steam.call("storeStats")


func set_rich_presence(key: String, value: String) -> void:
	if not available:
		return
	_steam.call("setRichPresence", key, value)


func _on_overlay_toggled(active: bool, _user_initiated: bool = false, _app_id: int = 0) -> void:
	overlay_toggled.emit(active)
