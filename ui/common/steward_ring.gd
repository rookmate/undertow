class_name StewardRing
extends Control
## The Steward's form as a UI element. States from the brief: idle (slow six-second breath), speaking
## (inner ring segments, petals fill), withholding (identical to idle except the inlay drifts 3° off
## centre), glitch (the rings tear and a cyan copy bleeds through a frame late), off (an unlit scorch
## mark). MUTED is the thin grey no-centre variant used by the title and HUD; REWRITE fills the gap.

enum State { IDLE, SPEAKING, WITHHOLDING, GLITCH, OFF, MUTED, REWRITE }

const BREATH_SECONDS := 6.0
const WITHHOLD_DEG := 3.0

@export var state: State = State.IDLE:
	set(value):
		state = value
		queue_redraw()
## > 1 makes the gold bloom on canvases with HDR glow.
@export var hdr: float = 1.0

var _t: float = 0.0
var _glitch_seed: int = 0
var _glitch_prev_seed: int = 0


func _ready() -> void:
	add_to_group(&"steward_ring")
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if state == State.GLITCH and Engine.get_process_frames() % 4 == 0:
		_glitch_prev_seed = _glitch_seed
		_glitch_seed = randi() % 100000
	queue_redraw()


## Band outer radius that fits this control, leaving room for the ticks.
func ring_radius() -> float:
	return minf(size.x, size.y) * 0.5 / RingPainter.EXTENT


func _draw() -> void:
	var c := size * 0.5
	var r := ring_radius()
	if state == State.GLITCH:
		var ghost := _look()
		ghost.color = Palette.TRUTH_CYAN
		ghost.alpha = 0.55
		ghost.tear_seed = _glitch_prev_seed
		ghost.halo = 0.0
		RingPainter.paint(self, c + Vector2(r * 0.035, -r * 0.018), r, ghost)
	RingPainter.paint(self, c, r, _look())


func _look() -> RingPainter.Look:
	var look := RingPainter.Look.new()
	look.hdr = hdr
	var breath := 0.84 + 0.16 * sin(TAU * _t / BREATH_SECONDS)
	match state:
		State.IDLE, State.WITHHOLDING:
			look.alpha = breath
			look.inlay_rotation_deg = WITHHOLD_DEG if state == State.WITHHOLDING else 0.0
		State.SPEAKING:
			look.alpha = 1.0
			look.inner_segments = 8
			look.segment_phase = _t * 0.9
			look.petal_fill = 0.42 + 0.18 * sin(_t * 7.0)
		State.GLITCH:
			look.alpha = 0.95
			look.tear_seed = _glitch_seed
		State.OFF:
			look.scorch = true
		State.MUTED:
			look.thin = true
			look.color = Palette.GREY_COLD
			look.show_center = false
			look.halo = 0.0
		State.REWRITE:
			look.alpha = breath
			look.gap_fill = Palette.TRUTH_CYAN
	return look
