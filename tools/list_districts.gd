extends SceneTree
## Prints the ids of every playable district, one per line (for tools/check.sh's district tours).


func _initialize() -> void:
	for id: String in LevelCatalog.LEVELS:
		print("DISTRICT ", id)
	quit()
