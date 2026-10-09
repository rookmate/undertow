extends TestCase
## Every script in the project must compile. Warnings are errors in this project (project.godot,
## [debug] gdscript/warnings), so this also catches new warnings.

const SKIP_DIRS: Array[String] = ["res://.godot", "res://port-city", "res://reports"]


func _walk(dir: String, out: PackedStringArray) -> void:
	if SKIP_DIRS.has(dir):
		return
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.get_extension() == "gd":
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		_walk(dir.path_join(sub) if dir != "res://" else "res://" + sub, out)


func test_all_scripts_compile() -> void:
	var scripts := PackedStringArray()
	_walk("res://", scripts)
	check(scripts.size() > 20, "found %d scripts" % scripts.size())
	for path: String in scripts:
		var s := load(path) as GDScript
		if s == null:
			fail("%s failed to load" % path)
		elif not s.can_instantiate():
			fail("%s does not compile" % path)
