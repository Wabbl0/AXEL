shader_type canvas_item;
// C4: pixelation + noise dither + palette map (VesperaFX-style test approximation).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 8.0) = 3.0;
uniform float dither_strength : hint_range(0.0, 0.2) = 0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 map_axel(float lum) {
	if (lum < 0.12) return vec4(0.0, 0.0, 0.0, 1.0);
	if (lum < 0.35) return vec4(0.26, 0.0, 0.0, 1.0);
	if (lum < 0.62) return vec4(0.88, 0.0, 0.0, 1.0);
	return vec4(0.0, 0.0, 0.0, 1.0);
}

void fragment() {
	ivec2 size = textureSize(screen_texture, 0);
	vec2 px = vec2(pixel_size) / vec2(size);
	vec2 uv = floor(SCREEN_UV / px) * px + px * 0.5;
	float lum = dot(texture(screen_texture, uv).rgb, vec3(0.299, 0.587, 0.114));
	lum += (hash(FRAGCOORD.xy) - 0.5) * dither_strength;
	COLOR = map_axel(clamp(lum, 0.0, 1.0));
}
