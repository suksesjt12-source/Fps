shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

uniform vec4 energy_color : source_color = vec4(0.18, 0.85, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.5, 12.0) = 4.5;

void fragment() {
	float pulse = 0.72 + 0.28 * sin(TIME * pulse_speed + UV.y * 10.0);
	ALBEDO = energy_color.rgb * pulse * 1.4;
	ALPHA = energy_color.a * pulse;
}
