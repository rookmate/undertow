class_name Reliquary
extends Interactable
## A district memory bunker. Power cores live here, on the path, and the Steward will walk you right to
## it. A concrete hatch with the Steward's ring inlaid in the lid, lit while it listens.

var level_id: String = ""
var opened: bool = false
var _leaving: bool = false


func setup(owner_level: Level, cell: Vector2i, id: String) -> void:
	level = owner_level
	level_id = id
	position = Iso.cell_center(cell)


func prompt_verb() -> String:
	return "BACK TO THE ARK" if _revisit() else "OPEN THE RELIQUARY"


func can_interact() -> bool:
	return not opened and not _leaving and not _carrying()


## A district you've done: it opened once (DECISIONS 176); now it's the way home.
func _revisit() -> bool:
	return level != null and level.revisit


## Carrying Noor, set her down first: opening it ends the district, and leaving without her is leaving her.
func blocked_reason() -> String:
	return "Set her down in the boat first." if _carrying() and not opened else ""


func _carrying() -> bool:
	return level != null and level.player != null and level.player.carrying


func interact(_player: Operator) -> void:
	if opened or _leaving:
		return
	if _revisit():
		# What you found here is in the Archive already: no choice to make, straight home.
		_leaving = true
		GameState.set_location("ark")
		SaveFlow.checkpoint(get_tree())
		if not SceneRouter.resume(GameState.run.location):
			SceneRouter.goto(&"title")
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
	if opened or _revisit():
		draw_colored_polygon(PackedVector2Array([c + Vector2(-hw * 0.3, 0), c + Vector2(0, -hh * 0.3), c + Vector2(hw * 0.3, 0), c + Vector2(0, hh * 0.3)]), Palette.NEAR_BLACK)
