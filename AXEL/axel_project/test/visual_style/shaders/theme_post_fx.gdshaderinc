// Shared theme tint for scanline/glitch comparison shaders.
// theme_mode: 0 = axel (pass-through), 1 = green phosphor, 2 = mono white terminal

vec3 apply_theme_tint(vec3 col, int theme_mode, float theme_strength) {
	if (theme_mode == 0 || theme_strength <= 0.001) {
		return col;
	}
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 themed = col;
	if (theme_mode == 1) {
		// Pip-Boy-style green phosphor
		themed = vec3(lum * 0.08, lum * 0.92, lum * 0.28);
	} else if (theme_mode == 2) {
		// High-contrast mono white terminal
		float band = smoothstep(0.18, 0.82, lum);
		themed = mix(vec3(0.04), vec3(0.94), band);
	}
	return mix(col, themed, clamp(theme_strength, 0.0, 1.0));
}
