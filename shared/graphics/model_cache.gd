class_name ModelCache
extends RefCounted

## ModelCache: High-performance in-engine 3D asset manager.
## Loads, caches, and instances production-quality CC0 and permissive glTF models
## with skeletons, animations, and materials across Web, Desktop, and Mobile.

static var _scene_cache: Dictionary = {}

static func clear_cache() -> void:
	_scene_cache.clear()

static func get_model(res_path: String) -> Node3D:
	if _scene_cache.has(res_path):
		var template: Node3D = _scene_cache[res_path]
		if is_instance_valid(template):
			return template.duplicate() as Node3D

	var scene = _load_glb(res_path)
	if scene:
		_scene_cache[res_path] = scene
		return scene.duplicate() as Node3D

	return null

static func _load_glb(path: String) -> Node3D:
	# Try direct ResourceLoader load first
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			var inst = res.instantiate()
			if inst is Node3D:
				return inst

	# Fallback to runtime GLTFDocument parser with globalized path
	var global_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_path):
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		var err = doc.append_from_file(global_path, state)
		if err == OK:
			var root = doc.generate_scene(state)
			if root is Node3D:
				return root

	return null

# ==============================================================================
# 1. CHARACTER INSTANTIATION (IRON CRUCIBLE)
# ==============================================================================

static func get_character(archetype: String = "assault") -> Node3D:
	var path = "res://assets/models/characters/soldier.glb"
	var model = get_model(path)
	if not model:
		return MeshBuilder.build_cyber_soldier(true)

	var target_scale = Vector3(1.0, 1.0, 1.0)
	var visor_color = Color(0.1, 0.8, 1.0) # Assault / Cyan

	match archetype.to_lower():
		"scout", "skirmisher":
			target_scale = Vector3(0.95, 0.95, 0.95)
			visor_color = Color(1.0, 0.7, 0.1) # Gold/Amber
		"heavy", "sentinel":
			target_scale = Vector3(1.15, 1.1, 1.15)
			visor_color = Color(1.0, 0.2, 0.2) # Red/Crimson
		_:
			target_scale = Vector3(1.0, 1.0, 1.0)
			visor_color = Color(0.2, 0.7, 1.0) # Electric Blue

	model.scale = target_scale
	model.rotation_degrees.y = 180.0
	_apply_visor_tint(model, visor_color)
	_ensure_animation_player(model)
	return model

static func _apply_visor_tint(root: Node3D, tint: Color) -> void:
	if not root:
		return
	var visor = root.find_child("vanguard_visor", true, false)
	if visor is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.emission_enabled = true
		mat.emission = tint
		mat.emission_energy_multiplier = 2.0
		mat.roughness = 0.2
		mat.metallic = 0.8
		visor.material_override = mat

# ==============================================================================
# 2. MUTANT / ENEMY INSTANTIATION (METRO SIEGE)
# ==============================================================================

static func get_enemy(enemy_type: String = "crawler") -> Node3D:
	var path = "res://assets/models/enemies/infected_human.glb"
	var target_scale = Vector3(1.0, 1.0, 1.0)
	var tint_color = Color(0.4, 0.6, 0.3) # Sickly olive green

	match enemy_type.to_lower():
		"crawler":
			path = "res://assets/models/enemies/fast_crawler.glb"
			target_scale = Vector3(0.85, 0.75, 1.1)
			tint_color = Color(0.8, 0.3, 0.1)
		"stalker":
			path = "res://assets/models/enemies/stalker.glb"
			target_scale = Vector3(0.95, 1.05, 0.95)
			tint_color = Color(0.3, 0.1, 0.5)
		"spitter":
			path = "res://assets/models/enemies/ranged_spitter.glb"
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.2, 0.9, 0.2)
		"brute":
			path = "res://assets/models/enemies/armored_brute.glb"
			target_scale = Vector3(1.5, 1.4, 1.5)
			tint_color = Color(0.6, 0.2, 0.1)
		"boss", "biocolossus":
			path = "res://assets/models/enemies/biocolossus_boss.glb"
			target_scale = Vector3(2.8, 2.8, 2.8)
			tint_color = Color(0.9, 0.1, 0.1)
		_:
			path = "res://assets/models/enemies/infected_human.glb"
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.5, 0.5, 0.4)

	var model = get_model(path)
	if not model:
		return Node3D.new()

	model.scale = target_scale
	model.rotation_degrees.y = 180.0
	_apply_enemy_tint(model, tint_color)
	_ensure_animation_player(model)
	return model

