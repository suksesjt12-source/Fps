shader_type canvas_item;

uniform float damage_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float low_health_pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.85, 0.08, 0.08, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float vignette = smoothstep(0.42, 1.28, dist);
	float strength = clamp(damage_intensity + low_health_pulse * 0.45, 0.0, 0.85);
	COLOR = vec4(tint_color.rgb, vignette * strength);
}
