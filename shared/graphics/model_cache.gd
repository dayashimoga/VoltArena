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
	model.rotation_degrees.y = 0.0
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
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.8, 0.3, 0.1)
		"stalker":
			path = "res://assets/models/enemies/stalker.glb"
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.3, 0.1, 0.5)
		"spitter":
			path = "res://assets/models/enemies/ranged_spitter.glb"
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.2, 0.9, 0.2)
		"brute":
			path = "res://assets/models/enemies/armored_brute.glb"
			target_scale = Vector3(1.35, 1.35, 1.35)
			tint_color = Color(0.6, 0.2, 0.1)
		"boss", "biocolossus":
			path = "res://assets/models/enemies/biocolossus_boss.glb"
			target_scale = Vector3(2.5, 2.5, 2.5)
			tint_color = Color(0.9, 0.1, 0.1)
		_:
			path = "res://assets/models/enemies/infected_human.glb"
			target_scale = Vector3(1.0, 1.0, 1.0)
			tint_color = Color(0.5, 0.5, 0.4)

	var model = get_model(path)
	if not model:
		return Node3D.new()

	model.scale = target_scale
	model.rotation_degrees.y = 0.0
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
	var rot_y = 0.0
	var is_kart = false
	var is_rocket_car = false
	var team_tint = Color.WHITE

	match vehicle_id.to_lower():
		"rocket_car_spectre", "spectre", "rocket_car", "truck_red":
			path = "res://assets/models/vehicles/rocket_car_spectre.glb"
			target_scale = Vector3(1.3, 1.3, 1.3)
			is_rocket_car = true
			team_tint = Color(0.1, 0.75, 1.0)
		"rocket_car_enforcer", "enforcer_car", "truck_yellow":
			path = "res://assets/models/vehicles/rocket_car_enforcer.glb"
			target_scale = Vector3(1.3, 1.3, 1.3)
			is_rocket_car = true
			team_tint = Color(1.0, 0.55, 0.05)
		"kart_drift", "drift", "drift_spec", "truck_green":
			path = "res://assets/models/vehicles/kart_drift.glb"
			is_kart = true
		"kart_muscle", "muscle", "enforcer":
			path = "res://assets/models/vehicles/kart_muscle.glb"
			is_kart = true
		"kart_turbo", "turbo", "truck_purple", "phantom":
			path = "res://assets/models/vehicles/kart_turbo.glb"
			is_kart = true
		"racecar_gp", "gp", "open_wheel":
			path = "res://assets/models/vehicles/racecar_gp.glb"
			target_scale = Vector3(1.1, 1.1, 1.1)
		_:
			path = "res://assets/models/vehicles/kart_speedster.glb"
			is_kart = true

	var model = get_model(path)
	if not model:
		model = get_model("res://assets/models/vehicles/kart_speedster.glb")
	if not model:
		return MeshBuilder.build_rocket_car(0)

	model.scale = target_scale
	model.rotation_degrees.y = rot_y

	if is_kart:
		_replace_kart_driver(model, vehicle_id)
	elif is_rocket_car:
		_enhance_rocket_car(model, team_tint)

	return model

static func _recursive_remove_chibi(node: Node) -> void:
	if not node:
		return
	for child in node.get_children():
		var c_name = child.name.to_lower()
		if "character" in c_name or "head" in c_name or "chibi" in c_name:
			if child is Node3D:
				child.visible = false
			child.queue_free()
		else:
			_recursive_remove_chibi(child)

static func _replace_kart_driver(model: Node3D, _vid: String) -> void:
	if not model:
		return
	_recursive_remove_chibi(model)

	# Create a sleek, helmeted racing driver matching Reference Screenshot 3
	var driver_root = Node3D.new()
	driver_root.name = "RacingDriver"
	driver_root.position = Vector3(0, 0.15, 0.0)

	var mat_suit = StandardMaterial3D.new()
	mat_suit.albedo_color = Color(0.20, 0.35, 0.65)
	mat_suit.roughness = 0.5

	var mat_helmet = StandardMaterial3D.new()
	mat_helmet.albedo_color = Color(0.96, 0.96, 0.98)
	mat_helmet.roughness = 0.2
	mat_helmet.metallic = 0.4

	var mat_visor = StandardMaterial3D.new()
	mat_visor.albedo_color = Color(0.04, 0.06, 0.10)
	mat_visor.roughness = 0.08
	mat_visor.metallic = 0.95

	# Torso in racing harness
	var torso = MeshInstance3D.new()
	var t_mesh = BoxMesh.new()
	t_mesh.size = Vector3(0.42, 0.46, 0.32)
	torso.mesh = t_mesh
	torso.material_override = mat_suit
	torso.position = Vector3(0, 0.30, 0.02)
	driver_root.add_child(torso)

	# Aerodynamic Racing Helmet
	var helmet = MeshInstance3D.new()
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.22
	h_mesh.height = 0.44
	helmet.mesh = h_mesh
	helmet.material_override = mat_helmet
	helmet.position = Vector3(0, 0.68, 0.02)
	driver_root.add_child(helmet)

	# Tinted Visor Band across front of helmet
	var visor = MeshInstance3D.new()
	var v_mesh = BoxMesh.new()
	v_mesh.size = Vector3(0.28, 0.10, 0.12)
	visor.mesh = v_mesh
	visor.material_override = mat_visor
	visor.position = Vector3(0, 0.70, -0.16)
	driver_root.add_child(visor)

	model.add_child(driver_root)

