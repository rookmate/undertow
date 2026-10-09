class_name Reliquary
extends Interactable
## A district memory bunker. Power cores live here, on the path, and the Steward will walk you right to
## it. A concrete hatch with the Steward's ring inlaid in the lid, lit while it listens.

var level_id: String = ""
var opened: bool = false


func setup(owner_level: Level, cell: Vector2i, id: String) -> void:
	level = owner_level
	level_id = id
	position = Iso.cell_center(cell)


func prompt_verb() -> String:
	return "OPEN THE RELIQUARY"


func can_interact() -> bool:
	return not opened


func interact(_player: Operator) -> void:
	if opened:
		return
	opened = true
	GameState.set_location("reliquary:" + level_id)
	SaveFlow.checkpoint(get_tree())
	SceneRouter.goto(&"core_choice")


func _process(_delta: float) -> void:
	queue_redraw()


func _ring_look() -> RingPainter.Look:
	var look := RingPainter.Look.new()
	look.hdr = 1.3
	look.halo = 0.0
	if not Steward.voice_on:
		look.thin = true
		look.color = Palette.GREY_COLD
		look.show_center = false
	return look


func _draw() -> void:
	var hw := Iso.HALF_W * 0.85
	var hh := Iso.HALF_H * 0.85
	var h := 58.0
	var top := Vector2(0, -hh)
	var right := Vector2(hw, 0)
	var bottom := Vector2(0, hh)
	var left := Vector2(-hw, 0)
	var up := Vector2(0, -h)
	draw_colored_polygon(PackedVector2Array([left, bottom, bottom + up, left + up]), Palette.STONE_OLD.darkened(0.2))
	draw_colored_polygon(PackedVector2Array([bottom, right, right + up, bottom + up]), Palette.STONE_OLD)
	draw_colored_polygon(PackedVector2Array([top + up, right + up, bottom + up, left + up]), Palette.STONE_OLD.lightened(0.15))
	# The canonical ring inlaid in the lid, laid flat onto it. Lit while the Steward listens; muted, the
	# thin grey ring without a centre.
	var c := up
	draw_set_transform(c, 0.0, Vector2(1.0, Iso.SQUASH))
	RingPainter.paint(self, Vector2.ZERO, hw * 0.4, _ring_look())
	draw_set_transform(Vector2.ZERO)
	if opened:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-hw * 0.3, 0), c + Vector2(0, -hh * 0.3), c + Vector2(hw * 0.3, 0), c + Vector2(0, hh * 0.3)]), Palette.NEAR_BLACK)
