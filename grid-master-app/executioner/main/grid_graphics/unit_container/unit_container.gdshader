shader_type canvas_item;

instance uniform vec4 team_color: source_color = vec4(0.5, 0.5, 0.5, 1);
uniform int outline_thickness: hint_range(0, 2) = 1;

void fragment() {
	vec3 texture_color = texture(TEXTURE, UV).rgb;
	float texture_alpha = texture(TEXTURE, UV).a;
	vec2 size = TEXTURE_PIXEL_SIZE;
	float outline = texture_alpha;

	for (int y = -outline_thickness; y <= outline_thickness; y++){
		for (int x = -outline_thickness; x <= outline_thickness; x++){
			outline += texture(TEXTURE, UV + vec2(float(x) * size.x, float(y) * size.y)).a;
		}
	}
	outline = min(outline, 1.0)- texture_alpha;
	COLOR.a = texture_alpha + outline;
	COLOR.rgb = mix(texture_color, team_color.rgb, outline);
}
