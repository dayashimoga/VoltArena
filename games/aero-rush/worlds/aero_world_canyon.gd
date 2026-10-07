class_name AeroWorldCanyon
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Mountain / Canyon environment: Red Rock Ridge.
## Towering red sandstone mesas, chasm cliffs, desert terrain, and evergreen pines.

func build_environment() -> void:
	# Golden Hour Desert Canyon Lighting
	setup_lighting(
		Color(1.0, 0.78, 0.45),                  # Warm Sun
		2.1,                                     # Energy
		Vector3(-28.0, 35.0, 0.0),               # Sun Angle
		Color(0.20, 0.45, 0.75),                 # Sky Top (Deep Blue)
		Color(0.92, 0.65, 0.40),                 # Sky Horizon (Dusty Amber)
		Color(0.85, 0.55, 0.35),                 # Fog Color
		0.0016                                   # Fog Density
	)

	# 1. Red Rock Sandstone Terrain Bed
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.72, 0.36, 0.22)
	ground_mat.roughness = 0.95
	ground_mat.metallic = 0.02
	create_ground_bed(1400.0, ground_mat, -1.0)

	# 2. Large Red Rock Mesas & Cliff Formations
	var mesa_mat = StandardMaterial3D.new()
	mesa_mat.albedo_color = Color(0.68, 0.32, 0.18)
	mesa_mat.roughness = 0.92

	var mesa_positions = [
		Vector3(-140, 0, -180), Vector3(160, 0, -220),
		Vector3(-220, 0, -380), Vector3(250, 0, -420),
		Vector3(-180, 0, 80), Vector3(200, 0, 120),
		Vector3(0, 0, -550), Vector3(-120, 0, -650), Vector3(160, 0, -680)
	]

	for m_pos in mesa_positions:
		var mesa = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = randf_range(25.0, 45.0)
		cyl.bottom_radius = randf_range(35.0, 60.0)
		cyl.height = randf_range(40.0, 80.0)
		mesa.mesh = cyl
		mesa.material_override = mesa_mat
		mesa.position = Vector3(m_pos.x, cyl.height * 0.5 - 2.0, m_pos.z)
		add_child(mesa)

	# 3. Dense Pine & Oak Forest Clusters
	var tree_models = [
		"res://assets/models/environment/tree_pine.glb",
		"res://assets/models/environment/tree_detailed.glb",
		"res://assets/models/environment/tree_oak.glb"
	]

	for t in range(40):
		var ang = randf() * TAU
		var rad = randf_range(50.0, 320.0)
		var t_pos = Vector3(cos(ang) * rad, 0.0, sin(ang) * rad)
		var t_path = tree_models[t % tree_models.size()]
		spawn_tree(t_path, t_pos, Vector2(1.0, 1.8))
