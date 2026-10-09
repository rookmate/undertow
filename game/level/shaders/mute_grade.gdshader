// The muted grade: with the Steward's voice off the world drops to cold greys and ivory on near-black.
// Bright, saturated light keeps its colour: the old city's neon still burns and what you found still
// glows cyan. `amount` runs 0 (voice on) to 1 (muted).
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cold = vec3(0.86, 0.9, 0.96);

void fragment() {
	vec4 c = textureLod(screen_tex, SCREEN_UV, 0.0);
	float luma = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
	float hi = max(max(c.r, c.g), c.b);
	float lo = min(min(c.r, c.g), c.b);
	float sat = (hi - lo) / max(hi, 0.0001);
	float keep = smoothstep(0.45, 0.8, sat) * smoothstep(0.25, 0.6, hi);
	vec3 grey = vec3(luma) * cold;
	COLOR = vec4(mix(c.rgb, grey, amount * (1.0 - keep)), 1.0);
}
