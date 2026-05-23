shader_type canvas_item;
// C2: 4-band AXEL palette + 4x4 Bayer dither.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 c_black : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 c_dark : source_color = vec4(0.26, 0.0, 0.0, 1.0);
uniform vec4 c_red : source_color = vec4(0.88, 0.0, 0.0, 1.0);
uniform vec4 c_light : source_color = vec4(0.0, 0.0, 0.0, 1.0);

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

void fragment() {
	float lum = dot(texture(screen_texture, SCREEN_UV).rgb, vec3(0.299, 0.587, 0.114));
	float d = bayer4(FRAGCOORD.xy);
	float t0 = 0.10;
	float t1 = 0.28;
	float t2 = 0.58;
	float adj = lum + (d - 0.5) * 0.08;
	vec4 out_col = c_black;
	if (adj < t0) out_col = c_black;
	else if (adj < t1) out_col = c_dark;
	else if (adj < t2) out_col = c_red;
	else out_col = c_light;
	COLOR = vec4(out_col.rgb, 1.0);
}
