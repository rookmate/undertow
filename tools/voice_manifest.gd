extends SceneTree
## Prints every Steward line (id and text) as JSON for tools/make_voice.py, which voices them.
##   godot --headless --path . -s tools/voice_manifest.gd


func _initialize() -> void:
	print("VOICE_MANIFEST_BEGIN")
	print(JSON.stringify(VoiceLines.all(), "", true))
	print("VOICE_MANIFEST_END")
	quit()
