shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Production Urban Interior Window Parallax Shader (NYC / Metropolis Overhaul)
// Reference: image_6e5d60.jpg
// Implements:
// - Architectural window grid with mullions and sills
// - Multi-temperature interior lighting (2700K warm incandescent to 4500K cool office white)
// - 35% - 60% randomized window occupancy/lighting
// - Pseudo-3D interior room parallax depth
// - Architectural glass reflections (roughness = 0.05, metallic = 0.1..0.8)

uniform vec4 facade_base_color : source_color = vec4(0.24, 0.25, 0.28, 1.0);
uniform vec4 window_frame_color : source_color = vec4(0.12, 0.12, 0.14, 1.0);
uniform vec4 room_temp_2700k : source_color = vec4(1.0, 0.76, 0.48, 1.0); // Warm residential
uniform vec4 room_temp_3500k : source_color = vec4(1.0, 0.88, 0.70, 1.0); // Neutral living
uniform vec4 room_temp_4500k : source_color = vec4(0.84, 0.92, 1.0, 1.0);  // Cool commercial

uniform vec2 window_grid_density = vec2(10.0, 18.0);
uniform float room_depth : hint_range(0.05, 1.0) = 0.40;
uniform float window_lit_probability : hint_range(0.2, 0.8) = 0.48; // 48% lit windows (target 35%-60%)
uniform float night_emission_factor : hint_range(0.0, 8.0) = 4.0;
uniform float glass_roughness : hint_range(0.0, 1.0) = 0.06;
uniform float glass_metallic : hint_range(0.0, 1.0) = 0.15;

varying vec3 v_tangent_view_dir;
varying vec3 v_world_normal;

float hash2D(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	mat3 tbn = mat3(TANGENT, BINORMAL, NORMAL);
	vec3 view_dir = normalize(-VERTEX);
	v_tangent_view_dir = tbn * view_dir;
}

void fragment() {
	vec2 uv_scaled = UV * window_grid_density;
	vec2 cell_id = floor(uv_scaled);
	vec2 cell_uv = fract(uv_scaled);

	// Window mullion / architectural frame border (0.10 horizontal, 0.12 vertical)
	vec2 frame_dist = min(cell_uv, 1.0 - cell_uv);
	float is_frame = step(min(frame_dist.x - 0.08, frame_dist.y - 0.10), 0.0);

	// Parallax room interior calculation
	vec2 parallax_offset = v_tangent_view_dir.xy * (room_depth * 0.18);
	vec2 room_uv = fract(cell_uv + parallax_offset);

	// Pseudo-random room properties
	float room_rand = hash2D(cell_id + vec2(3.14, 1.59));
	float temp_rand = hash2D(cell_id + vec2(19.8, 83.2));
	float blind_rand = hash2D(cell_id + vec2(55.4, 27.9));

	// Multi-color temperature selection: 2700K vs 3500K vs 4500K
	vec3 room_color;
	if (temp_rand < 0.45) {
		room_color = room_temp_2700k.rgb;
	} else if (temp_rand < 0.75) {
		room_color = room_temp_3500k.rgb;
	} else {
		room_color = room_temp_4500k.rgb;
	}

	// Interior features: ceiling, floor, window blinds / shades
	float ceiling_shade = smoothstep(0.65, 0.95, room_uv.y);
	float floor_shade = smoothstep(0.35, 0.05, room_uv.y);
	float blind_height = 0.2 + 0.6 * step(0.65, blind_rand);
	float blind_shade = smoothstep(1.0 - blind_height - 0.05, 1.0 - blind_height + 0.05, room_uv.y) * 0.75;

	vec3 interior_color = room_color * (1.0 - ceiling_shade * 0.35 - floor_shade * 0.4 - blind_shade);

	// Lit window determination (35% to 60%)
	float is_lit = step(1.0 - window_lit_probability, room_rand) * (1.0 - is_frame);

	// PBR Outputs
	vec3 albedo_out = mix(interior_color, facade_base_color.rgb, is_frame);
	float roughness_out = mix(glass_roughness, 0.85, is_frame);
	float metallic_out = mix(glass_metallic, 0.20, is_frame);

	ALBEDO = albedo_out;
	ROUGHNESS = roughness_out;
	METALLIC = metallic_out;
	SPECULAR = mix(0.75, 0.2, is_frame);

	if (is_lit > 0.5) {
		EMISSION = interior_color * night_emission_factor;
	} else {
		EMISSION = vec3(0.0);
	}
}
