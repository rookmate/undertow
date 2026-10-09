class_name Rain
extends CPUParticles2D
## "Rain on all of it" (art direction, the Quiet stratum). Thin slanted streaks over an area.

static var _streak: Texture2D = null


func setup(area: Rect2, density: float = 1.0) -> void:
	# Position first: with world-space particles, warm-up emission happens wherever the node is now.
	position = Vector2(area.position.x + area.size.x * 0.5, area.position.y - 40.0)
	texture = _streak_texture()
	amount = maxi(16, int(area.size.x * area.size.y / 4200.0 * density))
	lifetime = 0.7
	preprocess = 0.7
	emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(area.size.x * 0.6, 8.0)
	direction = Vector2(0.16, 1.0)
	spread = 2.0
	gravity = Vector2.ZERO
	initial_velocity_min = area.size.y * 1.35
	initial_velocity_max = area.size.y * 1.7
	particle_flag_align_y = true
	scale_amount_min = 0.6
	scale_amount_max = 1.2
	color = Color(Palette.FOG, 0.22)
	local_coords = false
	restart()


static func _streak_texture() -> Texture2D:
	if _streak == null:
		var img := Image.create(2, 28, false, Image.FORMAT_RGBA8)
		for y: int in 28:
			var a := sin(PI * y / 27.0)
			img.set_pixel(0, y, Color(1, 1, 1, a))
			img.set_pixel(1, y, Color(1, 1, 1, a * 0.5))
		_streak = ImageTexture.create_from_image(img)
	return _streak
