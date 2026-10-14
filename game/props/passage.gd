class_name Passage
extends Interactable
## A way down, or back up (design/deeper-districts.md): a ladder to a descent (a separate dark place
## below the street, off the Lattice) and the ladder back. They come in pairs on the map ('@ x,y
## <name>_down' and '@ x,y <name>_up'). A hold can keep the way down shut until it's done
## (Holds.keeping); while it's shut, what's still to find below glows up through it.

var passage_id: String = ""
## The pair's name ("greywater_sump"), and whether this end goes down.
var base: String = ""
var going_down: bool = true
var cell: Vector2i
var _t: float = 0.0


func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	passage_id = id
	going_down = id.ends_with("_down")
	base = id.trim_suffix("_down").trim_suffix("_up")
	cell = at
	position = Iso.cell_center(at)


func partner_id() -> String:
	return base + ("_up" if going_down else "_down")


## The hold keeping this way down shut ("" if none; the way back up is never shut).
func keeping_hold() -> String:
	return Holds.keeping(base) if going_down else ""


func is_open() -> bool:
	var hold := keeping_hold()
	return hold == "" or GameState.run.holds_done.has(hold)


func can_interact() -> bool:
	return is_open() and level != null and level.passage(partner_id()) != null


func blocked_reason() -> String:
	return "" if is_open() else Holds.text(keeping_hold(), "locked")


func prompt_verb() -> String:
	return "GO DOWN" if going_down else "CLIMB BACK UP"


func interact(_player: Operator) -> void:
	if can_interact():
		level.descents.take_passage(self)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	ArtCatalog.paint(self, "hatch", Rect2(-30, -14, 60, 28))
	if going_down:
		if not is_open():
			var d := PackedVector2Array([Vector2(-24, 0), Vector2(0, 11), Vector2(24, 0), Vector2(0, -11)])
			draw_colored_polygon(d, Color(Palette.WATER_SHEEN, 0.6))
			if level != null and level.descent_finds_left() > 0:
				draw_circle(Vector2.ZERO, 10.0 + sin(_t * 2.0) * 2.0, Color(Palette.TRUTH_CYAN, 0.35), true, -1.0, true)
	else:
		ArtCatalog.paint(self, "ladder", Rect2(-14, -70, 28, 70))
