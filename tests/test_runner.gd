extends Node
## Runs every tests/unit/test_*.gd and tests/integration/test_*.gd and exits 0 only if all pass.
##   godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn [-- --filter=save]
## With --fixed-fps every frame advances game time by 1/60 s as fast as the CPU allows, so tests that
## wait on game time run quicker than real time and deterministically.

const DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]
const SCRATCH_SAVES := "user://test_saves"
## Real time one test may take before the run is abandoned (a test awaiting something that never comes).
const TEST_TIMEOUT_MSEC := 120000

var _errors := ErrorLog.new()
var _running_test: String = ""
var _test_started_msec: int = 0


## Collects engine and script errors and warnings, so a test that hits one fails even when its checks
## pass (a script error aborts the function, which can skip the very checks that would have failed).
class ErrorLog:
	extends Logger
	var _lock := Mutex.new()
	var _lines: PackedStringArray = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var kind := "warning" if error_type == Logger.ERROR_TYPE_WARNING else "error"
		_lock.lock()
		_lines.append("%s: %s (%s:%d %s)" % [kind, rationale if rationale != "" else code, file, line, function])
		_lock.unlock()

	func take() -> PackedStringArray:
		_lock.lock()
		var out := _lines
		_lines = PackedStringArray()
		_lock.unlock()
		return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	OS.add_logger(_errors)
	SaveService.use_directory(SCRATCH_SAVES)
	_run.call_deferred()


func _process(_delta: float) -> void:
	if _running_test != "" and Time.get_ticks_msec() - _test_started_msec > TEST_TIMEOUT_MSEC:
		print("  FAIL  %s: still running after %.0f s" % [_running_test, TEST_TIMEOUT_MSEC / 1000.0])
		print("")
		print("RESULT: FAIL  %s timed out" % _running_test)
		Sound.quit(1)


func _run() -> void:
	var filter := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.get_slice("=", 1)
	var total := 0
	var failed_tests := 0
	var failures: PackedStringArray = []
	var matched_files := 0
	for dir: String in DIRS:
		if not DirAccess.dir_exists_absolute(dir):
			failures.append("test directory %s is missing" % dir)
			failed_tests += 1
			continue
		for file: String in _test_files(dir):
			if filter != "" and not file.contains(filter):
				continue
			matched_files += 1
			var script := load(dir.path_join(file)) as GDScript
			if script == null or not script.can_instantiate():
				failures.append("%s: failed to load" % file)
				failed_tests += 1
				continue
			var case := script.new() as TestCase
			if case == null:
				failures.append("%s: does not extend TestCase" % file)
				failed_tests += 1
				continue
			add_child(case)
			var seen: Dictionary[String, bool] = {}
			for method: Dictionary in script.get_script_method_list():
				var method_name: String = method["name"]
				if not method_name.begins_with("test_") or seen.has(method_name):
					continue
				seen[method_name] = true
				total += 1
				case.current_test = "%s::%s" % [file.get_basename(), method_name]
				_running_test = case.current_test
				_test_started_msec = Time.get_ticks_msec()
				_errors.take()
				await case.call(&"before_each")
				await case.call(method_name)
				await case.call(&"after_each")
				_running_test = ""
				# One test's leftovers (a pause, slowed time, an open screen) must not hang or skew the next.
				_reset_engine_state()
				var found := case.take_failures()
				for logged: String in _errors.take():
					found.append("%s: %s" % [case.current_test, logged])
				if found.is_empty():
					print("  ok    ", case.current_test)
				else:
					failed_tests += 1
					for line: String in found:
						print("  FAIL  ", line)
					failures.append_array(found)
			case.queue_free()
			await get_tree().process_frame
	_reset_engine_state()
	# Running nothing is not passing: a renamed folder or a filter that matches nothing must fail.
	if total == 0:
		failed_tests += 1
		failures.append("no tests ran (%s)" % ("filter '%s' matched nothing" % filter if filter != "" else "no test files found"))
	if filter != "" and matched_files == 0:
		failures.append("filter '%s' matched no test files" % filter)
	print("")
	if failed_tests == 0:
		print("RESULT: PASS  %d tests" % total)
	else:
		print("RESULT: FAIL  %d of %d tests failed" % [failed_tests, total])
		for line: String in failures:
			print("  - ", line)
	OS.remove_logger(_errors)
	Sound.quit(0 if failed_tests == 0 else 1)


func _reset_engine_state() -> void:
	Engine.time_scale = 1.0
	Modals.clear()
	get_tree().paused = false


func _test_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			out.append(f)
	out.sort()
	return out
