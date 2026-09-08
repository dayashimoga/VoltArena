class_name AIArchetypes
extends RefCounted

## Factory producing 10 specialized enemy archetypes for Strike Vector
## with distinct combat behaviors, stats, and rigged visual meshes.

const StrikeAIBaseScript = preload("res://games/strike-vector/ai/strike_ai_base.gd")

static func create_enemy(archetype_id: String, biome: String = "urban") -> CharacterBody3D:
	match archetype_id:
		"rifle_trooper": return create_rifle_trooper(biome)
		"assault_rusher": return create_assault_rusher(biome)
		"heavy": return create_heavy(biome)
		"marksman": return create_marksman(biome)
		"shield_unit": return create_shield_unit(biome)
		"grenadier": return create_grenadier(biome)
		"combat_drone": return create_combat_drone(biome)
		"turret": return create_turret(biome)
		"elite": return create_elite(biome)
		"commander": return create_commander(biome)
		_: return create_rifle_trooper(biome)

static func get_all_archetypes() -> Array[String]:
	return [
		"rifle_trooper", "assault_rusher", "heavy", "marksman",
		"shield_unit", "grenadier", "combat_drone", "turret",
		"elite", "commander"
	]

# 1. Rifle Trooper
static func create_rifle_trooper(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "RifleTrooper"
	ai.enemy_id = "rifle_trooper"
	ai.enemy_type = "Rifle Trooper"
	ai.max_health = 65.0
	ai.move_speed = 5.2
	ai.sprint_speed = 7.5
	ai.attack_range = 24.0
	ai.weapon_damage = 10.0
	ai.burst_count = 3
	ai.burst_fire_rate_rpm = 450.0
	ai.score_value = 150
	_attach_humanoid_visual(ai, Color(0.3, 0.4, 0.5), Color(1.0, 0.2, 0.2), 1.0)
	_setup_collision(ai, 0.45, 1.8)
	return ai

# 2. Assault / Rusher
static func create_assault_rusher(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "AssaultRusher"
	ai.enemy_id = "assault_rusher"
	ai.enemy_type = "Assault Rusher"
	ai.max_health = 55.0
	ai.move_speed = 7.0
	ai.sprint_speed = 10.0
	ai.attack_range = 14.0
	ai.weapon_damage = 14.0
	ai.burst_count = 4
	ai.burst_fire_rate_rpm = 650.0
	ai.score_value = 200
	_attach_humanoid_visual(ai, Color(0.4, 0.2, 0.2), Color(1.0, 0.5, 0.1), 0.95)
	_setup_collision(ai, 0.42, 1.7)
	return ai

# 3. Heavy
static func create_heavy(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "Heavy"
	ai.enemy_id = "heavy"
	ai.enemy_type = "Heavy Enforcer"
	ai.max_health = 180.0
	ai.move_speed = 3.6
	ai.sprint_speed = 5.0
	ai.attack_range = 28.0
	ai.weapon_damage = 16.0
	ai.burst_count = 8
	ai.burst_fire_rate_rpm = 550.0
	ai.score_value = 400
	_attach_humanoid_visual(ai, Color(0.2, 0.25, 0.3), Color(1.0, 0.1, 0.1), 1.25)
	_setup_collision(ai, 0.65, 2.1)
	return ai

# 4. Marksman
static func create_marksman(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "Marksman"
	ai.enemy_id = "marksman"
	ai.enemy_type = "Marksman Sniper"
	ai.max_health = 45.0
	ai.move_speed = 4.8
	ai.sprint_speed = 6.8
	ai.attack_range = 42.0
	ai.optimal_range = 32.0
	ai.weapon_damage = 38.0
	ai.burst_count = 1
	ai.burst_fire_rate_rpm = 60.0
	ai.score_value = 250
	_attach_humanoid_visual(ai, Color(0.25, 0.35, 0.3), Color(0.1, 0.7, 1.0), 0.95)
	_setup_collision(ai, 0.40, 1.8)
	return ai

# 5. Shield Unit
static func create_shield_unit(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "ShieldUnit"
	ai.enemy_id = "shield_unit"
	ai.enemy_type = "Shield Trooper"
	ai.max_health = 110.0
	ai.move_speed = 4.2
	ai.sprint_speed = 5.8
	ai.attack_range = 16.0
	ai.weapon_damage = 12.0
	ai.burst_count = 2
	ai.burst_fire_rate_rpm = 350.0
	ai.score_value = 300
	var root = _attach_humanoid_visual(ai, Color(0.3, 0.35, 0.4), Color(0.2, 0.9, 1.0), 1.05)
	# Attach Riot Shield Mesh
	var shield = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.9, 1.4, 0.08)
	shield.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.85, 1.0, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.85, 1.0)
	shield.material_override = mat
	shield.position = Vector3(0, 0.8, -0.6)
	ai.add_child(shield)
	_setup_collision(ai, 0.50, 1.85)
	return ai

# 6. Grenadier
static func create_grenadier(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "Grenadier"
	ai.enemy_id = "grenadier"
	ai.enemy_type = "Grenadier"
	ai.max_health = 80.0
	ai.move_speed = 4.8
	ai.sprint_speed = 6.5
	ai.attack_range = 22.0
	ai.weapon_damage = 25.0
	ai.burst_count = 1
	ai.burst_fire_rate_rpm = 50.0
	ai.score_value = 280
	_attach_humanoid_visual(ai, Color(0.4, 0.35, 0.2), Color(1.0, 0.6, 0.1), 1.05)
	_setup_collision(ai, 0.48, 1.8)
	return ai

# 7. Combat Drone
static func create_combat_drone(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "CombatDrone"
	ai.enemy_id = "combat_drone"
	ai.enemy_type = "Aerial Drone"
	ai.max_health = 40.0
	ai.move_speed = 7.5
	ai.sprint_speed = 11.0
	ai.attack_range = 20.0
	ai.weapon_damage = 8.0
	ai.burst_count = 5
	ai.burst_fire_rate_rpm = 600.0
	ai.score_value = 180

	var d_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.55
	d_mesh.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.2, 0.28)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 1.0)
	d_mesh.material_override = mat
	d_mesh.position = Vector3(0, 1.2, 0)
	ai.add_child(d_mesh)

	var col = CollisionShape3D.new()
	var cs = SphereShape3D.new()
	cs.radius = 0.5
	col.shape = cs
	col.position = Vector3(0, 1.2, 0)
	ai.add_child(col)
	return ai

# 8. Automated Turret
static func create_turret(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "Turret"
	ai.enemy_id = "turret"
	ai.enemy_type = "Defense Turret"
	ai.max_health = 140.0
	ai.move_speed = 0.0 # static
	ai.sprint_speed = 0.0
	ai.attack_range = 30.0
	ai.weapon_damage = 12.0
	ai.burst_count = 6
	ai.burst_fire_rate_rpm = 600.0
	ai.score_value = 350

	var t_base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.6
	cyl.bottom_radius = 0.8
	cyl.height = 0.8
	t_base.mesh = cyl
	t_base.position = Vector3(0, 0.4, 0)
	ai.add_child(t_base)

	var col = CollisionShape3D.new()
	var cs = CylinderShape3D.new()
	cs.radius = 0.7
	cs.height = 1.0
	col.shape = cs
	col.position = Vector3(0, 0.5, 0)
	ai.add_child(col)
	return ai

# 9. Elite Vanguard
static func create_elite(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "EliteVanguard"
	ai.enemy_id = "elite"
	ai.enemy_type = "Elite Vanguard"
	ai.max_health = 220.0
	ai.move_speed = 6.5
	ai.sprint_speed = 9.2
	ai.attack_range = 25.0
	ai.weapon_damage = 20.0
	ai.burst_count = 5
	ai.burst_fire_rate_rpm = 550.0
	ai.score_value = 600
	_attach_humanoid_visual(ai, Color(0.12, 0.15, 0.22), Color(1.0, 0.1, 0.8), 1.15)
	_setup_collision(ai, 0.55, 1.95)
	return ai

# 10. Squad Commander
static func create_commander(biome: String) -> CharacterBody3D:
	var ai = StrikeAIBaseScript.new()
	ai.name = "Commander"
	ai.enemy_id = "commander"
	ai.enemy_type = "Squad Commander"
	ai.max_health = 260.0
	ai.move_speed = 5.5
	ai.sprint_speed = 8.0
	ai.attack_range = 28.0
	ai.weapon_damage = 22.0
	ai.burst_count = 4
	ai.burst_fire_rate_rpm = 500.0
	ai.score_value = 800
	_attach_humanoid_visual(ai, Color(0.35, 0.28, 0.15), Color(1.0, 0.85, 0.1), 1.20)
	_setup_collision(ai, 0.58, 2.05)
	return ai

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

static func _attach_humanoid_visual(parent: Node3D, armor_color: Color, visor_color: Color, scale_mod: float) -> Node3D:
	var root = Node3D.new()
	root.name = "Visual"
	root.scale = Vector3(scale_mod, scale_mod, scale_mod)

	# Try authentic rigged character model
	var char_type = "trooper"
	if scale_mod > 1.1:
		char_type = "heavy"
	elif scale_mod < 0.95:
		char_type = "scout"

	var model = ModelCacheScript.get_character(char_type)
	if model:
		model.name = "CharacterRig"
		model.rotation_degrees.y = 180.0
		root.add_child(model)

		# Add handheld weapon model
		var w_model = ModelCacheScript.get_weapon_model("pulse_rifle")
		if w_model:
			w_model.position = Vector3(0.28, 1.0, -0.32)
			w_model.scale = Vector3(1.0, 1.0, 1.0)
			root.add_child(w_model)

		parent.add_child(root)
		return root

	# Fallback high-poly stylized mesh
	var mat_armor = StandardMaterial3D.new()
	mat_armor.albedo_color = armor_color
	mat_armor.metallic = 0.7
	mat_armor.roughness = 0.35

	var mat_visor = StandardMaterial3D.new()
	mat_visor.albedo_color = visor_color
	mat_visor.emission_enabled = true
	mat_visor.emission = visor_color
	mat_visor.emission_energy_multiplier = 3.5

	var torso = MeshInstance3D.new()
	var t_box = CapsuleMesh.new()
	t_box.radius = 0.28
	t_box.height = 0.85
	torso.mesh = t_box
	torso.position = Vector3(0, 1.12, 0)
	torso.material_override = mat_armor
	root.add_child(torso)

	var head = MeshInstance3D.new()
	var h_box = SphereMesh.new()
	h_box.radius = 0.18
	h_box.height = 0.36
	head.mesh = h_box
	head.position = Vector3(0, 0.55, 0)
	head.material_override = mat_armor
	torso.add_child(head)

	var visor = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.22, 0.08, 0.10)
	visor.mesh = v_box
	visor.position = Vector3(0, 0.02, -0.14)
	visor.material_override = mat_visor
	head.add_child(visor)

	parent.add_child(root)
	return root

static func _setup_collision(parent: Node3D, rad: float, h: float) -> void:
	var col = CollisionShape3D.new()
	col.name = "CollisionShape"
	var cap = CapsuleShape3D.new()
	cap.radius = rad
	cap.height = h
	col.shape = cap
	col.position = Vector3(0, h * 0.5, 0)
	parent.add_child(col)
