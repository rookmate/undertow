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
	GameState.save()
	SceneRouter.goto(&"core_choice")


func _process(_delta: float) -> void:
	queue_redraw()


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
	# The ring inlaid in the lid, flattened onto it.
	var c := up
	var col := Palette.STEWARD_GOLD_HOT if Steward.voice_on else Palette.GREY_DEEP
	var pts := PackedVector2Array()
	for i: int in 33:
		var a := RingPainter.clock_to_rad(lerpf(RingPainter.band_start_deg(), RingPainter.band_end_deg(), i / 32.0))
		pts.append(c + Vector2(cos(a) * hw * 0.55, sin(a) * hh * 0.55))
	draw_polyline(pts, col, 3.0, true)
	draw_circle(c, 4.0, col, true, -1.0, true)
	if opened:
		draw_colored_polygon(PackedVector2Array([c + Vector2(-hw * 0.3, 0), c + Vector2(0, -hh * 0.3), c + Vector2(hw * 0.3, 0), c + Vector2(0, hh * 0.3)]), Palette.NEAR_BLACK)
