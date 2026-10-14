class_name ArkFixture
extends Interactable
## The doors of the Ark's buildings, and the dock.

enum Kind { ARCHIVE_DOOR, DOCK, SIGNAL_DOOR, WORKSHOP_DOOR, CLINIC_DOOR, PUMPHOUSE_DOOR, COMMONS_DOOR, COUNCIL_DOOR }

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
		Kind.WORKSHOP_DOOR:
			return "ENTER THE WORKSHOP"
		Kind.CLINIC_DOOR:
			return "ENTER THE CLINIC"
		Kind.PUMPHOUSE_DOOR:
			return "LOOK IN AT THE PUMPHOUSE"
		Kind.COMMONS_DOOR:
			return "LOOK IN AT THE COMMONS"
		Kind.COUNCIL_DOOR:
			return "GO DOWN INTO THE COUNCIL CHAMBER"
	return "TAKE THE SKIFF"


func interact(_player: Operator) -> void:
	used.emit(kind)


func _draw() -> void:
	if kind == Kind.DOCK:
		ArtCatalog.paint(self, "dock", Rect2(-12, -44, 140, 105))
