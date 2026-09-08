class_name BossArchetypes
extends RefCounted

## Factory for all 8 campaign bosses in Strike Vector.
## Each boss features multi-phase mechanics, unique telegraphs, exposed weakness windows, and custom models.

const StrikeBossBaseScript = preload("res://games/strike-vector/bosses/strike_boss_base.gd")

static func create_boss_by_mission(mission_index: int) -> CharacterBody3D:
	match mission_index:
		1: return create_m1_urban_jammer_mech()
		2: return create_m2_vtol_gunship()
		3: return create_m3_gantry_loader_titan()
		4: return create_m4_convoy_battle_rig()
		5: return create_m5_subzero_walker()
		6: return create_m6_megafactory_apex_robot()
		7: return create_m7_sky_fortress_core()
		8: return create_m8_citadel_overlord()
		_: return create_m1_urban_jammer_mech()

# M1: Urban Jammer Command Mech
static func create_m1_urban_jammer_mech() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "UrbanJammerMech"
	b.boss_id = "m1_jammer_mech"
	b.boss_name = "Urban Jammer Command Mech"
	b.max_health_per_phase = 400.0
	b.total_phases = 2
	b.score_value = 5000
	_build_mech_model(b, Color(0.2, 0.25, 0.35), Color(1.0, 0.2, 0.1))
	return b

# M2: High-Speed VTOL Strike Gunship
static func create_m2_vtol_gunship() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "VTOLGunship"
	b.boss_id = "m2_vtol_gunship"
	b.boss_name = "Apex VTOL Strike Craft"
	b.max_health_per_phase = 450.0
	b.total_phases = 2
	b.score_value = 6000
	_build_aircraft_model(b, Color(0.18, 0.22, 0.28), Color(0.1, 0.85, 1.0))
	return b

# M3: Heavy Cargo-Loader Gantry Mech
static func create_m3_gantry_loader_titan() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "GantryLoaderTitan"
	b.boss_id = "m3_gantry_titan"
	b.boss_name = "Harbor Gantry Loader Titan"
	b.max_health_per_phase = 500.0
	b.total_phases = 2
	b.score_value = 7000
	_build_industrial_mech_model(b, Color(0.85, 0.65, 0.1), Color(1.0, 0.4, 0.0))
	return b

# M4: Armored Convoy Dreadnought / Battle Rig
static func create_m4_convoy_battle_rig() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "ConvoyBattleRig"
	b.boss_id = "m4_battle_rig"
	b.boss_name = "Convoy Dreadnought Battle Rig"
	b.max_health_per_phase = 550.0
	b.total_phases = 2
	b.score_value = 8000
	_build_tank_rig_model(b, Color(0.35, 0.30, 0.20), Color(1.0, 0.3, 0.1))
	return b

# M5: Arctic Sub-Zero Bipedal Walker
static func create_m5_subzero_walker() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "SubZeroWalker"
	b.boss_id = "m5_subzero_walker"
	b.boss_name = "Arctic Sub-Zero Bipedal Walker"
	b.max_health_per_phase = 600.0
	b.total_phases = 2
	b.score_value = 9000
	_build_mech_model(b, Color(0.7, 0.8, 0.9), Color(0.2, 0.9, 1.0))
	return b

# M6: Megafactory Apex Defense Robot
static func create_m6_megafactory_apex_robot() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "MegafactoryApexRobot"
	b.boss_id = "m6_megafactory_robot"
	b.boss_name = "Apex Factory Defense Automaton"
	b.max_health_per_phase = 650.0
	b.total_phases = 2
	b.score_value = 10000
	_build_industrial_mech_model(b, Color(0.25, 0.25, 0.25), Color(1.0, 0.15, 0.15))
	return b

# M7: Sky Fortress Aerial Core Platform
static func create_m7_sky_fortress_core() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "SkyFortressCore"
	b.boss_id = "m7_sky_core"
	b.boss_name = "Sky Fortress Aerial Core Platform"
	b.max_health_per_phase = 700.0
	b.total_phases = 2
	b.score_value = 12000
	_build_aerial_core_model(b, Color(0.15, 0.2, 0.35), Color(0.8, 0.2, 1.0))
	return b

# M8: Final Citadel Multi-Phase Command Overlord
static func create_m8_citadel_overlord() -> CharacterBody3D:
	var b = StrikeBossBaseScript.new()
	b.name = "CitadelOverlord"
	b.boss_id = "m8_citadel_overlord"
	b.boss_name = "Citadel Command Overlord"
	b.max_health_per_phase = 500.0
	b.total_phases = 3 # 3 Phases!
	b.score_value = 20000
	_build_citadel_overlord_model(b, Color(0.1, 0.12, 0.16), Color(1.0, 0.1, 0.2))
	return b

# --- Model Builders ---

