class_name TruthCache
extends Interactable
## An unindexed cache with a truth core in it: a dull cracked sphere with a faint blink inside. It looks
## broken, and the Steward says it is. Found alone, so it glows truth cyan through the fog.

var core_id: String = ""
var taken: bool = false
var cell: Vector2i
var _blink: float = 0.0
var _glow: PointLight2D


func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	core_id = id
	off_path = true
	cell = at
	position = Iso.cell_center(at)
	taken = GameState.run.found_core_ids.has(id) or GameState.run.truth_core_ids.has(id)
	_glow = PointLight2D.new()
	_glow.texture = LightTextures.radial()
	_glow.color = Palette.TRUTH_CYAN
	_glow.energy = 0.9
	_glow.texture_scale = 1.4
	_glow.scale = Vector2(1.0, Iso.SQUASH)
	_glow.position = Vector2(0, -30)
	add_child(_glow)


func can_interact() -> bool:
	return is_present() and not taken


func prompt_verb() -> String:
	return "TAKE THE CORE"


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	taken = true
	Sound.play(&"truth_find", global_position)
	GameState.find_core(core_id)


func _process(delta: float) -> void:
	_blink += delta
	visible = is_present()
	_glow.enabled = is_present() and not taken
	queue_redraw()


func _draw() -> void:
	# A crate the cache sits on.
	draw_colored_polygon(PackedVector2Array([Vector2(-34, -2), Vector2(0, 18), Vector2(34, -2), Vector2(34, -40), Vector2(0, -20), Vector2(-34, -40)]), Palette.STONE_OLD.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-34, -40), Vector2(0, -60), Vector2(34, -40), Vector2(0, -20)]), Palette.STONE_OLD)
	if taken:
		return
	var c := Vector2(0, -72)
	draw_circle(c, 22.0, Palette.GREY_DEEP, true, -1.0, true)
	draw_arc(c, 22.0, 0.0, TAU, 28, Palette.GREY_COLD.darkened(0.3), 2.0, true)
	for crack: PackedVector2Array in [
		PackedVector2Array([c + Vector2(-14, -12), c + Vector2(-4, -2), c + Vector2(-10, 10)]),
		PackedVector2Array([c + Vector2(8, -18), c + Vector2(4, -6), c + Vector2(15, 4)]),
	]:
		draw_polyline(crack, Palette.NEAR_BLACK, 2.0, true)
	var blink := 0.35 + 0.65 * maxf(0.0, sin(_blink * 2.4))
	draw_circle(c + Vector2(2, 2), 5.0, Color(Palette.TRUTH_CYAN_HOT, blink), true, -1.0, true)
