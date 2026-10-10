extends Node
## The game's sound. Gameplay asks for a cue by name (`Sound.play(&"dodge", position)`); this picks one of
## the cue's variations, nudges its pitch, and plays it on the cue's bus from a small pool of players.
## Ambience is a set of looping layers that fade toward the levels a scene asks for.
##
## Every file in assets/audio is placeholder, synthesized by tools/make_audio.py (DECISIONS #82).
## Buses: Master ← Music, Ambience, SFX, Steward (its chime, its voice later), UI. Options set their volumes.
##
## The Steward's own sounds follow the rules of its voice: it speaks (assets/voice, one file per line; the
## chime stands in for a line not voiced yet) only when its narration is allowed, so never while muted, it
## stops mid-word when muted or out of reach, and the Lattice hum is there only while it is with you.

const DIR := "res://assets/audio/"
const BUSES: Array[StringName] = [&"Music", &"Ambience", &"SFX", &"Steward", &"UI"]
const WORLD_PLAYERS := 16
const FLAT_PLAYERS := 10
## Seconds for an ambience layer to fade to its new level.
const AMBIENCE_FADE := 1.2
## World sounds fade out over this many pixels from the camera (about 14 tiles across the ground).
const HEARING_PX := 1800.0

## name -> {files, bus, db, pitch (± random fraction)}
const CUES: Dictionary[StringName, Dictionary] = {
	&"step_wet": {"files": ["step_wet_1", "step_wet_2", "step_wet_3", "step_wet_4"], "bus": &"SFX", "db": -8.0, "pitch": 0.08},
	&"step_dry": {"files": ["step_dry_1", "step_dry_2", "step_dry_3"], "bus": &"SFX", "db": -9.0, "pitch": 0.08},
	&"dodge": {"files": ["dodge_1", "dodge_2"], "bus": &"SFX", "db": -4.0, "pitch": 0.06},
	&"baton_swing": {"files": ["baton_swing_1", "baton_swing_2"], "bus": &"SFX", "db": -5.0, "pitch": 0.08},
	&"baton_hit": {"files": ["baton_hit_1", "baton_hit_2"], "bus": &"SFX", "db": -2.0, "pitch": 0.06},
	&"drone_shot": {"files": ["drone_shot_1", "drone_shot_2"], "bus": &"SFX", "db": -7.0, "pitch": 0.05},
	&"gauntlet_zap": {"files": ["gauntlet_zap"], "bus": &"SFX", "db": -3.0, "pitch": 0.05},
	&"gauntlet_overload": {"files": ["gauntlet_overload"], "bus": &"SFX", "db": -2.0, "pitch": 0.0},
	&"machine_hit": {"files": ["machine_hit_1", "machine_hit_2"], "bus": &"SFX", "db": -5.0, "pitch": 0.1},
	&"machine_death": {"files": ["machine_death"], "bus": &"SFX", "db": -3.0, "pitch": 0.08},
	&"windup": {"files": ["windup"], "bus": &"SFX", "db": -8.0, "pitch": 0.04},
	&"bale_throw": {"files": ["bale_throw"], "bus": &"SFX", "db": -7.0, "pitch": 0.1},
	&"hurt": {"files": ["hurt"], "bus": &"SFX", "db": -2.0, "pitch": 0.05},
	&"steward_chime": {"files": ["steward_chime"], "bus": &"Steward", "db": -10.0, "pitch": 0.0},
	&"voice_off": {"files": ["voice_off"], "bus": &"SFX", "db": -6.0, "pitch": 0.0},
	&"voice_on": {"files": ["voice_on"], "bus": &"SFX", "db": -7.0, "pitch": 0.0},
	&"lamp_off": {"files": ["lamp_off"], "bus": &"SFX", "db": -12.0, "pitch": 0.15},
	&"signal_lost": {"files": ["signal_lost"], "bus": &"Steward", "db": -12.0, "pitch": 0.0},
	&"ui_move": {"files": ["ui_move"], "bus": &"UI", "db": -14.0, "pitch": 0.03},
	&"ui_accept": {"files": ["ui_accept"], "bus": &"UI", "db": -10.0, "pitch": 0.0},
	&"ui_back": {"files": ["ui_back"], "bus": &"UI", "db": -11.0, "pitch": 0.0},
	&"core_take": {"files": ["core_take"], "bus": &"SFX", "db": -6.0, "pitch": 0.0},
	&"truth_find": {"files": ["truth_find"], "bus": &"SFX", "db": -6.0, "pitch": 0.0},
	&"wake": {"files": ["wake"], "bus": &"SFX", "db": -6.0, "pitch": 0.05},
	&"record_tick": {"files": ["record_tick"], "bus": &"UI", "db": -10.0, "pitch": 0.12},
	&"checkpoint": {"files": ["checkpoint"], "bus": &"SFX", "db": -9.0, "pitch": 0.0},
	&"respawn": {"files": ["respawn"], "bus": &"SFX", "db": -8.0, "pitch": 0.0},
	&"gate_shut": {"files": ["gate_shut"], "bus": &"SFX", "db": -5.0, "pitch": 0.04},
	&"lamp_hook": {"files": ["lamp_hook"], "bus": &"SFX", "db": -6.0, "pitch": 0.05},
	&"armour_clang": {"files": ["armour_clang"], "bus": &"SFX", "db": -6.0, "pitch": 0.08},
	&"carriage_run": {"files": ["carriage_run"], "bus": &"SFX", "db": -3.0, "pitch": 0.05},
	&"vent_hiss": {"files": ["vent_hiss"], "bus": &"SFX", "db": -6.0, "pitch": 0.05},
	&"signal_zap": {"files": ["signal_zap"], "bus": &"SFX", "db": -6.0, "pitch": 0.06},
	&"container_drop": {"files": ["container_drop"], "bus": &"SFX", "db": -2.0, "pitch": 0.06},
	&"seal_crank": {"files": ["seal_crank"], "bus": &"SFX", "db": -5.0, "pitch": 0.04},
	&"sterile_hiss": {"files": ["sterile_hiss"], "bus": &"SFX", "db": -8.0, "pitch": 0.06},
	&"dressing": {"files": ["dressing"], "bus": &"SFX", "db": -6.0, "pitch": 0.04},
}

