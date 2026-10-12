extends TestCase
## The brief's type rule in code: Fraunces Italic (UiFonts.narration()) is the Steward's voice and only
## the Steward's. People (Noor, Teo, the Waiting) and the UI speak in Barlow and Plex.

## Scripts allowed to use the Steward's font, and what of the Steward's they set in it.
const NARRATION_ALLOWED: Dictionary[String, String] = {
	"res://ui/hud/subtitles.gd": "the Steward's narration",
	"res://ui/hud/hud_view.gd": "the Steward's refusals over what it won't let you do",
	"res://ui/title/title.gd": "the Steward's last words before the Quiet",
	"res://ui/loadout/loadout.gd": "the Steward's line on the loadout",
	"res://ui/core_choice/core_choice.gd": "the Steward's comment on each card",
	"res://ui/archive/archive_screen.gd": "the Steward's present-day comment on a record",
	"res://ui/ark/clinic_screen.gd": "the Steward's comment on a triage record",
	"res://ui/ark/overrides_screen.gd": "the Steward's replies to your orders",
	"res://ui/ark/workshop_screen.gd": "the Steward's view on your upgrades",
	"res://ui/ark/noor_departure.gd": "the Steward's word on Noor going to the Ward",
	"res://game/props/confession.gd": "what the Steward says in the Spire, written into its glass",
	"res://ui/epilogue/epilogue.gd": "the Steward's words in the Reboot and Rewrite epilogues",
	"res://ui/ark/final_choice.gd": "the Steward's word at the Council Chamber's doors",
}
const SCAN_ROOTS: Array[String] = ["res://autoload", "res://core", "res://game", "res://ui"]


func test_only_the_steward_speaks_in_its_font() -> void:
	var users := PackedStringArray()
	for root: String in SCAN_ROOTS:
		_walk(root, users)
	check(not users.is_empty(), "the scan found the Steward's own uses")
	for path: String in users:
		check(NARRATION_ALLOWED.has(path), "%s sets something in the Steward's font; only the Steward speaks in it" % path)


func _walk(dir: String, out: PackedStringArray) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub: String in d.get_directories():
		_walk(dir.path_join(sub), out)
	for f: String in d.get_files():
		if f.get_extension() == "gd" and FileAccess.get_file_as_string(dir.path_join(f)).contains("UiFonts.narration()"):
			out.append(dir.path_join(f))
