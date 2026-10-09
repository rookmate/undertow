extends Node
## The Steward's presence in the earpiece: whether the voice is on. Step 4 adds the assists that hang
## off this switch.

signal voice_changed(voice_on: bool)

var voice_on: bool = true


func set_voice(on: bool) -> void:
	if on == voice_on:
		return
	voice_on = on
	GameState.count_voice_toggle()
	voice_changed.emit(voice_on)


func toggle_voice() -> void:
	set_voice(not voice_on)
