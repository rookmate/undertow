class_name WeaponIcon
extends Control
## Placeholder icons for the reclaimed city tools: chipped municipal paint, a half-peeled asset tag.

var weapon_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size * 0.5
	var paint := Palette.IRON_VERDIGRIS
	match weapon_id:
		WeaponDefs.BATON:
			draw_line(c + Vector2(-50, 50), c + Vector2(40, -40), Palette.IRON_DARK, 16.0, true)
			draw_line(c + Vector2(0, 0), c + Vector2(40, -40), Palette.IVORY, 10.0, true)
			draw_rect(Rect2(c + Vector2(-56, 30), Vector2(26, 14)), paint)
		WeaponDefs.RIOT_DRONE:
			draw_circle(c, 46.0, Palette.IRON_DARK, true, -1.0, true)
			draw_circle(c, 30.0, paint, true, -1.0, true)
			for k: int in 4:
				var a := TAU * k / 4.0 + PI * 0.25
				draw_line(c + Vector2.from_angle(a) * 46.0, c + Vector2.from_angle(a) * 66.0, Palette.GREY_COLD, 4.0, true)
			draw_circle(c, 7.0, Palette.IVORY, true, -1.0, true)
		WeaponDefs.DEFIB:
			draw_rect(Rect2(c + Vector2(-40, -30), Vector2(80, 70)), Palette.IRON_DARK)
			draw_rect(Rect2(c + Vector2(-34, -24), Vector2(68, 22)), paint)
			draw_line(c + Vector2(-10, 10), c + Vector2(4, 22), Palette.IVORY, 4.0, true)
			draw_line(c + Vector2(4, 22), c + Vector2(-4, 30), Palette.IVORY, 4.0, true)
		_:
			draw_arc(c, 46.0, 0.0, TAU, 32, Palette.GREY_DEEP, 3.0, true)
			draw_string(UiFonts.heading(), c + Vector2(-10, 16), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Palette.GREY_DEEP)
	# Half-peeled asset tag.
	if weapon_id in WeaponDefs.SLICE_WEAPONS:
		draw_rect(Rect2(c + Vector2(20, 40), Vector2(44, 18)), Palette.PAPER)
		draw_line(c + Vector2(24, 46), c + Vector2(58, 46), Palette.GREY_DEEP, 2.0)
