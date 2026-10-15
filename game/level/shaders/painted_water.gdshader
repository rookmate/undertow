shader_type canvas_item;

uniform vec4 source_region;
varying vec2 world_position;
varying vec4 vertex_tint;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	vertex_tint = COLOR;
}

void fragment() {
	vec2 local_uv = (UV - source_region.xy) / source_region.zw;
	vec2 ripple = vec2(sin(world_position.y * 0.021 + TIME * 0.65),
		cos(world_position.x * 0.017 - TIME * 0.47)) * 0.006;
	// Keep every sample inside the water painting's atlas region.
	vec2 uv = source_region.xy + fract(local_uv + ripple) * source_region.zw;
	float light = 0.96 + 0.04 * sin(world_position.x * 0.025 + world_position.y * 0.04 + TIME * 0.8);
	COLOR = texture(TEXTURE, uv) * vertex_tint * vec4(vec3(light), 1.0);
}
