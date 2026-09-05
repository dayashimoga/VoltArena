class_name MaterialGenerator
extends RefCounted

const TexSynth = preload("res://shared/graphics/texture_synthesizer.gd")

static var _cached_materials: Dictionary = {}

static func get_material(mat_type: String) -> StandardMaterial3D:
	if _cached_materials.has(mat_type):
		return _cached_materials[mat_type]

	var mat = StandardMaterial3D.new()
	match mat_type:
		"sci_fi_metal":
			mat.albedo_color = Color(0.85, 0.90, 0.95)
			mat.albedo_texture = TexSynth.get_texture("sci_fi_metal_albedo")
			mat.normal_enabled = true
			mat.normal_texture = TexSynth.get_texture("sci_fi_metal_normal")
			mat.metallic = 0.80
			mat.roughness = 0.30
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"dark_hull":
			mat.albedo_color = Color(0.75, 0.80, 0.88)
			mat.albedo_texture = TexSynth.get_texture("dark_hull_albedo")
			mat.metallic = 0.85
			mat.roughness = 0.35
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"neon_cyan":
			mat.albedo_color = Color(0.1, 0.95, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.95, 1.0)
			mat.emission_energy_multiplier = 2.4
		"neon_orange":
			mat.albedo_color = Color(1.0, 0.55, 0.05)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.55, 0.05)
			mat.emission_energy_multiplier = 2.4
		"neon_magenta":
			mat.albedo_color = Color(1.0, 0.1, 0.65)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.1, 0.65)
			mat.emission_energy_multiplier = 2.2
		"neon_green":
			mat.albedo_color = Color(0.2, 1.0, 0.4)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 1.0, 0.4)
			mat.emission_energy_multiplier = 2.2
		"asphalt_track":
			mat.albedo_color = Color(0.85, 0.88, 0.92)
			mat.albedo_texture = TexSynth.get_texture("asphalt_albedo")
			mat.normal_enabled = true
			mat.normal_texture = TexSynth.get_texture("asphalt_normal")
			mat.metallic = 0.1
			mat.roughness = 0.75
			mat.uv1_scale = Vector3(2.0, 8.0, 2.0)
		"subway_tile":
			mat.albedo_color = Color(0.92, 0.94, 0.96)
			mat.albedo_texture = TexSynth.get_texture("subway_tile_albedo")
			mat.normal_enabled = true
			mat.normal_texture = TexSynth.get_texture("subway_tile_normal")
			mat.metallic = 0.25
			mat.roughness = 0.45
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"grimy_concrete":
			mat.albedo_color = Color(0.82, 0.84, 0.86)
			mat.albedo_texture = TexSynth.get_texture("grimy_concrete_albedo")
			mat.metallic = 0.08
			mat.roughness = 0.85
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"gold_pickup":
			mat.albedo_color = Color(1.0, 0.88, 0.15)
			mat.metallic = 0.95
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.75, 0.1)
			mat.emission_energy_multiplier = 1.2
		"health_red":
			mat.albedo_color = Color(0.95, 0.15, 0.2)
			mat.metallic = 0.5
			mat.roughness = 0.3
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.1, 0.15)
			mat.emission_energy_multiplier = 1.4
		"energy_ball":
			mat.albedo_color = Color(0.95, 0.98, 1.0)
			mat.metallic = 0.3
			mat.roughness = 0.15
			mat.emission_enabled = true
			mat.emission = Color(0.1, 0.85, 1.0)
			mat.emission_energy_multiplier = 2.8
		"enemy_crawler":
			mat.albedo_color = Color(0.65, 0.2, 0.25)
			mat.metallic = 0.4
			mat.roughness = 0.6
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.15, 0.15)
			mat.emission_energy_multiplier = 1.2
		"dark_concrete":
			mat.albedo_color = Color(0.70, 0.72, 0.76)
			mat.albedo_texture = TexSynth.get_texture("grimy_concrete_albedo")
			mat.metallic = 0.10
			mat.roughness = 0.80
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"asphalt":
			mat.albedo_color = Color(0.85, 0.88, 0.92)
			mat.albedo_texture = TexSynth.get_texture("asphalt_albedo")
			mat.normal_enabled = true
			mat.normal_texture = TexSynth.get_texture("asphalt_normal")
			mat.metallic = 0.12
			mat.roughness = 0.80
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"grass":
			mat.albedo_color = Color(0.75, 0.90, 0.78)
			mat.albedo_texture = TexSynth.get_texture("stadium_pitch_albedo")
			mat.metallic = 0.05
			mat.roughness = 0.85
			mat.uv1_scale = Vector3(8.0, 8.0, 8.0)
		"stadium_pitch":
			mat.albedo_color = Color(0.90, 0.98, 0.92)
			mat.albedo_texture = TexSynth.get_texture("stadium_pitch_albedo")
			mat.metallic = 0.04
			mat.roughness = 0.85
		"hazard_stripe":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mat.albedo_texture = TexSynth.get_texture("hazard_stripe_albedo")
			mat.roughness = 0.5
			mat.uv1_scale = Vector3(4.0, 1.0, 4.0)
		"curb_stripes":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mat.albedo_texture = TexSynth.get_texture("curb_stripes_albedo")
			mat.roughness = 0.6
			mat.uv1_scale = Vector3(8.0, 1.0, 1.0)
		"digital_signage_cyan":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mat.albedo_texture = TexSynth.get_texture("digital_signage_cyan")
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.9, 1.0)
			mat.emission_energy_multiplier = 1.6
		"digital_signage_orange":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mat.albedo_texture = TexSynth.get_texture("digital_signage_orange")
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.5, 0.0)
			mat.emission_energy_multiplier = 1.6
		"stadium_spectators":
			mat.albedo_color = Color(0.85, 0.90, 0.95)
			mat.albedo_texture = TexSynth.get_texture("stadium_spectators")
			mat.roughness = 0.7
			mat.uv1_scale = Vector3(6.0, 2.0, 1.0)
		"neon_red":
			mat.albedo_color = Color(1.0, 0.15, 0.20)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.15, 0.20)
			mat.emission_energy_multiplier = 2.4
		"neon_blue":
			mat.albedo_color = Color(0.20, 0.55, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.20, 0.55, 1.0)
			mat.emission_energy_multiplier = 2.4
		"nitro_fire":
			mat.albedo_color = Color(1.0, 0.65, 0.15)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.50, 0.05)
			mat.emission_energy_multiplier = 3.5
		"sparks":
			mat.albedo_color = Color(1.0, 0.95, 0.60)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.85, 0.25)
			mat.emission_energy_multiplier = 4.5
		"drift_smoke":
			mat.albedo_color = Color(0.88, 0.90, 0.94, 0.6)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.roughness = 1.0
			mat.metallic = 0.0
		"stadium_pitch_day":
			mat.albedo_color = Color(0.92, 0.98, 0.92)
			mat.albedo_texture = TexSynth.get_texture("stadium_pitch_day")
			mat.metallic = 0.04
			mat.roughness = 0.80
		"stadium_pitch_cyber":
			mat.albedo_color = Color(0.90, 0.95, 1.0)
			mat.albedo_texture = TexSynth.get_texture("stadium_pitch_cyber")
			mat.metallic = 0.25
			mat.roughness = 0.60
		"canyon_rock":
			mat.albedo_color = Color(0.95, 0.90, 0.85)
			mat.albedo_texture = TexSynth.get_texture("canyon_rock")
			mat.normal_enabled = true
			mat.normal_texture = TexSynth.get_texture("canyon_rock_normal")
			mat.metallic = 0.08
			mat.roughness = 0.88
			mat.uv1_scale = Vector3(2.0, 4.0, 2.0)
		"snow_ice":
			mat.albedo_color = Color(0.95, 0.98, 1.0)
			mat.albedo_texture = TexSynth.get_texture("snow_ice")
			mat.metallic = 0.15
			mat.roughness = 0.35
			mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
		"subway_rust_metal":
			mat.albedo_color = Color(0.88, 0.88, 0.88)
			mat.albedo_texture = TexSynth.get_texture("subway_rust_metal")
			mat.metallic = 0.75
			mat.roughness = 0.45
			mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
		"acid_pool":
			mat.albedo_color = Color(0.2, 1.0, 0.2)
			mat.albedo_texture = TexSynth.get_texture("acid_pool")
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.95, 0.1)
			mat.emission_energy_multiplier = 2.8
			mat.roughness = 0.2
		"ball_hex_glow":
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			mat.albedo_texture = TexSynth.get_texture("ball_hex_glow")
			mat.emission_enabled = true
			mat.emission = Color(0.0, 0.85, 1.0)
			mat.emission_energy_multiplier = 1.8
			mat.metallic = 0.2
			mat.roughness = 0.3
		"neon_yellow":
			mat.albedo_color = Color(1.0, 0.95, 0.1)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.95, 0.1)
			mat.emission_energy_multiplier = 2.4
		"neon_purple":
			mat.albedo_color = Color(0.8, 0.2, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.2, 1.0)
			mat.emission_energy_multiplier = 2.8
		_:
			mat.albedo_color = Color(0.7, 0.7, 0.7)
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
