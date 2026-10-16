shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

// Polar-UV Propeller Blur Shader
// Dynamically transitions from distinct propeller blades at low RPM to a smooth semi-transparent motion disc at high RPM.

uniform float rpm : hint_range(0.0, 3500.0) = 800.0;
uniform float rotation_angle : hint_range(0.0, 6.2831853) = 0.0;
uniform int blade_count : hint_range(2, 4) = 2;
uniform vec4 blade_color : source_color = vec4(0.12, 0.12, 0.14, 1.0);
uniform vec4 tip_color : source_color = vec4(0.95, 0.85, 0.1, 1.0);
uniform vec4 blur_color : source_color = vec4(0.2, 0.22, 0.25, 0.35);

void fragment() {
	// Center UV coordinates at (0.5, 0.5)
	vec2 centered_uv = UV - vec2(0.5);
	float r = length(centered_uv) * 2.0; // Normalized radius [0, 1]

	// Discard outside propeller disc radius
	if (r > 1.0 || r < 0.08) {
		discard;
	}

	// Polar angle theta in range [-PI, PI]
	float theta = atan(centered_uv.y, centered_uv.x) - rotation_angle;
	// Wrap to [0, 2*PI]
	theta = mod(theta, 6.2831853);

	// Normalized sector angle for blade repetition
	float sector = 6.2831853 / float(blade_count);
	float blade_phase = mod(theta, sector) / sector; // [0, 1] within sector

	// Transition factor based on RPM: low RPM (< 1000) shows blades, high RPM (> 1600) blends into blur
	float blur_weight = clamp((rpm - 900.0) / 900.0, 0.0, 1.0);

	// Discrete blade shape (tapered blade geometry)
	float blade_width = 0.14 * (1.0 - 0.4 * r);
	float dist_from_blade_center = abs(blade_phase - 0.5);
	float is_blade = step(dist_from_blade_center, blade_width * 0.5);

	// Blade tip marking (yellow safety tips on outer 15% of blade radius)
	vec4 current_blade_color = (r > 0.85) ? tip_color : blade_color;

	// Blur disc gradient (radial density falloff)
	float disc_alpha = blur_color.a * (1.0 - smoothstep(0.85, 1.0, r)) * smoothstep(0.08, 0.2, r);
	vec4 current_blur_color = vec4(blur_color.rgb, disc_alpha);

	// Mix discrete blade and continuous motion blur
	vec4 final_color = mix(current_blade_color * is_blade, current_blur_color, blur_weight);

	ALBEDO = final_color.rgb;
	ALPHA = mix(is_blade, disc_alpha, blur_weight);
}
