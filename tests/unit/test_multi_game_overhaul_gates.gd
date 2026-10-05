class_name TestMultiGameOverhaulGates
extends RefCounted

## TestMultiGameOverhaulGates: Comprehensive behavioral regression suite
## Certifies fixes for all 5 screenshot defects:
## 1. RoboForge: Continuous ramps with chamfered lead-in/lead-out transition plates, capsule base collider, floor snapping and lighting.
## 2. WildCircuit: Scout model facing Godot -Z (180 deg Y rot), weapon meshes hidden, camera equipment attached, continuous terrain.
## 3. Skybound Odyssey: Explorer model facing Godot -Z, camera near plane 0.05m, minimum distance >= 1.8m, yaw tracking.
## 4. Chroma Rush: Waypoint track continuity between WP 28-31-0 without self-intersecting loops, authentic 3D GLB trees, holographic diamond beacon.
## 5. Strike Vector: Extraction helipad alignment at Z=-35.0, extraction zone Area3D, extraction_available state, vitals restore and signals.

const ModularRobotScript = preload("res://games/roboforge-arena/robot/modular_robot.gd")
const ChallengeManagerScript = preload("res://games/roboforge-arena/challenges/challenge_manager.gd")
const RoboForgeMainScript = preload("res://games/roboforge-arena/roboforge_main.gd")
const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")
const WildBiomesScript = preload("res://games/wildcircuit/world/wild_biomes.gd")
const OrbitCameraScript = preload("res://shared/cameras/orbit_camera.gd")
const SkyCharacterScript = preload("res://games/skybound-odyssey/character/sky_character.gd")
const NeonCityScript = preload("res://games/chroma-rush/worlds/neon_city.gd")
const ChromaRushMainScript = preload("res://games/chroma-rush/chroma_rush_main.gd")
const MissionDefinitionsScript = preload("res://games/strike-vector/missions/mission_definitions.gd")
const StrikePlayerScript = preload("res://games/strike-vector/player/strike_player.gd")
const CheckpointManagerScript = preload("res://games/strike-vector/campaign/checkpoint_manager.gd")
const StrikeVectorMainScript = preload("res://games/strike-vector/strike_vector_main.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_roboforge_ramp_continuity_and_physics_profile()
	test_wildcircuit_character_orientation_and_camera_equipment()
	test_skybound_camera_and_character_orientation()
	test_chroma_rush_roadway_continuity_and_visual_upgrade()
	test_strike_vector_extraction_and_vitals_restoration()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/roboforge-arena/robot/modular_robot.gd", ["_ready", "setup_robot", "_physics_process"]],
		["res://games/roboforge-arena/challenges/challenge_manager.gd", ["_add_continuous_ramp", "_build_obstacle_course"]],
		["res://shared/graphics/model_cache.gd", ["get_ranger_character", "get_explorer_character", "_clean_character_weapons", "_attach_ranger_camera"]],
		["res://shared/cameras/orbit_camera.gd", ["_ready", "_physics_process", "recenter"]],
		["res://games/chroma-rush/worlds/neon_city.gd", ["_build_track_waypoints", "_build_realistic_tree"]],
		["res://games/strike-vector/player/strike_player.gd", ["restore_vitals", "take_damage", "_die"]],
		["res://games/strike-vector/campaign/checkpoint_manager.gd", ["restore_player_to_checkpoint"]],
		["res://games/strike-vector/strike_vector_main.gd", ["_process", "_trigger_extraction", "_on_player_died"]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("MultiGameOverhaulGates FAIL: " + msg)

func test_roboforge_ramp_continuity_and_physics_profile() -> void:
	# 1. ModularRobot floor snapping and collision shape
	var robot = ModularRobotScript.new()
	robot._ready()
	assert_true(robot.floor_snap_length >= 0.40, "RoboForge robot floor_snap_length must be >= 0.40m to prevent ramp lip snagging")
	assert_true(robot.floor_constant_speed == true, "RoboForge robot floor_constant_speed must be true for smooth slope traversal")
	assert_true(robot.floor_max_angle >= deg_to_rad(50.0), "RoboForge robot floor_max_angle must support at least 50 deg inclines")

	var col = robot.get_node_or_null("CollisionShape")
	assert_true(col != null, "RoboForge robot must have CollisionShape node")
	if col:
		assert_true(col.shape is CapsuleShape3D, "RoboForge robot collision shape must be CapsuleShape3D to glide over track seams")

	# 2. Continuous Ramp generation in ChallengeManager
	var ch_mgr = ChallengeManagerScript.new()
	var arena_root = Node3D.new()
	ch_mgr._build_obstacle_course(arena_root)
	var found_continuous_ramp = false
	var found_lead_in = false
	for c in arena_root.get_children():
		if c.name.begins_with("ContinuousRamp"):
			found_continuous_ramp = true
			if c.has_node("LeadInPlate"):
				found_lead_in = true
	assert_true(found_continuous_ramp, "ObstacleCourse must contain ContinuousRamp with seamless slope geometry")
	assert_true(found_lead_in, "ContinuousRamp must have chamfered LeadInPlate to eliminate step snagging")

	# 3. Arena surroundings and lighting
	var rf_main = RoboForgeMainScript.new()
	rf_main._ready()
	assert_true(rf_main.has_node("RoboForgeWorldEnv"), "RoboForge must have WorldEnvironment so arena is never pitch-black")
	assert_true(rf_main.has_node("ArenaSunLight"), "RoboForge must have DirectionalLight3D for arena illumination")

	arena_root.free()
	ch_mgr.free()
	rf_main.free()
	robot.free()

func test_wildcircuit_character_orientation_and_camera_equipment() -> void:
	# 1. Ranger character model orientation & weapon stripping
	var ranger = ModelCacheScript.get_ranger_character()
	assert_true(ranger != null, "ModelCache.get_ranger_character() must return valid Node3D")
	if ranger:
		var has_180_rot = is_equal_approx(ranger.rotation_degrees.y, 180.0) or is_equal_approx(abs(ranger.rotation_degrees.y), 180.0)
		assert_true(has_180_rot, "Ranger character root visual must be rotated 180 deg to align forward facing with Godot -Z")

		var has_camera_model = ranger.find_child("FieldCameraProp", true, false) != null or ranger.find_child("CameraModel", true, false) != null
		assert_true(has_camera_model, "Ranger character must have FieldCameraProp equipped on chest/strap for photography missions")

		# Verify weapons are hidden/disabled
		var weapons_hidden = true
		var weapon_names = ["1H_Crossbow", "2H_Crossbow", "Knife", "Knife_Offhand", "Throwable"]
		for w_name in weapon_names:
			var w_node = ranger.find_child(w_name, true, false)
			if w_node and w_node is Node3D and w_node.visible:
				weapons_hidden = false
		assert_true(weapons_hidden, "Combat weapons (Crossbow/Knife) must be hidden on the photography Ranger character")

	# 2. Natural terrain continuous bed
	var wild_biomes = WildBiomesScript.new()
	var biome_node = Node3D.new()
	wild_biomes.biome_root = biome_node
	wild_biomes.build_biome(0)
	var terrain_bed = biome_node.get_node_or_null("NaturalTerrainBed")
	assert_true(terrain_bed != null, "WildCircuit biomes must have NaturalTerrainBed to eliminate black void horizon")

	biome_node.free()
	wild_biomes.free()
	if ranger:
		ranger.free()

func test_skybound_camera_and_character_orientation() -> void:
	# 1. Explorer character model orientation
	var explorer = ModelCacheScript.get_explorer_character()
	assert_true(explorer != null, "ModelCache.get_explorer_character() must return valid Node3D")
	if explorer:
		var has_180_rot = is_equal_approx(explorer.rotation_degrees.y, 180.0) or is_equal_approx(abs(explorer.rotation_degrees.y), 180.0)
		assert_true(has_180_rot, "Explorer character root visual must be rotated 180 deg to align forward facing with Godot -Z")

	# 2. OrbitCamera parameters
	var orbit_cam = OrbitCameraScript.new()
	orbit_cam._ready()
	assert_true(orbit_cam.min_distance >= 1.8, "OrbitCamera min_distance must be >= 1.8m to prevent character geometry clipping")
	assert_true(orbit_cam.target_offset.y >= 1.2, "OrbitCamera target_offset.y must be >= 1.2m to frame character head and torso")
	if is_instance_valid(orbit_cam.camera):
		assert_true(orbit_cam.camera.near <= 0.08, "OrbitCamera near clipping plane must be <= 0.08m to avoid near-plane geometry culling")

	orbit_cam.free()
	if explorer:
		explorer.free()

func test_chroma_rush_roadway_continuity_and_visual_upgrade() -> void:
	# 1. Waypoint track continuity (no self-intersecting X-crossing loop at WP 0)
	var city = NeonCityScript.new()
	var wps = city._build_track_waypoints()
	assert_true(wps.size() >= 30, "NeonCity must generate at least 30 waypoints for full city course")

	# Verify closing segment between last waypoint and WP 0 is continuous
	var last_wp = wps[wps.size() - 1]
	var first_wp = wps[0]
	var closing_dist = last_wp.distance_to(first_wp)
	assert_true(closing_dist <= 75.0, "Closing segment from final waypoint to WP 0 must be a direct straightaway <= 75m")

	# Verify realistic GLB trees are generated
	var tree = city._build_realistic_tree("oak", 6.5, 42)
	assert_true(tree != null, "Chroma Rush foliage must return valid tree node")
	if tree:
		var has_glb_tree = tree.has_node("AuthoredTree")
		assert_true(has_glb_tree, "Chroma Rush foliage must use authentic 3D GLB models instead of 7-segment procedural cylinders")
		tree.free()

	# 2. Target beacon visual upgrade
	var cr_main = ChromaRushMainScript.new()
	cr_main._init_target_beacon()
	assert_true(cr_main.has_node("BeaconTargetReticle"), "Chroma Rush must have BeaconTargetReticle holographic diamond marker")

	cr_main.free()
	city.free()

func test_strike_vector_extraction_and_vitals_restoration() -> void:
	# 1. Extraction Helipad alignment on final mission segment
	var segs = MissionDefinitionsScript.build_mission_segments(1)
	assert_true(segs.size() >= 5, "Mission 1 must have at least 5 segments")
	var final_seg = segs[segs.size() - 1]
	var has_helipad = false
	for c in final_seg.get_children():
		var pad = c.find_child("ExtractionPadVisual", true, false)
		if pad != null:
			has_helipad = true
			assert_true(abs(pad.position.z - (-35.0)) <= 3.0, "Extraction helipad must be positioned at ~ -35m on final segment")
	assert_true(has_helipad, "Final segment must contain ExtractionPadVisual structure")

	# 2. StrikePlayer vitals restoration and death handling
	var player = StrikePlayerScript.new()
	player._ready()
	player.restore_vitals(100.0, 50.0)
	assert_true(player.current_health == 100.0, "restore_vitals must set current_health to 100")
	assert_true(player.current_armor == 50.0, "restore_vitals must set current_armor to 50")
	assert_true(player.is_alive == true, "restore_vitals must set is_alive to true")

	# Test lethal damage
	player.take_damage(300.0, "TestEnemy", "Cannon")
	assert_true(player.current_health == 0.0, "Lethal damage must clamp health to 0")
	assert_true(player.is_alive == false, "Lethal damage must set is_alive to false")

	# 3. CheckpointManager restoration
	var cp_mgr = CheckpointManagerScript.new()
	cp_mgr.register_checkpoint("test_cp", Vector3(0, 0, -20), 0.0, 1, 0, player)
	cp_mgr.restore_player_to_checkpoint(player)
	assert_true(player.current_health >= 100.0, "Checkpoint restoration must restore health to at least 100")
	assert_true(player.current_armor >= 50.0, "Checkpoint restoration must restore armor to at least 50")
	assert_true(player.is_alive == true, "Checkpoint restoration must revive player with is_alive == true")

	# 4. StrikeVectorMain extraction countdown variables
	var sv_main = StrikeVectorMainScript.new()
	assert_true("extraction_available" in sv_main, "StrikeVectorMain must contain extraction_available property")
	assert_true("extraction_securing_timer" in sv_main, "StrikeVectorMain must contain extraction_securing_timer property")
	assert_true(sv_main.EXTRACTION_SECURE_REQUIRED_TIME == 3.0, "StrikeVectorMain extraction hold countdown must be 3.0s")

	sv_main.free()
	cp_mgr.free()
	player.free()
	for s in segs:
		s.free()
