shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec2 pad_uv = vec2(0.0);
uniform vec2 reach = vec2(0.1);
uniform vec3 glow_color = vec3(1.0, 0.24, 0.2);
uniform vec3 core_color = vec3(1.0, 0.93, 0.9);
uniform float strength = 1.0;

float alpha_at(sampler2D tex, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec2 uv = (UV - pad_uv) / max(vec2(1.0) - pad_uv * 2.0, vec2(0.0001));
	vec4 src = vec4(0.0);
	if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0) {
		src = texture(TEXTURE, uv);
	}
	float swell = 0.8 + 0.4 * pulse;
	float halo = 0.0;
	for (int i = 0; i < 16; i++) {
		float ang = float(i) * 0.3926991;
		vec2 dir = vec2(cos(ang), sin(ang)) * reach * swell;
		halo += alpha_at(TEXTURE, uv + dir * 0.35);
		halo += alpha_at(TEXTURE, uv + dir * 0.7) * 0.7;
		halo += alpha_at(TEXTURE, uv + dir) * 0.4;
	}
	halo = clamp(halo / 16.0 / 1.4, 0.0, 1.0);
	halo = smoothstep(0.0, 0.9, halo) * strength * (0.55 + 0.45 * pulse);
	float rim = halo * (1.0 - src.a);
	vec3 halo_rgb = mix(glow_color, core_color, smoothstep(0.55, 1.0, halo) * 0.5);
	vec3 lit = src.rgb * (1.0 + 0.3 * pulse);
	float a = max(src.a, rim);
	vec3 rgb = mix(halo_rgb, lit, src.a / max(a, 0.0001));
	COLOR = vec4(rgb, a);
}
