shader_type canvas_item;

// Locker-local noir mapping that preserves panel/vent readability.
uniform vec4 black_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 dark_blood_color : source_color = vec4(0.24, 0.0, 0.0, 1.0);
uniform vec4 blood_red_color : source_color = vec4(0.84, 0.0, 0.0, 1.0);
uniform vec4 white_color : source_color = vec4(0.90, 0.90, 0.90, 1.0);
uniform float t0 = 0.18;
uniform float t1 = 0.40;
uniform float t2 = 0.80;
uniform float darken_factor = 0.72;
uniform float detail_strength = 0.22;
uniform float glow_strength = 0.0;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec4 mapped = black_color;

	if (lum < t0) {
		mapped = black_color;
	} else if (lum < t1) {
		mapped = dark_blood_color;
	} else if (lum < t2) {
		mapped = blood_red_color;
	} else {
		mapped = white_color;
	}

	// Keep fine locker linework by reintroducing a little local luminance variation.
	float tonal_variation = clamp(0.82 + (lum * detail_strength), 0.0, 1.25);
	vec3 final_rgb = mapped.rgb * tonal_variation * darken_factor;
	float glow_mask = smoothstep(t1, t2, lum);
	final_rgb += mapped.rgb * glow_strength * glow_mask;
	COLOR = vec4(final_rgb, src.a);
}
