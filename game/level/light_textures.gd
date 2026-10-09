class_name LightTextures
extends RefCounted
## Shared textures for PointLight2D. Light nodes are scaled by (1, Iso.SQUASH) so pools lie flat on
## the isometric ground.

static var _radial: Texture2D = null


static func radial() -> Texture2D:
	if _radial == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.42))
		g.add_point(0.7, Color(1, 1, 1, 0.08))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_radial = t
	return _radial
