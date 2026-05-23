shader_type canvas_item;
// Option 3 — Terminal CRT (luminance-preserving scanlines + phosphor + static).
// Best dark-scene readability; occasional tracking-line glitches.

#include "res://test/visual_style/shaders/theme_post_fx.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int theme_mode = 0;
uniform float theme_strength : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.2) = 0.05;
uniform float scan_strength : hint_range(0.0, 0.35) = 0.11;
uniform float phosphor : hint_range(0.0, 1.0) = 0.28;
uniform float noise_strength : hint_range(0.0, 0.15) = 0.045;
uniform float tracking_rate : hint_range(0.0, 8.0) = 3.2;
uniform float tracking_shift : hint_range(0.0, 0.015) = 0.004;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 curve_uv(vec2 uv, float amount) {
	vec2 c = uv - 0.5;
	return uv + c * dot(c, c) * amount;
}

void fragment() {
	vec2 uv_base = SCREEN_UV;
	float t = TIME;

	// Tracking-line glitch (horizontal band wobble)
	float track_id = floor(t * tracking_rate);
	float track_on = step(0.78, hash21(vec2(track_id, 4.2)));
	float track_y = hash21(vec2(track_id, 17.9));
	float track_mask = track_on * (1.0 - smoothstep(0.0, 0.025, abs(uv_base.y - track_y)));
	vec2 uv = uv_base;
	uv.x += (hash21(vec2(track_id, uv_base.y * 80.0)) - 0.5) * tracking_shift * track_mask;

	uv = curve_uv(uv, curvature);
	vec3 col = texture(screen_texture, uv).rgb;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));

	// Luminance-preserving animated scanlines
	float scan = sin((uv.y + t * 0.03) * 680.0) * 0.5 + 0.5;
	float factor = 1.0 - scan * scan_strength;
	vec3 scaled = col * factor;
	float lum2 = dot(scaled, vec3(0.299, 0.587, 0.114));
	if (lum2 > 0.001) {
		col = scaled * (lum / lum2);
	} else {
		col = scaled;
	}

	// RGB phosphor grille
	vec3 ph = vec3(
		sin(uv.x * 900.0) * 0.5 + 0.5,
		sin(uv.x * 900.0 + 2.094) * 0.5 + 0.5,
		sin(uv.x * 900.0 + 4.188) * 0.5 + 0.5
	);
	col = mix(col, col * ph, phosphor * 0.32);

	// Frame-stepped white noise (Pip-Boy terminal snow)
	float grain_t = floor(t * 20.0);
	float grain = hash21(uv * 1100.0 + vec2(grain_t, grain_t * 0.51)) - 0.5;
	col += grain * noise_strength;

	// Soft vignette
	vec2 d = uv - 0.5;
	col *= 1.0 - dot(d, d) * 0.35;

	col = apply_theme_tint(col, theme_mode, theme_strength);
	COLOR = vec4(col, 1.0);
}
