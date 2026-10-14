class_name CoreArt
extends Control
## Painted core art (art direction, "Objects"): power cores are faceted amber prisms lit from inside,
## cut like jewellery (the Steward's gold); truth cores are dull cracked spheres with a faint blink
## inside, which look broken (found alone: truth cyan).

var truth: bool = false
var _t: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	ArtCatalog.fit(self, "truth_core" if truth else "power_core", Rect2(c - Vector2(60, 65), Vector2(120, 130)))
	if truth:
		var blink := 0.3 + 0.7 * maxf(0.0, sin(_t * 2.2))
		draw_circle(c + Vector2(4, 6), 3.5, Color(Palette.TRUTH_CYAN_HOT, blink), true, -1.0, true)
	else:
		draw_circle(c + Vector2(0, -6), 7.0, Color(Palette.STEWARD_GOLD_HOT, 0.55 + 0.1 * sin(_t * 1.6)), true, -1.0, true)
