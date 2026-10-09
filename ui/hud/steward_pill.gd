class_name StewardPill
extends Control
## Top-left of the HUD (mockups 1 and 2): the Steward's ring with "STEWARD · LISTENING" bound to [V],
## and its assists as chips. Muted: the thin grey ring, "STEWARD · MUTED", a muted timer, the chips
## struck through, and DMG TAKEN ×1.4.

const CHIPS: Array[String] = ["PATH", "MAP", "THREAT WARNINGS", "DODGE SLOW-MO", "AIM ASSIST", "TUNED WEAPONS"]

var ring: StewardRing
var speaking: bool = false
## What was last drawn; the text and chips redraw only when this changes.
var _signature: String = ""
## On the Ark the Steward may advise and may not act: no assists to show.
var advising_only: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(36, 32)
	size = Vector2(760, 150)
	ring = StewardRing.new()
	ring.position = Vector2(0, 0)
	ring.size = Vector2(64, 64)
	add_child(ring)


func _process(_delta: float) -> void:
	if not Steward.voice_on:
		ring.state = StewardRing.State.MUTED
	elif Steward.assists().signal_lost:
		ring.state = StewardRing.State.GLITCH
	else:
		ring.state = StewardRing.State.SPEAKING if speaking else StewardRing.State.IDLE
	var a := Steward.assists()
	var signature := "%d%d%d%d%d%d%d|%s|%d|%.1f" % [
		int(Steward.voice_on), int(a.signal_lost), int(advising_only), int(a.path_visible), int(a.threat_warnings),
		int(a.threat_warnings_overridden), int(a.weapons_forced_manual), Controls.prompt(&"voice_toggle"),
		-1 if Steward.voice_on else int(Steward.muted_for), a.damage_taken_mult]
	if signature != _signature:
		_signature = signature
		queue_redraw()


func _draw() -> void:
	var on := Steward.voice_on
	var a := Steward.assists()
	var title := ("STEWARD · ADVISING ONLY" if advising_only else "STEWARD · LISTENING") if on else "STEWARD · MUTED"
	var title_col := Palette.STEWARD_GOLD if on else Palette.GREY_COLD
	if a.signal_lost:
		title = "STEWARD · NO SIGNAL"
		title_col = Palette.GREY_COLD
	var heading := UiFonts.heading()
	draw_string(heading, Vector2(76, 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, title_col)
	var title_w := heading.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
	var key := Controls.prompt(&"voice_toggle")
	var key_at := Vector2(76 + title_w + 14, 8)
	var key_w := UiFonts.mono_medium().get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 16
	draw_rect(Rect2(key_at, Vector2(key_w, 28)), Palette.IVORY_FAINT, false, 1.0)
	draw_string(UiFonts.mono_medium(), key_at + Vector2(8, 20), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.IVORY_DIM)
	if not on:
		var t := int(Steward.muted_for)
		draw_string(UiFonts.mono(), Vector2(76, 56), "MUTED %02d:%02d" % [floori(t / 60.0), t % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.IVORY_DIM)
	if advising_only:
		return
	var states: Array[bool] = [a.path_visible, a.map_mode == Assists.MapMode.STEWARD, a.threat_warnings, a.dodge_slowmo_seconds > 0.0, a.aim_assist > 0.0, not a.weapons_forced_manual]
	var x := 0.0
	var y := 82.0
	var font := UiFonts.mono_medium()
	for i: int in CHIPS.size():
		var label := CHIPS[i]
		if i == 2 and a.threat_warnings_overridden:
			label += " · OVERRIDE"
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 20.0
		var r := Rect2(Vector2(x, y), Vector2(w, 26))
		if states[i]:
			draw_rect(r, Color(Palette.STEWARD_GOLD, 0.08))
			draw_rect(r, Color(Palette.STEWARD_GOLD, 0.6), false, 1.0)
			draw_string(font, r.position + Vector2(10, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.STEWARD_GOLD)
		else:
			draw_rect(r, Palette.IVORY_FAINT, false, 1.0)
			draw_string(font, r.position + Vector2(10, 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.GREY_COLD)
			draw_line(r.position + Vector2(6, 13), r.position + Vector2(w - 6, 13), Palette.GREY_COLD, 1.5)
		x += w + 8.0
		if x > 640.0:
			x = 0.0
			y += 34.0
	if a.damage_taken_mult > 1.0:
		var dmg := "DMG TAKEN ×%.1f" % a.damage_taken_mult
		var w2 := font.get_string_size(dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 20.0
		var r2 := Rect2(Vector2(x, y), Vector2(w2, 26))
		draw_rect(r2, Color(Palette.DANGER, 0.12))
		draw_rect(r2, Palette.DANGER, false, 1.0)
		draw_string(font, r2.position + Vector2(10, 18), dmg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Palette.DANGER)
