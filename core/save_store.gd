class_name SaveStore
extends RefCounted
## JSON save files in one directory. Writes go to a temp file first, the previous good save is kept as
## `.bak`, and a file that can't be parsed is moved aside as `.corrupt` and the backup is tried instead.
## Steam Auto-Cloud can sync the directory; nothing here talks to Steam.

enum Status { OK, MISSING, CORRUPT, TOO_NEW, IO_ERROR }

class Result:
	var status: Status = Status.MISSING
	var run: RunState = null
	## Human-readable detail for logs and the title screen.
	var note: String = ""
	## True when the main file was unusable and the backup was loaded instead.
	var from_backup: bool = false


var dir_path: String
var slot: String


func _init(directory: String, slot_name: String = "slot_1") -> void:
	dir_path = directory
	slot = slot_name


func path() -> String:
	return dir_path.path_join(slot + ".json")


func backup_path() -> String:
	return dir_path.path_join(slot + ".bak.json")


func has_save() -> bool:
	return FileAccess.file_exists(path()) or FileAccess.file_exists(backup_path())


func save(run: RunState) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK:
		return err
	var tmp := path() + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(run.to_dict(), "\t"))
	f.close()
	if FileAccess.file_exists(path()):
		if FileAccess.file_exists(backup_path()):
			DirAccess.remove_absolute(backup_path())
		err = DirAccess.rename_absolute(path(), backup_path())
		if err != OK:
			return err
	return DirAccess.rename_absolute(tmp, path())


func load_run() -> Result:
	var main := _read(path())
	if main.status == Status.OK or main.status == Status.TOO_NEW:
		return main
	if main.status == Status.CORRUPT:
		DirAccess.rename_absolute(path(), path() + ".corrupt")
	var backup := _read(backup_path())
	if backup.status == Status.OK:
		backup.from_backup = true
		backup.note = "Main save unreadable (%s); loaded the backup." % main.note
		return backup
	return main


func delete() -> void:
	for p: String in [path(), backup_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _read(file_path: String) -> Result:
	var r := Result.new()
	if not FileAccess.file_exists(file_path):
		r.status = Status.MISSING
		r.note = "no save at %s" % file_path
		return r
	var text := FileAccess.get_file_as_string(file_path)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		r.status = Status.IO_ERROR
		r.note = "could not read %s" % file_path
		return r
	# JSON.parse() reports failure through its return value; JSON.parse_string() would also print an
	# engine error, and a corrupt save is an expected, handled case.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not parsed is Dictionary:
		r.status = Status.CORRUPT
		r.note = "%s is not a valid save" % file_path.get_file()
		return r
	var run := RunState.from_dict(parsed)
	if run == null:
		r.status = Status.TOO_NEW
		r.note = "%s was written by a newer version of Undertow" % file_path.get_file()
		return r
	r.status = Status.OK
	r.run = run
	return r
