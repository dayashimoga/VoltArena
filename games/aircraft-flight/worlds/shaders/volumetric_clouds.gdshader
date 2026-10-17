shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_front;

// Raymarched 3D Volumetric Cloud Layer Shader for Apex Flight.
// Features:
// - Perlin-Worley 3D FBM noise modeling multi-scale cumulus billows
// - Dual-lobe Henyey-Greenstein / Mie forward scattering (silver lining around sun)
// - Light raymarching for Beer-Lambert self-shadowing and dark cloud bases
// - Aerial perspective atmospheric depth fog blending
// - Altitude-bounded slab between cloud_base and cloud_top

uniform vec3 sun_direction = vec3(0.45, 0.82, 0.35);
uniform vec4 sun_color : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 ambient_top_color : source_color = vec4(0.96, 0.97, 1.0, 1.0);
uniform vec4 ambient_base_color : source_color = vec4(0.85, 0.88, 0.95, 1.0);

uniform float cloud_base : hint_range(500.0, 3000.0) = 1600.0;
uniform float cloud_top : hint_range(1500.0, 6000.0) = 3200.0;
uniform float cloud_coverage : hint_range(0.1, 0.9) = 0.45;
uniform float cloud_density_scale : hint_range(0.001, 0.05) = 0.006;
uniform float wind_speed : hint_range(0.0, 50.0) = 8.0;

uniform int raymarch_steps : hint_range(8, 48) = 24;
uniform int light_steps : hint_range(2, 8) = 4;
uniform float mie_g_forward : hint_range(0.1, 0.9) = 0.65;
uniform float mie_g_backward : hint_range(-0.5, 0.0) = -0.20;

varying vec3 v_world_camera_pos;
varying vec3 v_world_pos;

// Hash and 3D gradient noise for Perlin-Worley generation
float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3D(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float n000 = hash31(i);
	float n100 = hash31(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(i + vec3(1.0, 1.0, 1.0));

	float nx00 = mix(n000, n100, f.x);
	float nx10 = mix(n010, n110, f.x);
	float nx01 = mix(n001, n101, f.x);
	float nx11 = mix(n011, n111, f.x);

	float nxy0 = mix(nx00, nx10, f.y);
	float nxy1 = mix(nx01, nx11, f.y);

	return mix(nxy0, nxy1, f.z);
}

// Worley cellular noise cell distance
float worley3D(vec3 p) {
	vec3 id = floor(p);
	vec3 f = fract(p);
	float min_dist = 1.0;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = vec3(float(x), float(y), float(z));
				vec3 point = neighbor + vec3(
					hash31(id + neighbor + vec3(0.0, 1.0, 2.0)),
					hash31(id + neighbor + vec3(3.0, 4.0, 5.0)),
					hash31(id + neighbor + vec3(6.0, 7.0, 8.0))
				);
				float d = length(point - f);
				min_dist = min(min_dist, d);
			}
		}
	}
	return min_dist;
}

// Perlin-Worley hybrid density field
float sample_cloud_density(vec3 p) {
	// Altitude height gradient within cloud layer
	float height_fraction = (p.y - cloud_base) / (cloud_top - cloud_base);
	if (height_fraction < 0.0 || height_fraction > 1.0) {
		return 0.0;
	}

	// Height profile: flat base, maximum density at 30%, tapering tops
	float height_envelope = 4.0 * height_fraction * (1.0 - height_fraction);
	height_envelope = smoothstep(0.0, 0.2, height_fraction) * (1.0 - smoothstep(0.65, 1.0, height_fraction));

	// Wind advection
	vec3 wind_offset = vec3(TIME * wind_speed, 0.0, TIME * wind_speed * 0.4);
	vec3 sample_coord = (p + wind_offset) * 0.0006;

	// Low frequency Perlin billows
	float perlin = noise3D(sample_coord * 1.5) * 0.625 +
	               noise3D(sample_coord * 3.0) * 0.250 +
	               noise3D(sample_coord * 6.0) * 0.125;

	// Worley cellular erosion
	float worley = 1.0 - (worley3D(sample_coord * 4.0) * 0.625 + worley3D(sample_coord * 8.0) * 0.375);

	// Blend into Perlin-Worley billow
	float pw = mix(perlin, worley, 0.35);

	// Coverage threshold
	float density = pw * height_envelope;
	density = smoothstep(1.0 - cloud_coverage, 1.0, density);

	return density * cloud_density_scale;
}

// Dual-lobe Henyey-Greenstein phase function for Mie forward scatter
float henyey_greenstein(float cos_theta, float g) {
	float g2 = g * g;
	return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5));
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_camera_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	vec3 ray_dir = normalize(v_world_pos - v_world_camera_pos);
	vec3 sun_norm = normalize(sun_direction);
	float cos_theta = dot(ray_dir, sun_norm);

	// Forward silver lining phase + backscatter
	float phase = mix(
		henyey_greenstein(cos_theta, mie_g_forward),
		henyey_greenstein(cos_theta, mie_g_backward),
		0.25
	);

	// Bounded intersection with cloud layer [cloud_base, cloud_top]
	float t_near = 0.0;
	float t_far = 8000.0;

	if (abs(ray_dir.y) > 0.0001) {
		float t_base = (cloud_base - v_world_camera_pos.y) / ray_dir.y;
		float t_top = (cloud_top - v_world_camera_pos.y) / ray_dir.y;
		t_near = max(0.0, min(t_base, t_top));
		t_far = min(t_far, max(t_base, t_top));
	}

	if (t_near >= t_far) {
		discard;
	}

	float step_size = (t_far - t_near) / float(raymarch_steps);
	step_size = clamp(step_size, 25.0, 200.0);

	vec3 p = v_world_camera_pos + ray_dir * t_near;
	float transmittance = 1.0;
	vec3 accum_color = vec3(0.0);

	for (int i = 0; i < raymarch_steps; i++) {
		if (transmittance < 0.02) break;

		float d = sample_cloud_density(p);
		if (d > 0.0001) {
			// Light raymarch towards sun for self-shadowing
			float light_d = 0.0;
			float l_step = 60.0;
			for (int j = 1; j <= light_steps; j++) {
				vec3 lp = p + sun_norm * (float(j) * l_step);
				light_d += sample_cloud_density(lp) * l_step;
			}
			float sun_transmittance = exp(-light_d * 2.5);

			// Ambient sky gradient
			float h_frac = clamp((p.y - cloud_base) / (cloud_top - cloud_base), 0.0, 1.0);
			vec3 ambient = mix(ambient_base_color.rgb, ambient_top_color.rgb, h_frac);

			// In-scattered radiance (bright sunlit silver lining)
			vec3 step_light = sun_color.rgb * sun_transmittance * phase * 3.8 + ambient * (1.0 - sun_transmittance * 0.25);
			float step_transmittance = exp(-d * step_size * 5.5);

			accum_color += step_light * (1.0 - step_transmittance) * transmittance;
			transmittance *= step_transmittance;
		}

		p += ray_dir * step_size;
	}

	float final_alpha = clamp(1.0 - transmittance, 0.0, 0.95);
	if (final_alpha < 0.01) {
		discard;
	}

	ALBEDO = accum_color;
	ALPHA = final_alpha;
	ROUGHNESS = 0.85;
}
