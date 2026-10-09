class_name RingPainter
extends RefCounted
## Draws the Steward's ring to match port-city/11-ring-reference.png, the canonical geometry for every
## in-game ring: a thick filigree band with its gap at the upper right, curled ends, outer ticks, a
## thin inner ring with cardinal dots, a four-petal inlay and a bright centre.
## Sizes are fractions of R, the band's outer radius. Angles are clock angles in degrees
## (0 = 12 o'clock, clockwise), converted with clock_to_rad().

## Everything that varies between ring states.
class Look:
	var color: Color = Palette.STEWARD_GOLD
	## Multiplies the colour's RGB; > 1 blooms when the canvas has HDR glow.
	var hdr: float = 1.0
	var alpha: float = 1.0
	## Muted variant (title and HUD): outlines only, no fill, no filigree.
	var thin: bool = false
	var show_center: bool = true
	var show_inlay: bool = true
	var show_ticks: bool = true
	var show_filigree: bool = true
	## Withholding: the inlay sits 3° off centre. The only tell.
	var inlay_rotation_deg: float = 0.0
	var petal_fill: float = 0.16
	## Speaking: the inner ring breaks into this many turning segments.
	var inner_segments: int = 0
	var segment_phase: float = 0.0
	## Glitch: the band tears into offset chunks. -1 = intact.
	var tear_seed: int = -1
	## Off: an unlit scorch mark.
	var scorch: bool = false
	## Rewrite: the gap is filled in this colour (transparent = open).
	var gap_fill: Color = Color(0, 0, 0, 0)
	## Soft fake bloom drawn as wide faint strokes, for canvases without HDR glow.
	var halo: float = 1.0

const GAP_CENTER := 45.0
const GAP_HALF := 20.0
const BAND_THICK := 0.23
const BAND_THIN := 0.13
const INNER_RING := 0.47
const PETAL_BASE := 0.055
const PETAL_TIP := 0.36
const PETAL_HALF_W := 0.088
const TICK_IN := 1.07
const SCROLL_LEN := 0.24
const BAND_STEPS := 180
## Below this radius (px) the leaves become noise; small rings draw the vine only.
const SMALL_RING := 70.0
## Furthest extent of anything drawn, in R. Containers use it to size the ring.
const EXTENT := 1.28


static func clock_to_rad(clock_deg: float) -> float:
	return deg_to_rad(clock_deg - 90.0)


## Clock angles where the band starts and ends, going clockwise. The gap lies between end and start.
static func band_start_deg() -> float:
	return GAP_CENTER + GAP_HALF


static func band_end_deg() -> float:
	return GAP_CENTER - GAP_HALF + 360.0


## Band thickness (in R) at fraction u along the band: thickest opposite the gap, like a crescent.
static func band_thickness(u: float) -> float:
	return BAND_THIN + (BAND_THICK - BAND_THIN) * pow(sin(PI * clampf(u, 0.0, 1.0)), 0.9)


static func paint(ci: CanvasItem, c: Vector2, r: float, look: Look) -> void:
	var line := _shade(look.color, look.hdr, look.alpha)
	if look.scorch:
		_paint_scorch(ci, c, r, look)
		return
	if look.thin:
		line = Color(look.color, look.alpha * 0.8)
	if look.halo > 0.0 and not look.thin:
		_paint_halo(ci, c, r, look)
	if look.show_ticks:
		_paint_ticks(ci, c, r, line, look)
	_paint_band(ci, c, r, line, look)
	if look.gap_fill.a > 0.0:
		_paint_gap_fill(ci, c, r, look)
	if look.show_inlay:
		_paint_inlay(ci, c, r, line, look)
	if look.show_center and not look.thin:
		_paint_center(ci, c, r, look)


static func _shade(col: Color, hdr: float, alpha: float) -> Color:
	return Color(col.r * hdr, col.g * hdr, col.b * hdr, col.a * alpha)


static func _polar(c: Vector2, radius: float, clock_deg: float) -> Vector2:
	return c + Vector2.from_angle(clock_to_rad(clock_deg)) * radius


