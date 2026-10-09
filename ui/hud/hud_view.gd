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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if level != null and level.player != null:
		level.player.hurt.connect(func(_a: float) -> void: _hurt_flash = 0.35)


func _process(delta: float) -> void:
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if level != null and level.player != null:
		_shown_integrity = move_toward(_shown_integrity, level.player.integrity.ratio(), delta * 0.8)
	queue_redraw()


func _draw() -> void:
	if level == null or level.player == null:
		return
	var p := level.player
	_draw_interaction(p)
	_draw_woken_lines()
	var bottom := size.y - MARGIN
	_draw_integrity(Vector2(MARGIN, bottom - CHIP_H - 64.0), p)
	for i: int in p.weapons.size():
		_draw_weapon(Rect2(MARGIN + i * (CHIP_W + 14.0), bottom - CHIP_H, CHIP_W, CHIP_H), p.weapons[i])


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


## What a woken survivor says, in plain type and human cream (the serif belongs to the Steward).
func _draw_woken_lines() -> void:
	for n: Node in get_tree().get_nodes_in_group(&"interactables"):
		var w := n as TheWaiting
		if w == null or w.spoken_line() == "" or not level.is_ancestor_of(w):
			continue
		var at := _to_screen(w.global_position + Vector2(0, -170))
		var font := UiFonts.label()
		var tw := font.get_string_size(w.spoken_line(), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		draw_string(font, at + Vector2(-tw * 0.5, 0), w.spoken_line(), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Palette.HUMAN_CREAM)


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
