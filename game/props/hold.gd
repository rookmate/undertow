class_name Hold
extends Interactable
## A hold (design/deeper-districts.md): something people did by hand, done again while the Steward's
## machines come to stop you. Start it at its crank; it runs while you stay within reach and pauses when
## you don't; its waves come out at the map's spawn points meanwhile. Done, it opens the passage it
## kept shut, for the rest of the run. Downed, you start it over: its progress and the machines it
## brought out are gone. Human work: its light and its bar are cream, not gold.

## Within this of the crank (tiles), it runs.
const RADIUS := 3.5
## Its waves come out at these shares of its running time.
const FIRST_WAVE := 0.06
const LAST_WAVE := 0.8

var hold_id: String = ""
var cell: Vector2i
var running: bool = false
var done: bool = false
## Seconds of it running so far.
var progress: float = 0.0
var _waves_out: int = 0
var _brought: Array[Enemy] = []
var _t: float = 0.0


func setup(owner_level: Level, at: Vector2i, id: String) -> void:
	level = owner_level
	hold_id = id
	cell = at
	position = Iso.cell_center(at)
	done = GameState.run.holds_done.has(id)


func can_interact() -> bool:
	return not running and not done


func prompt_verb() -> String:
	return Holds.text(hold_id, "verb")


func interact(_player: Operator) -> void:
	if not can_interact():
		return
	running = true
	progress = 0.0
	_waves_out = 0
	Sound.play(&"windup", global_position)
	var line := Holds.text(hold_id, "steward_start")
	if line != "":
		Narrator.say_fixed(line)


## Running and you're within reach: it's going.
func turning() -> bool:
	return running and level != null and level.player != null and level.player.is_alive() \
		and Iso.ground_distance(global_position, level.player.global_position) <= RADIUS


func ratio() -> float:
	return clampf(progress / Holds.seconds(hold_id), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if not running or done:
		return
	if turning():
		progress += delta
	var waves := Holds.waves(hold_id)
	while _waves_out < waves.size() and ratio() >= _wave_share(_waves_out, waves.size()):
		_bring_out(waves[_waves_out])
		_waves_out += 1
	if progress >= Holds.seconds(hold_id):
		_finish()


func _wave_share(i: int, n: int) -> float:
	return FIRST_WAVE if n <= 1 else lerpf(FIRST_WAVE, LAST_WAVE, float(i) / float(n - 1))


## A wave of the Steward's machines, out at the spawn points (the farthest from you first).
func _bring_out(wave: Variant) -> void:
	if level == null or not wave is Array:
		return
	var points := level.grid.cells_with(Tiles.HOLD_SPAWN)
	if points.is_empty():
		return
	var from := level.player.global_position if level.player != null else global_position
	points.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Iso.cell_center(a).distance_squared_to(from) > Iso.cell_center(b).distance_squared_to(from))
	var i := 0
	for kind: Variant in wave:
		var e := level.spawn_kind(str(kind), points[i % points.size()])
		if e != null:
			# Sent to stop you: they come for the crank, and don't give up on you.
			e.home = global_position
			e.aggro_tiles = 40.0
			e.leash_tiles = 40.0
			_brought.append(e)
		i += 1
	Sound.play(&"warden_alert", global_position)


func _finish() -> void:
	running = false
	done = true
	GameState.complete_hold(hold_id)
	Sound.play(&"checkpoint", global_position)
	var line := Holds.text(hold_id, "steward_done")
	if line != "":
		Narrator.say_fixed(line)


## You went down while it ran: start over. What it brought out goes back in.
func reset() -> void:
	if not running or done:
		return
	running = false
	progress = 0.0
	_waves_out = 0
	for e: Enemy in _brought:
		if is_instance_valid(e) and e.is_alive():
			level.forget_enemy(e)
	_brought.clear()


## The machines it brought out still standing.
func brought_out() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for e: Enemy in _brought:
		if is_instance_valid(e) and e.is_alive():
			out.append(e)
	return out


func _draw() -> void:
	draw_colored_polygon(Fx.ground_ellipse(0.4, 18, false), Color(Palette.NEAR_BLACK, 0.4))
	ArtCatalog.paint(self, "crank", Rect2(-24, -84, 48, 90))
	var spin := _t * 3.0 if turning() else 0.0
	draw_set_transform(Vector2(0, -58), spin)
	ArtCatalog.paint(self, "valve_wheel", Rect2(-18, -18, 36, 36))
	draw_set_transform(Vector2.ZERO)
	if running or done:
		draw_circle(Vector2(0, -90), 7.0, Color(Palette.HUMAN_CREAM, 1.0 if done else 0.5 + 0.5 * ratio()), true, -1.0, true)
