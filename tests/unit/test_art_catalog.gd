extends TestCase
## Imported art is a runtime dependency: bad crops or missing bindings fail before gameplay.

const COVERAGE := "res://assets/art/complete/coverage.json"

func test_every_frame_loads_and_stays_inside_its_source() -> void:
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ArtCatalog.MANIFEST))
	check(entries.size() > 100, "the complete painted collection")
	for key: String in entries:
		var frame := ArtCatalog.frame(key)
		check(frame != null, key + " loads")
		if frame == null:
			continue
		check(frame.region.has_area(), key + " has a nonempty crop")
		check(Rect2(Vector2.ZERO, frame.atlas.get_size()).encloses(frame.region), key + " is inside the PNG")
		check_eq(frame.texture.region, frame.region, key + " uses the reviewed crop")
		for anchor_id: String in frame.anchors:
			check(frame.region.has_point(frame.anchors[anchor_id]), key + "/" + anchor_id + " stays on the sprite")

func test_every_kind_and_owner_has_painted_art() -> void:
	var coverage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COVERAGE))
	for kind_name: String in LevelGrid.Floor:
		check(coverage.terrain.has(kind_name) or coverage.terrain_exceptions.has(kind_name), "terrain: " + kind_name)
	for kind_name: String in StaticProp.Kind:
		check(coverage.scenery.has(kind_name), "scenery: " + kind_name)
	for kind_name: String in BuildingCell.Facade:
		check(coverage.facades.has(kind_name), "facade: " + kind_name)
	for section: String in ["scenery", "facades", "owners"]:
		for owner_name: String in coverage[section]:
			var required: Array = coverage[section][owner_name]
			check(not required.is_empty(), owner_name + " requires art")
			for key: String in required:
				check(ArtCatalog.frame(key) != null, owner_name + ": " + key)
	for key: String in coverage.terrain.values():
		check(ArtCatalog.frame(key) != null, "terrain " + key)
	for kind: int in LevelGrid.Floor.values():
		if kind not in [LevelGrid.Floor.VOID, LevelGrid.Floor.BUILDING]:
			check(ArtCatalog.frame(ArtBindings.ground_key(kind, "vellum")) != null, "floor draw binding")
	for id: String in LevelCatalog.LEVELS.keys() + ["ark"]:
		var look := DistrictLook.for_district(id)
		check(look.wall_texture != null and look.roof_texture != null, id + " has building materials")
	check_eq(DistrictLook.for_district("hold_arena").district_id, "vellum", "test arenas share the documented default look")

func test_source_sprites_retain_real_transparency_and_mipmaps() -> void:
	var checked: Dictionary[String, bool] = {}
	var specs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/complete/specs.json"))
	for sheet: Dictionary in specs.sheets:
		var path: String = "res://assets/art/complete/%s.png" % sheet.name
		var recipe := ConfigFile.new()
		check_eq(recipe.load(path + ".import"), OK, path + " has an import recipe")
		check_eq(recipe.get_value("params", "mipmaps/generate", false), true, path + " generates mipmaps")
		if not sheet.transparent or checked.has(path):
			continue
		checked[path] = true
		var source := (load(path) as Texture2D).get_image()
		check(source.detect_alpha() != Image.ALPHA_NONE, path + " has an alpha channel")
		check_near(source.get_pixel(0, 0).a, 0.0, 0.005, path + " has a clear corner")


func test_runtime_joints_and_attachments_are_present() -> void:
	var coverage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COVERAGE))
	for key: String in coverage.required_anchors:
		var frame := ArtCatalog.frame(key)
		check(frame != null, key + " is required by an actor")
		if frame == null:
			continue
		for anchor_id: String in coverage.required_anchors[key]:
			check(frame.anchors.has(anchor_id), key + " requires " + anchor_id)
