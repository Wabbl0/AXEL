shader_type canvas_item;

// Local palette map for highlighted locker rendered above global noir.
uniform vec4 black_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 dark_blood_color : source_color = vec4(0.24, 0.0, 0.0, 1.0);
uniform vec4 blood_red_color : source_color = vec4(0.86, 0.0, 0.0, 1.0);
uniform vec4 white_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);
uniform float t0 = 0.20;
uniform float t1 = 0.44;
uniform float t2 = 0.76;
uniform float darken_factor = 0.67;

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

	COLOR = vec4(mapped.rgb * darken_factor, src.a);
}
