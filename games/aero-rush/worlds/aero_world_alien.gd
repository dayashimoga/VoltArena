class_name AeroWorldAlien
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Alien Planet environment: Xenon Prime.
## Extraterrestrial flora, bioluminescent spires, purple-emerald atmospheric haze, and crystalline mesas.

func build_environment() -> void:
	# Exotic Bioluminescent Alien Sky Lighting
	setup_lighting(
		Color(0.45, 0.95, 0.85),                  # Cyan Key Sun
		1.95,                                    # Sun Energy
		Vector3(-35.0, 50.0, 0.0),               # Sun Angle
		Color(0.28, 0.08, 0.42),                 # Sky Top (Deep Violet)
		Color(0.08, 0.72, 0.65),                 # Sky Horizon (Emerald-Cyan)
		Color(0.18, 0.45, 0.55),                 # Atmospheric Fog (Teal)
		0.0014                                   # Fog Density
	)

	# 1. Extraterrestrial Crystalline Terrain Bed
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.16, 0.24)
	ground_mat.roughness = 0.88
	ground_mat.metallic = 0.15
	ground_mat.emission_enabled = true
	ground_mat.emission = Color(0.02, 0.10, 0.14)
	create_ground_bed(1600.0, ground_mat, -1.0)

	# 2. Glowing Monolithic Crystal Spires
	var crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.15, 0.85, 0.95)
	crystal_mat.metallic = 0.85
	crystal_mat.roughness = 0.12
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.10, 0.75, 0.90)
	crystal_mat.emission_energy_multiplier = 1.4

	var spire_positions = [
		Vector3(-160, 0, -200), Vector3(180, 0, -240),
		Vector3(-240, 0, -420), Vector3(260, 0, -460),
		Vector3(-200, 0, 100), Vector3(220, 0, 140),
		Vector3(0, 0, -600), Vector3(-140, 0, -700), Vector3(180, 0, -720)
	]

	for s_pos in spire_positions:
		var spire = MeshInstance3D.new()
		var prism = PrismMesh.new()
		var h = randf_range(50.0, 95.0)
		var w = randf_range(16.0, 32.0)
		prism.size = Vector3(w, h, w)
		spire.mesh = prism
		spire.material_override = crystal_mat
		spire.position = Vector3(s_pos.x, h * 0.5 - 2.0, s_pos.z)
		spire.rotation_degrees.y = randf_range(0.0, 360.0)
		add_child(spire)

		var beacon = OmniLight3D.new()
		beacon.light_color = Color(0.15, 0.90, 1.0)
		beacon.light_energy = 2.5
		beacon.omni_range = 45.0
		beacon.position = Vector3(s_pos.x, h * 0.7, s_pos.z)
		add_child(beacon)

	# 3. Bioluminescent Alien Trees (Palm & Tall models with reactive emerald/cyan shaders)
	var tree_models = [
		"res://assets/models/environment/tree_palm.glb",
		"res://assets/models/environment/tree_tall.glb"
	]

	for t in range(45):
		var ang = randf() * TAU
		var rad = randf_range(60.0, 340.0)
		var t_pos = Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var t_path = tree_models[t % tree_models.size()]
		var tree_node = spawn_tree(t_path, t_pos, Vector2(1.2, 2.2))
		if tree_node:
			var light = OmniLight3D.new()
			light.light_color = Color(0.2, 1.0, 0.6) if t % 2 == 0 else Color(0.8, 0.2, 1.0)
			light.light_energy = 1.2
			light.omni_range = 14.0
			light.position = t_pos + Vector3(0, 4.0, 0)
			add_child(light)
