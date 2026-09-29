shader_type canvas_item;

uniform sampler2D sheet : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform float frame = 0.0;
uniform float frame_count = 5.0;
uniform float copies = 5.0;
uniform float thin = 0.72;
uniform float arc = 0.22;
uniform float ink_top = 0.0;
uniform float ink_bottom = 1.0;

void fragment() {
	float edge = (UV.x - 0.5) * 2.0;
	edge = edge * edge;
	float baseline = 1.0 - arc * (1.0 - edge);
	float top = baseline - thin;
	if (UV.y < top || UV.y > baseline) {
		COLOR = vec4(0.0);
	} else {
		float span = max(thin, 0.001);
		float along = clamp((UV.y - top) / span, 0.0, 1.0);
		float v = mix(ink_top, ink_bottom, along);
		float cell = clamp(fract(UV.x * copies), 0.001, 0.999);
		float u = (floor(frame) + cell) / max(frame_count, 1.0);
		COLOR = texture(sheet, vec2(u, v));
	}
}
