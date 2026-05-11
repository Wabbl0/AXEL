shader_type canvas_item;

uniform float noise_intensity : hint_range(0.0, 0.5) = 0.12;
uniform float noise_speed : hint_range(0.0, 20.0) = 8.0;
uniform float scan_strength : hint_range(0.0, 0.3) = 0.04;
uniform float scan_density : hint_range(100.0, 800.0) = 300.0;
uniform float blend_opacity : hint_range(0.0, 1.0) = 0.7;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.18;
uniform float flicker_strength : hint_range(0.0, 0.1) = 0.015;

float hash(vec2 p, float t) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
	p3 += dot(p3, p3.yzx + 19.19 + t);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// High-frequency white noise (TV static grain)
	float t = floor(TIME * noise_speed);
	float grain = hash(uv * 1000.0, t);
	grain = (grain - 0.5) * 2.0 * noise_intensity;

	// Subtle fixed scanlines (soft sine, no hard step)
	float scan = sin(uv.y * scan_density * 3.14159) * 0.5 + 0.5;
	scan = scan * scan_strength;

	// Vignette
	vec2 center = uv - vec2(0.5);
	float vig = 1.0 - dot(center, center) * vignette_strength * 3.5;

	// Global brightness flicker (simulates old TV power instability)
	float flicker = 1.0 + (sin(TIME * 7.3) * flicker_strength);

	// Composite: additive white noise + darkening scanlines
	float luminance = (grain - scan) * vig * flicker;

	COLOR = vec4(vec3(luminance), blend_opacity);
}
