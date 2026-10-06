shader_type canvas_item;

uniform float ink_low = 0.2;
uniform float ink_high = 0.6;
uniform vec3 glow_color = vec3(0.86, 0.80, 0.78);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	float lum = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	float ink = 1.0 - smoothstep(ink_low, ink_high, lum);
	float a = src.a * ink;
	a *= smoothstep(0.0, 0.12, a);
	COLOR = vec4(glow_color, a);
}
