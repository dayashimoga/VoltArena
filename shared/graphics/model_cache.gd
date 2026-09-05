class_name ModelCache
extends RefCounted

## ModelCache: High-performance in-engine 3D asset manager.
## Loads, caches, and instances production-quality CC0 glTF models
## with skeletons, animations, and materials across Web, Desktop, and Mobile.

static var _scene_cache: Dictionary = {}
static var _doc_cache: Dictionary = {}

static func clear_cache() -> void:
	_scene_cache.clear()
	_doc_cache.clear()

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

	# Fallback to runtime GLTFDocument parser
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	var err = doc.append_from_file(path, state)
	if err == OK:
		var root = doc.generate_scene(state)
		if root is Node3D:
			return root

	return null

# ==============================================================================
# 1. CHARACTER INSTANTIATION (IRON CRUCIBLE)
# ==============================================================================

static func get_character(archetype: String = "trooper") -> Node3D:
	var path = "res://assets/models/characters/trooper.glb"
	match archetype.to_lower():
		"scout", "skirmisher":
			path = "res://assets/models/characters/scout.glb"
		"heavy", "sentinel":
			path = "res://assets/models/characters/heavy.glb"
		_:
			path = "res://assets/models/characters/trooper.glb"

	var model = get_model(path)
	if not model:
		# Fallback to procedural articulated mesh
		return MeshBuilder.build_cyber_soldier(true)

	model.scale = Vector3(1.2, 1.2, 1.2)
	_ensure_animation_player(model)
	return model

# ==============================================================================
# 2. MUTANT / ENEMY INSTANTIATION (METRO SIEGE)
# ==============================================================================

static func get_enemy(enemy_type: String = "crawler") -> Node3D:
	var path = "res://assets/models/enemies/mutant_crawler.glb"
	var target_scale = Vector3(1.0, 1.0, 1.0)
	var tint_color = Color.WHITE

	match enemy_type.to_lower():
		"crawler":
			path = "res://assets/models/enemies/mutant_crawler.glb"
			target_scale = Vector3(0.9, 0.8, 0.9)
		"stalker":
			path = "res://assets/models/enemies/mutant_stalker.glb"
			target_scale = Vector3(1.1, 1.3, 1.1)
		"spitter":
			path = "res://assets/models/enemies/mutant_warrior.glb"
			target_scale = Vector3(1.0, 1.1, 1.0)
		"brute":
			path = "res://assets/models/enemies/mutant_warrior.glb"
			target_scale = Vector3(1.8, 1.7, 1.8)
		"boss", "biocolossus":
			path = "res://assets/models/enemies/mutant_warrior.glb"
			target_scale = Vector3(3.2, 3.2, 3.2)
		_:
			path = "res://assets/models/enemies/mutant_crawler.glb"

	var model = get_model(path)
	if not model:
		match enemy_type.to_lower():
			"crawler": return MeshBuilder.build_crawler_mesh()
			"spitter": return MeshBuilder.build_spitter_mesh()
			"stalker": return MeshBuilder.build_stalker_mesh()
			"brute": return MeshBuilder.build_brute_mesh()
			"boss", "biocolossus": return MeshBuilder.build_colossus_boss_mesh()
			_: return MeshBuilder.build_crawler_mesh()

	model.scale = target_scale
	_ensure_animation_player(model)
	return model

# ==============================================================================
# 3. VEHICLE INSTANTIATION (NITRO KICK & DRIFT STORM)
# ==============================================================================

static func get_vehicle(vehicle_id: String = "truck_red") -> Node3D:
	var path = "res://assets/models/vehicles/truck_red.glb"
	match vehicle_id.to_lower():
		"truck_green", "speeder", "speed_demon":
			path = "res://assets/models/vehicles/truck_green.glb"
		"truck_yellow", "enforcer", "turbo_truck":
			path = "res://assets/models/vehicles/truck_yellow.glb"
		"truck_purple", "phantom", "phantom_racer":
			path = "res://assets/models/vehicles/truck_purple.glb"
		"truck_red", "kart", "rocket_car":
			path = "res://assets/models/vehicles/truck_red.glb"
		_:
			path = "res://assets/models/vehicles/truck_red.glb"

	var model = get_model(path)
	if not model:
		return MeshBuilder.build_rocket_car(0)

	model.scale = Vector3(1.4, 1.4, 1.4)
	model.rotation_degrees.y = 180.0
	return model

