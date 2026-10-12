shader_type canvas_item;

uniform sampler2D sheet : source_color, hint_default_transparent, filter_nearest, repeat_disable;
uniform float frame = 0.0;
uniform float frame_count = 5.0;
uniform float copies = 13.0;
uniform vec2 center = vec2(0.0);
uniform vec2 radii = vec2(100.0);
uniform float arc_half = 1.75;
uniform float height_top = 150.0;
uniform float height_side = 0.55;
uniform float base_in = 20.0;
uniform float ink_top = 0.0;
uniform float ink_bottom = 1.0;
uniform float dim_on = 0.0;
uniform vec4 dim_inner = vec4(0.0);
uniform vec4 dim_outer = vec4(0.0);
uniform float dim_level = 0.44;

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

bool inside(vec2 p, vec4 r) {
	return p.x >= r.x && p.y >= r.y && p.x <= r.z && p.y <= r.w;
}

float hash(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	COLOR = vec4(0.0);
	vec2 d = local_pos - center;
	vec2 q = d / max(radii, vec2(1.0));
	float r = length(q);
	float phi = atan(q.x, -q.y);
	if (r > 0.001 && abs(phi) <= arc_half) {
		float s = (phi + arc_half) / (2.0 * arc_half);
		float idx = floor(s * copies);
		float cell = clamp(fract(s * copies), 0.001, 0.999);
		float side = abs(phi) / arc_half;
		float h = height_top * mix(1.0, height_side, side * side) * mix(0.85, 1.1, hash(idx + 1.0));
		float out_px = length(d) * (1.0 - 1.0 / r);
		float along = (out_px + base_in) / max(h, 1.0);
		if (along >= 0.0 && along <= 1.0) {
			float v = mix(ink_bottom, ink_top, along);
			float shift = floor(hash(idx + 7.0) * max(frame_count, 1.0));
			float f = mod(floor(frame) + shift, max(frame_count, 1.0));
			float u = (f + cell) / max(frame_count, 1.0);
			vec4 ink = texture(sheet, vec2(u, v));
			COLOR = vec4(vec3(1.0) - ink.rgb, ink.a);
			if (dim_on > 0.5 && inside(local_pos, dim_outer)) {
				if (inside(local_pos, dim_inner)) {
					COLOR = vec4(vec3(dim_level), ink.a);
				} else {
					COLOR = vec4(0.0);
				}
			}
		}
	}
}
