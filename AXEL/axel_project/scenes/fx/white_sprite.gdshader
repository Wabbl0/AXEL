shader_type canvas_item;

#define LEAF_POLY_MAX 32

uniform float leaf_fade_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float leaf_gate_softness = 18.0;
uniform float leaf_y_cutoff_0 = 1e9;
uniform float leaf_y_cutoff_1 = 1e9;
uniform float player_anchor_y = -1.0e9;

uniform vec2 leaf_poly_0[LEAF_POLY_MAX];
uniform int leaf_poly_0_count = 0;
uniform float leaf_poly_0_feather = 8.0;

uniform vec2 leaf_poly_1[LEAF_POLY_MAX];
uniform int leaf_poly_1_count = 0;
uniform float leaf_poly_1_feather = 8.0;

varying vec2 world_pos;

float _dist_to_segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float denom = dot(ab, ab);
	if (denom <= 0.000001) {
		return length(p - a);
	}
	float t = clamp(dot(p - a, ab) / denom, 0.0, 1.0);
	return length(p - (a + ab * t));
}

bool _point_in_polygon(vec2 p, vec2 points[LEAF_POLY_MAX], int count) {
	bool inside = false;
	int j = count - 1;
	for (int i = 0; i < count; i++) {
		vec2 pi = points[i];
		vec2 pj = points[j];
		bool intersect = ((pi.y > p.y) != (pj.y > p.y))
			&& (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y + 0.000001) + pi.x);
		if (intersect) {
			inside = !inside;
		}
		j = i;
	}
	return inside;
}

float _nearest_edge_distance(vec2 p, vec2 points[LEAF_POLY_MAX], int count) {
	float edge_dist = 1.0e9;
	for (int i = 0; i < count; i++) {
		int j = (i + 1) % count;
		edge_dist = min(edge_dist, _dist_to_segment(p, points[i], points[j]));
	}
	return edge_dist;
}

float _polygon_feather_mask(vec2 sample_pos, vec2 points[LEAF_POLY_MAX], int count, float feather_px) {
	if (count < 3) {
		return 0.0;
	}
	if (!_point_in_polygon(sample_pos, points, count)) {
		return 0.0;
	}
	float edge_dist = _nearest_edge_distance(sample_pos, points, count);
	return smoothstep(0.0, max(feather_px, 0.001), edge_dist);
}

float _trunk_line_gate(float sample_y, float cutoff_y, float softness_px) {
	if (cutoff_y > 1e8) {
		return 0.0;
	}
	float pixel_gate = smoothstep(cutoff_y + softness_px, cutoff_y - softness_px, sample_y);
	float feet_gate = smoothstep(cutoff_y + softness_px, cutoff_y - softness_px, player_anchor_y);
	float body_gate = min(pixel_gate, feet_gate);
	float depth_exit = smoothstep(cutoff_y - softness_px, cutoff_y + softness_px, player_anchor_y);
	float head_lift = smoothstep(cutoff_y, cutoff_y + max(softness_px * 0.2, 1.0), player_anchor_y);
	return body_gate * (1.0 - depth_exit) * (1.0 - head_lift);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float tex_a = texture(TEXTURE, UV).a;
	float leaf0 = _polygon_feather_mask(world_pos, leaf_poly_0, leaf_poly_0_count, leaf_poly_0_feather);
	float leaf1 = _polygon_feather_mask(world_pos, leaf_poly_1, leaf_poly_1_count, leaf_poly_1_feather);
	float gate0 = _trunk_line_gate(world_pos.y, leaf_y_cutoff_0, leaf_gate_softness);
	float gate1 = _trunk_line_gate(world_pos.y, leaf_y_cutoff_1, leaf_gate_softness);
	float m0 = leaf0 * gate0;
	float m1 = leaf1 * gate1;
	float mask_coverage = clamp(max(m0, m1), 0.0, 1.0);
	float base_alpha = tex_a * COLOR.a;
	float blended_alpha = base_alpha * mix(1.0, leaf_fade_alpha, mask_coverage);
	COLOR = vec4(1.0, 1.0, 1.0, blended_alpha);
}
