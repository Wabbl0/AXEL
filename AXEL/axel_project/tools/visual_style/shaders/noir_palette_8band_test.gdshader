shader_type canvas_item;
// Test-only 8-band inverted AXEL noir. Does not replace production noir_palette_filter.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 red1_color : source_color = vec4(0.90, 0.0, 0.0, 1.0);
uniform vec4 red2_color : source_color = vec4(0.70, 0.0, 0.0, 1.0);
uniform vec4 red3_color : source_color = vec4(0.50, 0.0, 0.0, 1.0);
uniform vec4 red4_color : source_color = vec4(0.30, 0.0, 0.0, 1.0);
uniform vec4 grey1_color : source_color = vec4(0.18, 0.02, 0.02, 1.0);
uniform vec4 grey2_color : source_color = vec4(0.08, 0.01, 0.01, 1.0);
uniform vec4 black1_color : source_color = vec4(0.02, 0.0, 0.0, 1.0);
uniform vec4 black2_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float t0 = 0.125;
uniform float t1 = 0.25;
uniform float t2 = 0.375;
uniform float t3 = 0.5;
uniform float t4 = 0.625;
uniform float t5 = 0.75;
uniform float t6 = 0.875;
uniform float line_contrast : hint_range(1.0, 3.0) = 1.25;

void fragment() {
	vec4 src = texture(screen_texture, SCREEN_UV);
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));

	// Contrast boost centered on midpoint to preserve dark line strokes
	lum = clamp((lum - 0.5) * line_contrast + 0.5, 0.0, 1.0);

	vec4 mapped = black2_color;

	// Inverted AXEL mapping: dark strokes -> reds, mid -> warm greys, bright fill -> blacks.
	if (lum < t0) {
		mapped = red1_color;
	} else if (lum < t1) {
		mapped = red2_color;
	} else if (lum < t2) {
		mapped = red3_color;
	} else if (lum < t3) {
		mapped = red4_color;
	} else if (lum < t4) {
		mapped = grey1_color;
	} else if (lum < t5) {
		mapped = grey2_color;
	} else if (lum < t6) {
		mapped = black1_color;
	} else {
		mapped = black2_color;
	}

	COLOR = vec4(mapped.rgb, src.a);
}
