shader_type canvas_item;
// C3: perceptual palette snap (Oklab-inspired approximation).

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 c_black : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 c_dark : source_color = vec4(0.26, 0.0, 0.0, 1.0);
uniform vec4 c_red : source_color = vec4(0.88, 0.0, 0.0, 1.0);
uniform vec4 c_light : source_color = vec4(0.0, 0.0, 0.0, 1.0);

vec3 to_oklab(vec3 c) {
	vec3 lms = mat3(
		vec3(0.4122214708, 0.5363325363, 0.0514459929),
		vec3(0.2119034982, 0.6806995451, 0.1073969566),
		vec3(0.0883024619, 0.2817188376, 0.6299787005)
	) * c;
	lms = pow(max(lms, vec3(0.0)), vec3(1.0 / 3.0));
	return vec3(
		dot(lms, vec3(0.2104542553, 0.7936177850, -0.0040720468)),
		dot(lms, vec3(1.9779984951, -2.4285922050, 0.4505937099)),
		dot(lms, vec3(0.0259040371, 0.7827717662, -0.8086757660))
	);
}

float dist_oklab(vec3 a, vec3 b) {
	vec3 d = a - b;
	return dot(d, d);
}

void fragment() {
	vec3 rgb = texture(screen_texture, SCREEN_UV).rgb;
	vec3 lab = to_oklab(rgb);
	vec4 palette[4] = vec4[4](c_black, c_dark, c_red, c_light);
	vec3 plabs[4];
	for (int i = 0; i < 4; i++) {
		plabs[i] = to_oklab(palette[i].rgb);
	}
	float best = 1e9;
	vec3 pick = rgb;
	for (int i = 0; i < 4; i++) {
		float d = dist_oklab(lab, plabs[i]);
		if (d < best) {
			best = d;
			pick = palette[i].rgb;
		}
	}
	COLOR = vec4(pick, 1.0);
}
