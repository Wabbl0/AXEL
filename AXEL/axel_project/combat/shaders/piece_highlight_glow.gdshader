shader_type canvas_item;

void fragment() {
	float base_a = texture(TEXTURE, UV).a;
	vec2 px = TEXTURE_PIXEL_SIZE;
	float radius = 4.0;
	float halo = 0.0;
	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			vec2 delta = vec2(float(x), float(y));
			float dist = length(delta);
			if (dist > radius || dist < 0.01) {
				continue;
			}
			float sample_a = texture(TEXTURE, UV + delta * px).a;
			float fall = 1.0 - dist / radius;
			halo = max(halo, sample_a * fall);
		}
	}
	float out_a = max(base_a, halo);
	if (out_a < 0.02) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, out_a);
	}
}
