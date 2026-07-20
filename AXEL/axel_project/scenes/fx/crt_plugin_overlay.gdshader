shader_type canvas_item;
// CRT post-pass (curvature, phosphor mask, vignette, chroma) — stacks above noir + scanline.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.25) = 0.08;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.12;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform float chroma : hint_range(0.0, 0.01) = 0.0025;
uniform float player_chroma : hint_range(0.0, 0.01) = 0.0002;
uniform float player_crt_reduction : hint_range(0.0, 1.0) = 0.33;
uniform float player_white_boost : hint_range(0.0, 1.0) = 0.8;

vec2 curve_uv(vec2 uv, float amount) {
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);
	return uv + c * r2 * amount;
}

// Overworld player uses white_sprite (balanced bright RGB); env is noir red/black.
float player_sprite_mask(vec3 rgb) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	float balance = 1.0 - abs(rgb.r - rgb.g) - abs(rgb.g - rgb.b);
	float white_body = smoothstep(0.42, 0.78, lum) * smoothstep(0.12, 0.45, balance);
	float shadow = smoothstep(0.02, 0.22, lum) * (1.0 - smoothstep(0.35, 0.55, lum));
	return clamp(max(white_body, shadow * 0.85), 0.0, 1.0);
}

float player_white_body_mask(vec3 rgb) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	float balance = 1.0 - abs(rgb.r - rgb.g) - abs(rgb.g - rgb.b);
	return smoothstep(0.42, 0.78, lum) * smoothstep(0.12, 0.45, balance);
}

void fragment() {
	vec2 uv_screen = SCREEN_UV;
	vec3 src = texture(screen_texture, uv_screen).rgb;
	float crt_mix = 1.0 - player_sprite_mask(src) * player_crt_reduction;

	// Curve can push UVs outside 0..1 at the bezel; clamp so edge pixels
	// fill that rim instead of painting black (keeps drawn lines to the screen edge).
	vec2 uv = clamp(curve_uv(uv_screen, curvature), vec2(0.0), vec2(1.0));
	float p_mask = player_sprite_mask(src);
	float p_chroma = p_mask;
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, uv_screen + vec2(chroma, 0.0)).rgb));
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, uv_screen - vec2(chroma, 0.0)).rgb));
	float off = mix(chroma, player_chroma, p_chroma);
	vec3 col;
	col.r = texture(screen_texture, clamp(uv + vec2(off, 0.0), vec2(0.0), vec2(1.0))).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, clamp(uv - vec2(off, 0.0), vec2(0.0), vec2(1.0))).b;
	float scan = sin(uv.y * 800.0) * 0.5 + 0.5;
	col *= 1.0 - scan * scanline_strength;
	float mask = sin(uv.x * 900.0) * 0.5 + 0.5;
	col = mix(col, col * 0.85, mask * mask_strength);
	vec2 d = uv - 0.5;
	float vig = 1.0 - dot(d, d) * vignette * 4.0;
	col *= vig;
	col = mix(src, col, crt_mix);
	float white_body = player_white_body_mask(src);
	col = mix(col, vec3(1.0), white_body * player_white_boost);
	COLOR = vec4(col, 1.0);
}
