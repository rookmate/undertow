shader_type canvas_item;
// Down in a descent: dark everywhere but round your hand lamp. Screen space; centre and radius in
// pixels of the visible rect (res).
uniform float amount = 0.0;
uniform vec2 center_uv = vec2(0.5, 0.5);
uniform vec2 res = vec2(1920.0, 1080.0);
uniform float radius = 240.0;
uniform float softness = 260.0;
uniform vec4 dark : source_color = vec4(0.01, 0.012, 0.02, 1.0);

void fragment() {
	float d = distance(SCREEN_UV * res, center_uv * res);
	float k = smoothstep(radius, radius + softness, d);
	COLOR = vec4(dark.rgb, dark.a * amount * mix(0.2, 0.93, k));
}
