shader_type canvas_item;

instance uniform vec4 team_color: source_color = vec4(0.5, 0.5, 0.5, 1);
uniform float outline_thickness: hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec3 texture_color = texture(TEXTURE, UV).rgb;
	float texture_alpha = texture(TEXTURE, UV).a;
	vec2 size = TEXTURE_PIXEL_SIZE * outline_thickness * 2.0;
	float outline = texture_alpha;

	for (float y = -1.0; y <= 1.0; y++){
		for (float x = -1.0; x <= 1.0; x++){
			outline += texture(TEXTURE, UV + vec2(x*size.x, y*size.y)).a;
		}
	}
	outline = min(outline, 1.0)- texture_alpha;
	COLOR.a = texture_alpha + outline;
	COLOR.rgb = mix(texture_color, team_color.rgb, outline);
}
