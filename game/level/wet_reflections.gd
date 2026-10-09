class_name WetReflections
extends Node2D
## Everything in Meridian is wet. Light sources leave long broken streaks on the cobbles below them,
## mirrored about the ground: the Lattice's gold (only while lit) and the old city's neon. Drawn
## additively above the floor and below everything that stands on it.

class Source:
	var node: Node2D
	var offset: Vector2
	var height: float
	var color: Color
	## Returns whether the source is lit; an empty Callable means always lit.
	var is_lit: Callable

var _sources: Array[Source] = []
var _time: float = 0.0


func _ready() -> void:
	add_to_group(&"wet_reflections")
	z_index = -15
	material = Emissive.additive_material()


## Registers a light source with the level's reflection layer (if there is one).
static func add(node: Node2D, offset: Vector2, height: float, color: Color, is_lit: Callable) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var layer := tree.get_first_node_in_group(&"wet_reflections") as WetReflections
	if layer == null:
		return
	var s := Source.new()
	s.node = node
	s.offset = offset
	s.height = height
	s.color = color
	s.is_lit = is_lit
	layer._sources.append(s)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for s: Source in _sources:
		if not is_instance_valid(s.node):
			continue
		if s.is_lit.is_valid() and not s.is_lit.call():
			continue
		var base := s.node.position + s.offset
		var length := s.height * 0.95
		# A soft vertical glow mirrored below the source...
		var w0 := 9.0
		var w1 := 17.0
		var top_col := Color(s.color, 0.07)
		var end_col := Color(s.color, 0.0)
		draw_polygon(PackedVector2Array([
			Vector2(base.x - w0, base.y + 6.0), Vector2(base.x + w0, base.y + 6.0),
			Vector2(base.x + w1, base.y + 6.0 + length), Vector2(base.x - w1, base.y + 6.0 + length),
		]), PackedColorArray([top_col, top_col, end_col, end_col]))
		# ...broken by ripples in the wet stone.
		const RIPPLES := 7
		for i: int in RIPPLES:
			var t := (i + 0.5) / RIPPLES
			var y := base.y + 10.0 + t * length
			var wobble := sin(_time * 2.3 + i * 1.7 + base.x * 0.01) * 5.0
			var half := lerpf(10.0, 26.0, t) * (0.6 + 0.4 * sin(i * 2.1 + _time * 1.3))
			var alpha := 0.14 * (1.0 - t)
			draw_line(Vector2(base.x - half + wobble, y), Vector2(base.x + half + wobble, y), Color(s.color, alpha), 2.0)