static func _apply_enemy_tint(root: Node3D, tint: Color) -> void:
	if not root:
		return
	var mesh = root.find_child("vanguard_Mesh", true, false)
	if mesh is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.roughness = 0.8
		mat.metallic = 0.2
		mesh.material_override = mat
	var visor = root.find_child("vanguard_visor", true, false)
	if visor is MeshInstance3D:
		var vmat = StandardMaterial3D.new()
		vmat.albedo_color = tint * 1.5
		vmat.emission_enabled = true
		vmat.emission = tint
		vmat.emission_energy_multiplier = 3.0
		visor.material_override = vmat

# ==============================================================================
# 3. VEHICLE INSTANTIATION (NITRO KICK & DRIFT STORM)
# ==============================================================================

static func get_vehicle(vehicle_id: String = "kart_speedster") -> Node3D:
	var path = "res://assets/models/vehicles/kart_speedster.glb"
	var target_scale = Vector3(1.2, 1.2, 1.2)
	var rot_y = 180.0

	match vehicle_id.to_lower():
		"kart_drift", "drift", "drift_spec", "truck_green":
			path = "res://assets/models/vehicles/kart_drift.glb"
		"kart_muscle", "muscle", "truck_yellow", "enforcer":
			path = "res://assets/models/vehicles/kart_muscle.glb"
		"kart_turbo", "turbo", "truck_purple", "phantom":
			path = "res://assets/models/vehicles/kart_turbo.glb"
		"racecar_gp", "gp", "open_wheel":
			path = "res://assets/models/vehicles/racecar_gp.glb"
			target_scale = Vector3(1.1, 1.1, 1.1)
		"rocket_car_spectre", "spectre", "rocket_car":
			path = "res://assets/models/vehicles/rocket_car_spectre.glb"
			target_scale = Vector3(1.3, 1.3, 1.3)
		"rocket_car_enforcer":
			path = "res://assets/models/vehicles/rocket_car_enforcer.glb"
			target_scale = Vector3(1.3, 1.3, 1.3)
		_:
			path = "res://assets/models/vehicles/kart_speedster.glb"

	var model = get_model(path)
	if not model:
		model = get_model("res://assets/models/vehicles/kart_speedster.glb")
	if not model:
		return MeshBuilder.build_rocket_car(0)

	model.scale = target_scale
	model.rotation_degrees.y = rot_y
	return model

# ==============================================================================
# 4. WEAPON & PROP INSTANTIATION
# ==============================================================================

static func get_weapon_model(weapon_name: String) -> Node3D:
	var path = "res://assets/models/weapons/pulse_rifle.glb"
	var s = Vector3(1.2, 1.2, 1.2)
	var pos = Vector3(0.0, -0.05, -0.15)
	var rot_y = 180.0

	match weapon_name.to_lower():
		"pulse rifle", "pulse_rifle", "assault rifle":
			path = "res://assets/models/weapons/pulse_rifle.glb"
			s = Vector3(1.2, 1.2, 1.2)
			pos = Vector3(0.0, -0.05, -0.15)
		"scatter cannon", "scatter_cannon", "shotgun":
			path = "res://assets/models/weapons/scatter_cannon.glb"
			s = Vector3(1.3, 1.3, 1.3)
			pos = Vector3(0.0, -0.05, -0.15)
		"rail driver", "rail_driver", "sniper":
			path = "res://assets/models/weapons/rail_driver.glb"
			s = Vector3(1.1, 1.1, 1.4)
			pos = Vector3(0.0, -0.05, -0.2)
		"grenade launcher", "grenade_launcher", "rocket_launcher":
			path = "res://assets/models/weapons/grenade_launcher.glb"
			s = Vector3(1.2, 1.2, 1.2)
			pos = Vector3(0.0, -0.05, -0.15)
		"plasma cutter", "plasma_cutter", "pistol":
			path = "res://assets/models/weapons/plasma_cutter.glb"
			s = Vector3(1.1, 1.1, 1.1)
			pos = Vector3(0.0, -0.03, -0.1)
		_:
			path = "res://assets/models/weapons/pulse_rifle.glb"

	var m = get_model(path)
	if m:
		m.scale = s
		m.position = pos
		m.rotation_degrees.y = rot_y
		return m

	return MeshBuilder.build_pulse_rifle()

