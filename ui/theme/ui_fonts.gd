class_name UiFonts
extends RefCounted
## The game's three type voices (brief, "Type"): Barlow Condensed for headings and labels, IBM Plex Mono
## for data and system text, Fraunces Italic for the Steward only.

const BARLOW_SEMIBOLD := "res://assets/fonts/BarlowCondensed-SemiBold.ttf"
const BARLOW_MEDIUM := "res://assets/fonts/BarlowCondensed-Medium.ttf"
const PLEX_MONO := "res://assets/fonts/IBMPlexMono-Regular.ttf"
const PLEX_MONO_MEDIUM := "res://assets/fonts/IBMPlexMono-Medium.ttf"
const FRAUNCES_ITALIC := "res://assets/fonts/Fraunces-Italic.ttf"

static var _cache: Dictionary[String, Font] = {}


## Headings: Barlow Condensed 600.
static func heading() -> Font:
	return _file(BARLOW_SEMIBOLD)


## Labels and buttons: Barlow Condensed 500.
static func label() -> Font:
	return _file(BARLOW_MEDIUM)


static func mono() -> Font:
	return _file(PLEX_MONO)


static func mono_medium() -> Font:
	return _file(PLEX_MONO_MEDIUM)


## The Steward's voice. Only Steward narration and Steward speech may use this font.
static func narration() -> Font:
	var key := "narration"
	if not _cache.has(key):
		var v := FontVariation.new()
		v.base_font = _file(FRAUNCES_ITALIC)
		v.variation_opentype = {"wght": 380, "opsz": 36, "SOFT": 60}
		_cache[key] = v
	return _cache[key]


## Barlow Condensed 600 tracked by `tracking` (fraction of the font size), for the title treatment.
static func tracked_heading(font_size: int, tracking: float) -> Font:
	var key := "tracked_%d_%.3f" % [font_size, tracking]
	if not _cache.has(key):
		var v := FontVariation.new()
		v.base_font = heading()
		v.spacing_glyph = roundi(font_size * tracking)
		_cache[key] = v
	return _cache[key]


static func _file(path: String) -> Font:
	if not _cache.has(path):
		var f := load(path) as Font
		if f == null:
			push_error("UiFonts: missing font %s" % path)
			f = ThemeDB.fallback_font
		_cache[path] = f
	return _cache[path]
