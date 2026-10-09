extends Node
## Turns gameplay events into the Steward's narration. Step 5 adds adaptive line selection.

signal line_spoken(line_id: String, text: String)


func speak_text(line_id: String, text: String) -> void:
	if not Steward.voice_on:
		return
	line_spoken.emit(line_id, text)
