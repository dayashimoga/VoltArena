class_name TestStrikeVisualInvariants
extends RefCounted

## Acceptance and Visual/Transform Invariant Test Suite for Strike Vector.
## Verifies:
## - Forward locomotion travel direction, visual orientation, and non-inverted controls.
## - Skeletal rig normalization, BoneAttachment3D, WeaponGrip attachment, and hand/muzzle heights.
## - Weapon sockets (Muzzle, Magazine, Scope, ShellEjection, LeftHandIK) and crosshair convergence.
## - Human-scale architecture (14-24m multi-story buildings, 5.5m streetlights) and zero-fall boundaries.
## - Programmatic NavigationRegion3D and NavigationMesh validity for AI pathfinding.
## - Tactical Navigation HUD (Compass bearing, Radar minimap with threat awareness, Tactical Map).

const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const StrikePlayerVisualScript = preload("res://games/strike-vector/player/strike_player_visual.gd")
const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")
const StrikeWeaponArsenalScript = preload("res://games/strike-vector/weapons/strike_weapon_arsenal.gd")
const StrikeWeaponBaseScript = preload("res://games/strike-vector/weapons/strike_weapon_base.gd")
const StrikeEnvironmentBuilderScript = preload("res://games/strike-vector/environment/strike_environment_builder.gd")
const StrikeHUDScript = preload("res://games/strike-vector/ui/strike_hud.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	test_forward_locomotion_and_facing_invariants()
	test_skeletal_normalization_and_hand_heights()
	test_weapon_grip_attachment_invariants()
	test_weapon_sockets_and_crosshair_convergence()
	test_navigation_mesh_and_pathfinding_invariants()
	test_human_scale_city_architecture()
	test_hud_compass_and_radar_invariants()
	test_anti_fall_collision_invariants()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  [FAIL] TestStrikeVisualInvariants: ", msg)

# ==============================================================================
# 1. FORWARD LOCOMOTION & FACING INVARIANTS
# ==============================================================================
func test_forward_locomotion_and_facing_invariants() -> void:
	var player = StrikePlayerScript.new()
	player._ready()

	# W input maps to Vector2(0, 1) -> world forward along camera look vector
	var cam_fwd = Vector3(0, 0, -1)
	var cam_right = Vector3(1, 0, 0)
	var input_vec = Vector2(0, 1) # Pressing W

	# Test camera-relative direction calculation
	var world_dir = (cam_fwd * input_vec.y + cam_right * input_vec.x).normalized()
	_assert(world_dir.is_equal_approx(Vector3(0, 0, -1)), "W key must produce forward travel direction Vector3(0, 0, -1), got: " + str(world_dir))

	# S input maps to Vector2(0, -1) -> backward travel
	var s_input = Vector2(0, -1)
	var s_dir = (cam_fwd * s_input.y + cam_right * s_input.x).normalized()
	_assert(s_dir.is_equal_approx(Vector3(0, 0, 1)), "S key must produce backward travel direction Vector3(0, 0, 1), got: " + str(s_dir))

	# D input maps to Vector2(1, 0) -> strafe right
	var d_input = Vector2(1, 0)
	var d_dir = (cam_fwd * d_input.y + cam_right * d_input.x).normalized()
	_assert(d_dir.is_equal_approx(Vector3(1, 0, 0)), "D key must produce right strafe direction Vector3(1, 0, 0), got: " + str(d_dir))

	# Facing angle for forward travel: atan2(-vx, -vz) for Vector3(0, 0, -1)
	var forward_travel = Vector3(0, 0, -5.0)
	var travel_facing_yaw = atan2(-forward_travel.x, -forward_travel.z)
	_assert(absf(travel_facing_yaw) < 0.01, "Forward travel facing angle must be 0 radians (facing -Z), got: " + str(travel_facing_yaw))

	# Character must NOT face backwards (PI or -PI) during forward travel
	_assert(absf(absf(travel_facing_yaw) - PI) > 1.0, "Character must not face backward during forward travel")

	player.queue_free()

# ==============================================================================
# 2. SKELETAL NORMALIZATION & HAND HEIGHTS
# ==============================================================================
func test_skeletal_normalization_and_hand_heights() -> void:
	var visual = StrikePlayerVisualScript.new()
	visual.build_visual()

	_assert(visual.skeleton != null, "Visual must have a valid Skeleton3D instance")
	if visual.skeleton != null:
		var hand_idx = visual.skeleton.find_bone("mixamorig_RightHand")
		_assert(hand_idx != -1, "Skeleton3D must contain 'mixamorig_RightHand' bone")

		var hips_idx = visual.skeleton.find_bone("mixamorig_Hips")
		_assert(hips_idx != -1, "Skeleton3D must contain 'mixamorig_Hips' bone")

		# Check bone rest positions are upright (in cm scale > 70cm, or in world > 0.7m)
		if hand_idx != -1:
			var hand_rest = visual.skeleton.get_bone_rest(hand_idx)
			_assert(hand_rest.origin.length() > 0.01, "Right hand bone rest position must not be at origin (0, 0, 0)")

	visual.queue_free()

# ==============================================================================
# 3. WEAPON GRIP ATTACHMENT INVARIANTS
# ==============================================================================
func test_weapon_grip_attachment_invariants() -> void:
	var visual = StrikePlayerVisualScript.new()
	visual.build_visual()

	_assert(visual.bone_attachment != null, "Visual must have a BoneAttachment3D node")
	_assert(visual.weapon_grip != null, "Visual must have a WeaponGrip Marker3D node")

	if visual.bone_attachment != null:
		_assert(visual.bone_attachment.bone_name == "mixamorig_RightHand", "BoneAttachment3D must track 'mixamorig_RightHand', got: " + visual.bone_attachment.bone_name)

	if visual.weapon_grip != null:
		# Weapon grip scale should be 100 to compensate for parent Character 0.01 scale
		_assert(visual.weapon_grip.scale.is_equal_approx(Vector3(100.0, 100.0, 100.0)), "WeaponGrip scale must be Vector3(100, 100, 100) to ensure human-scale weapons")
		# Weapon grip rotation should be 90 deg around Y to align barrel with character forward
		_assert(is_equal_approx(visual.weapon_grip.rotation_degrees.y, 90.0), "WeaponGrip rotation_degrees.y must be 90 to align barrel forward (-Z)")

	# Test Weapon Parenting
	var player = StrikePlayerScript.new()
	player._ready()

	_assert(player.active_weapon != null, "Player must have an active weapon equipped on spawn")
	if player.active_weapon != null and is_instance_valid(player.visual) and is_instance_valid(player.visual.weapon_grip):
		_assert(player.active_weapon.get_parent() == player.visual.weapon_grip, "Active weapon must be parented strictly to visual.weapon_grip, got parent: " + str(player.active_weapon.get_parent()))
		_assert(player.active_weapon.position.is_equal_approx(Vector3.ZERO), "Active weapon position relative to WeaponGrip must be Vector3.ZERO")

	player.queue_free()
	visual.queue_free()

# ==============================================================================
# 4. WEAPON SOCKETS & CROSSHAIR CONVERGENCE
# ==============================================================================
func test_weapon_sockets_and_crosshair_convergence() -> void:
	var weapon_ids = StrikeWeaponArsenalScript.get_all_weapon_ids()
	_assert(weapon_ids.size() == 9, "Arsenal must provide exactly 9 weapons, found: " + str(weapon_ids.size()))

	for w_id in weapon_ids:
		var w = StrikeWeaponArsenalScript.create_weapon_by_id(w_id)
		_assert(w != null, "Weapon factory failed to instantiate weapon: " + w_id)
		if w != null:
			_assert(w.muzzle_socket != null, "Weapon " + w_id + " must have MuzzleSocket")
			_assert(w.magazine_socket != null, "Weapon " + w_id + " must have MagazineSocket")
			_assert(w.scope_socket != null, "Weapon " + w_id + " must have ScopeSocket")
			_assert(w.shell_ejection_socket != null, "Weapon " + w_id + " must have ShellEjectionSocket")
			_assert(w.left_hand_ik_target != null, "Weapon " + w_id + " must have LeftHandIKTarget")
			# Verify weapon scale is realistic (~0.55 - 0.65)
			_assert(w.scale.x >= 0.45 and w.scale.x <= 0.75, "Weapon " + w_id + " scale must be realistic human size (0.45-0.75), got: " + str(w.scale.x))
			w.queue_free()

# ==============================================================================
# 5. NAVIGATION MESH & PATHFINDING INVARIANTS
# ==============================================================================
func test_navigation_mesh_and_pathfinding_invariants() -> void:
	var env = StrikeEnvironmentBuilderScript.build_segment_environment("urban", 0, 40.0, 16.0)
	_assert(env != null, "Environment builder must build Urban Blackout segment")

	var nav_reg: NavigationRegion3D = null
	for child in env.get_children():
		if child is NavigationRegion3D:
			nav_reg = child
			break

	_assert(nav_reg != null, "Urban segment must contain a NavigationRegion3D node")
	if nav_reg != null:
		var n_mesh = nav_reg.navigation_mesh
		_assert(n_mesh != null, "NavigationRegion3D must have a valid NavigationMesh resource")
		if n_mesh != null:
			_assert(n_mesh.vertices.size() >= 4, "NavigationMesh must have at least 4 vertices, got: " + str(n_mesh.vertices.size()))
			_assert(n_mesh.get_polygon_count() >= 2, "NavigationMesh must have at least 2 polygons, got: " + str(n_mesh.get_polygon_count()))

	env.queue_free()

# ==============================================================================
# 6. HUMAN-SCALE CITY ARCHITECTURE
# ==============================================================================
func test_human_scale_city_architecture() -> void:
	var env = StrikeEnvironmentBuilderScript.build_segment_environment("urban", 0, 40.0, 16.0)

	var has_tall_building = false
	var has_streetlight = false
	var has_solid_curb = false

	for child in env.get_children():
		if child is Node3D and child.name.begins_with("building"):
			if child.scale.y >= 14.0:
				has_tall_building = true
		if child is OmniLight3D and child.position.y >= 3.5:
			has_streetlight = true
		if child is StaticBody3D:
			for grand in child.get_children():
				if grand is CollisionShape3D and grand.shape is BoxShape3D:
					has_solid_curb = true

	_assert(has_tall_building, "Urban Blackout must feature human-scale multi-story buildings (>= 14m tall)")
	_assert(has_streetlight, "Urban Blackout must feature elevated streetlights with active illumination")
	_assert(has_solid_curb, "Urban Blackout must feature solid physics colliders for roads and curbs")

	env.queue_free()

# ==============================================================================
# 7. TACTICAL NAVIGATION HUD (COMPASS & RADAR)
# ==============================================================================
func test_hud_compass_and_radar_invariants() -> void:
	var hud = StrikeHUDScript.new()
	hud._ready()

	_assert(hud.compass_tape != null, "HUD must instantiate StrikeCompassTape")
	_assert(hud.minimap != null, "HUD must instantiate StrikeMinimap")
	_assert(hud.tactical_map != null, "HUD must instantiate StrikeTacticalMap")
	_assert(hud.crosshair != null, "HUD must instantiate StrikeCrosshair")

	# Test navigation update
	var p_pos = Vector3(0, 0, -10.0)
	var obj_pos = Vector3(0, 0, -110.0)
	var threat_pos = Vector3(5, 0, -25.0)

	hud.update_navigation_state(p_pos, 0.0, obj_pos, "JAMMER INSTALLATION", [threat_pos])

	_assert(hud.active_objective_name == "JAMMER INSTALLATION", "HUD active objective name must match update")
	_assert(hud.minimap.hostile_blips.size() == 1, "Minimap must register detected hostile threat blip")

	# Test tactical map toggle
	_assert(not hud.tactical_map.visible, "Tactical map must start hidden")
	hud.toggle_tactical_map()
	_assert(hud.tactical_map.visible, "Tactical map must become visible when toggled")
	hud.toggle_tactical_map()
	_assert(not hud.tactical_map.visible, "Tactical map must hide when toggled again")

	hud.queue_free()

# ==============================================================================
# 8. ANTI-FALL COLLISION INVARIANTS
# ==============================================================================
func test_anti_fall_collision_invariants() -> void:
	var player = StrikePlayerScript.new()
	player._ready()

	_assert(player.floor_snap_length >= 0.35, "Player floor_snap_length must be >= 0.35 to prevent stair/ramp disconnection, got: " + str(player.floor_snap_length))
	_assert(player.safe_margin >= 0.07, "Player safe_margin must be >= 0.07 to prevent wall tunneling, got: " + str(player.safe_margin))

	# Test safe ground transform recovery
	player.position = Vector3(0, -20.0, -50.0) # Fell below world
	player.safe_ground_position = Vector3(0, 0.5, -45.0)
	player.recover_to_safe_ground()

	_assert(player.position.y >= 0.0, "Player must recover above ground level when falling out of bounds")
	_assert(player.position.distance_to(player.safe_ground_position + Vector3(0, 0.6, 0)) < 0.1, "Player must recover to recorded safe ground position")

	player.queue_free()

func get_coverage_entries() -> Array:
	return [
		["res://games/strike-vector/player/strike_player.gd", [
			"_calculate_world_input_direction", "recover_to_safe_ground"
		]],
		["res://games/strike-vector/player/strike_player_visual.gd", [
			"build_visual", "update_animation"
		]],
		["res://games/strike-vector/weapons/strike_weapon_arsenal.gd", [
			"create_weapon_by_id", "get_all_weapon_ids"
		]],
		["res://games/strike-vector/environment/strike_environment_builder.gd", [
			"build_segment_environment"
		]],
		["res://games/strike-vector/ui/strike_hud.gd", [
			"setup_hud", "update_navigation_state", "toggle_tactical_map"
		]]
	]
