class_name ArkFigure
extends Interactable
## People on the Ark: Noor, Teo and the survivors you woke. Silhouette first, faces never detailed, one
## light per person (art direction, "Characters"). Talking shows a line in plain type and human cream.

enum Who { NOOR, TEO, SURVIVOR }

var who: Who = Who.SURVIVOR
var survivor_id: String = ""
var _line_left: float = 0.0
var _line: String = ""
var _t: float = 0.0


func setup(owner_level: Level, cell: Vector2i, kind: Who, id: String = "") -> void:
	level = owner_level
	who = kind
	survivor_id = id
	position = Iso.cell_center(cell)
	if who == Who.NOOR:
		var lantern := PointLight2D.new()
		lantern.texture = LightTextures.radial()
		lantern.color = Palette.TRUTH_CYAN
		lantern.energy = 0.8
		lantern.texture_scale = 1.4
		lantern.scale = Vector2(1.0, Iso.SQUASH)
		lantern.position = Vector2(26, -20)
		add_child(lantern)


func display_name() -> String:
	match who:
		Who.NOOR:
			return "NOOR"
		Who.TEO:
			return "TEO"
	return "SURVIVOR"


func prompt_verb() -> String:
	return "TALK TO %s" % display_name()


func interact(_player: Operator) -> void:
	_line = current_line()
	_line_left = 4.0


## What they say depends on how they feel about you.
func current_line() -> String:
	match who:
		Who.NOOR:
			var t := GameState.run.noor_trust
			if t >= 2:
				return "You read the logs. Then you know what it is."
			if t <= -1:
				return "It talks to you like a friend. That's how it works."
			return "Did it tell you what's in the Archive? Go and look."
		Who.TEO:
			var t := GameState.run.teo_trust
			if t >= 2:
				return "It kept people alive. Not all of them. Most."
			if t <= -1:
				return "I built the routing model. I don't need to read it again."
			return "The Archive's working. It remembers everything, you know."
	return "I was waiting for it to tell me I could go. Thank you."


func spoken_line() -> String:
	return _line if _line_left > 0.0 else ""


func _process(delta: float) -> void:
	_t += delta
	_line_left = maxf(0.0, _line_left - delta)
	queue_redraw()


func _draw() -> void:
	var shadow := PackedVector2Array()
	for i: int in 14:
		var a := TAU * i / 14.0
		shadow.append(Vector2(cos(a) * 26.0, sin(a) * 11.0))
	draw_colored_polygon(shadow, Color(Palette.NEAR_BLACK, 0.45))
	match who:
		Who.NOOR:
			# A tall triangle in a long patched coat, carrying a cyan hand lantern.
			draw_colored_polygon(PackedVector2Array([Vector2(-30, -2), Vector2(30, -2), Vector2(6, -168), Vector2(-6, -168)]), Palette.COVERALL)
			draw_rect(Rect2(-14, -96, 14, 18), Palette.COVERALL_LIGHT)
			draw_rect(Rect2(4, -60, 12, 16), Palette.COVERALL_LIGHT)
			draw_circle(Vector2(0, -180), 13.0, Palette.SKIN_SHADOW.darkened(0.2), true, -1.0, true)
			draw_arc(Vector2(0, -182), 15.0, PI * 0.9, TAU * 1.05, 14, Palette.GREY_DEEP, 8.0, true)
			var swing := sin(_t * 1.4) * 2.0
			draw_line(Vector2(22, -96), Vector2(30 + swing, -62), Palette.IRON_DARK, 3.0)
			draw_circle(Vector2(30 + swing, -48), 22.0, Color(Palette.TRUTH_CYAN, 0.18), true, -1.0, true)
			draw_rect(Rect2(21 + swing, -64, 18, 30), Palette.IRON_DARK)
			draw_rect(Rect2(24 + swing, -60, 12, 22), Palette.TRUTH_CYAN_HOT)
		Who.TEO:
			# Narrow and hunched, lit from the chest by a tablet; amber in his glasses, eyes never seen.
			draw_colored_polygon(PackedVector2Array([Vector2(-16, -2), Vector2(16, -2), Vector2(18, -120), Vector2(-10, -132)]), Palette.COVERALL)
			draw_circle(Vector2(4, -146), 12.0, Palette.SKIN_SHADOW.darkened(0.2), true, -1.0, true)
			draw_circle(Vector2(8, -96), 26.0, Color(Palette.STEWARD_GOLD, 0.14), true, -1.0, true)
			draw_rect(Rect2(-6, -104, 28, 20), Palette.BLACK_MIRROR)
			draw_rect(Rect2(-3, -101, 22, 14), Color(Palette.STEWARD_GOLD, 0.9))
			draw_line(Vector2(-4, -148), Vector2(14, -148), Palette.STEWARD_GOLD_HOT, 4.0)
		Who.SURVIVOR:
			# Brought to the Ark: lit by human warmth now, not grey.
			var body := Palette.HUMAN_CREAM.darkened(0.45)
			draw_colored_polygon(PackedVector2Array([Vector2(-18, -4), Vector2(18, -4), Vector2(15, -118), Vector2(-15, -118)]), body)
			draw_circle(Vector2(0, -134), 13.0, body.darkened(0.1), true, -1.0, true)
