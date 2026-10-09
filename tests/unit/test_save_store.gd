extends TestCase

const DIR := "user://test_saves/store"

var store: SaveStore


func before_each() -> void:
	store = SaveStore.new(DIR)
	store.delete()
	for f: String in ["slot_1.json.corrupt", "slot_1.json.tmp"]:
		if FileAccess.file_exists(DIR.path_join(f)):
			DirAccess.remove_absolute(DIR.path_join(f))


func _state(trust: int) -> RunState:
	var s := RunState.new()
	s.noor_trust = trust
	return s


func _write_raw(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_missing_save_reports_missing() -> void:
	check_false(store.has_save())
	check_eq(store.load_run().status, SaveStore.Status.MISSING)


func test_save_then_load_round_trips() -> void:
	check_eq(store.save(_state(4)), OK)
	check(store.has_save())
	var r := store.load_run()
	check_eq(r.status, SaveStore.Status.OK)
	check_eq(r.run.noor_trust, 4)
	check_false(r.from_backup)


func test_second_save_keeps_previous_as_backup() -> void:
	store.save(_state(1))
	store.save(_state(2))
	check(FileAccess.file_exists(store.backup_path()))
	check_eq(store.load_run().run.noor_trust, 2)


func test_corrupt_save_falls_back_to_backup_and_is_quarantined() -> void:
	store.save(_state(1))
	store.save(_state(2))
	_write_raw(store.path(), "{ not json")
	var r := store.load_run()
	check_eq(r.status, SaveStore.Status.OK)
	check(r.from_backup, "loaded from backup")
	check_eq(r.run.noor_trust, 1)
	check(FileAccess.file_exists(store.path() + ".corrupt"), "corrupt file kept aside")


func test_corrupt_save_without_backup_reports_corrupt() -> void:
	_write_raw(store.path(), "[1, 2, 3]")
	var r := store.load_run()
	check_eq(r.status, SaveStore.Status.CORRUPT)
	check(r.run == null)


func test_save_from_newer_version_is_refused_and_left_alone() -> void:
	_write_raw(store.path(), JSON.stringify({"version": RunState.SAVE_VERSION + 1}))
	var r := store.load_run()
	check_eq(r.status, SaveStore.Status.TOO_NEW)
	check(FileAccess.file_exists(store.path()), "newer save not moved or deleted")


## A store whose disk silently writes half the file.
class TruncatingStore:
	extends SaveStore
	func _write_text(file_path: String, text: String) -> Error:
		var f := FileAccess.open(file_path, FileAccess.WRITE)
		f.store_string(text.substr(0, int(text.length() * 0.5)))
		f.close()
		return OK


class FailingStore:
	extends SaveStore
	func _write_text(_file_path: String, _text: String) -> Error:
		return ERR_FILE_CANT_WRITE


func test_a_short_write_never_replaces_the_last_good_save() -> void:
	store.save(_state(1))
	var bad := TruncatingStore.new(DIR)
	check(bad.save(_state(2)) != OK, "the truncated write is caught")
	check_eq(store.load_run().run.noor_trust, 1, "the last good save is untouched")
	check_false(FileAccess.file_exists(store.path() + ".tmp"), "no temp file left behind")


func test_a_failed_write_reports_the_error() -> void:
	store.save(_state(1))
	check_eq(FailingStore.new(DIR).save(_state(2)), ERR_FILE_CANT_WRITE)
	check_eq(store.load_run().run.noor_trust, 1)


func test_a_corrupt_main_save_is_not_rotated_over_the_good_backup() -> void:
	store.save(_state(1))
	store.save(_state(2))
	_write_raw(store.path(), "{ broken")
	check_eq(store.save(_state(3)), OK)
	var backup := SaveStore.new(DIR)
	DirAccess.remove_absolute(store.path())
	check_eq(backup.load_run().run.noor_trust, 1, "the backup still holds the last good save before the corruption")


func test_save_service_uses_scratch_directory_in_tests() -> void:
	check(SaveService.store.dir_path.begins_with("user://test_saves"), "tests never touch the player's save")
