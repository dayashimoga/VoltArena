shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// 4-Layer Triplanar Height-Blended PBR Terrain Splatmap Shader for Apex Flight.
// Layers:
// 1. Coastal Sand (0m - 8m, slope < 25°)
// 2. Temperate Grass (8m - 950m, slope < 32°)
// 3. Cliff Granite (slope >= 32°)
// 4. Alpine Snow (> 1100m, slope < 42°)

uniform vec4 sand_color : source_color = vec4(0.76, 0.70, 0.52, 1.0);
uniform vec4 grass_color : source_color = vec4(0.24, 0.42, 0.18, 1.0);
uniform vec4 cliff_color : source_color = vec4(0.32, 0.30, 0.28, 1.0);
uniform vec4 snow_color : source_color = vec4(0.94, 0.96, 0.98, 1.0);

uniform float uv_scale : hint_range(0.001, 0.1) = 0.015;
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 4.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// Value noise for natural height variation & anti-tiling
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise2D(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	// Slope in radians: 0 = flat ground (n.y = 1.0), PI/2 = vertical cliff (n.y = 0.0)
	float slope_deg = degrees(acos(clamp(abs(n.y), 0.0, 1.0)));

	// Triplanar projection weights
	vec3 blending = pow(abs(n), vec3(triplanar_sharpness));
	blending = normalize(max(blending, vec3(0.0001)));
	float b_total = blending.x + blending.y + blending.z;
	blending /= b_total;

	// Macro & micro noise offsets
	vec2 uv_xz = v_world_pos.xz * uv_scale;
	float macro_n = noise2D(uv_xz * 0.4) * 25.0 - 12.5;
	float micro_n = (noise2D(uv_xz * 6.0) - 0.5) * 0.15;

	float effective_alt = v_world_pos.y + macro_n;

	// Layer 1: Sand (0m - 8m, slope < 25°)
	float sand_weight = (1.0 - smoothstep(4.0, 12.0, effective_alt)) * (1.0 - smoothstep(18.0, 25.0, slope_deg));

	// Layer 4: Alpine Snow (> 1100m, slope < 42°)
	float snow_weight = smoothstep(1050.0, 1180.0, effective_alt) * (1.0 - smoothstep(32.0, 42.0, slope_deg));

	// Layer 3: Cliff Granite (slope >= 32°)
	float cliff_weight = smoothstep(28.0, 36.0, slope_deg);

	// Layer 2: Grass (default background between 8m and 950m)
	float grass_weight = clamp(1.0 - (sand_weight + snow_weight + cliff_weight), 0.0, 1.0);

	// Normalize blending weights
	float sum_w = sand_weight + grass_weight + cliff_weight + snow_weight;
	sand_weight /= sum_w;
	grass_weight /= sum_w;
	cliff_weight /= sum_w;
	snow_weight /= sum_w;

	// Texture color synthesis
	vec3 c_sand = sand_color.rgb + vec3(micro_n * 0.5);
	vec3 c_grass = grass_color.rgb + vec3(micro_n);
	vec3 c_cliff = cliff_color.rgb + vec3(micro_n * 1.5);
	vec3 c_snow = snow_color.rgb + vec3(micro_n * 0.3);

	vec3 final_albedo = c_sand * sand_weight + c_grass * grass_weight + c_cliff * cliff_weight + c_snow * snow_weight;

	ALBEDO = final_albedo;
	ROUGHNESS = mix(0.85, 0.40, snow_weight);
	METALLIC = mix(0.0, 0.05, cliff_weight);
	SPECULAR = mix(0.2, 0.35, snow_weight);
}
