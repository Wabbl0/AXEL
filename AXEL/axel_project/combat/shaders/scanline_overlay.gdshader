shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 0.0, 0.0, 0.08);
uniform float line_density = 420.0;
uniform float chroma_strength = 0.025;

void fragment() {
	float scan = step(0.5, fract(UV.y * line_density));
	vec3 col = vec3(0.0);
	col += line_color.rgb * scan;
	col.r += chroma_strength * sin(UV.y * 1200.0);
	col.b += chroma_strength * cos(UV.y * 1200.0);
	COLOR = vec4(col, line_color.a);
}
