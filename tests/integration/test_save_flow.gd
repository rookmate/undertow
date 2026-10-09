extends TestCase
## When a save fails the player is told: at a checkpoint the run goes on, and leaving the run asks first.

const DIR := "user://test_saves_flow"

var _real_store: SaveStore


class FailingStore:
	extends SaveStore
	func _write_text(_file_path: String, _text: String) -> Error:
		return ERR_FILE_CANT_WRITE


func before_each() -> void:
	GameState.new_run()
	_real_store = SaveService.store
	SaveService.store = FailingStore.new(DIR)


func after_each() -> void:
	SaveService.store.delete()
	SaveService.store = _real_store
	# The answer resumes the test from inside the dialog's own signal, so it can only be queued for freeing.
	for n: Node in get_tree().root.get_children():
		if n is SaveFailure:
			n.queue_free()
	Modals.clear()
	get_tree().paused = false
	await wait_frames(1)


func _shown() -> SaveFailure:
	for n: Node in get_tree().root.get_children():
		if n is SaveFailure and not n.is_queued_for_deletion():
			return n as SaveFailure
	return null


## Answers the "couldn't save" question a moment after it is asked.
func _answer_soon(choice: SaveFailure.Choice, then: Callable = Callable()) -> void:
	get_tree().create_timer(0.1, true).timeout.connect(func() -> void:
		if then.is_valid():
			then.call()
		var asked := _shown()
		check(asked != null and asked.asking, "the player is asked")
		check(get_tree().paused, "the game waits for the answer")
		if asked != null:
			asked.call(&"_choose", choice))


func test_a_failed_checkpoint_tells_the_player_and_play_goes_on() -> void:
	check_false(SaveFlow.checkpoint(get_tree()))
	await wait_frames(1)
	var notice := _shown()
	check(notice != null, "a notice is shown")
	check(notice != null and not notice.asking, "only a notice: nothing to answer")
	check_false(get_tree().paused, "play goes on")


func test_staying_keeps_you_in_the_run() -> void:
	_answer_soon(SaveFailure.Choice.STAY)
	check_false(await SaveFlow.before_leaving(get_tree()), "you stay")
	check_false(get_tree().paused, "and play resumes")


func test_leaving_without_saving_is_the_players_choice() -> void:
	_answer_soon(SaveFailure.Choice.LEAVE)
	check(await SaveFlow.before_leaving(get_tree()), "you may leave")
	check_false(SaveService.store.has_save(), "nothing was written")


func test_trying_again_saves_once_the_disk_works() -> void:
	GameState.run.noor_trust = 2
	_answer_soon(SaveFailure.Choice.RETRY, func() -> void: SaveService.store = SaveStore.new(DIR))
	check(await SaveFlow.before_leaving(get_tree()), "the retry worked")
	check_eq(SaveService.store.load_run().run.noor_trust, 2, "and the run is on disk")
