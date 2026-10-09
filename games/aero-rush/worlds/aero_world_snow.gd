class_name AeroWorldSnow
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Snowbound Peaks: Alpine Winter Stunt Environment.
## Towering snow-capped mountain peaks, frozen glacial lakes, alpine pine forests,
## icy suspended roadway decking, and atmospheric snowfall weather particles.

const SNOW_GROUND_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert;

void fragment() {
	vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	float noise = sin(world_pos.x * 0.05) * cos(world_pos.y * 0.05);
	vec3 snow_col = mix(vec3(0.92, 0.95, 0.98), vec3(0.85, 0.91, 0.96), noise * 0.5 + 0.5);
	ALBEDO = snow_col;
	ROUGHNESS = 0.65;
	METALLIC = 0.05;
	SPECULAR = 0.60;
}
"""

func build_environment() -> void:
	# 1. Crisp Alpine Winter Lighting with Low Sun & Cool Sapphire Sky
	setup_lighting(
		Color(1.0, 0.94, 0.88),                  # Bright Crisp Sunlight
		2.3,                                     # Sunlight Energy
		Vector3(-32.0, 42.0, 0.0),               # Sun Angle
		Color(0.12, 0.32, 0.65),                 # Sky Top (Alpine Sapphire)
		Color(0.72, 0.84, 0.95),                 # Sky Horizon (Icy Mist)
		Color(0.80, 0.88, 0.96),                 # Volumetric Snow Fog
		0.0014                                   # Fog Density
	)

	# 2. Frozen Glacier / Snow Terrain Bed
	var snow_mat = ShaderMaterial.new()
	var s_sh = Shader.new()
	s_sh.code = SNOW_GROUND_SHADER
	snow_mat.shader = s_sh
	create_ground_bed(1600.0, snow_mat, -4.5)

	# 3. Frozen Lake Basin
	_build_frozen_lake()

	# 4. Mountain Peak Formations flanking track
	_build_mountain_peaks()

	# 5. Dense Alpine Pine Forest Clusters
	_build_alpine_forest()

	# 6. Snowfall Weather Particles
	_build_snowfall_emitter()

func _build_frozen_lake() -> void:
	var ice_mesh = MeshInstance3D.new()
	ice_mesh.name = "GlacialIceSheet"
	var plane = PlaneMesh.new()
	plane.size = Vector2(280.0, 1200.0)
	ice_mesh.mesh = plane

	var ice_mat = StandardMaterial3D.new()
	ice_mat.albedo_color = Color(0.55, 0.82, 0.94, 0.88)
	ice_mat.roughness = 0.12
	ice_mat.metallic = 0.25
	ice_mat.specular = 0.85
	ice_mesh.material_override = ice_mat
	ice_mesh.position = Vector3(140.0, -4.3, 0.0)
	add_child(ice_mesh)

func _build_mountain_peaks() -> void:
	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.35, 0.40, 0.46)
	rock_mat.roughness = 0.90

	var snow_cap_mat = StandardMaterial3D.new()
	snow_cap_mat.albedo_color = Color(0.95, 0.97, 1.0)
	snow_cap_mat.roughness = 0.60

	var peak_coords = [
		Vector3(-180, -4.5, -120), Vector3(-240, -4.5, -280),
		Vector3(-190, -4.5, -420), Vector3(220, -4.5, -180),
		Vector3(260, -4.5, -340), Vector3(190, -4.5, 60),
		Vector3(-220, -4.5, 90), Vector3(0, -4.5, -600)
	]

	for i in range(peak_coords.size()):
		var pos = peak_coords[i]
		var peak = MeshInstance3D.new()
		peak.name = "AlpinePeak_%d" % i
		var cone = CylinderMesh.new()
		cone.top_radius = 2.0
		cone.bottom_radius = randf_range(45.0, 75.0)
		cone.height = randf_range(90.0, 160.0)
		peak.mesh = cone
		peak.material_override = rock_mat
		peak.position = Vector3(pos.x, cone.height * 0.5 - 4.5, pos.z)
		add_child(peak)

		# Snow cap on top
		var cap = MeshInstance3D.new()
		var cap_cone = CylinderMesh.new()
		cap_cone.top_radius = 0.5
		cap_cone.bottom_radius = cone.bottom_radius * 0.45
		cap_cone.height = cone.height * 0.45
		cap.mesh = cap_cone
		cap.material_override = snow_cap_mat
		cap.position = Vector3(0, cone.height * 0.28, 0)
		peak.add_child(cap)

func _build_alpine_forest() -> void:
	var pine_path = "res://assets/models/environment/tree_pine.glb"
	for p in range(50):
		var ang = randf() * TAU
		var rad = randf_range(45.0, 320.0)
		var p_pos = Vector3(cos(ang) * rad, -4.5, sin(ang) * rad)
		spawn_tree(pine_path, p_pos, Vector2(1.2, 2.2))

func _build_snowfall_emitter() -> void:
	var particles = GPUParticles3D.new()
	particles.name = "SnowfallWeatherEmitter"
	particles.amount = 450
	particles.lifetime = 6.0
	particles.visibility_aabb = AABB(Vector3(-150, -20, -250), Vector3(300, 100, 500))

	var p_mat = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(90.0, 25.0, 140.0)
	p_mat.direction = Vector3(0.2, -1.0, 0.1).normalized()
	p_mat.spread = 15.0
	p_mat.initial_velocity_min = 4.0
	p_mat.initial_velocity_max = 8.0
	p_mat.gravity = Vector3(0, -3.5, 0)
	p_mat.scale_min = 0.08
	p_mat.scale_max = 0.22

	var flake_mesh = QuadMesh.new()
	flake_mesh.size = Vector2(0.25, 0.25)
	var flake_mat = StandardMaterial3D.new()
	flake_mat.albedo_color = Color(0.96, 0.98, 1.0, 0.85)
	flake_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flake_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake_mesh.material = flake_mat

	particles.process_material = p_mat
	particles.draw_pass_1 = flake_mesh
	particles.position = Vector3(0, 35.0, -100.0)
	add_child(particles)
