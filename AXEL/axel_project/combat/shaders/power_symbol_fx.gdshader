shader_type canvas_item;

uniform float fx_mode = 0.0;
uniform float progress = 0.0;
uniform float skip_white_hit = 0.0;
uniform sampler2D next_tex : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform sampler2D noise_tex : hint_default_white, filter_linear, repeat_enable;

float _ease(float t) {
	return t * t * (3.0 - 2.0 * t);
}

vec3 _grey(vec3 rgb) {
	float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
	return vec3(mix(lum, 0.72, 0.55));
}

void fragment() {
	float t = clamp(progress, 0.0, 1.0);
	float eased = _ease(t);
	float hit = 0.0;
	if (skip_white_hit < 0.5) {
		hit = smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.10, 0.22, t));
	}
	float grey_amt = smoothstep(0.06, 0.42, t);
	if (fx_mode < 0.5) {
		grey_amt *= 1.0 - smoothstep(0.70, 1.0, t);
	}

	vec2 wobble = vec2(0.0);
	if (fx_mode < 0.5) {
		float wob = sin(t * 16.0) * 0.008 * (1.0 - t);
		wobble = vec2(wob, wob * -0.45);
	}

	vec4 src = texture(TEXTURE, UV + wobble);
	vec4 dst = texture(next_tex, UV);
	float n = texture(noise_tex, UV * vec2(2.4, 2.8)).r;
	vec3 src_rgb = mix(src.rgb, _grey(src.rgb), grey_amt);
	src_rgb = mix(src_rgb, vec3(1.0), hit);

	if (fx_mode < 0.5) {
		float mix_t = smoothstep(0.16, 0.78, eased);
		vec3 dst_rgb = mix(_grey(dst.rgb), dst.rgb, smoothstep(0.62, 1.0, t));
		dst_rgb = mix(dst_rgb, vec3(1.0), hit * (1.0 - mix_t));
		vec3 rgb = mix(src_rgb, dst_rgb, mix_t);
		float a = mix(src.a, dst.a, mix_t);
		COLOR = vec4(rgb, a);
	} else if (fx_mode < 1.5) {
		float hole = smoothstep(0.10, 0.96, eased);
		float dist = length((UV - vec2(0.5)) * vec2(1.0, 1.05));
		float radius = mix(0.02, 0.78, hole);
		float keep = smoothstep(radius, radius + 0.045, dist);
		float rim = (1.0 - smoothstep(radius, radius + 0.07, dist)) * step(0.02, hole);
		vec3 rgb = mix(src_rgb, vec3(0.78), rim * 0.65);
		COLOR = vec4(rgb, src.a * keep);
	} else {
		float front = mix(-0.2, 1.25, smoothstep(0.04, 0.94, eased));
		float along = UV.x + (n - 0.5) * 0.42;
		float alive = smoothstep(front - 0.02, front + 0.07, along);
		float ember = (1.0 - smoothstep(0.0, 0.10, along - front)) * alive;
		ember *= 1.0 - step(0.5, skip_white_hit);
		vec3 rgb = mix(src_rgb, vec3(1.0), ember);
		COLOR = vec4(rgb, src.a * alive);
	}
}
