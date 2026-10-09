class_name Modals
extends RefCounted
## Who owns the paused game, the focus and the input. Screens that pause it (the pause menu, the Archive,
## the end of the slice, a save question) push themselves, and the topmost one owns everything:
## - it is drawn above the screens under it;
## - the screens under it go inert (nothing in them can be focused or clicked) until it closes, and
##   focus then returns to where it was before it opened;
## - only it takes cancel/back (screens check `is_top`);
## - the game unpauses only when the last one closes.
## A blocking screen (a save question) can't have the pause menu opened over it. Scene changes dismiss
## whatever is still open, so no question outlives the scene that asked it.

class Entry:
	var owner: Node
	var blocking: bool = false
	var return_focus: Control


static var _stack: Array[Entry] = []


static func push(owner: Node, blocking: bool = false) -> void:
	_prune()
	if _index_of(owner) >= 0:
		return
	var e := Entry.new()
	e.owner = owner
	e.blocking = blocking
	var focus := owner.get_viewport().gui_get_focus_owner()
	e.return_focus = focus if focus != null and not owner.is_ancestor_of(focus) else null
	var below: Node = _stack[_stack.size() - 1].owner if not _stack.is_empty() else null
	# On the stack first, so making the screen below inert leaves this one alone even if it's nested in it.
	_stack.append(e)
	if below != null:
		_set_inert(below, true)
		if owner is CanvasLayer and below is CanvasLayer:
			(owner as CanvasLayer).layer = maxi((owner as CanvasLayer).layer, (below as CanvasLayer).layer + 1)
	owner.get_tree().paused = true


static func pop(owner: Node) -> void:
	var i := _index_of(owner)
	if i >= 0:
		var e := _stack[i]
		_stack.remove_at(i)
		_prune()
		if i == _stack.size():
			if not _stack.is_empty():
				_set_inert(_stack[_stack.size() - 1].owner, false)
			if is_instance_valid(e.return_focus) and e.return_focus.is_visible_in_tree():
				e.return_focus.grab_focus()
	else:
		_prune()
	var tree := Engine.get_main_loop() as SceneTree
	if _stack.is_empty() and tree != null:
		tree.paused = false


static func is_top(owner: Node) -> bool:
	_prune()
	return not _stack.is_empty() and _stack[_stack.size() - 1].owner == owner


static func any_open() -> bool:
	_prune()
	return not _stack.is_empty()


## True while a screen that must be answered first (a save question) is on top.
static func top_blocks() -> bool:
	_prune()
	return not _stack.is_empty() and _stack[_stack.size() - 1].blocking


## Scene changes (and the test runner, between tests) start with nothing open. Screens that are waiting
## for an answer are told they were dismissed (`dismiss()`), so nobody waits forever.
static func clear() -> void:
	var open := _stack.duplicate()
	_stack.clear()
	for e: Entry in open:
		if is_instance_valid(e.owner):
			_set_inert(e.owner, false)
			if e.owner.has_method(&"dismiss"):
				e.owner.call(&"dismiss")


static func _index_of(owner: Node) -> int:
	for i: int in _stack.size():
		if _stack[i].owner == owner:
			return i
	return -1


static func _prune() -> void:
	for i: int in range(_stack.size() - 1, -1, -1):
		var o := _stack[i].owner
		if not is_instance_valid(o) or not o.is_inside_tree():
			_stack.remove_at(i)
			if i == _stack.size() and not _stack.is_empty():
				_set_inert(_stack[_stack.size() - 1].owner, false)


## True if `control` belongs to another open screen nested inside `screen` (its own rules apply to it).
static func _inside_other_screen(control: Node, screen: Node) -> bool:
	var n := control
	while n != null and n != screen:
		if _index_of(n) >= 0:
			return true
		n = n.get_parent()
	return false


## Makes every control in a screen unfocusable and unclickable, or gives back what each one had.
static func _set_inert(node: Node, inert: bool) -> void:
	if not is_instance_valid(node):
		return
	var controls: Array[Node] = node.find_children("*", "Control", true, false)
	if node is Control:
		controls.append(node)
	for n: Node in controls:
		if _inside_other_screen(n, node):
			continue
		var c := n as Control
		if inert:
			if c.has_meta(&"_modal_focus"):
				continue
			c.set_meta(&"_modal_focus", c.focus_mode)
			c.set_meta(&"_modal_mouse", c.mouse_filter)
			if c.has_focus():
				c.release_focus()
			c.focus_mode = Control.FOCUS_NONE
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif c.has_meta(&"_modal_focus"):
			c.focus_mode = c.get_meta(&"_modal_focus")
			c.mouse_filter = c.get_meta(&"_modal_mouse")
			c.remove_meta(&"_modal_focus")
			c.remove_meta(&"_modal_mouse")
