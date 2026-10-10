extends TestCase
## Enforces the brief's colour ownership in code:
## 1. The gold hex appears only in core/palette.gd.
## 2. Palette.STEWARD_* (gold) is used only by scripts that draw things the Steward controls.
## 3. No hex colour literals outside core/palette.gd (every colour has a named owner).
## 4. No amber-looking numeric Color(...) literals outside core/palette.gd.

## Scripts allowed to use STEWARD_* colours, and why. Add to this list only for Steward-controlled things.
const STEWARD_ALLOWED: Dictionary[String, String] = {
	"res://ui/common/ring_painter.gd": "the Steward's ring",
	"res://ui/title/title.gd": "the Steward's last words before the Quiet (its narration)",
	"res://game/level/lamp_post.gd": "Lattice lamps are the Steward's hardware",
	"res://game/level/building_cell.gd": "the gilt on the ironwork is the Steward's overlay",
	"res://game/player/operator_body.gd": "the earpiece glows when the Steward is on",
	"res://game/weapons/weapon_glow.gd": "a Steward-tuned tool glows gold (manual tools glow ivory)",
	"res://ui/hud/hud_view.gd": "the TUNED tag (a weapon the Steward runs), its threat callouts and its refusals",
	"res://ui/loadout/loadout.gd": "the Steward's line on the loadout screen (its narration)",
	"res://game/enemies/custodian.gd": "a Custodian's lamp dome is Steward hardware",
	"res://game/path/predicted_path.gd": "the predicted path is the Steward's light",
	"res://game/path/path_tile_painter.gd": "the gilded path tiles are the Steward's",
	"res://game/props/the_waiting.gd": "the Lanyard at a Waiting resident's ear is a sliver of the Steward",
	"res://ui/hud/steward_pill.gd": "the Steward's own status and its assists",
	"res://ui/hud/minimap.gd": "the Steward's map (voice on)",
	"res://ui/hud/subtitles.gd": "the Steward's narration",
	"res://ui/core_choice/core_art.gd": "power cores are the Steward's amber prisms",
	"res://ui/core_choice/core_choice.gd": "POWER CORE label and the Steward's comments on the cards",
	"res://game/props/reliquary.gd": "the Steward's ring inlaid in the Reliquary lid",
	"res://game/ark/ark_level.gd": "the Ark's ring of gold floor lights",
	"res://game/props/ark_figure.gd": "Teo's tablet is the Steward's device, amber in his glasses",
	"res://ui/archive/archive_screen.gd": "the Steward's present-day comment (its narration)",
	"res://ui/archive/archive_dot.gd": "the Steward's own records are marked in its gold",
	"res://ui/ark/city_map.gd": "the Loop's route lights are the Steward's",
	"res://game/level/smart_gate.gd": "the gilt on a smart gate is the Steward's overlay",
	"res://game/enemies/lamplighter.gd": "a Lamplighter is a Lattice lamp on legs: its lens and its beam are the Steward's light",
	"res://game/bosses/conductor.gd": "the Conductor is the Loop's train-management unit: its core is the Steward's",
	"res://game/level/route_light.gd": "the Loop's route lights are the Steward's",
	"res://ui/ark/overrides_screen.gd": "the Steward's replies to your orders (its narration)",
	"res://game/level/crane_leg.gd": "the gilt climbing the Tideworks' crane legs is the Steward's overlay",
	"res://ui/ark/workshop_screen.gd": "the Steward's view on your upgrades (its narration)",
	"res://game/bosses/crane.gd": "the Crane is the Steward's last working crane: its core and its gilt are the Steward's",
	"res://game/level/ward_seal.gd": "the seal across a ward door is the Steward's lock",
	"res://game/bosses/surgeon.gd": "the Surgeon's operating lamp and the guide line it lays are the Steward's light",
}

const SCAN_ROOTS: Array[String] = ["res://autoload", "res://core", "res://game", "res://ui", "res://data"]
const SCAN_EXT: Array[String] = ["gd", "tscn", "tres"]
const PALETTE := "res://core/palette.gd"


func _files() -> PackedStringArray:
	var out := PackedStringArray()
	for root: String in SCAN_ROOTS:
		_walk(root, out)
	return out


func _walk(dir: String, out: PackedStringArray) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if SCAN_EXT.has(f.get_extension()):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		_walk(dir.path_join(sub), out)


func test_scan_finds_the_codebase() -> void:
	check(_files().size() > 10, "colour scan sees the project's files")


func test_gold_hex_only_in_palette() -> void:
	var re := RegEx.create_from_string("(?i)f0b35b")
	for path: String in _files():
		if path == PALETTE:
			continue
		if re.search(FileAccess.get_file_as_string(path)) != null:
			fail("%s contains the Steward gold hex; use Palette.STEWARD_GOLD" % path)


func test_steward_colours_only_in_steward_owned_scripts() -> void:
	var re := RegEx.create_from_string("\\bSTEWARD_[A-Z_]+")
	for path: String in _files():
		if path == PALETTE or STEWARD_ALLOWED.has(path):
			continue
		var m := re.search(FileAccess.get_file_as_string(path))
		if m != null:
			fail("%s uses %s but is not on the Steward allowlist" % [path, m.get_string()])


func test_no_hex_colour_literals_outside_palette() -> void:
	var re := RegEx.create_from_string("Color\\(\\s*\"#?[0-9A-Fa-f]{6}|Color\\.html\\(")
	for path: String in _files():
		if path == PALETTE:
			continue
		var m := re.search(FileAccess.get_file_as_string(path))
		if m != null:
			fail("%s has a hex colour literal (%s); add a named colour to Palette" % [path, m.get_string()])


func test_no_amber_numeric_colours_outside_palette() -> void:
	var re := RegEx.create_from_string("Color\\(\\s*([0-9.]+)\\s*,\\s*([0-9.]+)\\s*,\\s*([0-9.]+)")
	for path: String in _files():
		if path == PALETTE:
			continue
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
			var c := Color(m.get_string(1).to_float(), m.get_string(2).to_float(), m.get_string(3).to_float())
			if is_amber(c):
				fail("%s has an amber colour literal %s; gold belongs to the Steward" % [path, m.get_string()])


func test_amber_detector_recognises_gold_and_ignores_cream() -> void:
	check(is_amber(Palette.STEWARD_GOLD), "gold is amber")
	check_false(is_amber(Palette.HUMAN_CREAM), "cream is human warmth, not amber")
	check_false(is_amber(Palette.DANGER), "red-orange danger is not amber")
	check_false(is_amber(Palette.TRUTH_CYAN))


static func is_amber(c: Color) -> bool:
	var hue := c.h * 360.0
	return hue >= 25.0 and hue <= 52.0 and c.s >= 0.45 and c.v >= 0.5
