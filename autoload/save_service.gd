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
## A small record beside the save (`legacy.json`, written like the save itself, with its backup): whether
## any run has ended in a Rewrite (the title's ring keeps its gap filled from then on). New Game doesn't
## touch it. A saved run that ended in a Rewrite counts too, so a failed write is never the end of it.
const LEGACY := "legacy"


func rewritten() -> bool:
	if store.load_record(LEGACY).get("rewrite", false) == true:
		return true
	if not has_save():
		return false
	var saved := load_run()
	return saved.status == SaveStore.Status.OK and saved.run.ending == Endings.REWRITE


func remember_rewrite() -> Error:
	var err := store.save_record(LEGACY, {"version": 1, "rewrite": true})
	if err != OK:
		print("[save] could not remember the Rewrite: %s" % error_string(err))
	return err


## The record says what the saved run does: a finished Rewrite on file is written down (again).
func settle_legacy() -> Error:
	if store.load_record(LEGACY).get("rewrite", false) != true and rewritten():
		return remember_rewrite()
	return OK


## Automated runs start from nothing at all.
func forget_legacy() -> void:
	store.delete_record(LEGACY)
