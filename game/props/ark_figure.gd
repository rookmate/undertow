class_name ArkFigure
extends Interactable
## People on the Ark: Noor, Teo and the survivors you woke, and with the Commons standing, the Wardfolk
## who came over. Silhouette first, faces never detailed, one light per person (art direction,
## "Characters"). Talking shows a line in plain type and human cream. Living in the Commons, the
## survivors each carry a light of their own and say something of their own (CommonsPeople).

enum Who { NOOR, TEO, SURVIVOR, WARDFOLK }

var who: Who = Who.SURVIVOR
var survivor_id: String = ""
## Which of the Wardfolk (their lines go in turn).
var wardfolk_index: int = 0
## Carrying a light of their own: the Wardfolk, and the survivors once the Commons stands.
var lit: bool = false
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
	lit = who == Who.WARDFOLK or (who == Who.SURVIVOR and GameState.run.buildings_restored.has("commons"))
	if lit:
		var lamp := PointLight2D.new()
		lamp.texture = LightTextures.radial()
		lamp.color = Palette.WARD_CYAN if who == Who.WARDFOLK else Palette.HUMAN_CREAM
		lamp.energy = 0.6
		lamp.texture_scale = 1.1
		lamp.scale = Vector2(1.0, Iso.SQUASH)
		lamp.position = Vector2(22, -24)
		add_child(lamp)


func display_name() -> String:
	match who:
		Who.NOOR:
			return "NOOR"
		Who.TEO:
			return "TEO"
		Who.WARDFOLK:
			return "WARDFOLK"
	return "SURVIVOR"


func prompt_verb() -> String:
	return "TALK TO %s" % display_name()


## Noor and Teo talk a district over with you the first time after it (ConversationScreen); otherwise
## each says a line.
func interact(_player: Operator) -> void:
	var ark := level as ArkLevel
	if (who == Who.NOOR or who == Who.TEO) and ark != null and GameState.run.pending_conversation() != "":
		ark.open_conversation(GameState.run.pending_conversation())
		return
	_line = current_line()
	_line_left = 4.0


## What they say depends on how they feel about you.
func current_line() -> String:
	match who:
		Who.NOOR:
			if GameState.run.buildings_restored.has(GameState.MAST):
				return "The Mast hears the places the Lattice never listed. They're on your map now. Every district."
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
		Who.WARDFOLK:
			return CommonsPeople.wardfolk_line(wardfolk_index, GameState.run, level != null and not level.is_hub())
	if lit:
		var own := CommonsPeople.survivor_line(survivor_id)
		if own != "":
			return own
	return "I was waiting for it to tell me I could go. Thank you."


## Says a line of their own (an arrival, a conversation) for a while.
func say(line: String, seconds: float) -> void:
	_line = line
	_line_left = seconds


## Walks through `points` on the Ark at an even pace, taking `seconds` in all, after `delay`.
func walk_along(points: Array[Vector2], seconds: float, delay: float = 0.0) -> void:
	var total := 0.0
	var from := position
	for p: Vector2 in points:
		total += Iso.ground_distance(from, p)
		from = p
	var t := create_tween()
	t.tween_interval(delay)
	from = position
	for p: Vector2 in points:
		var leg := seconds * Iso.ground_distance(from, p) / maxf(total, 0.001)
		t.tween_property(self, "position", p, leg)
		from = p


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
			if lit:
				# Living in the Commons: a light of their own, a hand lamp in human warmth.
				draw_line(Vector2(14, -70), Vector2(20, -46), Palette.IRON_DARK, 2.0)
				draw_circle(Vector2(20, -36), 16.0, Color(Palette.HUMAN_CREAM, 0.16), true, -1.0, true)
				draw_rect(Rect2(14, -46, 12, 16), Palette.IRON_DARK)
				draw_rect(Rect2(16, -44, 8, 12), Palette.HUMAN_CREAM)
		Who.WARDFOLK:
			# Over from the Ward: an oilskin hood and a long coat, never a Lanyard, a cyan lantern on a pole.
			draw_colored_polygon(PackedVector2Array([Vector2(-22, -2), Vector2(22, -2), Vector2(12, -128), Vector2(-12, -128)]), Palette.BOATHOUSE)
			draw_circle(Vector2(0, -140), 13.0, Palette.SKIN_SHADOW.darkened(0.2), true, -1.0, true)
			draw_arc(Vector2(0, -142), 16.0, PI * 0.95, TAU * 1.03, 14, Palette.BOATHOUSE.darkened(0.3), 9.0, true)
			draw_line(Vector2(18, -2), Vector2(18, -112), Palette.IRON_DARK, 3.0)
			draw_line(Vector2(18, -112), Vector2(32, -104), Palette.IRON_DARK, 2.0)
			draw_circle(Vector2(32, -86), 20.0, Color(Palette.WARD_CYAN, 0.16), true, -1.0, true)
			draw_rect(Rect2(26, -102, 12, 18), Palette.IRON_DARK)
			draw_rect(Rect2(28, -100, 8, 13), Palette.WARD_CYAN_HOT)
