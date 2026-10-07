class_name AeroWorldCoastal
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Tropical / Coastal environment: Azure Coast.
## Deep azure ocean waters, sandy shoreline boardwalks, and palm groves.

func build_environment() -> void:
	# Vibrant Tropical Ocean Sun Lighting
	setup_lighting(
		Color(1.0, 0.96, 0.88),                  # Bright Sun
		2.4,                                     # Energy
		Vector3(-45.0, 60.0, 0.0),               # Angle
		Color(0.12, 0.55, 0.95),                 # Sky Top (Azure Cyan)
		Color(0.65, 0.88, 0.98),                 # Sky Horizon
		Color(0.70, 0.90, 0.98),                 # Fog Color
		0.0012                                   # Fog Density
	)

	# 1. Azure Ocean Water Bed
	var ocean_mat = StandardMaterial3D.new()
	ocean_mat.albedo_color = Color(0.06, 0.42, 0.65, 0.85)
	ocean_mat.roughness = 0.05
	ocean_mat.metallic = 0.45
	ocean_mat.specular = 0.95
	create_ground_bed(1500.0, ocean_mat, -2.5)

	# 2. Sandy Coastal Shoreline Platform
	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.92, 0.84, 0.65)
	sand_mat.roughness = 0.90
	var shore = create_ground_bed(700.0, sand_mat, -0.2)
	shore.position = Vector3(120.0, -0.2, 0.0)

	# 3. Palm Tree Groves along coastline
	var palm_model = "res://assets/models/environment/tree_palm.glb"
	for p in range(35):
		var ang = randf() * TAU
		var rad = randf_range(40.0, 260.0)
		var p_pos = Vector3(100.0 + cos(ang) * rad, 0.0, sin(ang) * rad)
		spawn_tree(palm_model, p_pos, Vector2(1.1, 1.9))

	# 4. Coastal Barrier Props along shore
	var barrier_path = "res://assets/models/environment/racing/barrier_wall.glb"
	for b in range(-4, 5):
		var b_pos = Vector3(float(b * 35), 0.0, 20.0)
		spawn_building(barrier_path, b_pos, 0.0, Vector3(1.0, 1.0, 1.0))
