class_name AeroWorldSky
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## High-Altitude / Sky Circuit environment: Strato Pylon.
## Stratospheric tracks suspended high above the cloud layer with magnetic pylons.

func build_environment() -> void:
	# High-Altitude Stratosphere Lighting
	setup_lighting(
		Color(1.0, 0.98, 0.92),                  # Pure Sunlight
		2.6,                                     # Energy
		Vector3(-52.0, 50.0, 0.0),               # Angle
		Color(0.06, 0.12, 0.45),                 # Deep Upper Stratosphere Sky
		Color(0.55, 0.70, 0.92),                 # Lower Cloud Horizon
		Color(0.65, 0.78, 0.95),                 # Cloud Mist Fog
		0.0010                                   # Fog Density
	)

	# 1. Cloud Sea Platform below track
	var cloud_mat = StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(0.92, 0.94, 0.98, 0.90)
	cloud_mat.roughness = 0.95
	cloud_mat.emission_enabled = true
	cloud_mat.emission = Color(0.85, 0.88, 0.95) * 0.4
	create_ground_bed(2000.0, cloud_mat, 15.0)

	# 2. Magnetic Levitation Pylons & Tether Hubs
	var pylon_mat = StandardMaterial3D.new()
	pylon_mat.albedo_color = Color(0.20, 0.22, 0.28)
	pylon_mat.metallic = 0.9
	pylon_mat.roughness = 0.2

	var pylon_positions = [
		Vector3(-90, 40, -140), Vector3(110, 40, -180),
		Vector3(-140, 40, -280), Vector3(160, 40, -320),
		Vector3(-120, 40, 60), Vector3(140, 40, 90),
		Vector3(0, 40, -420)
	]

	for p_pos in pylon_positions:
		var pylon = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 4.5
		cyl.bottom_radius = 8.0
		cyl.height = 120.0
		pylon.mesh = cyl
		pylon.material_override = pylon_mat
		pylon.position = Vector3(p_pos.x, 60.0, p_pos.z)
		add_child(pylon)

		# Glowing Magnetic Emitter Ring
		var ring = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.inner_radius = 5.2
		torus.outer_radius = 7.5
		ring.mesh = torus

		var ring_mat = StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.1, 0.9, 1.0)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.1, 0.8, 1.0) * 4.0
		ring.material_override = ring_mat
		ring.position = Vector3(p_pos.x, 90.0, p_pos.z)
		add_child(ring)

	# 3. High-Tech Scifi Industrial Barriers
	var scifi_barrier = "res://assets/models/environment/scifi/barrier_high.glb"
	for s in range(-3, 4):
		var s_pos = Vector3(float(s * 40), 70.0, -50.0)
		spawn_building(scifi_barrier, s_pos, 0.0, Vector3(1.0, 1.0, 1.0))
