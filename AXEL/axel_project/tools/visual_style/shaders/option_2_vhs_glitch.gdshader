shader_type canvas_item;


#include "res://tools/visual_style/shaders/theme_post_fx.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform int theme_mode = 0;
uniform float theme_strength : hint_range(0.0, 1.0) = 1.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.55;
uniform float glitch_frequency : hint_range(0.1, 10.0) = 2.8;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.28;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.22;
uniform float slice_intensity : hint_range(0.0, 1.0) = 0.42;
uniform float red_displacement : hint_range(0.0, 0.05) = 0.014;
uniform float green_displacement : hint_range(0.0, 0.05) = 0.012;
uniform float blue_displacement : hint_range(0.0, 0.05) = 0.016;
uniform float ghost_intensity : hint_range(0.0, 0.5) = 0.08;

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 col = texture(screen_texture, uv).rgb;

	float glitch_time = TIME * glitch_frequency;
	float glitch_noise = noise(vec2(glitch_time, 0.0));
	float glitch_active = step(1.0 - intensity, glitch_noise);

	if (glitch_active > 0.5) {
		float slice_y = random(vec2(glitch_time * 10.0, 0.0));
		if (abs(uv.y - slice_y) < 0.02 * slice_intensity) {
			float slice_offset = (random(vec2(glitch_time * 15.0, 0.0)) - 0.5) * 0.1 * slice_intensity;
			uv.x += slice_offset;
		}
		float vertical_shift = random(vec2(glitch_time * 8.0, 0.0)) * 0.04 * intensity;
		uv.y += vertical_shift;
		float wave = sin(uv.y * 100.0 + glitch_time * 5.0) * 0.012 * intensity;
		uv.x += wave;
		col = texture(screen_texture, uv).rgb;
	}

	float shift = glitch_active;
	col.r = mix(col.r, texture(screen_texture, uv + vec2(red_displacement * shift, 0.0)).r, shift);
	col.g = mix(col.g, texture(screen_texture, uv + vec2(-green_displacement * shift, 0.0)).g, shift);
	col.b = mix(col.b, texture(screen_texture, uv + vec2(blue_displacement * shift, 0.0)).b, shift);

	float scanline = sin(uv.y * 320.0 + glitch_time * 2.0) * 0.5 + 0.5;
	col *= 1.0 - scanline * scanline_intensity;


	float static_noise = random(uv + floor(TIME * 24.0)) - 0.5;
	col += static_noise * noise_intensity * (0.35 + glitch_active * 0.65);

	if (ghost_intensity > 0.0) {
		vec3 ghost = texture(screen_texture, uv + vec2(0.008, 0.008)).rgb;
		col = mix(col, ghost, ghost_intensity * 0.45 * (0.5 + glitch_active * 0.5));
	}

	col = apply_theme_tint(col, theme_mode, theme_strength);
	COLOR = vec4(col, 1.0);
}
