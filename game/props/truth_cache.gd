class_name TruthCache
extends Interactable
## An unindexed cache with a truth core in it: a dull cracked sphere with a faint blink inside. It looks
## broken, and the Steward says it is. Found alone, so it glows truth cyan through the fog.

var core_id: String = ""
var taken: bool = false
var cell: Vector2i
var _blink: float = 0.0
var _glow: PointLight2D


## How long "FILED TO THE ARCHIVE" shows over it.
const FILED_SECONDS := 3.0
var _filed: float = 0.0

func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	core_id = id
	off_path = true
	cell = at
	position = Iso.cell_center(at)
	# Carried, or left behind at the Reliquary: gone either way.
	taken = GameState.run.found_core_ids.has(id) or GameState.run.truth_core_ids.has(id) or GameState.run.cores_left.has(id)
	_glow = PointLight2D.new()
	_glow.texture = LightTextures.radial()
	_glow.color = Palette.TRUTH_CYAN
	_glow.energy = 0.9
	_glow.texture_scale = 1.4
	_glow.scale = Vector2(1.0, Iso.SQUASH)
	_glow.position = Vector2(0, -30)
	add_child(_glow)


func can_interact() -> bool:
	return is_present() and not taken


func still_to_find() -> bool:
	return not taken


func prompt_verb() -> String:
	return "TAKE THE CORE"


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	taken = true
	Sound.play(&"truth_find", global_position)
	if level != null and level.revisit:
		# A revisit's truth goes straight to the Archive (DECISIONS 176): its Reliquary won't open again.
		GameState.file_truth(core_id)
		_filed = FILED_SECONDS
	else:
		GameState.find_core(core_id)


## Said over it for a moment once a revisit's truth is filed.
func spoken_line() -> String:
	return "FILED TO THE ARCHIVE" if _filed > 0.0 else ""


func _process(delta: float) -> void:
	_blink += delta
	_filed = maxf(0.0, _filed - delta)
	visible = is_present()
	_glow.enabled = is_present() and not taken
	queue_redraw()


func _draw() -> void:
	ArtCatalog.paint(self, "crate", Rect2(-34, -60, 68, 78))
	if taken:
		return
	ArtCatalog.paint(self, "truth_core", Rect2(-22, -94, 44, 44))
	var blink := 0.35 + 0.65 * maxf(0.0, sin(_blink * 2.4))
	draw_circle(Vector2(2, -70), 3.0, Color(Palette.TRUTH_CYAN_HOT, blink), true, -1.0, true)
