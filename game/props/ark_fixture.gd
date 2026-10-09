class_name ArkFixture
extends Interactable
## The Archive's door, the Signal Room's door and the dock on the Ark.

enum Kind { ARCHIVE_DOOR, DOCK, SIGNAL_DOOR }

signal used(fixture: Kind)

var kind: Kind = Kind.ARCHIVE_DOOR


func setup(owner_level: Level, cell: Vector2i, fixture: Kind) -> void:
	level = owner_level
	kind = fixture
	position = Iso.cell_center(cell)


func prompt_verb() -> String:
	match kind:
		Kind.ARCHIVE_DOOR:
			return "ENTER THE ARCHIVE"
		Kind.SIGNAL_DOOR:
			return "ENTER THE SIGNAL ROOM"
	return "TAKE THE SKIFF"


func interact(_player: Operator) -> void:
	used.emit(kind)


func _draw() -> void:
	if kind == Kind.DOCK:
		# A mooring post and a small skiff.
		draw_rect(Rect2(-6, -40, 12, 40), Palette.IRON_DARK)
		draw_colored_polygon(PackedVector2Array([Vector2(10, 18), Vector2(90, 58), Vector2(120, 50), Vector2(44, 10)]), Palette.IRON_VERDIGRIS.darkened(0.3))
