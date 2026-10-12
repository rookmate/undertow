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


## A finished Rewrite on file is the title's proof of it while its record isn't written: nothing replaces
## that save until the record is (failing that, this save fails too, and the player hears about it).
func save_run(run: RunState) -> Error:
	var err := settle_legacy()
	if err == OK:
		err = store.save(run)
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
## touch it. A run on file (the save or its backup) that ended in a Rewrite counts too, and no save
## replaces it before the record is written (save_run), so a failed write is never the end of it.
const LEGACY := "legacy"


## A legacy record is a dictionary with a true-or-false "rewrite"; anything else is broken.
static func legacy_valid(d: Dictionary) -> bool:
	return d.get("rewrite") is bool


func _recorded_rewrite() -> bool:
	return store.load_record(LEGACY, legacy_valid).get("rewrite", false) == true


func rewritten() -> bool:
	if _recorded_rewrite():
		return true
	for run: RunState in store.saved_runs():
		if run.ending == Endings.REWRITE:
			return true
	return false


func remember_rewrite() -> Error:
	var err := store.save_record(LEGACY, {"version": 1, "rewrite": true}, legacy_valid)
	if err != OK:
		print("[save] could not remember the Rewrite: %s" % error_string(err))
	return err


## The record says what the saved run does: a finished Rewrite on file is written down (again).
func settle_legacy() -> Error:
	if not _recorded_rewrite() and rewritten():
		return remember_rewrite()
	return OK


## Automated runs start from nothing at all.
func forget_legacy() -> void:
	store.delete_record(LEGACY)
