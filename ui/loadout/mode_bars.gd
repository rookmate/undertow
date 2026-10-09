class_name ModeBars
extends Control
## Ease vs skill-ceiling bars for a weapon mode (loadout mockup).

var ease_rating: float = 0.0
var ceiling_rating: float = 0.0
var tuned: bool = true


func set_values(ease_value: float, ceiling_value: float, is_tuned: bool) -> void:
	ease_rating = ease_value
	ceiling_rating = ceiling_value
	tuned = is_tuned
	queue_redraw()


func _draw() -> void:
	var w := size.x - 200.0
	var font := UiFonts.mono()
	for i: int in 2:
		var y := 8.0 + i * 30.0
		var label := "EASE" if i == 0 else "SKILL CEILING"
		var value := ease_rating if i == 0 else ceiling_rating
		draw_string(font, Vector2(0, y + 14.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.IVORY_DIM)
		draw_rect(Rect2(180, y, w, 14), Palette.GREY_DEEP)
		draw_rect(Rect2(180, y, w * value, 14), WeaponGlow.color(tuned) if i == 0 else Palette.IVORY)
