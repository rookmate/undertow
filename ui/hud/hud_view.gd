class_name HudView
extends Control
## Draws the HUD every frame from live state (it is small, and everything on it changes constantly).

const MARGIN := 40.0
const BAR_W := 380.0
const CHIP_W := 330.0
const CHIP_H := 74.0

var level: Level

var _hurt_flash: float = 0.0
var _shown_integrity: float = 1.0
## What was last drawn. The HUD redraws when this changes, or every frame while something on it is
## pinned to the world (it has to follow the camera).
var _signature: String = ""
var _was_anchored: bool = false
## Threat callouts: enemy -> seconds left. Keys can be freed at any time (enemies die), so they are
## held as Variants and checked before use.
var _threats: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if level != null and level.player != null:
		level.player.hurt.connect(func(_a: float) -> void: _hurt_flash = 0.35)
	Steward.threat_warned.connect(_on_threat)


func _exit_tree() -> void:
	if Steward.threat_warned.is_connected(_on_threat):
		Steward.threat_warned.disconnect(_on_threat)


func _on_threat(enemy: Node2D, seconds: float) -> void:
	_threats[enemy] = seconds + 0.2


## Enemies currently called out by the Steward (tests read this).
func active_threats() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for key: Variant in _threats:
		if is_instance_valid(key):
			out.append(key as Node2D)
	return out


func _process(delta: float) -> void:
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	var warnings_on := Steward.assists().threat_warnings
	for key: Variant in _threats.keys():
		var left: float = _threats[key] - delta
		if left <= 0.0 or not is_instance_valid(key) or not warnings_on:
			_threats.erase(key)
		else:
			_threats[key] = left
	if level != null and level.player != null:
		_shown_integrity = move_toward(_shown_integrity, level.player.integrity.ratio(), delta * 0.8)
	# World-anchored marks (threats, prompts, people's words) move with the camera, so they redraw every
	# frame while there are any, and once more when the last one goes so it doesn't linger.
	var signature := _state_signature()
	var anchored := _world_anchored()
	if signature != _signature or anchored or _was_anchored:
		_signature = signature
		queue_redraw()
	_was_anchored = anchored


func _state_signature() -> String:
	if level == null or level.player == null:
		return ""
	var p := level.player
	var parts := PackedStringArray([str(roundi(p.integrity.value)), "%.3f" % _shown_integrity, "%.2f" % _hurt_flash])
	var b := level.boss
	if b != null and is_instance_valid(b):
		parts.append("%d%d%d%.1f" % [int(b.is_engaged), int(b.is_alive()), int(b.is_vulnerable()), b.integrity.value])
	for w: Weapon in p.weapons:
		parts.append("%s%d%s%.2f" % [Controls.prompt(w.action()), int(w.is_tuned()), w.status(), snappedf(w.readiness(), 0.02)])
	return "|".join(parts)


func _world_anchored() -> bool:
	if level == null or level.player == null:
		return false
	if not _threats.is_empty() or level.player.interact_target() != null:
		return true
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if n.has_method(&"spoken_line") and str(n.call(&"spoken_line")) != "" and level.is_ancestor_of(n):
			return true
	return false


func _draw() -> void:
	if level == null or level.player == null:
		return
	var p := level.player
	_draw_boss()
	_draw_threats(p)
	_draw_interaction(p)
	_draw_woken_lines()
	if level.is_hub():
		return
	var bottom := size.y - MARGIN
	_draw_integrity(Vector2(MARGIN, bottom - CHIP_H - 64.0), p)
	for i: int in p.weapons.size():
		_draw_weapon(Rect2(MARGIN + i * (CHIP_W + 14.0), bottom - CHIP_H, CHIP_W, CHIP_H), p.weapons[i])


## The Steward's threat callout: a gold bracket over the enemy winding up, and a gold mark on a ring
## around the Operator pointing at it. (The danger itself is the enemy's red-orange windup.)
## The boss's name and integrity, top centre, once the fight has started. Brighter while it's open.
func _draw_boss() -> void:
	var b := level.boss
	if b == null or not is_instance_valid(b) or not b.is_engaged or not b.is_alive():
		return
	var w := 640.0
	var at := Vector2((size.x - w) * 0.5, 40.0)
	draw_string(UiFonts.heading(), at + Vector2(0, -6), b.boss_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.IVORY)
	draw_rect(Rect2(at + Vector2(0, 6), Vector2(w, 10)), Color(Palette.NEAR_BLACK, 0.7))
	var fill := Palette.IVORY if b.is_vulnerable() else Palette.IVORY_DIM
	draw_rect(Rect2(at + Vector2(0, 6), Vector2(w * b.integrity.ratio(), 10)), fill)


