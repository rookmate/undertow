shader_type canvas_item;
render_mode unshaded;

uniform vec4 deep_color : source_color;
uniform vec4 mist_color : source_color;
uniform vec2 camera_world;
uniform vec2 viewport_size;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float cloud(vec2 p) {
	return noise(p) * 0.58 + noise(p * 2.03 + 7.1) * 0.28 + noise(p * 4.07) * 0.14;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 screen = (uv - 0.5) * viewport_size;
	vec2 far_plane = (screen + camera_world * 0.18) / vec2(950.0, 410.0);
	vec2 near_plane = (screen + camera_world * 0.43) / vec2(640.0, 230.0);
	float far_mist = cloud(far_plane + vec2(TIME * 0.009, 0.0));
	float near_mist = cloud(near_plane - vec2(TIME * 0.017, TIME * 0.004));
	float density = smoothstep(0.2, 0.86, far_mist * 0.55 + near_mist * 0.45);
	float vignette = 1.0 - 0.24 * dot(uv - 0.5, uv - 0.5);
	COLOR = vec4(mix(deep_color.rgb, mist_color.rgb, density) * vignette, 1.0);
}
