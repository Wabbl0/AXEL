shader_type canvas_item;


uniform float spread : hint_range(1.0, 28.0) = 10.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.28;
uniform vec4 glow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * spread;
	float halo = 0.0;
	halo += texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	halo += texture(TEXTURE, UV + vec2(-px.x, 0.0)).a;
	halo += texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	halo += texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
	halo += texture(TEXTURE, UV + vec2(px.x, px.y)).a * 0.75;
	halo += texture(TEXTURE, UV + vec2(-px.x, px.y)).a * 0.75;
	halo += texture(TEXTURE, UV + vec2(px.x, -px.y)).a * 0.75;
	halo += texture(TEXTURE, UV + vec2(-px.x, -px.y)).a * 0.75;
	halo += texture(TEXTURE, UV + vec2(px.x * 1.8, 0.0)).a * 0.4;
	halo += texture(TEXTURE, UV + vec2(-px.x * 1.8, 0.0)).a * 0.4;
	halo += texture(TEXTURE, UV + vec2(0.0, px.y * 1.8)).a * 0.4;
	halo += texture(TEXTURE, UV + vec2(0.0, -px.y * 1.8)).a * 0.4;
	halo = clamp(halo / 8.6, 0.0, 1.0);
	float src_a = texture(TEXTURE, UV).a;
	float ring = max(halo - src_a, 0.0);
	COLOR = vec4(glow_color.rgb, ring * intensity * glow_color.a);
}
