shader_type canvas_item;

void fragment() {
	float tex_a = texture(TEXTURE, UV).a;
	COLOR = vec4(1.0, 1.0, 1.0, tex_a * COLOR.a);
}