## Looping layers: name -> {file, db at full level}
const AMBIENCE: Dictionary[StringName, Dictionary] = {
	&"rain": {"file": "amb_rain", "db": -8.0},
	&"lattice_hum": {"file": "amb_lattice_hum", "db": -16.0},
	&"estuary": {"file": "amb_estuary", "db": -7.0},
	&"underground": {"file": "amb_underground", "db": -10.0},
}

## Cues asked for, newest last (the last 64): {cue, bus, at}. Tests read this.
var history: Array[Dictionary] = []
## How many times each cue has been asked for since the game started (never capped).
var _counts: Dictionary[StringName, int] = {}
## Under the dummy audio driver (headless runs: tests, CI) nothing can be heard and the driver never
## releases a sound once started, so cues are set up and recorded but not started. Movie Maker also uses
## the dummy driver, but drives it frame by frame and records it, so recordings are audible.
var audible: bool = AudioServer.get_driver_name() != "Dummy" or Engine.get_write_movie_path() != ""

var _streams: Dictionary[String, AudioStream] = {}
var _world: Array[AudioStreamPlayer2D] = []
var _flat: Array[AudioStreamPlayer] = []
var _next_world: int = 0
var _next_flat: int = 0
var _layers: Dictionary[StringName, AudioStreamPlayer] = {}
var _voice: AudioStreamPlayer
## The Steward line being spoken now ("" if none).
var voice_line: String = ""
## The length of that line, and (when nothing can be heard: headless runs) how far into it the voice is:
## the same real-time advance a playing recording makes, through a pause and through slowed time.
var _voice_length: float = 0.0
var _voice_at: float = 0.0
## Quitting: nothing new may start (a sound begun after the silence would leak at exit).
var closing: bool = false
## Wanted level (0..1) of each ambience layer, and where it is now.
var _layer_target: Dictionary[StringName, float] = {}
var _layer_level: Dictionary[StringName, float] = {}
var _rng := RandomNumberGenerator.new()


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus: StringName in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")


