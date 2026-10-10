class_name BaleStack
extends WeakPoint
## The pulper by the press, and a stack of paper bales on its ledge where the hall's crew left them (the
## Vellum). Knock the stack in while the Editor is pulping the page and the pulper jams.


func _draw() -> void:
	draw_shadow(26.0, 12.0)
	var flash := hit_flash()
	# The pulper: an iron vat of grey slurry (its base, its side, its rim).
	var iron := Palette.IRON_DARK.lerp(Palette.IVORY, flash)
	var rim := PackedVector2Array()
	var base := PackedVector2Array()
	for i: int in 16:
		var p := Iso.grid_to_world(Vector2.from_angle(TAU * i / 16.0) * 0.36)
		base.append(p)
		rim.append(p + Vector2(0, -26))
	var half_w := Iso.grid_to_world(Vector2.from_angle(-PI * 0.25) * 0.36).x
	draw_colored_polygon(base, iron)
	draw_rect(Rect2(-half_w, -26, half_w * 2.0, 26), iron)
	draw_colored_polygon(rim, Palette.PAPER.darkened(0.45))
	var jammed := boss is Editor and (boss as Editor).phase == Editor.Phase.JAMMED
	if jammed:
		# The bales gone in, jammed in the mouth.
		for k: int in 3:
			draw_rect(Rect2(-18 + k * 10, -34 - k * 3, 16, 10), Palette.PAPER)
	else:
		# On the ledge above it: three bales, strapped.
		draw_line(Vector2(-22, -54), Vector2(22, -54), Palette.IRON_DARK, 4.0)
		for k: int in 3:
			var at := Vector2(-16 + (k % 2) * 8, -70 - k * 12)
			draw_rect(Rect2(at, Vector2(26, 13)), Palette.PAPER.lerp(Palette.IVORY, flash))
			draw_line(at + Vector2(8, 0), at + Vector2(8, 13), Palette.IRON_DARK, 2.0)
	draw_circle(Vector2(26, -60), 3.5, Palette.HUMAN_CREAM if tell_on() else Palette.GREY_DEEP, true, -1.0, true)
