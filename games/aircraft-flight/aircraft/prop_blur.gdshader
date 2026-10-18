shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// Radial Motion-Blur Disk Shader for high-RPM propellers and helicopter rotors.
// Generates realistic blade streaks, hub falloff, tip fade, and specular disc reflections.

uniform int blade_count : hint_range(2, 6) = 3;
uniform float rpm_normalized : hint_range(0.0, 1.0) = 1.0;
uniform vec4 disc_color : source_color = vec4(0.12, 0.12, 0.14, 0.45);
uniform vec4 tip_color : source_color = vec4(0.95, 0.85, 0.15, 0.70); // Yellow safety tip markings
uniform float tip_fraction : hint_range(0.05, 0.3) = 0.12;
uniform float inner_hub_cutoff : hint_range(0.05, 0.4) = 0.18;
uniform float blur_smoothness : hint_range(0.1, 1.0) = 0.85;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0; // 0.0 at center, 1.0 at outer edge

	// Discard outside disc or inside hub
	if (dist > 1.0 || dist < inner_hub_cutoff) {
		discard;
	}

	float angle = atan(centered.y, centered.x); // -PI to PI
	float blade_angle_span = (2.0 * PI) / float(blade_count);
	float local_angle = mod(angle + TIME * 12.0 * rpm_normalized, blade_angle_span);
	float blade_phase = local_angle / blade_angle_span;

	// Radial falloff: soft edges at inner hub and outer rim
	float hub_fade = smoothstep(inner_hub_cutoff, inner_hub_cutoff + 0.08, dist);
	float rim_fade = 1.0 - smoothstep(0.96, 1.0, dist);
	float radial_mask = hub_fade * rim_fade;

	// Motion blur ghosting: higher RPM = more uniform disc, lower RPM = distinct ghosts
	float streak = pow(blade_phase, mix(3.5, 0.8, rpm_normalized));
	float disc_alpha = mix(streak, 0.75, rpm_normalized * blur_smoothness);

	// Subtle blade-tip marking: modulated by blade phase so it does not form a solid glowing yellow ring
	float tip_mask = smoothstep(1.0 - tip_fraction, 1.0 - tip_fraction + 0.04, dist);
	float tip_sweep = pow(blade_phase, mix(4.0, 1.2, rpm_normalized));
	vec3 base_rgb = mix(disc_color.rgb, tip_color.rgb, tip_mask * tip_sweep * 0.45);
	float final_alpha = mix(disc_color.a, tip_color.a * tip_sweep * 0.35, tip_mask) * disc_alpha * radial_mask * rpm_normalized;

	ALBEDO = base_rgb;
	ALPHA = clamp(final_alpha, 0.0, 0.85);
}