static func get_building(variant: String = "a") -> Node3D:
	var path = "res://assets/models/environment/scifi/wall_pillar.glb"
	match variant.to_lower():
		"b": path = "res://assets/models/environment/scifi/wall_window.glb"
		"c": path = "res://assets/models/environment/scifi/door_double.glb"
		"d": path = "res://assets/models/environment/scifi/stairs_industrial.glb"
		_: path = "res://assets/models/environment/scifi/wall_pillar.glb"

	var m = get_model(path)
	if m:
		m.scale = Vector3(3.0, 3.0, 3.0)
		return m
	return null

static func get_prop(prop_id: String) -> Node3D:
	var search_dirs = [
		"res://assets/models/environment/scifi/",
		"res://assets/models/environment/subway/",
		"res://assets/models/environment/stadium/",
		"res://assets/models/environment/racing/",
		"res://assets/models/weapons/",
		"res://assets/models/props/",
	]
	for dir in search_dirs:
		var full_path = dir + prop_id + ".glb"
		var m = get_model(full_path)
		if m:
			return m
	return null

# ==============================================================================
# 5. ANIMATION HELPERS
# ==============================================================================

static func _ensure_animation_player(root: Node3D) -> AnimationPlayer:
	if not root:
		return null
	var anim: AnimationPlayer = null
	for child in root.get_children():
		if child is AnimationPlayer:
			anim = child
			break
	if not anim:
		anim = root.find_child("*AnimationPlayer*", true, false) as AnimationPlayer
	return anim

static func play_animation(root: Node3D, anim_name: String, blend_time: float = 0.2) -> bool:
	if not root or not is_instance_valid(root):
		return false
	var anim = _ensure_animation_player(root)
	if not anim:
		return false

	var target_anim = _resolve_animation_name(anim, anim_name)
	if target_anim != "" and anim.has_animation(target_anim):
		if anim.current_animation != target_anim:
			anim.play(target_anim, blend_time)
		return true
	return false

static func _resolve_animation_name(anim: AnimationPlayer, generic_name: String) -> String:
	if anim.has_animation(generic_name):
		return generic_name

	var anim_list = anim.get_animation_list()
	var g_lower = generic_name.to_lower()

	for a in anim_list:
		var a_lower = a.to_lower()
		match g_lower:
			"idle":
				if "idle" in a_lower: return a
			"walk", "walking":
				if "walk" in a_lower and "back" not in a_lower: return a
			"walk_back", "walkback":
				if "walkback" in a_lower or "back" in a_lower: return a
			"run", "running", "sprint":
				if "run" in a_lower: return a
			"strafe_left", "strafeleft":
				if "strafeleft" in a_lower or "strafe_left" in a_lower: return a
			"strafe_right", "straferight":
				if "straferight" in a_lower or "strafe_right" in a_lower: return a
			"aim", "aiming":
				if "aim" in a_lower: return a
			"shoot", "fire", "attack":
				if "fire" in a_lower or "shoot" in a_lower: return a
			"reload":
				if "reload" in a_lower: return a
			"hit", "hurt", "hit_react":
				if "hit" in a_lower: return a
			"death", "die":
				if "death" in a_lower: return a
			"turn_left":
				if "turnleft" in a_lower or "turn_left" in a_lower: return a
			"turn_right":
				if "turnright" in a_lower or "turn_right" in a_lower: return a

	if not anim_list.is_empty():
		return anim_list[0]
	return ""