func _draw_threats(p: Operator) -> void:
	var font := UiFonts.heading()
	var me := _to_screen(p.global_position + Vector2(0, -80))
	for e: Node2D in active_threats():
		var at := _to_screen(e.global_position + Vector2(0, -150))
		draw_polyline(PackedVector2Array([at + Vector2(-26, -8), at + Vector2(-26, 8), at + Vector2(-18, 8)]), Palette.STEWARD_GOLD, 3.0, true)
		draw_polyline(PackedVector2Array([at + Vector2(26, -8), at + Vector2(26, 8), at + Vector2(18, 8)]), Palette.STEWARD_GOLD, 3.0, true)
		draw_string(font, at + Vector2(-34, -16), "THREAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.STEWARD_GOLD)
		var dir := (_to_screen(e.global_position) - _to_screen(p.global_position)).normalized()
		var a := dir.angle()
		draw_arc(me, 96.0, a - 0.22, a + 0.22, 10, Palette.STEWARD_GOLD, 4.0, true)


func _to_screen(world_pos: Vector2) -> Vector2:
	return level.get_viewport().get_canvas_transform() * world_pos


## "[E] WAKE" over the thing in reach; or, if the Steward forbids it, its reason in its own voice.
func _draw_interaction(p: Operator) -> void:
	var target := p.interact_target()
	if target == null:
		return
	var at := _to_screen(target.global_position + Vector2(0, -175))
	var reason := target.blocked_reason()
	if not target.can_interact() and reason != "":
		var font := UiFonts.narration()
		var w := font.get_string_size(reason, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_rect(Rect2(at + Vector2(-w * 0.5 - 14, -30), Vector2(w + 28, 42)), Palette.PANEL)
		draw_string(font, at + Vector2(-w * 0.5, 0), reason, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.STEWARD_GOLD)
		return
	var text := "%s  %s" % [Controls.prompt(&"interact"), target.prompt_verb()]
	var label_font := UiFonts.heading()
	var tw := label_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_rect(Rect2(at + Vector2(-tw * 0.5 - 14, -30), Vector2(tw + 28, 42)), Palette.PANEL)
	draw_rect(Rect2(at + Vector2(-tw * 0.5 - 14, -30), Vector2(tw + 28, 42)), Palette.IVORY_FAINT, false, 1.0)
	draw_string(label_font, at + Vector2(-tw * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.IVORY)


## What people say, in plain type and human cream (the serif belongs to the Steward).
func _draw_woken_lines() -> void:
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		if not level.is_ancestor_of(n) or not n.has_method(&"spoken_line"):
			continue
		var line: String = n.call(&"spoken_line")
		if line == "":
			continue
		var at := _to_screen((n as Node2D).global_position + Vector2(0, -238))
		var font := UiFonts.label()
		var tw := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_rect(Rect2(at + Vector2(-tw * 0.5 - 12, -28), Vector2(tw + 24, 38)), Color(Palette.NEAR_BLACK, 0.6))
		draw_string(font, at + Vector2(-tw * 0.5, 0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.HUMAN_CREAM)


func _draw_integrity(at: Vector2, p: Operator) -> void:
	var label_font := UiFonts.heading()
	draw_string(label_font, at + Vector2(0, 2), "INTEGRITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.IVORY_DIM)
	var value := "%d" % roundi(p.integrity.value)
	draw_string(UiFonts.mono(), at + Vector2(BAR_W - 40.0, 2), value, HORIZONTAL_ALIGNMENT_RIGHT, 40.0, 18, Palette.IVORY_DIM)
	var bar := Rect2(at + Vector2(0, 14), Vector2(BAR_W, 12))
	draw_rect(bar, Palette.GREY_DEEP)
	draw_rect(Rect2(bar.position, Vector2(BAR_W * _shown_integrity, 12)), Color(Palette.DANGER, 0.6))
	draw_rect(Rect2(bar.position, Vector2(BAR_W * p.integrity.ratio(), 12)), Palette.IVORY)
	if _hurt_flash > 0.0:
		draw_rect(bar.grow(3.0), Color(Palette.DANGER, _hurt_flash * 2.0), false, 2.0)


func _draw_weapon(r: Rect2, w: Weapon) -> void:
	draw_rect(r, Palette.PANEL)
	draw_rect(r, Palette.IVORY_FAINT, false, 1.0)
	var tuned := w.is_tuned()
	var prompt := Controls.prompt(w.action())
	draw_string(UiFonts.mono_medium(), r.position + Vector2(14, 26), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.IVORY_DIM)
	draw_string(UiFonts.label(), r.position + Vector2(70, 28), WeaponDefs.display_name(w.weapon_id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, CHIP_W - 84.0, 24, Palette.IVORY)
	var tag := "TUNED" if tuned else "MANUAL"
	var tag_col := Palette.STEWARD_GOLD if tuned else Palette.IVORY
	draw_string(UiFonts.mono_medium(), r.position + Vector2(70, 54), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tag_col)
	var status := w.status()
	if status != "":
		var col := Palette.DANGER if status == "OVERHEAT" or status == "OVERLOAD" else Palette.IVORY
		draw_string(UiFonts.mono_medium(), r.position + Vector2(150, 54), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, col)
	var ready_bar := Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x * w.readiness(), 4))
	draw_rect(ready_bar, Color(tag_col, 0.75))
