shader_type canvas_item;

uniform sampler2D mask_tex : filter_linear;
uniform float level : hint_range(0.0, 1.0) = 0.0;
uniform float top_uv = 0.0;
uniform float bottom_uv = 1.0;
uniform float wave_amp = 0.01;
uniform float wave_speed = 1.0;
uniform float slosh = 0.0;
uniform float foam_px = 7.0;
uniform float rect_h = 922.0;
uniform float bone_min = 0.55;
uniform float body_alpha = 0.86;
uniform float alpha = 1.0;
uniform float clock = 0.0;

void fragment() {
	vec4 m = texture(mask_tex, UV);
	float lum = dot(m.rgb, vec3(0.299, 0.587, 0.114));
	float bone = m.a * smoothstep(bone_min, bone_min + 0.2, lum);
	float t = clock * wave_speed;
	float amp = wave_amp * (1.0 + slosh * 3.5);
	float wave = sin(UV.x * 9.0 + t * 2.3) * amp
		+ sin(UV.x * 17.0 - t * 3.1) * amp * 0.5
		+ sin(UV.x * 31.0 + t * 5.3) * amp * 0.2 * slosh;
	float margin = 0.03 + amp * 1.8;
	float surface = mix(bottom_uv + margin, top_uv - margin, level) + wave;
	float edge = 1.0 / rect_h;
	float fill = smoothstep(surface - edge, surface + edge, UV.y) * step(0.001, level);
	float foam = 1.0 - smoothstep(surface, surface + foam_px / rect_h, UV.y);
	float a = bone * fill * mix(body_alpha, 1.0, foam) * alpha;
	COLOR = vec4(1.0, 1.0, 1.0, a);
}
