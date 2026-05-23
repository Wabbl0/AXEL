shader_type canvas_item;
// Test-only VHS / tape degradation approximation (GodotRetro-inspired).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float noise_strength : hint_range(0.0, 0.3) = 0.08;
uniform float bleed : hint_range(0.0, 0.05) = 0.012;
uniform float jitter : hint_range(0.0, 0.02) = 0.004;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 12.0);
	float j = (hash(vec2(t, uv.y)) - 0.5) * jitter;
	uv.x += j;
	vec3 col;
	col.r = texture(screen_texture, uv + vec2(bleed, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv - vec2(bleed, 0.0)).b;
	float n = hash(uv * 1200.0 + t) - 0.5;
	col += n * noise_strength;
	float band = step(0.97, hash(vec2(uv.y * 40.0, t)));
	col = mix(col, col * 0.6, band * 0.35);
	COLOR = vec4(col, 1.0);
}
