shader_type canvas_item;

uniform float ink_low = 0.2;
uniform float ink_high = 0.6;
uniform vec3 glow_color = vec3(1.0, 1.0, 1.0);
uniform vec3 halo_color = vec3(1.0, 0.94, 0.9);
uniform float halo_px = 10.0;
uniform float halo_strength = 0.7;

float ink_of(vec4 src) {
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	return src.a * (1.0 - smoothstep(ink_low, ink_high, lum));
}

void fragment() {
	float core = ink_of(texture(TEXTURE, UV));
	core *= smoothstep(0.0, 0.12, core);
	float halo = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 0.5235988;
		vec2 dir = vec2(cos(ang), sin(ang)) * TEXTURE_PIXEL_SIZE * halo_px;
		halo += ink_of(texture(TEXTURE, UV + dir * 0.5));
		halo += ink_of(texture(TEXTURE, UV + dir)) * 0.6;
	}
	halo = clamp(halo / 12.0, 0.0, 1.0) * halo_strength;
	float a = max(core, halo);
	vec3 col = mix(halo_color, glow_color, core / max(a, 0.0001));
	COLOR = vec4(col, a);
}
