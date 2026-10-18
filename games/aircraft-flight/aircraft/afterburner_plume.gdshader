shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// Volumetric Shock-Diamond Exhaust & Afterburner Shader for Apex Flight.
// Core flame transitions from intense blue-white at nozzle exit to bright amber-orange along length.
// Analytical shock diamonds modulate along local length using periodic cosine modulation.

uniform vec4 core_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);       // Intense blue-white nozzle core
uniform vec4 plume_color : source_color = vec4(1.0, 0.45, 0.1, 0.85);    // Bright amber-orange reheat flame
uniform float throttle : hint_range(0.0, 1.0) = 1.0;
uniform float diamond_spacing : hint_range(0.05, 0.5) = 0.22;
uniform float scroll_speed = 22.0;

varying vec3 v_local_pos;

void vertex() {
	v_local_pos = VERTEX;
}

void fragment() {
	float z_norm = clamp(UV.y, 0.0, 1.0);
	float radial = clamp(abs(UV.x - 0.5) * 2.0, 0.0, 1.0);

	float active_intensity = smoothstep(0.30, 0.85, throttle);
	if (active_intensity <= 0.001) {
		discard;
	}

	vec3 base_gradient = mix(core_color.rgb, plume_color.rgb, smoothstep(0.0, 0.55, z_norm));

	float phase = (2.0 * 3.14159265 * z_norm / diamond_spacing) - TIME * scroll_speed;
	float diamond_raw = cos(phase);
	float diamond = pow(clamp(diamond_raw, 0.0, 1.0), 4.0) * (1.0 - z_norm * 0.85);

	vec3 final_color = mix(base_gradient, core_color.rgb * 1.5, diamond * 0.75);

	float radial_falloff = 1.0 - pow(radial, 2.0);
	float length_falloff = 1.0 - smoothstep(0.70, 1.0, z_norm);

	float alpha = (radial_falloff * length_falloff * (0.65 + diamond * 0.85)) * active_intensity;

	ALBEDO = final_color * (2.2 + diamond * 2.8);
	ALPHA = clamp(alpha, 0.0, 1.0);
}