static func _build_mech_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.8
	mat_hull.roughness = 0.3

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 4.0

	# Main Chassis
	_add_box(root, Vector3(3.2, 2.4, 3.8), Vector3(0, 3.2, 0), mat_hull)
	# Heavy Dual Cannons
	_add_box(root, Vector3(0.6, 0.6, 3.2), Vector3(-1.8, 3.2, -1.2), mat_hull)
	_add_box(root, Vector3(0.6, 0.6, 3.2), Vector3(1.8, 3.2, -1.2), mat_hull)
	# Sturdy Legs
	_add_box(root, Vector3(0.9, 2.4, 0.9), Vector3(-1.4, 1.2, 0), mat_hull)
	_add_box(root, Vector3(0.9, 2.4, 0.9), Vector3(1.4, 1.2, 0), mat_hull)
	# Weakpoint Core on back
	var core = _add_box(root, Vector3(1.0, 1.0, 0.4), Vector3(0, 3.2, 2.0), mat_glow)
	core.name = "CoolantCore"
	parent.coolant_core = core

static func _build_aircraft_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.85
	mat_hull.roughness = 0.25

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 4.5

	# Fuselage
	_add_box(root, Vector3(2.8, 1.6, 6.5), Vector3(0, 2.5, 0), mat_hull)
	# Swept Wings
	_add_box(root, Vector3(7.5, 0.3, 2.2), Vector3(0, 2.4, 0), mat_hull)
	# VTOL Tilt Rotors
	_add_box(root, Vector3(1.2, 1.2, 1.8), Vector3(-3.8, 2.5, 0), mat_hull)
	_add_box(root, Vector3(1.2, 1.2, 1.8), Vector3(3.8, 2.5, 0), mat_hull)
	# Turbine Glow
	var core = _add_box(root, Vector3(1.2, 0.8, 0.4), Vector3(0, 2.5, 3.2), mat_glow)
	parent.coolant_core = core

static func _build_industrial_mech_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.6
	mat_hull.roughness = 0.45

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 4.0

	_add_box(root, Vector3(4.0, 3.5, 3.5), Vector3(0, 3.5, 0), mat_hull)
	_add_box(root, Vector3(1.2, 3.0, 1.2), Vector3(-2.2, 1.5, 0), mat_hull)
	_add_box(root, Vector3(1.2, 3.0, 1.2), Vector3(2.2, 1.5, 0), mat_hull)
	var core = _add_box(root, Vector3(1.4, 1.4, 0.4), Vector3(0, 3.5, 1.8), mat_glow)
	parent.coolant_core = core

static func _build_tank_rig_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.8
	mat_hull.roughness = 0.35

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 4.0

	# Tank Treads & Hull
	_add_box(root, Vector3(4.5, 1.8, 7.5), Vector3(0, 1.2, 0), mat_hull)
	# Revolving Heavy Turret
	_add_box(root, Vector3(3.2, 1.6, 3.8), Vector3(0, 2.8, -0.5), mat_hull)
	_add_box(root, Vector3(0.7, 0.7, 4.5), Vector3(0, 2.8, -3.2), mat_hull)
	var core = _add_box(root, Vector3(1.6, 0.8, 0.4), Vector3(0, 2.0, 3.8), mat_glow)
	parent.coolant_core = core

static func _build_aerial_core_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.9
	mat_hull.roughness = 0.2

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 5.0

	_add_box(root, Vector3(5.0, 1.8, 5.0), Vector3(0, 3.0, 0), mat_hull)
	_add_box(root, Vector3(2.5, 2.5, 2.5), Vector3(0, 4.5, 0), mat_glow)
	var core = _add_box(root, Vector3(1.8, 1.8, 0.4), Vector3(0, 3.0, 2.6), mat_glow)
	parent.coolant_core = core

static func _build_citadel_overlord_model(parent: CharacterBody3D, armor_col: Color, glow_col: Color) -> void:
	var root = parent.visual_root
	var mat_hull = StandardMaterial3D.new()
	mat_hull.albedo_color = armor_col
	mat_hull.metallic = 0.95
	mat_hull.roughness = 0.2

	var mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = glow_col
	mat_glow.emission_enabled = true
	mat_glow.emission = glow_col
	mat_glow.emission_energy_multiplier = 5.0

	# Towering Praetorian Overlord Titan
	_add_box(root, Vector3(4.2, 3.2, 3.6), Vector3(0, 4.2, 0), mat_hull)
	_add_box(root, Vector3(1.8, 2.0, 1.8), Vector3(0, 6.2, 0), mat_hull)
	_add_box(root, Vector3(1.4, 0.5, 0.8), Vector3(0, 6.2, -0.9), mat_glow) # Visor
	_add_box(root, Vector3(1.2, 4.2, 1.2), Vector3(-2.2, 2.1, 0), mat_hull) # Leg L
	_add_box(root, Vector3(1.2, 4.2, 1.2), Vector3(2.2, 2.1, 0), mat_hull) # Leg R
	var core = _add_box(root, Vector3(1.8, 1.8, 0.6), Vector3(0, 4.2, 1.9), mat_glow)
	parent.coolant_core = core

static func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	if is_instance_valid(parent):
		parent.add_child(mi)
	return mi
