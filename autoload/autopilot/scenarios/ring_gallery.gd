extends AutopilotScenario
## The Steward's ring in every state, on one screen (for looking at it).


func expected() -> Array[String]:
	var out := super()
	out.append("ring_gallery_shown")
	return out


func on_title(_title: Node, _gen: int) -> void:
	SceneRouter.goto(&"ring_gallery")


func on_ring_gallery(gen: int) -> void:
	Autopilot.pass_check("ring_gallery_shown")
	if not await Autopilot.wait(1.5, gen):
		return
	await Autopilot.snap("ring_gallery")
