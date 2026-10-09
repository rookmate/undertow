extends Node
## The game's save slot. Saves are JSON in the user-data folder (`user://saves`, which is
## ~/.local/share/Undertow, %APPDATA%\Undertow or ~/Library/Application Support/Undertow).

const DEFAULT_DIR := "user://saves"

var store: SaveStore = SaveStore.new(DEFAULT_DIR)


## Tests point the service at a scratch directory so they never touch the player's save.
func use_directory(directory: String) -> void:
	store = SaveStore.new(directory)


func has_save() -> bool:
	return store.has_save()


func save_run(run: RunState) -> Error:
	var err := store.save(run)
	if err != OK:
		print("[save] could not write %s: %s" % [store.path(), error_string(err)])
	return err


func load_run() -> SaveStore.Result:
	var result := store.load_run()
	if result.note != "" and result.status != SaveStore.Status.MISSING:
		print("[save] ", result.note)
	return result


func delete_save() -> void:
	store.delete()
