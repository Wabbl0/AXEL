shader_type canvas_item;

uniform vec2 art_size_px = vec2(1.0, 1.0);
uniform vec2 pad_px = vec2(4.0, 4.0);
uniform float blur_px = 4.0;
uniform vec4 shadow_color = vec4(0.22, 0.22, 0.22, 1.0);

void fragment() {
	vec2 safe_size = max(art_size_px, vec2(1.0));
	vec2 node_size = safe_size + pad_px * 2.0;
	vec2 local_px = UV * node_size;
	vec2 art_px = local_px - pad_px;
	float blur_len = max(blur_px, 0.5);
	float step_px = max(blur_len / 4.0, 1.0);
	float a = 0.0;
	vec2 delta = vec2(0.0);
	vec2 sample_px = vec2(0.0);
	vec2 sample_uv = vec2(0.0);
	float sample_a = 0.0;
	float dist = 0.0;
	float fall = 0.0;
	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			delta = vec2(float(x), float(y)) * step_px;
			dist = length(delta);
			if (dist > blur_len) {
				continue;
			}
			sample_px = art_px + delta;
			sample_uv = sample_px / safe_size;
			sample_a = 0.0;
			if (sample_uv.x >= 0.0 && sample_uv.y >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y <= 1.0) {
				sample_a = texture(TEXTURE, sample_uv).a;
			}
			fall = 1.0 - dist / blur_len;
			a = max(a, sample_a * fall);
		}
	}
	// A soft edge over the white plate disappears in the combat color filter.
	if (a < 0.08) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = vec4(shadow_color.rgb, 1.0);
	}
}
