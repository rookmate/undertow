class_name Modals
extends RefCounted
## Who owns the paused game. Screens that pause it (the pause menu, the Archive, the end of the slice,
## a save warning) push themselves; the game unpauses only when the last one closes, and only the
## topmost one takes input. Without this, closing one screen could unpause another still open.

static var _stack: Array[Node] = []


static func push(owner: Node) -> void:
	_prune()
	if not _stack.has(owner):
		_stack.append(owner)
	owner.get_tree().paused = true


static func pop(owner: Node) -> void:
	var tree := owner.get_tree()
	_stack.erase(owner)
	_prune()
	if _stack.is_empty() and tree != null:
		tree.paused = false


static func is_top(owner: Node) -> bool:
	_prune()
	return not _stack.is_empty() and _stack[_stack.size() - 1] == owner


static func any_open() -> bool:
	_prune()
	return not _stack.is_empty()


## Scene changes start with nothing open.
static func clear() -> void:
	_stack.clear()


static func _prune() -> void:
	for i: int in range(_stack.size() - 1, -1, -1):
		if not is_instance_valid(_stack[i]) or not _stack[i].is_inside_tree():
			_stack.remove_at(i)
