shader_type canvas_item;

#define LEAF_POLY_MAX 64

uniform float leaf_fade_alpha : hint_range(0.0, 1.0) = 0.2;
uniform float leaf_gate_softness = 18.0;
uniform float leaf_y_cutoff_0 = 1e9;
uniform float leaf_y_cutoff_1 = 1e9;
uniform float leaf_y_cutoff_2 = 1e9;
uniform float leaf_y_cutoff_3 = 1e9;
uniform float leaf_y_cutoff_4 = 1e9;
uniform float leaf_y_cutoff_5 = 1e9;
uniform float player_anchor_y = -1.0e9;
uniform int leaf_mask_use_anchor_y = 0;

uniform vec2 leaf_poly_0[LEAF_POLY_MAX];
uniform int leaf_poly_0_count = 0;
uniform float leaf_poly_0_feather = 2.0;
uniform ivec4 leaf_poly_0_parts = ivec4(0);
uniform vec4 leaf_poly_0_part_cutoffs = vec4(0.0);

uniform vec2 leaf_poly_1[LEAF_POLY_MAX];
uniform int leaf_poly_1_count = 0;
uniform float leaf_poly_1_feather = 2.0;
uniform ivec4 leaf_poly_1_parts = ivec4(0);
uniform vec4 leaf_poly_1_part_cutoffs = vec4(0.0);

uniform vec2 leaf_poly_2[LEAF_POLY_MAX];
uniform int leaf_poly_2_count = 0;
uniform float leaf_poly_2_feather = 2.0;
uniform ivec4 leaf_poly_2_parts = ivec4(0);
uniform vec4 leaf_poly_2_part_cutoffs = vec4(0.0);

uniform vec2 leaf_poly_3[LEAF_POLY_MAX];
uniform int leaf_poly_3_count = 0;
uniform float leaf_poly_3_feather = 2.0;
uniform ivec4 leaf_poly_3_parts = ivec4(0);
uniform vec4 leaf_poly_3_part_cutoffs = vec4(0.0);

uniform vec2 leaf_poly_4[LEAF_POLY_MAX];
uniform int leaf_poly_4_count = 0;
uniform float leaf_poly_4_feather = 2.0;
uniform ivec4 leaf_poly_4_parts = ivec4(0);
uniform vec4 leaf_poly_4_part_cutoffs = vec4(0.0);

uniform vec2 leaf_poly_5[LEAF_POLY_MAX];
uniform int leaf_poly_5_count = 0;
uniform float leaf_poly_5_feather = 2.0;
uniform ivec4 leaf_poly_5_parts = ivec4(0);
uniform vec4 leaf_poly_5_part_cutoffs = vec4(0.0);

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

