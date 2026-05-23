shader_type canvas_item;
// D: CRT display — RGB shadow mask + scanlines + mild bloom.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float mask_pitch : hint_range(200.0, 1200.0) = 720.0;
uniform float scan_strength : hint_range(0.0, 0.4) = 0.14;
uniform float glow : hint_range(0.0, 0.5) = 0.12;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
	vec3 col = texture(screen_texture, uv).rgb;
	vec3 blur = (
		texture(screen_texture, uv + vec2(px.x, 0.0)).rgb +
		texture(screen_texture, uv - vec2(px.x, 0.0)).rgb +
		texture(screen_texture, uv + vec2(0.0, px.y)).rgb +
		texture(screen_texture, uv - vec2(0.0, px.y)).rgb
	) * 0.25;
	col = mix(col, blur, glow);
	float tri = abs(fract(uv.x * mask_pitch) - 0.5);
	vec3 mask = vec3(
		clamp(1.0 - tri * 3.0, 0.0, 1.0),
		clamp(1.0 - abs(tri * 3.0 - 1.0), 0.0, 1.0),
		clamp(1.0 - abs(tri * 3.0 - 2.0), 0.0, 1.0)
	);
	col *= mix(vec3(1.0), mask, 0.55);
	float scan = sin(uv.y * 700.0) * 0.5 + 0.5;
	col *= 1.0 - scan * scan_strength;
	COLOR = vec4(col, 1.0);
}
