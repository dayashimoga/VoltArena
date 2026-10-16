shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

// Realistic Water Shader for Apex Flight.
// Features:
// - Gerstner wave displacement (crest steepness & directional harmonics)
// - Beer-Lambert depth absorption
// - Fresnel reflection curve
// - Shoreline depth foam

uniform vec4 shallow_color : source_color = vec4(0.12, 0.52, 0.62, 0.85);
uniform vec4 deep_color : source_color = vec4(0.02, 0.08, 0.22, 0.98);
uniform vec4 foam_color : source_color = vec4(0.92, 0.96, 1.0, 1.0);

uniform float wave_speed : hint_range(0.1, 5.0) = 1.2;
uniform float wave_steepness : hint_range(0.01, 1.0) = 0.25;
uniform float depth_absorption_rate : hint_range(0.01, 1.0) = 0.15;
uniform float foam_distance : hint_range(0.1, 8.0) = 1.5;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

// Gerstner wave function
vec3 gerstner_wave(vec4 wave_params, vec3 p, inout vec3 tangent, inout vec3 binormal, float time) {
	// wave_params = vec4(dir_x, dir_z, steepness, wavelength)
	vec2 d = normalize(wave_params.xy);
	float k = 2.0 * PI / wave_params.w;
	float c = sqrt(9.8 / k);
	float f = k * (dot(d, p.xz) - c * time * wave_speed);
	float a = wave_params.z / k;

	tangent += vec3(
		-d.x * d.x * (wave_params.z * sin(f)),
		d.x * (wave_params.z * cos(f)),
		-d.x * d.y * (wave_params.z * sin(f))
	);
	binormal += vec3(
		-d.x * d.y * (wave_params.z * sin(f)),
		d.y * (wave_params.z * cos(f)),
		-d.y * d.y * (wave_params.z * sin(f))
	);

	return vec3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
	);
}

void vertex() {
	vec3 grid_point = VERTEX;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);

	vec3 p = grid_point;
	p += gerstner_wave(vec4(1.0, 0.3, wave_steepness, 35.0), grid_point, tangent, binormal, TIME);
	p += gerstner_wave(vec4(0.7, 0.8, wave_steepness * 0.6, 18.0), grid_point, tangent, binormal, TIME);
	p += gerstner_wave(vec4(-0.4, 0.9, wave_steepness * 0.4, 8.5), grid_point, tangent, binormal, TIME);

	VERTEX = p;
	NORMAL = normalize(cross(binormal, tangent));
}

void fragment() {
	// Depth-buffer shoreline foam & Beer-Lambert absorption
	float depth_raw = texture(depth_texture, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 world_depth_pos = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	world_depth_pos.xyz /= world_depth_pos.w;

	float water_depth = max(0.0, VERTEX.z - (INV_PROJECTION_MATRIX * vec4(ndc, 1.0)).z);
	float depth_ratio = clamp(water_depth * depth_absorption_rate, 0.0, 1.0);

	// Beer-Lambert light transmission
	vec3 water_col = mix(shallow_color.rgb, deep_color.rgb, depth_ratio);

	// Shoreline foam
	float foam_mask = 1.0 - smoothstep(0.0, foam_distance, water_depth);
	vec3 final_color = mix(water_col, foam_color.rgb, foam_mask * 0.75);

	// Fresnel reflection: F = F0 + (1 - F0) * (1 - dot(N, V))^5
	float fresnel = 0.04 + 0.96 * pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 5.0);

	ALBEDO = final_color;
	ROUGHNESS = mix(0.05, 0.80, foam_mask);
	METALLIC = 0.15;
	SPECULAR = mix(0.45, 0.10, foam_mask);
	ALPHA = mix(shallow_color.a, deep_color.a, depth_ratio);
}
