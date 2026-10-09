class_name Screenshot
extends RefCounted
## With HDR 2D on, the viewport texture holds linear-light floats; the screen shows them after an sRGB
## conversion. Image.linear_to_srgb() only accepts 8-bit images, and quantising linear data to 8 bits
## first bands the dark scenes badly, so the conversion is done here in float.

static func linear_to_srgb(source: Image, max_width: int = 0) -> Image:
	var img := source.duplicate() as Image
	if max_width > 0 and img.get_width() > max_width:
		var h := roundi(img.get_height() * float(max_width) / img.get_width())
		img.resize(max_width, h, Image.INTERPOLATE_BILINEAR)
	img.convert(Image.FORMAT_RGBAF)
	var data := img.get_data().to_float32_array()
	var i := 0
	var n := data.size()
	while i < n:
		data[i] = _encode(data[i])
		data[i + 1] = _encode(data[i + 1])
		data[i + 2] = _encode(data[i + 2])
		i += 4
	var out := Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBAF, data.to_byte_array())
	out.convert(Image.FORMAT_RGBA8)
	return out


static func _encode(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	if v <= 0.0031308:
		return v * 12.92
	return 1.055 * pow(v, 1.0 / 2.4) - 0.055