bool _point_in_polygon_range(vec2 p, vec2 points[LEAF_POLY_MAX], int start, int count) {
	bool inside = false;
	int last = start + count - 1;
	int j = last;
	for (int i = start; i <= last; i++) {
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

float _nearest_edge_distance_range(vec2 p, vec2 points[LEAF_POLY_MAX], int start, int count) {
	float edge_dist = 1.0e9;
	for (int i = 0; i < count; i++) {
		int i0 = start + i;
		int i1 = start + ((i + 1) % count);
		edge_dist = min(edge_dist, _dist_to_segment(p, points[i0], points[i1]));
	}
	return edge_dist;
}

float _polygon_feather_mask_range(vec2 sample_pos, vec2 points[LEAF_POLY_MAX], int start, int count, float feather_px) {
	if (count < 3) {
		return 0.0;
	}
	if (!_point_in_polygon_range(sample_pos, points, start, count)) {
		return 0.0;
	}
	float edge_dist = _nearest_edge_distance_range(sample_pos, points, start, count);
	return smoothstep(0.0, max(feather_px, 0.001), edge_dist);
}

int _part_count_at(ivec4 parts, int part) {
	if (part == 0) {
		return parts.x;
	}
	if (part == 1) {
		return parts.y;
	}
	if (part == 2) {
		return parts.z;
	}
	return parts.w;
}

float _part_cutoff_at(vec4 part_cutoffs, int part, float slot_cutoff) {
	float c = slot_cutoff;
	if (part == 0) {
		c = part_cutoffs.x;
	} else if (part == 1) {
		c = part_cutoffs.y;
	} else if (part == 2) {
		c = part_cutoffs.z;
	} else {
		c = part_cutoffs.w;
	}
	if (c == 0.0) {
		return slot_cutoff;
	}
	return c;
}

float _trunk_line_gate(float sample_y, float cutoff_y, float softness_px) {
	// 1e9 = no trunk line (wall / unused). Allow the polygon mask to win.
	if (cutoff_y > 1e8) {
		return 1.0;
	}
	float pixel_gate = smoothstep(cutoff_y + softness_px, cutoff_y - softness_px, sample_y);
	float feet_gate = smoothstep(cutoff_y + softness_px, cutoff_y - softness_px, player_anchor_y);
	float body_gate = min(pixel_gate, feet_gate);
	float depth_exit = smoothstep(cutoff_y - softness_px, cutoff_y + softness_px, player_anchor_y);
	float head_lift = smoothstep(cutoff_y, cutoff_y + max(softness_px * 0.2, 1.0), player_anchor_y);
	return body_gate * (1.0 - depth_exit) * (1.0 - head_lift);
}

float _polygon_parts_mask(
	vec2 sample_pos,
	vec2 points[LEAF_POLY_MAX],
	int count,
	ivec4 parts,
	vec4 part_cutoffs,
	float slot_cutoff,
	float feather_px,
	float softness_px,
	bool skip_y_gate
) {
	ivec4 use_parts = parts;
	if (use_parts.x <= 0) {
		use_parts = ivec4(count, 0, 0, 0);
	}
	float m = 0.0;
	int offset = 0;
	for (int part = 0; part < 4; part++) {
		int n = _part_count_at(use_parts, part);
		if (n >= 3) {
			float mask = _polygon_feather_mask_range(sample_pos, points, offset, n, feather_px);
			float gate = 1.0;
			if (!skip_y_gate) {
				gate = _trunk_line_gate(
					sample_pos.y,
					_part_cutoff_at(part_cutoffs, part, slot_cutoff),
					softness_px
				);
			}
			m = max(m, mask * gate);
		}
		offset += max(n, 0);
	}
	return m;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 mask_pos = world_pos;
	if (leaf_mask_use_anchor_y != 0) {
		mask_pos = vec2(world_pos.x, player_anchor_y);
	}
	bool skip_y_gate = leaf_mask_use_anchor_y != 0;
	float m0 = _polygon_parts_mask(mask_pos, leaf_poly_0, leaf_poly_0_count, leaf_poly_0_parts, leaf_poly_0_part_cutoffs, leaf_y_cutoff_0, leaf_poly_0_feather, leaf_gate_softness, skip_y_gate);
	float m1 = _polygon_parts_mask(world_pos, leaf_poly_1, leaf_poly_1_count, leaf_poly_1_parts, leaf_poly_1_part_cutoffs, leaf_y_cutoff_1, leaf_poly_1_feather, leaf_gate_softness, skip_y_gate);
	float m2 = _polygon_parts_mask(world_pos, leaf_poly_2, leaf_poly_2_count, leaf_poly_2_parts, leaf_poly_2_part_cutoffs, leaf_y_cutoff_2, leaf_poly_2_feather, leaf_gate_softness, skip_y_gate);
	float m3 = _polygon_parts_mask(world_pos, leaf_poly_3, leaf_poly_3_count, leaf_poly_3_parts, leaf_poly_3_part_cutoffs, leaf_y_cutoff_3, leaf_poly_3_feather, leaf_gate_softness, skip_y_gate);
	float m4 = _polygon_parts_mask(world_pos, leaf_poly_4, leaf_poly_4_count, leaf_poly_4_parts, leaf_poly_4_part_cutoffs, leaf_y_cutoff_4, leaf_poly_4_feather, leaf_gate_softness, skip_y_gate);
	float m5 = _polygon_parts_mask(world_pos, leaf_poly_5, leaf_poly_5_count, leaf_poly_5_parts, leaf_poly_5_part_cutoffs, leaf_y_cutoff_5, leaf_poly_5_feather, leaf_gate_softness, skip_y_gate);
	float mask_coverage = clamp(max(max(max(m0, m1), max(m2, m3)), max(m4, m5)), 0.0, 1.0);
	vec4 tex = texture(TEXTURE, UV);
	float base_alpha = tex.a * COLOR.a;
	float blended_alpha = base_alpha * mix(1.0, leaf_fade_alpha, mask_coverage);
	// Keep packed brush brightness (white ink, empty gaps). Do not 1-bit the face.
	COLOR = vec4(tex.rgb, blended_alpha);
}