# --- Band -------------------------------------------------------------------------------------------
static func _paint_band(ci: CanvasItem, c: Vector2, r: float, line: Color, look: Look) -> void:
	var chunks: Array[Vector2] = [Vector2(0.0, 1.0)]
	var rng := RandomNumberGenerator.new()
	if look.tear_seed >= 0:
		rng.seed = look.tear_seed
		chunks = []
		var u := 0.0
		while u < 1.0:
			var next := minf(1.0, u + rng.randf_range(0.12, 0.32))
			chunks.append(Vector2(u, next))
			u = next + rng.randf_range(0.01, 0.035)
	for chunk: Vector2 in chunks:
		var jitter := Vector2.ZERO
		if look.tear_seed >= 0:
			jitter = Vector2(rng.randf_range(-0.025, 0.025), rng.randf_range(-0.015, 0.015)) * r
		_paint_band_chunk(ci, c + jitter, r, chunk.x, chunk.y, line, look)
	if look.tear_seed < 0:
		_paint_scroll(ci, c, r, 0.0, -1.0, line, look)
		_paint_scroll(ci, c, r, 1.0, 1.0, line, look)


static func _paint_band_chunk(ci: CanvasItem, c: Vector2, r: float, u0: float, u1: float, line: Color, look: Look) -> void:
	var a0 := band_start_deg()
	var a1 := band_end_deg()
	var steps := maxi(4, int(BAND_STEPS * (u1 - u0)))
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var outer_in := PackedVector2Array()
	var inner_in := PackedVector2Array()
	for i: int in steps + 1:
		var u := lerpf(u0, u1, float(i) / steps)
		var a := lerpf(a0, a1, u)
		var t := band_thickness(u)
		outer.append(_polar(c, r, a))
		inner.append(_polar(c, r * (1.0 - t), a))
		outer_in.append(_polar(c, r * (1.0 - 0.032), a))
		inner_in.append(_polar(c, r * (1.0 - t + 0.032), a))
	if not look.thin:
		var fill := PackedVector2Array(outer)
		var rev := inner.duplicate()
		rev.reverse()
		fill.append_array(rev)
		ci.draw_colored_polygon(fill, Color(line, line.a * 0.28))
	ci.draw_polyline(outer, line, maxf(1.0, r * (0.006 if look.thin else 0.014)), true)
	ci.draw_polyline(inner, line, maxf(1.0, r * (0.005 if look.thin else 0.01)), true)
	if look.thin:
		return
	ci.draw_polyline(outer_in, Color(line, line.a * 0.55), maxf(1.0, r * 0.005), true)
	ci.draw_polyline(inner_in, Color(line, line.a * 0.55), maxf(1.0, r * 0.005), true)
	if look.show_filigree:
		_paint_filigree(ci, c, r, u0, u1, line, r >= SMALL_RING)


## A vine running along the band with leaves at its crests: the "thick filigree" of the reference.
static func _paint_filigree(ci: CanvasItem, c: Vector2, r: float, u0: float, u1: float, line: Color, leaves: bool) -> void:
	const WAVES := 13.0
	var a0 := band_start_deg()
	var a1 := band_end_deg()
	var vine := PackedVector2Array()
	var steps := maxi(4, int(BAND_STEPS * 1.5 * (u1 - u0)))
	for i: int in steps + 1:
		var u := lerpf(u0, u1, float(i) / steps)
		vine.append(_vine_point(c, r, u, a0, a1, WAVES))
	ci.draw_polyline(vine, Color(line, line.a * 0.75), maxf(1.0, r * 0.006), true)
	if not leaves:
		return
	var leaf_col := Color(line, line.a * 0.4)
	var k := 0
	while true:
		var u := (k + 0.5) / (WAVES * 2.0)
		k += 1
		if u > 1.0:
			break
		if u < u0 or u > u1 or u < 0.03 or u > 0.97:
			continue
		var p := _vine_point(c, r, u, a0, a1, WAVES)
		var ahead := _vine_point(c, r, minf(1.0, u + 0.004), a0, a1, WAVES)
		var tangent := (ahead - p).normalized()
		var side := 1.0 if k % 2 == 0 else -1.0
		var dir := tangent.rotated(side * 0.75)
		var t := band_thickness(u)
		_leaf(ci, p, dir, r * t * 0.55, r * t * 0.2, leaf_col, line, r)
		var curl_dir := tangent.rotated(-side * 0.9)
		ci.draw_arc(p + curl_dir * r * t * 0.22, r * t * 0.1, curl_dir.angle(), curl_dir.angle() + side * 4.2, 10, Color(line, line.a * 0.6), maxf(1.0, r * 0.004), true)


static func _vine_point(c: Vector2, r: float, u: float, a0: float, a1: float, waves: float) -> Vector2:
	var t := band_thickness(u)
	var mid := 1.0 - t * 0.5
	var radius := mid + sin(u * TAU * waves) * t * 0.24
	return _polar(c, r * radius, lerpf(a0, a1, u))


