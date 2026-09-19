shader_type canvas_item;
// Option 1 — CRT TV stack (nofacer / Asset Library CRT inspired).
// Scanlines, curvature, phosphor mask, rolling line, interference noise, subtle glitch.

#include "res://tools/visual_style/shaders/theme_post_fx.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int theme_mode = 0;
uniform float theme_strength : hint_range(0.0, 1.0) = 1.0;
uniform float curvature : hint_range(0.0, 0.25) = 0.09;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.14;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.32;
uniform float vignette : hint_range(0.0, 1.0) = 0.24;
uniform float chroma : hint_range(0.0, 0.01) = 0.003;
uniform float noise_amount : hint_range(0.0, 0.2) = 0.06;
uniform float interference : hint_range(0.0, 1.0) = 0.18;
uniform float roll_amount : hint_range(0.0, 1.0) = 0.35;
uniform float roll_speed : hint_range(-8.0, 8.0) = 2.4;
uniform float glitch_rate : hint_range(0.0, 12.0) = 4.5;
uniform float glitch_shift : hint_range(0.0, 0.02) = 0.006;
uniform float player_chroma : hint_range(0.0, 0.01) = 0.001;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 curve_uv(vec2 uv, float amount) {
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	return uv + c * r2 * amount;
}

float player_sprite_mask(vec3 rgb) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	float balance = 1.0 - abs(rgb.r - rgb.g) - abs(rgb.g - rgb.b);
	float white_body = smoothstep(0.32, 0.78, lum) * smoothstep(0.12, 0.45, balance);
	float shadow = smoothstep(0.02, 0.22, lum) * (1.0 - smoothstep(0.35, 0.55, lum));
	return clamp(max(white_body, shadow * 0.85), 0.0, 1.0);
}

void fragment() {
	vec2 uv_screen = SCREEN_UV;
	float t = TIME;
	vec3 src = texture(screen_texture, uv_screen).rgb;
	float p_chroma = player_sprite_mask(src);
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, uv_screen + vec2(chroma, 0.0)).rgb));
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, uv_screen - vec2(chroma, 0.0)).rgb));

	// Occasional horizontal glitch burst
	float burst_id = floor(t * glitch_rate);
	float burst_on = step(0.72, hash21(vec2(burst_id, 1.7)));
	float burst_y = hash21(vec2(burst_id, 9.3));
	float burst_band = burst_on * (1.0 - smoothstep(0.0, 0.035, abs(uv_screen.y - burst_y)));
	vec2 uv = uv_screen;
	uv.x += (hash21(vec2(burst_id, uv_screen.y * 120.0)) - 0.5) * glitch_shift * burst_band;

	uv = curve_uv(uv, curvature);

	vec3 col = vec3(0.0);
	float off = mix(chroma, player_chroma, p_chroma);
	vec2 uv_safe = clamp(uv, vec2(0.0), vec2(1.0));
	col.r = texture(screen_texture, clamp(uv + vec2(off, 0.0), vec2(0.0), vec2(1.0))).r;
	col.g = texture(screen_texture, uv_safe).g;
	col.b = texture(screen_texture, clamp(uv - vec2(off, 0.0), vec2(0.0), vec2(1.0))).b;

	// Animated scanlines
	float scan = sin((uv_safe.y + t * 0.04) * 820.0) * 0.5 + 0.5;
	col *= 1.0 - scan * scanline_strength;

	// Phosphor shadow mask
	float mask = sin(uv_safe.x * 920.0) * 0.5 + 0.5;
	col = mix(col, col * 0.86, mask * mask_strength);

	// Rolling bright line (old TV roll)
	float roll = fract(uv_safe.y * 0.5 + t * roll_speed * 0.08);
	float roll_line = smoothstep(0.92, 1.0, roll) * roll_amount;
	col += vec3(roll_line * 0.12, 0.0, 0.0);

	// Interference + white static grain
	float grain_t = floor(t * 18.0);
	float grain = hash21(uv_safe * 1400.0 + vec2(grain_t, grain_t * 0.37)) - 0.5;
	float interf = sin(uv_safe.y * 180.0 + t * 14.0) * 0.5 + 0.5;
	col += grain * noise_amount;
	col = mix(col, col * (0.85 + interf * 0.15), interference * 0.35);

	vec2 d = uv_safe - 0.5;
	float vig = 1.0 - dot(d, d) * vignette * 4.0;
	col *= vig;

	col = apply_theme_tint(col, theme_mode, theme_strength);
	COLOR = vec4(col, 1.0);
}
