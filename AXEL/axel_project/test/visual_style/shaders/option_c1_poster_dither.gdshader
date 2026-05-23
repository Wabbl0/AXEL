shader_type canvas_item;
// C1: posterization + ordered dither + light outline.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 c_black : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 c_dark : source_color = vec4(0.29, 0.0, 0.0, 1.0);
uniform vec4 c_red : source_color = vec4(0.9, 0.0, 0.0, 1.0);
uniform vec4 c_light : source_color = vec4(0.85, 0.85, 0.85, 1.0);
uniform float levels : hint_range(2.0, 8.0) = 4.0;

float bayer4(vec2 p) {
	vec2 m = mod(floor(p), 4.0);
	int idx = int(m.x + m.y * 4.0);
	const float b[16] = float[16](
		0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0,
		12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
		3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0,
		15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
	);
	return b[idx];
}

vec4 map_palette(float lum) {
	if (lum < 0.2) return c_black;
	if (lum < 0.45) return c_dark;
	if (lum < 0.72) return c_red;
	return c_light;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / vec2(textureSize(screen_texture, 0));
	vec3 src = texture(screen_texture, uv).rgb;
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	float edge = length(texture(screen_texture, uv + vec2(px.x, 0.0)).rgb - texture(screen_texture, uv - vec2(px.x, 0.0)).rgb);
	edge += length(texture(screen_texture, uv + vec2(0.0, px.y)).rgb - texture(screen_texture, uv - vec2(0.0, px.y)).rgb);
	lum = floor(lum * levels) / levels;
	float d = bayer4(FRAGCOORD.xy);
	lum += (d - 0.5) * (1.0 / levels);
	vec4 mapped = map_palette(clamp(lum, 0.0, 1.0));
	if (edge > 0.35) {
		mapped = c_black;
	}
	COLOR = vec4(mapped.rgb, 1.0);
}
