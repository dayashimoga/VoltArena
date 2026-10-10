class_name AeroWorldSpace
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Orbital Space environment: Orbital Zenith.
## Cosmic starfield, deep space void, orbital space station modules, and solar array satellites.

func build_environment() -> void:
	# Deep Orbital Cosmic Lighting (High-contrast solar irradiance with zero atmosphere)
	setup_lighting(
		Color(1.0, 0.98, 0.95),                  # Pure Sunlight
		2.4,                                     # Energy
		Vector3(-45.0, 60.0, 0.0),               # Sun Angle
		Color(0.01, 0.01, 0.04),                 # Sky Top (Pitch Cosmic Black)
		Color(0.06, 0.12, 0.28),                 # Horizon (Distant Earth Blue Limb)
		Color(0.02, 0.04, 0.10),                 # Deep Space Fog
		0.0003                                   # Thin Vacuum Fog
	)

	# 1. Distant Earth / Planetary Limb Disk below
	var earth_mat = StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.12, 0.35, 0.65) # Azure ocean
	earth_mat.roughness = 0.45
	earth_mat.metallic = 0.10
	earth_mat.emission_enabled = true
	earth_mat.emission = Color(0.08, 0.25, 0.50)
	earth_mat.emission_energy_multiplier = 0.6
	create_ground_bed(2800.0, earth_mat, -120.0)

	# 2. Orbital Space Station Modules & Solar Arrays
	var truss_mat = StandardMaterial3D.new()
	truss_mat.albedo_color = Color(0.85, 0.88, 0.92)
	truss_mat.metallic = 0.92
	truss_mat.roughness = 0.20

	var solar_mat = StandardMaterial3D.new()
	solar_mat.albedo_color = Color(0.08, 0.15, 0.45)
	solar_mat.metallic = 0.85
	solar_mat.roughness = 0.10
	solar_mat.emission_enabled = true
	solar_mat.emission = Color(0.04, 0.20, 0.60)
	solar_mat.emission_energy_multiplier = 1.2

	var station_coords = [
		Vector3(-220, 40, -250), Vector3(240, 30, -320),
		Vector3(-300, 60, -480), Vector3(320, 50, -520),
		Vector3(0, 80, -680)
	]

	for pos in station_coords:
		var st_node = Node3D.new()
		st_node.position = pos

		# Central Pressurized Habitation Hub
		var hub = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 12.0
		cyl.bottom_radius = 12.0
		cyl.height = 45.0
		hub.mesh = cyl
		hub.material_override = truss_mat
		st_node.add_child(hub)

		# Twin Photovoltaic Solar Wings
		for s_side in [-1.0, 1.0]:
			var panel = MeshInstance3D.new()
			var p_box = BoxMesh.new()
			p_box.size = Vector3(45.0, 0.4, 18.0)
			panel.mesh = p_box
			panel.material_override = solar_mat
			panel.position = Vector3(s_side * 36.0, 0.0, 0.0)
			st_node.add_child(panel)

		st_node.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
		add_child(st_node)
