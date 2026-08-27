shader_type canvas_item;

// Soft ribbon along a Line2D stroke. Authored black so 8-band noir remaps it
// to a faint red glow (same look as the kitchen flashlight halo).
uniform float intensity : hint_range(0.0, 1.0) = 0.32;
uniform vec4 glow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float edge = abs(UV.y - 0.5) * 2.0;
	float falloff = 1.0 - clamp(edge, 0.0, 1.0);
	falloff *= falloff;
	COLOR = vec4(glow_color.rgb, falloff * intensity * glow_color.a);
}