static func _enhance_rocket_car(model: Node3D, team_col: Color) -> void:
	if not model:
		return
	# Add rear boost thruster glow points
	for side in [-0.42, 0.42]:
		var thruster = MeshInstance3D.new()
		thruster.name = "ThrusterGlow_" + ("L" if side < 0 else "R")
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.14
		cyl.height = 0.35
		thruster.mesh = cyl
		thruster.rotation_degrees.x = -90.0
		thruster.position = Vector3(side, 0.42, 1.45)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = team_col
		mat.emission_enabled = true
		mat.emission = team_col
		mat.emission_energy_multiplier = 3.0
		thruster.material_override = mat
		model.add_child(thruster)

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
			s = Vector3(1.1, 1.1, 1.3)
			pos = Vector3(0.0, -0.05, -0.20)
		"grenade launcher", "grenade_launcher", "rocket_launcher":
			path = "res://assets/models/weapons/grenade_launcher.glb"
			s = Vector3(1.2, 1.2, 1.2)
			pos = Vector3(0.0, -0.05, -0.15)
		"plasma cutter", "plasma_cutter", "pistol":
			path = "res://assets/models/weapons/plasma_cutter.glb"
			s = Vector3(1.1, 1.1, 1.1)
			pos = Vector3(0.0, -0.03, -0.10)
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
	var id_clean = prop_id.to_lower()
	# Prop aliases to match model directory filenames
	match id_clean:
		"stadium_stands", "grandstand_stands":
			id_clean = "grandstand"
		"ad_board", "advertisement_board":
			id_clean = "billboard"
		"floodlight":
			id_clean = "floodlight_tower"

	var search_dirs = [
		"res://assets/models/environment/scifi/",
		"res://assets/models/environment/subway/",
		"res://assets/models/environment/stadium/",
		"res://assets/models/environment/racing/",
		"res://assets/models/weapons/",
		"res://assets/models/props/",
	]
	for dir in search_dirs:
		var full_path = dir + id_clean + ".glb"
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
	if anim:
		_normalize_rig_tracks(anim)
	return anim

static func _normalize_rig_tracks(anim: AnimationPlayer) -> void:
	if not anim or anim.has_meta("tracks_normalized"):
		return
	anim.set_meta("tracks_normalized", true)
	for a_name in anim.get_animation_list():
		var a = anim.get_animation(a_name)
		if not a:
			continue
		for t in range(a.get_track_count()):
			if "mixamorig_Hips" in str(a.track_get_path(t)) and a.track_get_type(t) == Animation.TYPE_POSITION_3D:
				var k_count = a.track_get_key_count(t)
				if k_count > 0:
					var k0: Vector3 = a.track_get_key_value(t, 0)
					if k0.z < 10.0 and k0.y > 0.5:
						for k in range(k_count):
							var val: Vector3 = a.track_get_key_value(t, k)
							a.track_set_key_value(t, k, Vector3(val.x * 100.0, -val.z * 100.0, val.y * 100.0))

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
	var anim_list = anim.get_animation_list()
	var g_lower = generic_name.to_lower()

	# 1. Direct exact or case-insensitive match
	if anim.has_animation(generic_name):
		return generic_name
	for a in anim_list:
		if a.to_lower() == g_lower:
			return a

	# 2. Locomotion / Moving requests (walk, run, sprint, patrol, seek, strafe)
	if "strafeleft" in g_lower:
		for a in anim_list:
			if "strafeleft" in a.to_lower(): return a
	if "straferight" in g_lower:
		for a in anim_list:
			if "straferight" in a.to_lower(): return a
	if "walkback" in g_lower or "back" in g_lower:
		for a in anim_list:
			if "walkback" in a.to_lower() or "back" in a.to_lower(): return a

	if "run" in g_lower or "sprint" in g_lower or "seek" in g_lower or "chase" in g_lower:
		for a in anim_list:
			if a.to_lower() == "run" or ("run" in a.to_lower() and "walk" not in a.to_lower()):
				return a
		for a in anim_list:
			if "walk" in a.to_lower():
				return a

	if "walk" in g_lower or "strafe" in g_lower or "patrol" in g_lower or "move" in g_lower or "step" in g_lower:
		for a in anim_list:
			if a.to_lower() == "walk" or ("walk" in a.to_lower() and "back" not in a.to_lower()):
				return a
		for a in anim_list:
			if "run" in a.to_lower():
				return a

	# 3. Idle requests
	if "idle" in g_lower or "rest" in g_lower or "stand" in g_lower:
		for a in anim_list:
			if "idle" in a.to_lower():
				return a

	# 4. Action requests (aim, fire, reload)
	if "aim" in g_lower:
		for a in anim_list:
			if "aim" in a.to_lower(): return a
	if "fire" in g_lower or "shoot" in g_lower or "attack" in g_lower:
		for a in anim_list:
			if "fire" in a.to_lower(): return a
	if "reload" in g_lower:
		for a in anim_list:
			if "reload" in a.to_lower(): return a

	# 5. Safe upright fallback: prioritize verified upright animations (Idle, Walk, Run)
	for a in anim_list:
		if "idle" in a.to_lower():
			return a
	for a in anim_list:
		if "walk" in a.to_lower():
			return a
	for a in anim_list:
		if "run" in a.to_lower():
			return a

	if not anim_list.is_empty():
		return anim_list[0]
	return ""
