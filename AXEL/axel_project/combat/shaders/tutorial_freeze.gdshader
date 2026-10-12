shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float jitter : hint_range(0.0, 1.0) = 1.0;
uniform float burst : hint_range(0.0, 1.0) = 1.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(UV.y * 30.0);
	float tick = floor(TIME * 10.0);
	float r = hash(row * 12.9898 + tick * 78.233);
	float spike = step(0.82, hash(floor(TIME * 2.5) * 3.71));
	float cut = mix(0.97, 0.8, clamp(burst + spike * 0.5, 0.0, 1.0));
	float slice = step(cut, r) * jitter;
	uv.x += (r - 0.5) * 0.04 * slice;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float split = 0.006 * slice;
	vec3 w = vec3(0.299, 0.587, 0.114);
	float lr = dot(texture(screen_tex, uv + vec2(split, 0.0)).rgb, w);
	float lg = dot(texture(screen_tex, uv).rgb, w);
	float lb = dot(texture(screen_tex, uv - vec2(split, 0.0)).rgb, w);
	vec3 grey = vec3(lr, lg, lb) * 0.75 + vec3(0.05);
	float scan = 0.94 + 0.06 * sin(UV.y * 600.0);
	float roll = 0.03 * jitter * step(0.5, fract(UV.y * 3.0 - TIME * 0.6)) ;
	COLOR = vec4(mix(c, grey * scan - vec3(roll), amount), 1.0);
}
