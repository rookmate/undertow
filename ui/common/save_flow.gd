class_name SaveFlow
extends RefCounted
## How the game saves: at checkpoints (a failure is reported and play goes on), and before leaving the
## run (a failure asks the player what to do; nothing is discarded silently).

## Saves at a checkpoint. Returns whether it worked; on failure the player sees a notice.
static func checkpoint(tree: SceneTree) -> bool:
	var err := GameState.save()
	if err != OK:
		SaveFailure.notice(tree, err)
	return err == OK


## Saves before the run is left. Returns true when it's safe to leave: the save worked, or the player
## chose to leave without saving. Returns false if they chose to stay.
static func before_leaving(tree: SceneTree) -> bool:
	var err := GameState.save()
	while err != OK:
		var dialog := SaveFailure.ask(tree, err)
		var choice: SaveFailure.Choice = await dialog.resolved
		match choice:
			SaveFailure.Choice.RETRY:
				err = GameState.save()
			SaveFailure.Choice.LEAVE:
				return true
			_:
				return false
	return true
