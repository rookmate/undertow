class_name SkyBackdrop
extends Control
## Continuous atmosphere below the street's painted foundations. Camera movement samples world
## coordinates at two depths; it never reaches the edge of a stretched panorama.

var follow: Level
var look: DistrictLook = DistrictLook.new()

var _atmosphere: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_atmosphere = ShaderMaterial.new()
	_atmosphere.shader = preload("res://game/level/shaders/depth_atmosphere.gdshader")
	_atmosphere.set_shader_parameter("deep_color", look.sky_top.darkened(0.48))
	_atmosphere.set_shader_parameter("mist_color", look.sky_bottom.darkened(0.22))
	material = _atmosphere
	resized.connect(queue_redraw)


func _process(_delta: float) -> void:
	if is_instance_valid(follow):
		_atmosphere.set_shader_parameter("camera_world", follow.view_center())
	_atmosphere.set_shader_parameter("viewport_size", size)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
