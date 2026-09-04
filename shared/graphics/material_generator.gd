class_name MaterialGenerator
extends RefCounted

static var _cached_materials: Dictionary = {}

static func get_material(mat_type: String) -> StandardMaterial3D:
	if _cached_materials.has(mat_type):
		return _cached_materials[mat_type]

	var mat = StandardMaterial3D.new()
	match mat_type:
		"sci_fi_metal":
			mat.albedo_color = Color(0.18, 0.22, 0.28)
			mat.metallic = 0.85
			mat.roughness = 0.35
		"dark_hull":
			mat.albedo_color = Color(0.08, 0.10, 0.14)
			mat.metallic = 0.90
			mat.roughness = 0.40
		"neon_cyan":
			mat.albedo_color = Color(0.0, 0.9, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.9, 1.0)
			mat.emission_energy_multiplier = 2.0
		"neon_orange":
			mat.albedo_color = Color(1.0, 0.45, 0.0)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.45, 0.0)
			mat.emission_energy_multiplier = 2.2
		"neon_magenta":
			mat.albedo_color = Color(1.0, 0.0, 0.55)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.0, 0.55)
			mat.emission_energy_multiplier = 2.0
		"neon_green":
			mat.albedo_color = Color(0.1, 1.0, 0.3)
			mat.emission_enabled = true
			mat.emission = Color(0.1, 1.0, 0.3)
			mat.emission_energy_multiplier = 2.0
		"asphalt_track":
			mat.albedo_color = Color(0.12, 0.12, 0.14)
			mat.metallic = 0.1
			mat.roughness = 0.8
		"subway_tile":
			mat.albedo_color = Color(0.25, 0.28, 0.30)
			mat.metallic = 0.3
			mat.roughness = 0.5
		"grimy_concrete":
			mat.albedo_color = Color(0.18, 0.19, 0.20)
			mat.metallic = 0.05
			mat.roughness = 0.9
		"gold_pickup":
			mat.albedo_color = Color(1.0, 0.84, 0.0)
			mat.metallic = 0.95
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.65, 0.0)
			mat.emission_energy_multiplier = 0.8
		"health_red":
			mat.albedo_color = Color(0.9, 0.1, 0.15)
			mat.metallic = 0.5
			mat.roughness = 0.3
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.05, 0.1)
			mat.emission_energy_multiplier = 1.2
		"energy_ball":
			mat.albedo_color = Color(0.9, 0.95, 1.0)
			mat.metallic = 0.4
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.8, 1.0)
			mat.emission_energy_multiplier = 2.5
		"enemy_crawler":
			mat.albedo_color = Color(0.4, 0.1, 0.15)
			mat.metallic = 0.3
			mat.roughness = 0.7
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.1, 0.1)
			mat.emission_energy_multiplier = 1.0
		"dark_concrete":
			mat.albedo_color = Color(0.12, 0.13, 0.16)
			mat.metallic = 0.10
			mat.roughness = 0.85
		"asphalt":
			mat.albedo_color = Color(0.14, 0.14, 0.16)
			mat.metallic = 0.12
			mat.roughness = 0.82
		"grass":
			mat.albedo_color = Color(0.14, 0.32, 0.18)
			mat.metallic = 0.05
			mat.roughness = 0.90
		"neon_red":
			mat.albedo_color = Color(1.0, 0.10, 0.15)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.10, 0.15)
			mat.emission_energy_multiplier = 2.4
		"neon_blue":
			mat.albedo_color = Color(0.10, 0.40, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.10, 0.40, 1.0)
			mat.emission_energy_multiplier = 2.4
		"nitro_fire":
			mat.albedo_color = Color(1.0, 0.60, 0.10)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.45, 0.0)
			mat.emission_energy_multiplier = 3.2
		"sparks":
			mat.albedo_color = Color(1.0, 0.90, 0.50)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.80, 0.20)
			mat.emission_energy_multiplier = 4.0
		"drift_smoke":
			mat.albedo_color = Color(0.85, 0.88, 0.92, 0.6)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 1.0
			mat.metallic = 0.0
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
			mat.metallic = 0.5
			mat.roughness = 0.5

	_cached_materials[mat_type] = mat
	return mat

static func create_pbr_material(albedo: Color, metallic: float, roughness: float, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = clampf(metallic, 0.0, 1.0)
	mat.roughness = clampf(roughness, 0.0, 1.0)
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

static func clear_cache() -> void:
	_cached_materials.clear()