static func _leaf(ci: CanvasItem, base: Vector2, dir: Vector2, length: float, half_width: float, fill: Color, line: Color, r: float) -> void:
	var pts := PackedVector2Array()
	var normal := dir.orthogonal()
	const N := 10
	for i: int in N + 1:
		var s := float(i) / N
		pts.append(base + dir * length * s + normal * half_width * sin(PI * s))
	for i: int in range(N - 1, 0, -1):
		var s := float(i) / N
		pts.append(base + dir * length * s - normal * half_width * sin(PI * s))
	ci.draw_colored_polygon(pts, fill)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, Color(line, line.a * 0.7), maxf(1.0, r * 0.004), true)


## The nouveau scroll at each end of the band: a tapering ribbon that runs into the gap and curls
## toward the centre. `u` is 0 (band start) or 1 (band end); `travel` is the clock direction it runs.
static func _paint_scroll(ci: CanvasItem, c: Vector2, r: float, u: float, travel: float, line: Color, look: Look) -> void:
	var a := lerpf(band_start_deg(), band_end_deg(), u)
	var t := band_thickness(u)
	var p := _polar(c, r * (1.0 - t * 0.5), a)
	var heading := Vector2.from_angle(clock_to_rad(a) + travel * PI * 0.5)
	const STEPS := 44
	var length := SCROLL_LEN * r
	var ds := length / STEPS
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var spine := PackedVector2Array()
	for i: int in STEPS + 1:
		var s := float(i) / STEPS
		var curvature := (1.0 / r) * (1.0 + 54.0 * pow(s, 1.6))
		# Never wider than the curl's radius, so the ribbon's inner edge can't fold over itself.
		var half := minf(lerpf(t * 0.5, 0.012, pow(s, 0.8)) * r, 0.8 / curvature)
		var normal := heading.orthogonal()
		left.append(p + normal * half)
		right.append(p - normal * half)
		spine.append(p)
		heading = heading.rotated(travel * curvature * ds)
		p += heading * ds
	if not look.thin:
		# Quads drawn one by one: no triangulation, so a tight curl can't produce an invalid polygon.
		var fill := Color(line, line.a * 0.28)
		var quad_colors := PackedColorArray([fill, fill, fill, fill])
		for i: int in STEPS:
			ci.draw_primitive(PackedVector2Array([left[i], left[i + 1], right[i + 1], right[i]]), quad_colors, PackedVector2Array())
	ci.draw_polyline(left, line, maxf(1.0, r * (0.006 if look.thin else 0.012)), true)
	ci.draw_polyline(right, line, maxf(1.0, r * (0.005 if look.thin else 0.009)), true)
	if not look.thin:
		ci.draw_polyline(spine, Color(line, line.a * 0.55), maxf(1.0, r * 0.005), true)
		ci.draw_circle(spine[spine.size() - 1], r * 0.016, line, true, -1.0, true)


# --- Ticks, inlay, centre -------------------------------------------------------------------------
static func _paint_ticks(ci: CanvasItem, c: Vector2, r: float, line: Color, look: Look) -> void:
	var tick_col := Color(line, line.a * (0.4 if look.thin else 0.85))
	var deg := 0
	while deg < 360:
		var length := 0.035
		var width := 0.007
		if deg == 0 or deg == 180:
			length = 0.2
			width = 0.012
		elif deg % 30 == 0:
			length = 0.075
			width = 0.009
		var from := _polar(c, r * TICK_IN, deg)
		var to := _polar(c, r * (TICK_IN + length), deg)
		ci.draw_line(from, to, tick_col, maxf(1.0, r * width), true)
		deg += 6


static func _paint_inlay(ci: CanvasItem, c: Vector2, r: float, line: Color, look: Look) -> void:
	var rot := look.inlay_rotation_deg
	var ring_col := Color(line, line.a * (0.6 if look.thin else 0.95))
	var radius := r * INNER_RING
	var width := maxf(1.0, r * 0.008)
	if look.inner_segments > 0:
		var seg := TAU / look.inner_segments
		for i: int in look.inner_segments:
			var start := clock_to_rad(rot) + look.segment_phase + i * seg
			ci.draw_arc(c, radius, start, start + seg * 0.72, 16, ring_col, width * 1.4, true)
	else:
		ci.draw_arc(c, radius, 0.0, TAU, 96, ring_col, width, true)
	for k: int in 4:
		var a := rot + k * 90.0
		ci.draw_line(_polar(c, r * 0.06, a), _polar(c, radius, a), Color(line, line.a * 0.55), maxf(1.0, r * 0.004), true)
		if not look.thin:
			ci.draw_circle(_polar(c, radius, a), r * 0.016, line, true, -1.0, true)
			ci.draw_circle(_polar(c, r * (INNER_RING + 0.05), a), r * 0.008, Color(line, line.a * 0.8), true, -1.0, true)
		_petal(ci, c, r, a, line, look)


