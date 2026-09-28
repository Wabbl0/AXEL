shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float roll = 1.5;
uniform float seed = 0.0;

float hash11(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	float a = clamp(amount, 0.0, 1.0);
	vec2 uv = UV;
	vec4 col = texture(TEXTURE, uv);
	if (a >= 0.001) {
		float band = floor(uv.y * 14.0);
		float gate = step(0.38, hash11(band + seed));
		uv.x += (hash11(band * 2.3 + seed) - 0.5) * 0.075 * a * gate;

		float roll_band = 1.0 - smoothstep(0.02, 0.16, abs(uv.y - roll));
		uv.x += sin((uv.y + seed) * 30.0) * 0.045 * a * roll_band;
		uv.x += (hash11(floor(uv.y * 80.0) + seed) - 0.5) * 0.09 * a * roll_band;
		uv.y += (uv.y - roll) * 0.45 * roll_band * a;
		uv = clamp(uv, vec2(0.001), vec2(0.999));

		col = texture(TEXTURE, uv);
		float shift = 0.02 * a;
		vec2 uv_r = clamp(uv + vec2(shift, 0.0), vec2(0.001), vec2(0.999));
		vec2 uv_b = clamp(uv - vec2(shift * 0.65, 0.0), vec2(0.001), vec2(0.999));
		col.r = texture(TEXTURE, uv_r).r;
		col.b = max(col.b, texture(TEXTURE, uv_b).r * roll_band);
		float tear = (1.0 - smoothstep(0.0, 0.012, abs(uv.y - roll))) * a;
		col.rgb = mix(col.rgb, vec3(0.55, 0.02, 0.02), tear * 0.85);
	}
	COLOR = col;
}
