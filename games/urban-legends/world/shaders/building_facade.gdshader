shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Building Facade & Interior Window Parallax Shader for Urban Legends Metropolis.
// Features:
// - Procedural window grid with architectural mullions
// - Pseudo-interior room depth parallax mapping
// - Randomized room lighting emission for nighttime city liveliness
// - Day/Night energy response

uniform vec4 facade_base_color : source_color = vec4(0.22, 0.24, 0.28, 1.0);
uniform vec4 window_frame_color : source_color = vec4(0.12, 0.12, 0.14, 1.0);
uniform vec4 room_lit_warm : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform vec4 room_lit_cool : source_color = vec4(0.55, 0.85, 1.0, 1.0);

uniform vec2 window_grid_density = vec2(8.0, 14.0);
uniform float room_depth : hint_range(0.05, 1.0) = 0.45;
uniform float night_emission_factor : hint_range(0.0, 5.0) = 3.5;
uniform float window_lit_probability : hint_range(0.0, 1.0) = 0.45;

varying vec3 v_tangent_view_dir;
varying vec3 v_world_normal;

float hash2D(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// Compute tangent view direction for interior room parallax
	mat3 tbn = mat3(TANGENT, BINORMAL, NORMAL);
	vec3 view_dir = normalize(-VERTEX);
	v_tangent_view_dir = tbn * view_dir;
}

void fragment() {
	vec2 uv_scaled = UV * window_grid_density;
	vec2 cell_id = floor(uv_scaled);
	vec2 cell_uv = fract(uv_scaled);

	// Window mullion / architectural frame border (0.15 margin)
	vec2 frame_dist = min(cell_uv, 1.0 - cell_uv);
	float is_frame = step(min(frame_dist.x, frame_dist.y), 0.12);

	// Parallax room interior calculation
	vec2 parallax_offset = v_tangent_view_dir.xy * (room_depth * 0.15);
	vec2 room_uv = fract(cell_uv + parallax_offset);

	// Random seed per window cell
	float room_rand = hash2D(cell_id);
	float color_rand = hash2D(cell_id + vec2(17.3, 43.1));

	// Determine if this room is lit at night
	float is_lit = step(1.0 - window_lit_probability, room_rand) * (1.0 - is_frame);
	vec3 room_color = mix(room_lit_warm.rgb, room_lit_cool.rgb, step(0.5, color_rand));

	// Interior room furniture silhouette / ceiling shading
	float ceiling_shade = smoothstep(0.7, 0.95, room_uv.y);
	float floor_shade = smoothstep(0.3, 0.05, room_uv.y);
	vec3 interior_color = room_color * (1.0 - ceiling_shade * 0.35 - floor_shade * 0.45);

	// Blend exterior facade vs window interior
	vec3 albedo_out = mix(interior_color, facade_base_color.rgb, is_frame);
	float roughness_out = mix(0.12, 0.82, is_frame);
	float metallic_out = mix(0.85, 0.20, is_frame);

	ALBEDO = albedo_out;
	ROUGHNESS = roughness_out;
	METALLIC = metallic_out;
	SPECULAR = mix(0.65, 0.25, is_frame);

	// Night emission for lit windows
	if (is_lit > 0.5) {
		EMISSION = interior_color * night_emission_factor;
	} else {
		EMISSION = vec3(0.0);
	}
}
