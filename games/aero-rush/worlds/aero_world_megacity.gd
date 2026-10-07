class_name AeroWorldMegacity
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Neon/Modern Megacity environment: Neo-Cascade Metropolis.
## High-rise commercial towers, gleaming glass skyscrapers, asphalt urban parcels,
## and glowing neon roadway lighting.

func build_environment() -> void:
	# Twilight Neon Metropolis Palette
	setup_lighting(
		Color(0.85, 0.90, 1.0),                  # Cool Sun Light
		1.6,                                     # Energy
		Vector3(-38.0, 45.0, 0.0),               # Angle
		Color(0.04, 0.08, 0.18),                 # Sky Top (Deep Indigo)
		Color(0.18, 0.22, 0.38),                 # Horizon (Neon Twilight)
		Color(0.15, 0.20, 0.32),                 # Fog Color
		0.0018                                   # Fog Density
	)

	# 1. Dark Urban Asphalt Foundation
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.12, 0.14, 0.16)
	ground_mat.roughness = 0.85
	ground_mat.metallic = 0.1
	create_ground_bed(1200.0, ground_mat, -0.4)

	# 2. Dense Architectural Grid (Skyscrapers & Commercial Towers)
	var skyscraper_models = [
		"res://assets/models/environment/building_skyscraper_a.glb",
		"res://assets/models/environment/building_skyscraper_b.glb",
		"res://assets/models/environment/building_skyscraper_c.glb",
		"res://assets/models/environment/building_skyscraper_d.glb",
		"res://assets/models/environment/building_skyscraper_e.glb"
	]
	var comm_models = [
		"res://assets/models/environment/building_comm_a.glb",
		"res://assets/models/environment/building_comm_b.glb",
		"res://assets/models/environment/building_comm_c.glb",
		"res://assets/models/environment/building_comm_d.glb",
		"res://assets/models/environment/building_comm_e.glb",
		"res://assets/models/environment/building_comm_f.glb"
	]

	# Perimeter and Midground Skyscraper Cluster
	var bld_positions = [
		Vector3(-85, 0, -120), Vector3(95, 0, -140),
		Vector3(-120, 0, -250), Vector3(150, 0, -280),
		Vector3(-140, 0, 50), Vector3(180, 0, 80),
		Vector3(-90, 0, 180), Vector3(110, 0, 200),
		Vector3(-220, 0, -180), Vector3(250, 0, -220),
		Vector3(-260, 0, 80), Vector3(280, 0, 120),
		Vector3(0, 0, -380), Vector3(-180, 0, -340), Vector3(220, 0, -360)
	]

	for i in range(bld_positions.size()):
		var pos = bld_positions[i]
		var m_path = skyscraper_models[i % skyscraper_models.size()]
		var scale_y = randf_range(1.1, 1.8)
		spawn_building(m_path, pos, float(i * 45), Vector3(1.2, scale_y, 1.2))

	# Secondary Commercial Structures
	var comm_positions = [
		Vector3(-60, 0, -60), Vector3(70, 0, -70),
		Vector3(-70, 0, 100), Vector3(85, 0, 110),
		Vector3(-160, 0, -80), Vector3(190, 0, -100)
	]
	for j in range(comm_positions.size()):
		var c_pos = comm_positions[j]
		var c_path = comm_models[j % comm_models.size()]
		spawn_building(c_path, c_pos, float(j * 90), Vector3(1.0, 1.0, 1.0))

	# 3. Urban Streetlight Posts along perimeter
	for k in range(-5, 6):
		var lp_pos = Vector3(float(k * 45), 0, -15.0)
		spawn_building("res://assets/models/environment/road_lightposts.glb", lp_pos, 0.0, Vector3(1.2, 1.2, 1.2))
