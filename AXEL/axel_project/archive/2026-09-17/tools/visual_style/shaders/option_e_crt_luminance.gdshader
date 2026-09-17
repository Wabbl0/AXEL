shader_type canvas_item;
// E: CRT with luminance-preserving scanlines + subtle curvature.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.2) = 0.06;
uniform float scan_strength : hint_range(0.0, 0.35) = 0.1;
uniform float phosphor : hint_range(0.0, 1.0) = 0.25;

vec2 curve_uv(vec2 uv) {
	vec2 c = uv - 0.5;
	return uv + c * dot(c, c) * curvature;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);
	vec3 col = texture(screen_texture, uv).rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float scan = sin(uv.y * 650.0) * 0.5 + 0.5;
	float factor = 1.0 - scan * scan_strength;
	vec3 scaled = col * factor;
	float lum2 = dot(scaled, vec3(0.299, 0.587, 0.114));
	if (lum2 > 0.001) {
		col = scaled * (lum / lum2);
	} else {
		col = scaled;
	}
	vec3 ph = vec3(
		sin(uv.x * 900.0) * 0.5 + 0.5,
		sin(uv.x * 900.0 + 2.094) * 0.5 + 0.5,
		sin(uv.x * 900.0 + 4.188) * 0.5 + 0.5
	);
	col = mix(col, col * ph, phosphor * 0.35);
	COLOR = vec4(col, 1.0);
}
