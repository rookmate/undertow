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


## Writes the run. The new save only replaces the old one after it has been written, flushed and read
## back intact, so a full disk or a short write can never cost the player their last good save. The
## previous save becomes the backup only if it is itself readable; a corrupt main file is never rotated
## over a good backup.
func save(run: RunState) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK:
		return err
	var text := JSON.stringify(run.to_dict(), "\t")
	var tmp := path() + ".tmp"
	err = _write_text(tmp, text)
	if err == OK and FileAccess.get_file_as_string(tmp) != text:
		err = ERR_FILE_CORRUPT
	if err != OK:
		_discard(tmp)
		return err
	if FileAccess.file_exists(path()) and _read(path()).status == Status.OK:
		_discard(backup_path())
		err = DirAccess.rename_absolute(path(), backup_path())
		if err != OK:
			_discard(tmp)
			return err
	else:
		_discard(path())
	err = DirAccess.rename_absolute(tmp, path())
	if err != OK and not FileAccess.file_exists(path()) and FileAccess.file_exists(backup_path()):
		# Put the last good save back where Continue looks for it.
		DirAccess.copy_absolute(backup_path(), path())
	return err


## The one place bytes hit the disk (tests override it to simulate failing writes).
func _write_text(file_path: String, text: String) -> Error:
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.flush()
	var err := f.get_error()
	f.close()
	return err


static func _discard(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)


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
