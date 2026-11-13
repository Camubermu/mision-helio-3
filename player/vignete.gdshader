shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 position = (UV - vec2(0.5)) * 2.0;
	float distance_squared = dot(position, position);

	float intensity = 0.75;
	float diffusion = 0.8;

	float darkness = 1.0 - exp(-distance_squared * diffusion);

	COLOR = vec4(0.0, 0.0, 0.0, darkness * intensity);
}