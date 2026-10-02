shader_type canvas_item;


uniform float spread : hint_range(0.5, 8.0) = 1.92;
uniform vec2 frame_px = vec2(48.0, 48.0);
uniform vec2 sheet_px = vec2(240.0, 48.0);
uniform vec2 region_pos = vec2(0.0, 0.0);
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 pixel_in_frame;

void vertex() {
	vec2 dir = sign(VERTEX);
	vec2 half_frame = frame_px * 0.5;
	VERTEX += dir * spread;
	pixel_in_frame = dir * (half_frame + vec2(spread)) + half_frame;
}

void fragment() {
	float halo = 0.0;
	vec2 center = pixel_in_frame;
	float limit = spread < 1.0 ? 1.0 : spread;
	for (int y = -8; y <= 8; y++) {
		for (int x = -8; x <= 8; x++) {
			float dist = length(vec2(float(x), float(y)));
			if (dist > limit) {
				continue;
			}
			vec2 frame_pixel = center + vec2(float(x), float(y));
			if (frame_pixel.x < 0.0 || frame_pixel.y < 0.0) {
				continue;
			}
			if (frame_pixel.x >= frame_px.x || frame_pixel.y >= frame_px.y) {
				continue;
			}
			vec2 uv = (region_pos + frame_pixel) / sheet_px;
			halo = max(halo, step(0.15, texture(TEXTURE, uv).a));
		}
	}
	COLOR = vec4(glow_color.rgb, halo * glow_color.a);
}
