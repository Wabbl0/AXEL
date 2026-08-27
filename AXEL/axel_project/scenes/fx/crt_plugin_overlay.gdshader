shader_type canvas_item;
// CRT post-pass (curvature, phosphor mask, vignette, chroma) — stacks above noir + scanline.
// Geometry/darkening knobs are inert at 0.0 so the same shader serves round overworld TV and flat combat.
// Built-ins (SCREEN_UV / SCREEN_PIXEL_SIZE) are only legal inside fragment(); pass them into helpers.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float curvature : hint_range(0.0, 0.25) = 0.08;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.12;
uniform float mask_strength : hint_range(0.0, 1.0) = 0.35;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform float chroma : hint_range(0.0, 0.01) = 0.0025;
uniform float player_chroma : hint_range(0.0, 0.01) = 0.0004;
uniform float player_crt_reduction : hint_range(0.0, 1.0) = 0.7;
uniform float player_white_boost : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade_px : hint_range(0.0, 64.0) = 0.0;
uniform float corner_darkness : hint_range(0.0, 1.0) = 0.0;
uniform float corner_radius : hint_range(0.0, 1.0) = 0.45;

// Aspect-corrected barrel: round glass on 3:2 (and any) window. amount 0 = identity.
vec2 curve_uv(vec2 uv, float amount, float aspect) {
	vec2 c = (uv - 0.5) * vec2(aspect, 1.0);
	float r2 = dot(c, c);
	vec2 offset = c * r2 * amount;
	offset.x /= max(aspect, 0.000001);
	return uv + offset;
}

// Soft dark-glass rim: fade starts slightly inside the picture edge and reaches black outside.
float rim_fade(vec2 warped_uv, float fade_px, vec2 px) {
	if (fade_px <= 0.0001) {
		return 1.0;
	}
	float edge_dist_px = min(
		min(warped_uv.x, 1.0 - warped_uv.x) / px.x,
		min(warped_uv.y, 1.0 - warped_uv.y) / px.y
	);
	// Positive = inside; 0 = at edge; negative = outside. Soften from ~0.35*fade inside.
	return smoothstep(0.0, fade_px, edge_dist_px + fade_px * 0.35);
}

// Reflect chroma taps that would leave the picture so the rim never smears the last column.
vec2 reflect_uv(vec2 uv) {
	uv = abs(uv);
	uv = 1.0 - abs(uv - 1.0);
	return clamp(uv, vec2(0.0), vec2(1.0));
}

// Overworld player uses white_sprite (balanced bright RGB); env is noir red/black.
float player_sprite_mask(vec3 rgb) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	float balance = 1.0 - abs(rgb.r - rgb.g) - abs(rgb.g - rgb.b);
	float white_body = smoothstep(0.32, 0.78, lum) * smoothstep(0.12, 0.45, balance);
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
	vec2 px = max(SCREEN_PIXEL_SIZE, vec2(0.000001));
	float aspect = px.y / px.x;

	vec2 warped = curve_uv(uv_screen, curvature, aspect);
	float glass = rim_fade(warped, edge_fade_px, px);
	vec2 uv = reflect_uv(warped);

	vec3 bent_src = texture(screen_texture, uv).rgb;
	float crt_mix = 1.0 - player_sprite_mask(bent_src) * player_crt_reduction;

	float p_chroma = player_sprite_mask(bent_src);
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, reflect_uv(uv + vec2(chroma, 0.0))).rgb));
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, reflect_uv(uv - vec2(chroma, 0.0))).rgb));
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, reflect_uv(uv + vec2(chroma * 2.0, 0.0))).rgb));
	p_chroma = max(p_chroma, player_sprite_mask(texture(screen_texture, reflect_uv(uv - vec2(chroma * 2.0, 0.0))).rgb));
	float off = mix(chroma, player_chroma, p_chroma);

	vec3 col;
	col.r = texture(screen_texture, reflect_uv(uv + vec2(off, 0.0))).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, reflect_uv(uv - vec2(off, 0.0))).b;

	float scan = sin(uv.y * 800.0) * 0.5 + 0.5;
	col *= 1.0 - scan * scanline_strength;
	float mask = sin(uv.x * 900.0) * 0.5 + 0.5;
	col = mix(col, col * 0.85, mask * mask_strength);

	col = mix(bent_src, col, crt_mix);
	float white_body = player_white_body_mask(bent_src);
	col = mix(col, vec3(1.0), white_body * player_white_boost);

	// Darkening last, from raw window position — radius 0 at centre, 1 at corners.
	vec2 d = (uv_screen - 0.5) * 2.0;
	d.x *= aspect;
	float r = length(d) / length(vec2(aspect, 1.0));
	float vig = 1.0 - r * r * vignette;
	float corner = 1.0 - smoothstep(corner_radius, 1.0, r) * corner_darkness;
	col *= vig * corner * glass;

	COLOR = vec4(col, 1.0);
}
