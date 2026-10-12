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


# --- What outlives a run --------------------------------------------------------------------------
## A small file beside the save: whether any run has ended in a Rewrite (the title's ring keeps its gap
## filled from then on). New Game doesn't touch it.
const LEGACY_FILE := "legacy.json"


func rewritten() -> bool:
	var text := FileAccess.get_file_as_string(store.dir_path.path_join(LEGACY_FILE))
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	return parsed is Dictionary and (parsed as Dictionary).get("rewrite", false) == true


func remember_rewrite() -> Error:
	DirAccess.make_dir_recursive_absolute(store.dir_path)
	var f := FileAccess.open(store.dir_path.path_join(LEGACY_FILE), FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		print("[save] could not remember the Rewrite: %s" % error_string(err))
		return err
	f.store_string(JSON.stringify({"version": 1, "rewrite": true}))
	return OK


## Automated runs start from nothing at all.
func forget_legacy() -> void:
	var path := store.dir_path.path_join(LEGACY_FILE)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