func _ready() -> void:
	for i: int in WORLD_PLAYERS:
		var p := AudioStreamPlayer2D.new()
		p.max_distance = HEARING_PX
		p.attenuation = 1.4
		add_child(p)
		_world.append(p)
	for i: int in FLAT_PLAYERS:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_flat.append(p)
	for layer: StringName in AMBIENCE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Ambience"
		var stream := _stream(str(AMBIENCE[layer]["file"]))
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		p.stream = stream
		p.volume_db = -80.0
		add_child(p)
		_layers[layer] = p
		_layer_target[layer] = 0.0
		_layer_level[layer] = 0.0
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"Steward"
	_voice.finished.connect(func() -> void: voice_line = "")
	add_child(_voice)
	get_tree().node_added.connect(_on_node_added)
	Narrator.line_spoken.connect(func(id: String, _text: String) -> void:
		if say(id) <= 0.0:
			play(&"steward_chime"))
	Steward.voice_changed.connect(func(on: bool) -> void:
		if not on:
			hush())
	Steward.coverage_changed.connect(func(covered: bool) -> void:
		if not covered and Steward.voice_on:
			hush()
			play(&"signal_lost"))


## The way out of the game: everything falls silent, the audio thread gets a moment to let go of what
## was playing (otherwise its playbacks leak at exit), then the game quits. Every quit goes through here.
func quit(exit_code: int = 0) -> void:
	# The game runs on for a moment yet (a respawn's sound, the Steward's word on it); none of it starts.
	closing = true
	_silence()
	await get_tree().create_timer(0.15, true, false, true).timeout
	get_tree().quit(exit_code)


func _silence() -> void:
	voice_line = ""
	for layer: StringName in _layer_target:
		_layer_target[layer] = 0.0
		_layer_level[layer] = 0.0
	for p: Node in get_children():
		if p is AudioStreamPlayer:
			(p as AudioStreamPlayer).stop()
			(p as AudioStreamPlayer).stream = null
		elif p is AudioStreamPlayer2D:
			(p as AudioStreamPlayer2D).stop()
			(p as AudioStreamPlayer2D).stream = null
	_streams.clear()


## Plays a cue: at a ground position in the world if `at` is a Vector2, otherwise flat (UI, the Steward).
## Returns the player used, or null if the cue doesn't exist.
func play(cue: StringName, at: Variant = null) -> Node:
	if closing:
		return null
	if not CUES.has(cue):
		Diagnostics.error("Sound: unknown cue %s" % cue)
		return null
	var def := CUES[cue]
	var files: Array = def["files"]
	var stream := _stream(str(files[_rng.randi() % files.size()]))
	if stream == null:
		return null
	var spread: float = def["pitch"]
	var pitch := 1.0 + _rng.randf_range(-spread, spread)
	history.append({"cue": cue, "bus": def["bus"], "at": at})
	_counts[cue] = _counts.get(cue, 0) + 1
	if history.size() > 64:
		history.pop_front()
	if at is Vector2:
		var p := _world[_next_world]
		_next_world = (_next_world + 1) % _world.size()
		p.stop()
		p.stream = stream
		p.bus = def["bus"]
		p.volume_db = def["db"]
		p.pitch_scale = pitch
		p.global_position = at
		if audible:
			p.play()
		return p
	var f := _flat[_next_flat]
	_next_flat = (_next_flat + 1) % _flat.size()
	f.stop()
	f.stream = stream
	f.bus = def["bus"]
	f.volume_db = def["db"]
	f.pitch_scale = pitch
	if audible:
		f.play()
	return f


