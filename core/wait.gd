class_name Wait
extends RefCounted
## Delays that die with their node. `await Wait.seconds(self, 1.0)` never resumes if `self` is freed
## first (a SceneTree timer would, and the coroutine would then touch a freed instance).

static func seconds(node: Node, duration: float) -> Signal:
	var tween := node.create_tween()
	tween.tween_interval(maxf(duration, 0.0))
	return tween.finished
