shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float jitter : hint_range(0.0, 1.0) = 1.0;
uniform float burst : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(UV.y * 30.0);
	float tick = floor(TIME * 10.0);
	float r = fract(sin(row * 12.9898 + tick * 78.233) * 43758.5453);
	float cut = mix(0.95, 0.8, burst);
	float slice = step(cut, r) * jitter;
	uv.x += (r - 0.5) * 0.04 * slice;
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float split = 0.006 * slice;
	float lr = dot(texture(screen_tex, uv + vec2(split, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
	float lg = dot(texture(screen_tex, uv).rgb, vec3(0.299, 0.587, 0.114));
	float lb = dot(texture(screen_tex, uv - vec2(split, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = vec3(lr, lg, lb) * 0.5;
	float scan = 0.96 + 0.04 * sin(UV.y * 600.0);
	COLOR = vec4(mix(c, grey * scan, amount), 1.0);
}
