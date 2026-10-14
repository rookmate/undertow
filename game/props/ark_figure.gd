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
				return "The Mast hears what the Lattice never listed. It can't say where. It'll tell you how many."
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
	draw_colored_polygon(Fx.ground_ellipse(0.4, 18, false), Color(Palette.NEAR_BLACK, 0.4))
	var key: String = ["noor", "teo", "survivor", "wardfolk"][who]
	var h: float = [197.0, 158.0, 147.0, 163.0][who]
	ArtCatalog.actor(self, key, h)
	match who:
		Who.NOOR, Who.WARDFOLK:
			var lamp := ArtCatalog.actor_anchor(key, "lantern", h)
			var col := Palette.TRUTH_CYAN_HOT if who == Who.NOOR else Palette.WARD_CYAN_HOT
			draw_circle(lamp, 14.0, Color(col, 0.12), true, -1.0, true)
			draw_circle(lamp, 3.6, col, true, -1.0, true)
		Who.TEO:
			var tablet := ArtCatalog.actor_anchor(key, "tablet", h)
			draw_circle(tablet, 18.0, Color(Palette.STEWARD_GOLD, 0.13), true, -1.0, true)
			draw_line(tablet - Vector2(6, 0), tablet + Vector2(6, 0), Palette.STEWARD_GOLD, 2.0)
		Who.SURVIVOR:
			if lit:
				var hand := ArtCatalog.actor_anchor(key, "hand", h)
				ArtCatalog.paint(self, "lantern_housing", Rect2(hand - Vector2(6, 2), Vector2(12, 22)))
				draw_circle(hand + Vector2(0, 9), 3.0, Palette.HUMAN_CREAM, true, -1.0, true)
