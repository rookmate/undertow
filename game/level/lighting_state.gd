class_name LightingState
extends Node
## The two lighting states (art direction): with the voice on, gold lamps light the path and shadows go
## soft; muted, the gilt dies and only what you carry (and the old neon) is lit. Lattice lamps go dark
## one by one outward from the Operator, and come back the same way.

const STAGGER_SECONDS := 0.045
const FADE_SECONDS := 0.8

var level: Level
var ambient: CanvasModulate
var grade: ShaderMaterial

var _grade_amount: float = 0.0
var _sequence: int = 0


func setup(owner_level: Level, canvas_modulate: CanvasModulate) -> void:
	level = owner_level
	ambient = canvas_modulate
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.name = "MuteGrade"
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade = ShaderMaterial.new()
	grade.shader = preload("res://game/level/shaders/mute_grade.gdshader")
	rect.material = grade
	layer.add_child(rect)
	level.add_child(layer)
	Steward.voice_changed.connect(_on_voice_changed)
	Steward.coverage_changed.connect(_on_coverage_changed)
	_apply_instantly(steward_lit())


func _exit_tree() -> void:
	if Steward.voice_changed.is_connected(_on_voice_changed):
		Steward.voice_changed.disconnect(_on_voice_changed)
	if Steward.coverage_changed.is_connected(_on_coverage_changed):
		Steward.coverage_changed.disconnect(_on_coverage_changed)


## The Steward's light is on: its voice is, and (where the Lattice doesn't reach into the district at all)
## it's on its own hardware. In Harbor Ward the light is yours until the border, voice on or off.
func steward_lit() -> bool:
	return Steward.voice_on and (level.has_lattice() or Steward.covered)


func _on_coverage_changed(_covered: bool) -> void:
	if not level.has_lattice():
		_on_voice_changed(Steward.voice_on)


## The cold grade marks the Steward's absence from its own city. Where the Lattice never reached
## (Harbor Ward) there's nothing missing: the light is the Wardfolk's, and it's never graded.
func _grade_for(on: bool) -> float:
	return 0.0 if on or not level.has_lattice() else 1.0


func _apply_instantly(on: bool) -> void:
	ambient.color = level.look.ambient_on if on else level.look.ambient_muted
	_grade_amount = _grade_for(on)
	grade.set_shader_parameter(&"amount", _grade_amount)
	for lamp: LampPost in _lamps():
		lamp.lit = on
	for b: Node in get_tree().get_nodes_in_group(&"gilt"):
		# Anything carrying the gilt (buildings, crane legs) lights and dies with the Steward.
		if "gilt_lit" in b:
			b.set(&"gilt_lit", on)
	if level.player != null:
		level.player.set_carried_light(not on or level.in_descent())


func _on_voice_changed(_voice: bool) -> void:
	var on := steward_lit()
	_sequence += 1
	var seq := _sequence
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(ambient, "color", level.look.ambient_on if on else level.look.ambient_muted, FADE_SECONDS)
	t.tween_method(_set_grade, _grade_amount, _grade_for(on), FADE_SECONDS)
	for b: Node in get_tree().get_nodes_in_group(&"gilt"):
		# Anything carrying the gilt (buildings, crane legs) lights and dies with the Steward.
		if "gilt_lit" in b:
			b.set(&"gilt_lit", on)
	if level.player != null:
		level.player.set_carried_light(not on or level.in_descent())
	# Lamps nearest the Operator change first; the rest follow down the street.
	var lamps := _lamps()
	if level.player != null:
		var from := level.player.global_position
		lamps.sort_custom(func(a: LampPost, b: LampPost) -> bool: return a.global_position.distance_squared_to(from) < b.global_position.distance_squared_to(from))
	for i: int in lamps.size():
		var lamp := lamps[i]
		await Wait.seconds(self, STAGGER_SECONDS)
		if seq != _sequence:
			return
		if is_instance_valid(lamp):
			lamp.lit = on
			if not on:
				Sound.play(&"lamp_off", lamp.global_position)


func _set_grade(value: float) -> void:
	_grade_amount = value
	grade.set_shader_parameter(&"amount", value)


func _lamps() -> Array[LampPost]:
	var out: Array[LampPost] = []
	for n: Node in get_tree().get_nodes_in_group(&"lattice_lamps"):
		if level.is_ancestor_of(n):
			out.append(n as LampPost)
	return out


## 0 with the voice on, 1 fully muted (tests read this).
func grade_amount() -> float:
	return _grade_amount
