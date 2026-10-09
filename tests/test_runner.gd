extends Node
## Runs every tests/unit/test_*.gd and tests/integration/test_*.gd and exits 0 only if all pass.
##   godot --headless --fixed-fps 60 --path . res://tests/test_runner.tscn [-- --filter=save]
## With --fixed-fps every frame advances game time by 1/60 s as fast as the CPU allows, so tests that
## wait on game time run quicker than real time and deterministically.

const DIRS: Array[String] = ["res://tests/unit", "res://tests/integration"]
const SCRATCH_SAVES := "user://test_saves"


func _ready() -> void:
	SaveService.use_directory(SCRATCH_SAVES)
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.get_slice("=", 1)
	var total := 0
	var failed_tests := 0
	var failures: PackedStringArray = []
	for dir: String in DIRS:
		for file: String in _test_files(dir):
			if filter != "" and not file.contains(filter):
				continue
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
				await case.call(&"before_each")
				await case.call(method_name)
				await case.call(&"after_each")
				var found := case.take_failures()
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
	print("")
	if failed_tests == 0:
		print("RESULT: PASS  %d tests" % total)
	else:
		print("RESULT: FAIL  %d of %d tests failed" % [failed_tests, total])
		for line: String in failures:
			print("  - ", line)
	get_tree().quit(0 if failed_tests == 0 else 1)


func _reset_engine_state() -> void:
	Engine.time_scale = 1.0
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
