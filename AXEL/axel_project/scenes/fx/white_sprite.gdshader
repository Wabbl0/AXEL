shader_type canvas_item;

uniform vec4 leaf_mask_0 = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 leaf_mask_1 = vec4(0.0, 0.0, 1.0, 1.0);
uniform float leaf_fade_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float leaf_edge_softness = 18.0;
uniform float leaf_y_cutoff_0 = 1e9;
uniform float leaf_y_cutoff_1 = 1e9;
uniform vec4 behind_mask_0 = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 behind_mask_1 = vec4(0.0, 0.0, 0.0, 0.0);
uniform float behind_edge_softness = 16.0;

varying vec2 world_pos;

float _ellipse_mask(vec2 sample_pos, vec4 mask_rect, float softness_px) {
	vec2 center = mask_rect.xy;
	vec2 radius = max(mask_rect.zw, vec2(1.0, 1.0));
	vec2 rel = (sample_pos - center) / radius;
	float dist = length(rel);
	float softness_norm = max(softness_px / max(radius.x, radius.y), 0.0001);
	return 1.0 - smoothstep(1.0 - softness_norm, 1.0 + softness_norm, dist);
}

float _behind_zone_coverage(vec2 sample_pos, vec4 mask_rect, float softness_px) {
	if (mask_rect.z < 0.5 && mask_rect.w < 0.5) {
		return 0.0;
	}
	return _ellipse_mask(sample_pos, mask_rect, softness_px);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float tex_a = texture(TEXTURE, UV).a;
	float m0 = _ellipse_mask(world_pos, leaf_mask_0, leaf_edge_softness)
		* _behind_zone_coverage(world_pos, behind_mask_0, behind_edge_softness);
	float m1 = _ellipse_mask(world_pos, leaf_mask_1, leaf_edge_softness)
		* _behind_zone_coverage(world_pos, behind_mask_1, behind_edge_softness);
	float mask_coverage = clamp(max(m0, m1), 0.0, 1.0);
	float base_alpha = tex_a * COLOR.a;
	float blended_alpha = base_alpha * mix(1.0, leaf_fade_alpha, mask_coverage);
	COLOR = vec4(1.0, 1.0, 1.0, blended_alpha);
}
