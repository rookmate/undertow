extends SceneTree
## Native atlas review: godot --disable-vsync --path . --script res://tools/art_gallery.gd
## -- --art-shots=/absolute/output/folder. Original PNGs are never modified.

class Gallery extends Control:
	var frames: Array[String] = []
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.GREY_DEEP)
		for i: int in frames.size():
			var at := Vector2(i % 5, floori(i / 5.0)) * Vector2(384, 360)
			ArtCatalog.fit(self, frames[i], Rect2(at + Vector2(22, 14), Vector2(340, 302)))
			draw_string(UiFonts.mono_medium(), at + Vector2(20, 343), frames[i], HORIZONTAL_ALIGNMENT_LEFT, 345, 18, Palette.IVORY)

var gallery: Gallery
var output: String = "res://reports/art-complete/gallery"

func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--art-shots="):
			output = arg.trim_prefix("--art-shots=")
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Art gallery requires a rendering display")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	gallery = Gallery.new()
	gallery.size = Vector2(1920, 1080)
	root.add_child(gallery)
	DirAccess.make_dir_recursive_absolute(output)
	var keys := ArtCatalog.keys()
	for page: int in ceili(keys.size() / 15.0):
		gallery.frames.clear()
		for i: int in range(page * 15, mini((page + 1) * 15, keys.size())):
			gallery.frames.append(keys[i])
		gallery.queue_redraw()
		await _capture("atlas_%02d" % page)
	gallery.frames.clear()
	gallery.queue_redraw()
	var screen_kinds: Array[StaticProp.Kind] = [StaticProp.Kind.KIOSK, StaticProp.Kind.DESK, StaticProp.Kind.NEWS_DESK]
	for i: int in screen_kinds.size():
		var prop := StaticProp.new()
		prop.setup(Vector2i.ZERO, screen_kinds[i])
		prop.position = Vector2(330 + i * 630, 820)
		prop.scale = Vector2(5, 5)
		gallery.add_child(prop)
	await _capture("screen_afterimages")
	print("ART GALLERY PASS: %d frames" % keys.size())
	quit()


func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if root.use_hdr_2d:
		capture = Screenshot.linear_to_srgb(capture, 1920)
	var result := capture.save_png(output.path_join(label + ".png"))
	if result != OK:
		push_error("Art gallery capture failed: %s" % result)
		quit(1)
