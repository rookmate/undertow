class_name DescentDark
extends CanvasLayer
## Down in a descent (design/deeper-districts.md): below the street and off the Lattice, nothing's lit but
## what you carry. The dark closes in round your hand lamp as you go down, and lifts as you climb out;
## your lamp is on down there, voice on or off.

const FADE_SECONDS := 0.6

var level: Level
## 0 up on the street .. 1 down in it.
var amount: float = 0.0
var _rect: ColorRect
var _mat: ShaderMaterial
var _was_down: bool = false


func _ready() -> void:
	# Over the rain (2), under the Feed's white-out and the HUD.
	layer = 3
	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://game/level/shaders/descent_dark.gdshader")
	_rect.material = _mat
	add_child(_rect)
	_apply()


func _process(delta: float) -> void:
	if level == null or level.player == null:
		return
	var down := level.in_descent()
	amount = move_toward(amount, 1.0 if down else 0.0, delta / FADE_SECONDS)
	if down != _was_down:
		_was_down = down
		# Your own lamp down there, whatever the Steward's doing; back up, its light is its business again.
		level.player.set_carried_light(down or not level.lighting.steward_lit())
		level.show_the_street(not down)
	_apply()


func _apply() -> void:
	_rect.visible = amount > 0.001
	if level == null or level.player == null:
		return
	var size := level.get_viewport().get_visible_rect().size
	var at := level.player.get_global_transform_with_canvas().origin + Vector2(0, -40)
	_mat.set_shader_parameter(&"amount", amount)
	_mat.set_shader_parameter(&"res", size)
	_mat.set_shader_parameter(&"center_uv", at / size)
