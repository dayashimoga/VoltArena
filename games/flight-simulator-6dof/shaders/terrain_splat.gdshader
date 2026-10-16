shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Triplanar procedural splatmap shader for flight simulator terrain.
// Blends grass (lowlands), slope-based rock (cliffs), and snow (> 1800m MSL) with procedural anti-tiling.

uniform vec4 grass_color : source_color = vec4(0.22, 0.38, 0.16, 1.0);
uniform vec4 rock_color : source_color = vec4(0.35, 0.33, 0.31, 1.0);
uniform vec4 snow_color : source_color = vec4(0.92, 0.94, 0.98, 1.0);

uniform float snow_altitude_min : hint_range(1000.0, 3000.0) = 1750.0;
uniform float snow_altitude_full : hint_range(1200.0, 3500.0) = 1950.0;
uniform float rock_slope_threshold : hint_range(0.1, 0.9) = 0.65;
uniform float uv_scale : hint_range(0.001, 0.1) = 0.02;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

// Simple hash / pseudo-random generator for procedural anti-tiling
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D value noise for surface microdetail
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(v_world_normal);
	float slope = 1.0 - abs(n.y); // 0.0 = flat ground, 1.0 = vertical cliff

	// Triplanar projection blending weights
	vec3 blending = abs(n);
	blending = normalize(max(blending, 0.00001));
	float b_total = blending.x + blending.y + blending.z;
	blending /= b_total;

	// Microdetail noise coordinates
	vec2 uv_xz = v_world_pos.xz * uv_scale;
	float detail_noise = noise(uv_xz * 8.0) * 0.15 - 0.075;
	float macro_noise = noise(uv_xz * 0.5) * 0.25;

	// Slope-based rock mask
	float rock_factor = smoothstep(rock_slope_threshold - 0.15, rock_slope_threshold + 0.1, slope + detail_noise);

	// Altitude-based snow mask (above ~1800m MSL)
	float alt = v_world_pos.y + macro_noise * 120.0;
	float snow_factor = smoothstep(snow_altitude_min, snow_altitude_full, alt);
	// Snow only accumulates on gentler slopes (< 60 degrees)
	snow_factor *= (1.0 - smoothstep(0.55, 0.85, slope));

	// Layer blending
	vec3 base_grass = grass_color.rgb + vec3(detail_noise);
	vec3 base_rock = rock_color.rgb + vec3(detail_noise * 1.5);
	vec3 base_snow = snow_color.rgb;

	vec3 surface_color = mix(base_grass, base_rock, rock_factor);
	surface_color = mix(surface_color, base_snow, snow_factor);

	ALBEDO = surface_color;
	ROUGHNESS = mix(0.85, 0.45, snow_factor);
	METALLIC = 0.0;
	SPECULAR = 0.2;
}
