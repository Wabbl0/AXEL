shader_type canvas_item;

uniform float ink_low = 0.2;
uniform float ink_high = 0.6;

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	float ink = 1.0 - smoothstep(ink_low, ink_high, lum);
	float a = src.a * ink;
	if (a < 0.03) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, a);
	}
}
