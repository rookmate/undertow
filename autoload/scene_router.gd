extends CanvasLayer
## Screen changes with a short fade. Scenes are referred to by key so callers never hard-code paths.

signal scene_changed(key: StringName)

const FADE_SECONDS := 0.25

const SCENES: Dictionary[StringName, String] = {
	&"title": "res://ui/title/title.tscn",
	&"ring_gallery": "res://ui/common/ring_gallery.tscn",
	&"loadout": "res://ui/loadout/loadout.tscn",
	&"level_vellum": "res://game/level/vellum_street.tscn",
}

## Where a saved RunState.location resumes.
const LOCATIONS: Dictionary[String, StringName] = {
	# Weapons are picked before each level, so a run saved in the level resumes at the loadout.
	"level:vellum": &"loadout",
}

var current_key: StringName = &""
var _fade: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.theme = UiTheme.build()
	_fade = ColorRect.new()
	_fade.color = Palette.NEAR_BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	var scene := get_tree().current_scene
	if scene != null:
		current_key = key_for_path(scene.scene_file_path)


func key_for_path(scene_path: String) -> StringName:
	for key: StringName in SCENES:
		if SCENES[key] == scene_path:
			return key
	return &""


func key_for_location(location: String) -> StringName:
	return LOCATIONS.get(location, &"")


func goto(key: StringName) -> void:
	if not SCENES.has(key):
		push_error("SceneRouter: unknown scene key %s" % key)
		return
	if _busy:
		return
	_busy = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, FADE_SECONDS)
	await tween.finished
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(SCENES[key])
	if err != OK:
		push_error("SceneRouter: could not load %s (%s)" % [SCENES[key], error_string(err)])
		_busy = false
		return
	await get_tree().scene_changed
	current_key = key
	scene_changed.emit(key)
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS)
	await back.finished
	_busy = false
