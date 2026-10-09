class_name Emissive
extends Node2D
## Light sources: lamp lenses, lit windows, neon, the gilt, the path. Drawn unshaded, so neither the
## night's CanvasModulate nor 2D lights darken them, and their HDR colours bloom.

static var _unshaded: CanvasItemMaterial = null
static var _additive: CanvasItemMaterial = null

var layers: Array[DrawOps] = []
## Optional per-layer switches (same length as `layers`; missing entries count as on).
var enabled: Array[bool] = []


func _init(additive: bool = false) -> void:
	material = additive_material() if additive else unshaded_material()


func set_layer_enabled(index: int, on: bool) -> void:
	while enabled.size() <= index:
		enabled.append(true)
	if enabled[index] != on:
		enabled[index] = on
		queue_redraw()


func _draw() -> void:
	for i: int in layers.size():
		if i < enabled.size() and not enabled[i]:
			continue
		layers[i].paint(self)


static func unshaded_material() -> CanvasItemMaterial:
	if _unshaded == null:
		_unshaded = CanvasItemMaterial.new()
		_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _unshaded


static func additive_material() -> CanvasItemMaterial:
	if _additive == null:
		_additive = CanvasItemMaterial.new()
		_additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _additive
