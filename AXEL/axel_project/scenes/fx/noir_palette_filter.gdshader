shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 black_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 dark_blood_color : source_color = vec4(0.30, 0.0, 0.0, 1.0);
uniform vec4 blood_red_color : source_color = vec4(0.90, 0.0, 0.0, 1.0);
uniform vec4 white_color : source_color = vec4(0.88, 0.06, 0.05, 1.0);
uniform float t0 = 0.07;
uniform float t1 = 0.31;
uniform float t2 = 0.78;
uniform float line_contrast : hint_range(1.0, 3.0) = 1.25;

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));

	// Contrast boost centered on midpoint to preserve dark line strokes
	lum = clamp((lum - 0.5) * line_contrast + 0.5, 0.0, 1.0);

	vec4 mapped = black_color;

	// Inverted AXEL mapping: dark strokes -> red, mid/high luminance -> black fill.
	if (lum < t0) {
		mapped = blood_red_color;
	} else if (lum < t1) {
		mapped = dark_blood_color;
	} else {
		mapped = black_color;
	}

	COLOR = vec4(mapped.rgb, src.a);
}
