class_name Interactable
extends Node2D
## Something the Operator can use with Interact (E / X) when standing close. Off-path things are only
## there for you when the Steward isn't: unindexed places never show up while the voice is on.

const REACH_TILES := 1.4

## True for things the Steward never indexed (the stacks): hidden and unusable while it listens.
var off_path: bool = false
var level: Level


func _enter_tree() -> void:
	add_to_group(&"interactables")


## Present in the world right now (visible and usable).
func is_present() -> bool:
	return not (off_path and Steward.voice_on)


func can_interact() -> bool:
	return is_present()


## Verb shown in the prompt, e.g. "WAKE".
func prompt_verb() -> String:
	return "USE"


## Why the prompt is shown but can't be used (shown instead of the verb), or "".
func blocked_reason() -> String:
	return ""


func interact(_player: Operator) -> void:
	pass


## Interact pressed while blocked (see blocked_reason). Nothing by default.
func refused(_player: Operator) -> void:
	pass


func _process(_delta: float) -> void:
	visible = is_present()
