shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// 4-Layer Triplanar PBR Geological Terrain Shader for Apex Flight.
// Blends:
// 1. Coastal Sand (0m - 12m, slope < 25°)
// 2. Lush Forest Grass (12m - 950m, slope < 30°)
// 3. Scree / Talus Gravel (slope 26° - 34°)
// 4. Strata Rock Cliffs (slope >= 30° with vertical sedimentary striations)
// 5. Alpine Snow Caps (> 1200m, slope < 40°, clamped albedo <= 0.85, roughness 0.45)

uniform vec4 sand_color : source_color = vec4(0.72, 0.66, 0.50, 1.0);
uniform vec4 grass_color : source_color = vec4(0.22, 0.38, 0.16, 1.0);
uniform vec4 scree_color : source_color = vec4(0.42, 0.39, 0.36, 1.0);
uniform vec4 cliff_color : source_color = vec4(0.30, 0.28, 0.26, 1.0);
uniform vec4 snow_color : source_color = vec4(0.82, 0.84, 0.85, 1.0); // Clamped albedo <= 0.85 prevents #FFFFFF blowout

uniform float uv_scale : hint_range(0.0005, 0.05) = 0.0018;
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 4.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// Hash and procedural gradient noise
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

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise2D(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	// Slope in degrees: 0 = horizontal (n.y = 1.0), 90 = vertical cliff (n.y = 0.0)
	float slope_deg = degrees(acos(clamp(abs(n.y), 0.0, 1.0)));

	// Triplanar projection weights
	vec3 blending = pow(abs(n), vec3(triplanar_sharpness));
	blending = normalize(max(blending, vec3(0.0001)));
	blending /= (blending.x + blending.y + blending.z);

	// Macro & micro noise offsets
	vec2 uv_xz = v_world_pos.xz * uv_scale;
	float macro_n = (fbm(uv_xz * 0.3) - 0.5) * 35.0;
	float micro_n = (noise2D(uv_xz * 5.0) - 0.5) * 0.12;

	float effective_alt = v_world_pos.y + macro_n;

	// Strata banding on vertical cliff walls
	float strata = sin(v_world_pos.y * 0.15 + fbm(v_world_pos.xz * 0.02) * 6.0) * 0.5 + 0.5;
	vec3 rock_strata_color = mix(cliff_color.rgb * 0.85, cliff_color.rgb * 1.15, strata);

	// Layer 1: Coastal Sand (0m - 14m, slope < 25°)
	float sand_weight = (1.0 - smoothstep(6.0, 16.0, effective_alt)) * (1.0 - smoothstep(18.0, 26.0, slope_deg));

	// Layer 5: Alpine Snow (> 1200m, slope < 40°)
	float snow_weight = smoothstep(1150.0, 1280.0, effective_alt) * (1.0 - smoothstep(32.0, 42.0, slope_deg));

	// Layer 4: Strata Rock Cliff (slope >= 30°)
	float cliff_weight = smoothstep(28.0, 38.0, slope_deg);

	// Layer 3: Scree / Talus Gravel (transitions on steep slopes 24° - 32°)
	float scree_weight = smoothstep(22.0, 30.0, slope_deg) * (1.0 - smoothstep(32.0, 40.0, slope_deg));

	// Layer 2: Lush Forest Grass (default base between 12m and 1150m)
	float grass_weight = clamp(1.0 - (sand_weight + snow_weight + cliff_weight + scree_weight * 0.6), 0.0, 1.0);

	// Normalize blending weights
	float sum_w = sand_weight + grass_weight + scree_weight + cliff_weight + snow_weight;
	sum_w = max(sum_w, 0.0001);
	sand_weight /= sum_w;
	grass_weight /= sum_w;
	scree_weight /= sum_w;
	cliff_weight /= sum_w;
	snow_weight /= sum_w;

	// Texture color synthesis
	vec3 c_sand = sand_color.rgb + vec3(micro_n * 0.4);
	vec3 c_grass = grass_color.rgb + vec3(micro_n * 0.8);
	vec3 c_scree = scree_color.rgb + vec3(micro_n * 1.2);
	vec3 c_cliff = rock_strata_color + vec3(micro_n * 1.4);
	vec3 c_snow = clamp(snow_color.rgb + vec3(micro_n * 0.2), vec3(0.0), vec3(0.85)); // Clamped albedo <= 0.85

	vec3 final_albedo = c_sand * sand_weight +
	                    c_grass * grass_weight +
	                    c_scree * scree_weight +
	                    c_cliff * cliff_weight +
	                    c_snow * snow_weight;

	ALBEDO = final_albedo;
	ROUGHNESS = mix(mix(0.85, 0.45, snow_weight), 0.95, cliff_weight * 0.5);
	METALLIC = mix(0.0, 0.04, cliff_weight);
	SPECULAR = mix(0.2, 0.35, snow_weight);

	// Procedural cliff strata normal bump
	vec3 bump_normal = n;
	if (cliff_weight > 0.05) {
		float dn_dy = cos(v_world_pos.y * 0.15) * 0.15;
		bump_normal = normalize(n + vec3(0.0, dn_dy * cliff_weight, 0.0));
	}
	NORMAL = bump_normal;
}
