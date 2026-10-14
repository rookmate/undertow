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
	draw_colored_polygon(Fx.ground_ellipse(0.5, 18, false), Color(Palette.NEAR_BLACK, 0.4))
	var key := "noor_seated" if staying else "noor_downed"
	var h := 112.0 if staying else 48.0
	ArtCatalog.actor(self, key, h, Vector2(0, 8))
	var lantern := ArtCatalog.actor_anchor(key, "lantern", h, Vector2(0, 8))
	draw_circle(lantern, 3.0, Color(Palette.TRUTH_CYAN_HOT, 0.85 + sin(_t * 7.0) * 0.1), true, -1.0, true)
