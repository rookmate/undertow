extends CanvasLayer
## Screen changes with a short fade. Screens are referred to by key and districts by id
## (LevelCatalog), so callers never hard-code scene paths.
##
## A navigation and the state change that goes with it are one operation: goto(key, prepare) runs
## `prepare` only if the transition is accepted. While a transition is running, further navigation is
## refused (and `prepare` is not run) and GUI input is blocked, so a second click during a fade can't
## change the run behind the first.

signal scene_changed(key: StringName)

const FADE_SECONDS := 0.25
## Key reported for any district scene (see current_level for which one).
const LEVEL_KEY := &"level"

const SCENES: Dictionary[StringName, String] = {
	&"title": "res://ui/title/title.tscn",
	&"ring_gallery": "res://ui/common/ring_gallery.tscn",
	&"loadout": "res://ui/loadout/loadout.tscn",
	&"core_choice": "res://ui/core_choice/core_choice.tscn",
	&"ark": "res://game/ark/ark.tscn",
	&"epilogue": "res://ui/epilogue/epilogue.tscn",
}

var current_key: StringName = &""
## District id while a district scene is current, "" otherwise.
var current_level: String = ""
var _fade: ColorRect
var _busy: bool = false
## Set when the scene being entered couldn't start; the transition then goes on to the title instead.
var _abandoned: bool = false


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Merge the game's theme into the engine default so every Control gets it, including ones under a
	# CanvasLayer or Node2D, where theme inheritance from the root window stops.
	UiTheme.install()
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
	for id: String in LevelCatalog.LEVELS:
		if LevelCatalog.scene_of(id) == scene_path:
			return LEVEL_KEY
	return &""


func is_busy() -> bool:
	return _busy


## Goes to a named screen. Returns false (and doesn't run `prepare`) if a transition is already running.
func goto(key: StringName, prepare: Callable = Callable()) -> bool:
	if not SCENES.has(key):
		push_error("SceneRouter: unknown scene key %s" % key)
		return false
	return _start(SCENES[key], key, "", prepare)


## Goes into a district.
func goto_level(level_id: String, prepare: Callable = Callable()) -> bool:
	if not LevelCatalog.has_level(level_id):
		push_error("SceneRouter: unknown district %s" % level_id)
		return false
	return _start(LevelCatalog.scene_of(level_id), LEVEL_KEY, level_id, prepare)


## Called by a scene that can't start (a broken map). If it arrived through a transition, the player is
## taken on to the title behind the same fade; if it is the current scene otherwise, a normal transition
## to the title starts. A scene that isn't current (a test fixture) is left as it is.
func abandon(scene: Node) -> void:
	if _busy:
		_abandoned = true
	elif scene == get_tree().current_scene:
		goto(&"title")


## Where Continue takes a saved location: a screen key, or &"" if this build has no such place.
func destination_for(location: String) -> StringName:
	if location == "ark":
		return &"ark"
	if not LevelCatalog.has_level(LevelCatalog.level_in(location)):
		return &""
	if location.begins_with("loadout:") or location.begins_with("level:"):
		return &"loadout"
	if location.begins_with("reliquary:"):
		return &"core_choice"
	return &""


## Continues from a saved location. Returns false if it can't (unknown place, or busy).
func resume(location: String, prepare: Callable = Callable()) -> bool:
	var key := destination_for(location)
	if key == &"":
		return false
	return goto(key, prepare)


func _start(path: String, key: StringName, level_id: String, prepare: Callable) -> bool:
	if _busy:
		return false
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: missing scene %s" % path)
		return false
	_busy = true
	if prepare.is_valid():
		prepare.call()
	_transition(path, key, level_id)
	return true


func _transition(path: String, key: StringName, level_id: String) -> void:
	var vp := get_viewport()
	vp.gui_disable_input = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, FADE_SECONDS)
	await tween.finished
	Modals.clear()
	get_tree().paused = false
	_abandoned = false
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("SceneRouter: could not load %s (%s)" % [path, error_string(err)])
	else:
		await get_tree().scene_changed
		if _abandoned:
			_abandoned = false
			key = &"title"
			level_id = ""
			get_tree().change_scene_to_file(SCENES[key])
			await get_tree().scene_changed
		current_key = key
		current_level = level_id
		scene_changed.emit(key)
	var back := create_tween()
	back.tween_property(_fade, "modulate:a", 0.0, FADE_SECONDS)
	await back.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp.gui_disable_input = false
	_busy = false
