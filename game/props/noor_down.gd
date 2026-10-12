class_name NoorDown
extends Interactable
## Noor at the border (her turn, design/act-3.md): she came to cut the Steward's relay, and the
## Warden-Prime got there first. Down by the fence, her lantern beside her. Once it's fallen, you decide:
## carry her to the Wardfolk's boat, or leave her. With her trust in you fallen to the bottom, she won't
## take your hand.

## Her trust in you at or below this, and she won't let you carry her.
const REFUSES_AT := -3

var cell: Vector2i
## She's been picked up (and is on your shoulder), or stays (sitting up, staying).
var carried: bool = false
var staying: bool = false
var _t: float = 0.0


func setup(owner_level: Level, at: Vector2i) -> void:
	level = owner_level
	cell = at
	position = Iso.cell_center(at)


static func refuses() -> bool:
	return GameState.run.noor_trust <= REFUSES_AT


func is_present() -> bool:
	return not carried and GameState.run.noor_present


func can_interact() -> bool:
	return is_present() and not staying and GameState.run.noor_away and _boss_down()


func blocked_reason() -> String:
	if staying:
		return "She's staying."
	if not _boss_down():
		return "She's down. Not while that thing's on its feet."
	return ""


func prompt_verb() -> String:
	return "GO TO NOOR"


func interact(_player: Operator) -> void:
	if can_interact() and level != null:
		level.open_noor_choice(self)


func _boss_down() -> bool:
	return level == null or level.boss == null or not is_instance_valid(level.boss) or not level.boss.is_alive()


func _process(delta: float) -> void:
	_t += delta
	visible = is_present()
	queue_redraw()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(0, 14), Vector2(34, 0), Vector2(0, -14)]), Color(Palette.NEAR_BLACK, 0.45))
	if staying:
		# Sitting up against the fence, her lantern lit: staying.
		draw_colored_polygon(PackedVector2Array([Vector2(-20, -2), Vector2(20, -2), Vector2(8, -90), Vector2(-8, -90)]), Palette.COVERALL)
		draw_circle(Vector2(0, -100), 12.0, Palette.SKIN_SHADOW.darkened(0.2), true, -1.0, true)
	else:
		# Down: the long coat on the ground.
		draw_colored_polygon(PackedVector2Array([Vector2(-44, -6), Vector2(30, 10), Vector2(36, -6), Vector2(-38, -20)]), Palette.COVERALL)
		draw_circle(Vector2(-48, -16), 11.0, Palette.SKIN_SHADOW.darkened(0.2), true, -1.0, true)
	var flicker := 0.85 + sin(_t * 7.0) * 0.1
	draw_rect(Rect2(34, -24, 14, 22), Palette.IRON_DARK)
	draw_rect(Rect2(36, -21, 10, 15), Color(Palette.TRUTH_CYAN_HOT, flicker))