## Speaks a Steward line in its voice, cutting off whatever it was saying. Returns the line's length in
## seconds, or 0.0 if it has no voice yet. Callers decide whether the Steward may speak (narration rules).
func say(line_id: String) -> float:
	if closing:
		return 0.0
	var path := VoiceLines.clip_path(line_id)
	if not ResourceLoader.exists(path):
		return 0.0
	var stream := load(path) as AudioStream
	if stream == null:
		return 0.0
	_voice.stop()
	_voice.stream = stream
	voice_line = line_id
	_voice_length = stream.get_length()
	_voice_at = 0.0
	history.append({"cue": &"voice", "bus": &"Steward", "at": line_id})
	if history.size() > 64:
		history.pop_front()
	_counts[&"voice"] = _counts.get(&"voice", 0) + 1
	if audible:
		_voice.play()
	return stream.get_length()


## The Steward stops speaking (muted, or out of its reach), mid-word.
func hush() -> void:
	_voice.stop()
	voice_line = ""


## Seconds left of the line being spoken, on the recording's own clock (0.0 if it's saying nothing).
## Subtitles keep to this, so a line's text lasts exactly as long as its voice.
func voice_left() -> float:
	if voice_line == "":
		return 0.0
	var at := _voice.get_playback_position() if audible else _voice_at
	return maxf(0.0, _voice_length - at)


## Seconds a line takes to say (0.0 if not voiced).
func voice_length(line_id: String) -> float:
	var path := VoiceLines.clip_path(line_id)
	if not ResourceLoader.exists(path):
		return 0.0
	var stream := load(path) as AudioStream
	return stream.get_length() if stream != null else 0.0


## The ambience a scene wants: each named layer fades to its level (0..1); layers not named fade out.
func set_ambience(levels: Dictionary) -> void:
	if closing:
		return
	for layer: StringName in _layer_target:
		_layer_target[layer] = clampf(float(levels.get(layer, 0.0)), 0.0, 1.0)
	for layer: StringName in levels:
		if not AMBIENCE.has(layer):
			Diagnostics.error("Sound: unknown ambience layer %s" % layer)


## One layer's wanted level, leaving the others as they are.
func set_layer(layer: StringName, level: float) -> void:
	if closing:
		return
	if not AMBIENCE.has(layer):
		Diagnostics.error("Sound: unknown ambience layer %s" % layer)
		return
	_layer_target[layer] = clampf(level, 0.0, 1.0)


func layer_target(layer: StringName) -> float:
	return _layer_target.get(layer, 0.0)


## Bus volume as a 0..1 slider value.
func set_volume(bus: StringName, linear: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		Diagnostics.error("Sound: unknown bus %s" % bus)
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(i, linear <= 0.001)


func volume(bus: StringName) -> float:
	var i := AudioServer.get_bus_index(bus)
	if i == -1 or AudioServer.is_bus_mute(i):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(i))


func _process(delta: float) -> void:
	# With nothing to hear, the voice still runs its course, as a recording would (then it's finished).
	if voice_line != "" and not audible:
		_voice_at += delta / maxf(Engine.time_scale, 0.01)
		if _voice_at >= _voice_length:
			voice_line = ""
	for layer: StringName in _layers:
		var p := _layers[layer]
		var level := move_toward(_layer_level[layer], _layer_target[layer], delta / AMBIENCE_FADE)
		_layer_level[layer] = level
		if level <= 0.0:
			if p.playing:
				p.stop()
			continue
		p.volume_db = float(AMBIENCE[layer]["db"]) + linear_to_db(level)
		if audible and not p.playing:
			p.play(_rng.randf() * maxf(p.stream.get_length() - 0.1, 0.0) if p.stream != null else 0.0)


func _stream(file: String) -> AudioStream:
	if _streams.has(file):
		return _streams[file]
	var path := DIR + file + ".ogg"
	var s := load(path) as AudioStream if ResourceLoader.exists(path) else null
	if s == null:
		Diagnostics.error("Sound: missing %s" % path)
	_streams[file] = s
	return s


## How many times `cue` has been asked for since the game started.
func heard(cue: StringName) -> int:
	return _counts.get(cue, 0)


## Every button in the game ticks when focused and confirms when pressed.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var b := node as BaseButton
		b.focus_entered.connect(func() -> void: play(&"ui_move"))
		b.pressed.connect(func() -> void: play(&"ui_accept"))