static func _petal(ci: CanvasItem, c: Vector2, r: float, clock_deg: float, line: Color, look: Look) -> void:
	var dir := Vector2.from_angle(clock_to_rad(clock_deg))
	var normal := dir.orthogonal()
	const N := 14
	var pts := PackedVector2Array()
	for i: int in N + 1:
		var s := float(i) / N
		var along := lerpf(PETAL_BASE, PETAL_TIP, s) * r
		var half := PETAL_HALF_W * r * pow(sin(PI * pow(s, 0.85)), 0.9)
		pts.append(c + dir * along + normal * half)
	for i: int in range(N - 1, 0, -1):
		var s := float(i) / N
		var along := lerpf(PETAL_BASE, PETAL_TIP, s) * r
		var half := PETAL_HALF_W * r * pow(sin(PI * pow(s, 0.85)), 0.9)
		pts.append(c + dir * along - normal * half)
	if not look.thin:
		ci.draw_colored_polygon(pts, Color(line, line.a * look.petal_fill))
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, Color(line, line.a * (0.5 if look.thin else 0.95)), maxf(1.0, r * 0.007), true)
	if not look.thin:
		ci.draw_line(c + dir * PETAL_BASE * r, c + dir * PETAL_TIP * r * 0.92, Color(line, line.a * 0.5), maxf(1.0, r * 0.004), true)


static func _paint_center(ci: CanvasItem, c: Vector2, r: float, look: Look) -> void:
	var hot := _shade(look.color.lightened(0.55), look.hdr * 1.25, look.alpha)
	ci.draw_circle(c, r * 0.13, Color(look.color, look.alpha * 0.07), true, -1.0, true)
	ci.draw_circle(c, r * 0.075, Color(look.color, look.alpha * 0.2), true, -1.0, true)
	ci.draw_circle(c, r * 0.04, hot, true, -1.0, true)


static func _paint_halo(ci: CanvasItem, c: Vector2, r: float, look: Look) -> void:
	var a0 := band_start_deg()
	var a1 := band_end_deg()
	var mid := PackedVector2Array()
	for i: int in BAND_STEPS + 1:
		var u := float(i) / BAND_STEPS
		mid.append(_polar(c, r * (1.0 - band_thickness(u) * 0.5), lerpf(a0, a1, u)))
	for layer: Vector2 in [Vector2(0.36, 0.015), Vector2(0.27, 0.025), Vector2(0.2, 0.04)]:
		ci.draw_polyline(mid, Color(look.color, look.alpha * layer.y * look.halo), r * layer.x, true)


static func _paint_gap_fill(ci: CanvasItem, c: Vector2, r: float, look: Look) -> void:
	var a0 := band_end_deg() - 360.0
	var a1 := band_start_deg()
	var pts := PackedVector2Array()
	for i: int in 25:
		pts.append(_polar(c, r * (1.0 - BAND_THIN * 0.5), lerpf(a0, a1, i / 24.0)))
	ci.draw_polyline(pts, Color(look.gap_fill, look.alpha), r * BAND_THIN, true)


static func _paint_scorch(ci: CanvasItem, c: Vector2, r: float, look: Look) -> void:
	var scorch := Color(Palette.SCORCH, 0.85 * look.alpha)
	var a0 := band_start_deg()
	var a1 := band_end_deg()
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i: int in BAND_STEPS + 1:
		var u := float(i) / BAND_STEPS
		var a := lerpf(a0, a1, u)
		outer.append(_polar(c, r * 1.02, a))
		inner.append(_polar(c, r * (1.0 - band_thickness(u) * 1.1), a))
	var poly := PackedVector2Array(outer)
	var rev := inner.duplicate()
	rev.reverse()
	poly.append_array(rev)
	ci.draw_colored_polygon(poly, scorch)
	ci.draw_polyline(outer, Color(Palette.GREY_DEEP, 0.5 * look.alpha), maxf(1.0, r * 0.006), true)
