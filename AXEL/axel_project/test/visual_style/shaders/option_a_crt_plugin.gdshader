shader_type canvas_item;
// Test-only approximation of nofacer CRT plugin (curvature, mask, vignette, chroma).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.25) = 0.08;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.12;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform float chroma : hint_range(0.0, 0.01) = 0.0025;

vec2 curve_uv(vec2 uv, float amount) {
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	return uv + c * r2 * amount;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV, curvature);
	vec3 col = vec3(0.0);
	if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
		float off = chroma;
		col.r = texture(screen_texture, uv + vec2(off, 0.0)).r;
		col.g = texture(screen_texture, uv).g;
		col.b = texture(screen_texture, uv - vec2(off, 0.0)).b;
		float scan = sin(uv.y * 800.0) * 0.5 + 0.5;
		col *= 1.0 - scan * scanline_strength;
		float mask = sin(uv.x * 900.0) * 0.5 + 0.5;
		col = mix(col, col * 0.85, mask * mask_strength);
		vec2 d = uv - 0.5;
		float vig = 1.0 - dot(d, d) * vignette * 4.0;
		col *= vig;
	}
	COLOR = vec4(col, 1.0);
}
