class_name BaleStack
extends WeakPoint
## The pulper by the press, and a stack of paper bales on its ledge where the hall's crew left them (the
## Vellum). Knock the stack in while the Editor is pulping the page and the pulper jams.


func _draw() -> void:
	draw_shadow(26.0, 12.0)
	var jammed := boss is Editor and (boss as Editor).phase == Editor.Phase.JAMMED
	ArtCatalog.paint(self, "bale_stack", Rect2(-28, -44 if jammed else -94, 56, 44 if jammed else 94), Color.WHITE * (1.0 + hit_flash()))
	draw_circle(Vector2(26, -60), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
