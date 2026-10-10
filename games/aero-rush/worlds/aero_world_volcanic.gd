class_name AeroWorldVolcanic
extends "res://games/aero-rush/worlds/aero_world_base.gd"

## Volcanic Underworld environment: Molten Caldera.
## Glowing magma fissures, basalt crags, volcanic ash atmosphere, and thermal ember glow.

func build_environment() -> void:
	# Fiery Volcanic Ash Atmosphere Lighting
	setup_lighting(
		Color(1.0, 0.42, 0.12),                  # Radiant Magma Sun
		2.1,                                     # Energy
		Vector3(-30.0, 40.0, 0.0),               # Sun Angle
		Color(0.18, 0.05, 0.04),                 # Sky Top (Dark Volcanic Ash)
		Color(0.85, 0.28, 0.08),                 # Sky Horizon (Fiery Magma Glow)
		Color(0.65, 0.20, 0.05),                 # Ash Fog
		0.0018                                   # Fog Density
	)

	# 1. Molten Magma Caldera Bed
	var lava_mat = StandardMaterial3D.new()
	lava_mat.albedo_color = Color(0.95, 0.32, 0.05)
	lava_mat.roughness = 0.35
	lava_mat.metallic = 0.10
	lava_mat.emission_enabled = true
	lava_mat.emission = Color(1.0, 0.38, 0.05)
	lava_mat.emission_energy_multiplier = 1.6
	create_ground_bed(1600.0, lava_mat, -2.0)

	# 2. Jagged Basalt / Obsidian Crags
	var basalt_mat = StandardMaterial3D.new()
	basalt_mat.albedo_color = Color(0.14, 0.13, 0.15)
	basalt_mat.roughness = 0.85
	basalt_mat.metallic = 0.25

	var crag_positions = [
		Vector3(-150, 0, -180), Vector3(170, 0, -210),
		Vector3(-230, 0, -390), Vector3(250, 0, -430),
		Vector3(-190, 0, 90), Vector3(210, 0, 130),
		Vector3(0, 0, -560), Vector3(-130, 0, -660), Vector3(170, 0, -690)
	]

	for c_pos in crag_positions:
		var crag = MeshInstance3D.new()
		var prism = PrismMesh.new()
		var h = randf_range(40.0, 75.0)
		var w = randf_range(25.0, 50.0)
		prism.size = Vector3(w, h, w)
		crag.mesh = prism
		crag.material_override = basalt_mat
		crag.position = Vector3(c_pos.x, h * 0.5 - 2.0, c_pos.z)
		crag.rotation_degrees.y = randf_range(0.0, 360.0)
		add_child(crag)

		# Thermal lava vent light at base
		var vent_light = OmniLight3D.new()
		vent_light.light_color = Color(1.0, 0.35, 0.08)
		vent_light.light_energy = 3.2
		vent_light.omni_range = 35.0
		vent_light.position = c_pos + Vector3(0, 1.5, 0)
		add_child(vent_light)
