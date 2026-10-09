extends Node
## The player's settings: volumes, display, subtitle size and rebound controls. Kept in
## user://settings.cfg (separate from the run's save, so a new game keeps them) and applied at start.

signal changed

const DEFAULT_PATH := "user://settings.cfg"
const VOLUME_DEFAULTS: Dictionary[StringName, float] = {
	&"Master": 1.0, &"Music": 0.8, &"Ambience": 0.8, &"SFX": 0.9, &"Steward": 1.0, &"UI": 0.7,
}
const DISPLAY_MODES: Array[String] = ["windowed", "fullscreen"]
const SUBTITLE_SIZES: Dictionary[String, float] = {"small": 0.85, "medium": 1.0, "large": 1.25}

var path: String = DEFAULT_PATH
var volumes: Dictionary[StringName, float] = VOLUME_DEFAULTS.duplicate()
var display_mode: String = "windowed"
var vsync: bool = true
var subtitle_size: String = "medium"


func _ready() -> void:
	load_settings()
	apply(true)


## Tests point the settings at a scratch file.
func use_path(file_path: String) -> void:
	path = file_path
	reset_all()


func reset_all() -> void:
	volumes = VOLUME_DEFAULTS.duplicate()
	display_mode = "windowed"
	vsync = true
	subtitle_size = "medium"
	Controls.reset_bindings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for bus: StringName in VOLUME_DEFAULTS:
		volumes[bus] = clampf(float(cfg.get_value("audio", String(bus), VOLUME_DEFAULTS[bus])), 0.0, 1.0)
	var mode := str(cfg.get_value("display", "mode", "windowed"))
	display_mode = mode if DISPLAY_MODES.has(mode) else "windowed"
	vsync = bool(cfg.get_value("display", "vsync", true))
	var size := str(cfg.get_value("subtitles", "size", "medium"))
	subtitle_size = size if SUBTITLE_SIZES.has(size) else "medium"
	var bindings: Variant = cfg.get_value("controls", "bindings", {})
	Controls.set_overrides(bindings if bindings is Dictionary else {})


func save_settings() -> Error:
	var cfg := ConfigFile.new()
	for bus: StringName in volumes:
		cfg.set_value("audio", String(bus), volumes[bus])
	cfg.set_value("display", "mode", display_mode)
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("subtitles", "size", subtitle_size)
	cfg.set_value("controls", "bindings", Controls.overrides())
	return cfg.save(path)


## Puts every setting into effect. Display settings only apply to a real window: never in headless runs,
## under the autopilot or in a recording (their window is part of what they check). At start, vsync is
## only touched if the player turned it off, so a launch flag like --disable-vsync still wins.
func apply(at_start: bool = false) -> void:
	for bus: StringName in volumes:
		Sound.set_volume(bus, volumes[bus])
	var automated := OS.get_cmdline_user_args().has("--autopilot") or Engine.get_write_movie_path() != ""
	if DisplayServer.get_name() != "headless" and not automated:
		var window_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if display_mode == "fullscreen" else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != window_mode:
			DisplayServer.window_set_mode(window_mode)
		if not (at_start and vsync):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	changed.emit()


func set_volume(bus: StringName, linear: float) -> void:
	volumes[bus] = clampf(linear, 0.0, 1.0)
	Sound.set_volume(bus, volumes[bus])
	changed.emit()


func subtitle_scale() -> float:
	return SUBTITLE_SIZES.get(subtitle_size, 1.0)
