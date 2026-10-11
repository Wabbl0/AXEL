shader_type canvas_item;

uniform int mode = 0;
uniform float ink_low = 0.2;
uniform float ink_high = 0.6;
uniform vec3 glow_color = vec3(1.0, 1.0, 1.0);
uniform vec3 halo_color = vec3(1.0, 0.97, 0.95);
uniform vec3 bloom_color = vec3(0.9, 0.06, 0.06);
uniform float halo_px = 14.0;
uniform float halo_strength = 0.85;
uniform vec2 pad_uv = vec2(0.0);
uniform vec2 bloom_reach = vec2(0.04);
uniform float bloom_strength = 0.9;
uniform float sweep = -1.0;
uniform float pulse = 0.0;

float ink_of(vec4 src) {
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	return src.a * (1.0 - smoothstep(ink_low, ink_high, lum));
}

float ink_at(vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return ink_of(texture(TEXTURE, uv));
}

vec2 art_uv_of(vec2 uv) {
	return (uv - pad_uv) / max(vec2(1.0) - pad_uv * 2.0, vec2(0.0001));
}

void fragment() {
	vec2 uv = art_uv_of(UV);
	float core = ink_at(uv);
	core *= smoothstep(0.0, 0.12, core);
	if (mode == 1) {
		float bloom = 0.0;
		for (int i = 0; i < 16; i++) {
			float ang = float(i) * 0.3926991;
			vec2 dir = vec2(cos(ang), sin(ang)) * bloom_reach;
			bloom += ink_at(uv + dir * 0.33);
			bloom += ink_at(uv + dir * 0.66) * 0.75;
			bloom += ink_at(uv + dir) * 0.45;
		}
		bloom = clamp(bloom / 16.0, 0.0, 1.0);
		bloom = smoothstep(0.0, 0.8, bloom) * bloom_strength * (0.75 + 0.35 * pulse);
		COLOR = vec4(bloom_color, bloom * (1.0 - core));
	} else {
		float swell = 1.0 + 0.4 * pulse;
		float halo = 0.0;
		for (int i = 0; i < 12; i++) {
			float ang = float(i) * 0.5235988;
			vec2 dir = vec2(cos(ang), sin(ang)) * TEXTURE_PIXEL_SIZE * halo_px * swell;
			halo += ink_at(uv + dir * 0.33);
			halo += ink_at(uv + dir * 0.66) * 0.8;
			halo += ink_at(uv + dir) * 0.5;
		}
		halo = clamp(halo / 12.0, 0.0, 1.0) * halo_strength * (0.85 + 0.3 * pulse);
		float band = 0.0;
		if (sweep >= -0.5) {
			float d = (uv.x + uv.y) * 0.5;
			band = 1.0 - smoothstep(0.0, 0.09, abs(d - sweep));
		}
		halo = clamp(halo * (1.0 + band * 1.6), 0.0, 1.0);
		float a = max(core, halo);
		vec3 col = mix(halo_color, glow_color, core / max(a, 0.0001));
		col = mix(col, vec3(1.0), band);
		COLOR = vec4(col, a);
	}
}
