shader_type canvas_item;

#define CLIP_MAX 16

uniform vec2 clip_points[CLIP_MAX];
uniform int clip_count = 0;
uniform float feather_px = 1.0;

varying vec2 local_pos;
varying float px_in_local;

float _dist_to_segment(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float denom = dot(ab, ab);
	if (denom <= 0.000001) {
		return length(p - a);
	}
	float t = clamp(dot(p - a, ab) / denom, 0.0, 1.0);
	return length(p - (a + ab * t));
}

bool _inside(vec2 p) {
	bool inside = false;
	int j = clip_count - 1;
	for (int i = 0; i < CLIP_MAX; i++) {
		if (i < clip_count) {
			vec2 pi = clip_points[i];
			vec2 pj = clip_points[j];
			bool hit = ((pi.y > p.y) != (pj.y > p.y))
				&& (p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y + 0.000001) + pi.x);
			if (hit) {
				inside = !inside;
			}
			j = i;
		}
	}
	return inside;
}

float _edge_dist(vec2 p) {
	float edge = 1.0e9;
	for (int i = 0; i < CLIP_MAX; i++) {
		if (i < clip_count) {
			int i1 = i + 1;
			if (i1 >= clip_count) {
				i1 = 0;
			}
			edge = min(edge, _dist_to_segment(p, clip_points[i], clip_points[i1]));
		}
	}
	return edge;
}

void vertex() {
	local_pos = VERTEX;
	px_in_local = 1.0 / max(length((MODEL_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xy), 0.001);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float keep = 1.0;
	if (clip_count >= 3) {
		if (!_inside(local_pos)) {
			keep = 0.0;
		} else {
			float feather_local = max(feather_px, 0.0) * px_in_local;
			keep = smoothstep(0.0, max(feather_local, 0.0001), _edge_dist(local_pos));
		}
	}
	COLOR = vec4(tex.rgb * COLOR.rgb, tex.a * COLOR.a * keep);
}