# ==============================================================================
# 4. WEAPON & PROP INSTANTIATION
# ==============================================================================

static func get_weapon_model(weapon_name: String) -> Node3D:
	match weapon_name.to_lower():
		"pulse rifle", "pulse_rifle":
			var m = get_model("res://assets/models/weapons/blaster_repeater.glb")
			if m:
				m.scale = Vector3(0.35, 0.35, 0.35)
				m.position = Vector3(0.0, -0.05, -0.15)
				m.rotation_degrees.y = 180.0
				return m
			return MeshBuilder.build_pulse_rifle()
		"scatter cannon", "scatter_cannon":
			var m = get_model("res://assets/models/weapons/blaster.glb")
			if m:
				m.scale = Vector3(0.40, 0.40, 0.40)
				m.position = Vector3(0.0, -0.05, -0.15)
				m.rotation_degrees.y = 180.0
				return m
			return MeshBuilder.build_scatter_cannon()
		"rail driver", "rail_driver":
			var m = get_model("res://assets/models/weapons/blaster_repeater.glb")
			if m:
				m.scale = Vector3(0.32, 0.32, 0.45)
				m.position = Vector3(0.0, -0.05, -0.18)
				m.rotation_degrees.y = 180.0
				return m
			return MeshBuilder.build_rail_driver()
		"grenade launcher", "grenade_launcher":
			var m = get_model("res://assets/models/weapons/blaster.glb")
			if m:
				m.scale = Vector3(0.44, 0.44, 0.36)
				m.position = Vector3(0.0, -0.05, -0.15)
				m.rotation_degrees.y = 180.0
				return m
			return MeshBuilder.build_grenade_launcher()
		"plasma cutter", "plasma_cutter":
			var m = get_model("res://assets/models/weapons/blaster_repeater.glb")
			if m:
				m.scale = Vector3(0.30, 0.30, 0.30)
				m.position = Vector3(0.0, -0.05, -0.12)
				m.rotation_degrees.y = 180.0
				return m
			return MeshBuilder.build_plasma_cutter()
		_:
			return MeshBuilder.build_pulse_rifle()

static func get_building(variant: String = "a") -> Node3D:
	var path = "res://assets/models/environment/building_a.glb"
	match variant.to_lower():
		"b": path = "res://assets/models/environment/building_b.glb"
		"c": path = "res://assets/models/environment/building_c.glb"
		"d": path = "res://assets/models/environment/building_d.glb"
		"garage": path = "res://assets/models/environment/building_garage.glb"
		_: path = "res://assets/models/environment/building_a.glb"

	var m = get_model(path)
	if m:
		m.scale = Vector3(4.0, 4.0, 4.0)
		return m
	return null

static func get_prop(prop_id: String) -> Node3D:
	var path = "res://assets/models/props/" + prop_id + ".glb"
	var m = get_model(path)
	if not m:
		path = "res://assets/models/environment/" + prop_id + ".glb"
		m = get_model(path)
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
	return anim

static func play_animation(root: Node3D, anim_name: String, blend_time: float = 0.2) -> bool:
	if not root or not is_instance_valid(root):
		return false
	var anim = _ensure_animation_player(root)
	if not anim:
		return false

	# Map generic action names to glTF animation names
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

	# Smart semantic matching
	for a in anim_list:
		var a_lower = a.to_lower()
		match g_lower:
			"idle":
				if a_lower == "idle" or a_lower.begins_with("idle") or "idle" in a_lower:
					return a
			"walk", "walking":
				if a_lower.begins_with("walking_a") or a_lower.begins_with("walk") or "walking" in a_lower:
					return a
			"run", "running", "sprint":
				if a_lower.begins_with("running_a") or a_lower.begins_with("run") or "running" in a_lower:
					return a
			"strafe_left":
				if "strafe_left" in a_lower: return a
			"strafe_right":
				if "strafe_right" in a_lower: return a
			"aim", "aiming":
				if "ranged_aiming" in a_lower or "aim" in a_lower: return a
			"shoot", "fire":
				if "ranged_shoot" in a_lower or "attack" in a_lower or "shoot" in a_lower: return a
			"hit", "hurt":
				if "hit_a" in a_lower or "hit" in a_lower: return a
			"death", "die":
				if "death_a" in a_lower or "death" in a_lower: return a
			"jump":
				if "jump_start" in a_lower or "jump" in a_lower: return a

	if not anim_list.is_empty():
		return anim_list[0]
	return ""
