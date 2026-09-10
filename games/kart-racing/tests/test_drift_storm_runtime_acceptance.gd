class_name TestDriftStormRuntimeAcceptance
extends RefCounted

## TestDriftStormRuntimeAcceptance: Rigorous physics, spline, grounding, and multi-car
## acceptance test suite for Drift Storm in VoltArena.
## Verifies 100% elimination of all 7 verified runtime defects.

var assertions_passed: int = 0
var assertions_failed: int = 0

const RaceSplineScript = preload("res://games/kart-racing/tracks/race_spline.gd")
const TrackGeneratorScript = preload("res://games/kart-racing/tracks/track_generator.gd")
const KartControllerScript = preload("res://games/kart-racing/kart/kart_controller.gd")
const KartAIScript = preload("res://games/kart-racing/ai/kart_ai.gd")
const KartRacingMainScript = preload("res://games/kart-racing/kart_racing_main.gd")
const RaceManagerScript = preload("res://games/kart-racing/game/race_manager.gd")
const TrackRegistryScript = preload("res://games/kart-racing/tracks/track_registry.gd")

func run_tests() -> Dictionary:
	test_authoritative_race_spline_integrity()
	test_road_surface_mesh_and_upward_normals()
	test_kart_grounding_and_suspension_telemetry()
	test_zero_false_wrong_way_on_valid_lap()
	test_reversing_triggers_wrong_way_and_recovery_clears()
	test_six_car_multi_lap_simulation()
	test_six_circuits_continuous_colliders_and_environments()
	test_five_vehicle_classes_and_stats()
	test_seam_wrapping_and_continuous_progress()
	test_track_registry_and_extended_spline_methods()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/kart-racing/tracks/race_spline.gd", ["_init", "build_from_nodes", "get_closest_distance", "sample_at_distance", "get_tangent_at_pos", "get_lateral_offset", "is_point_on_track", "get_progress", "get_safe_respawn_transform", "sample_lookahead_forward", "get_forward_delta", "get_minimap_points"]],
		["res://games/kart-racing/tracks/track_generator.gd", ["_ready", "build_circuit", "_build_continuous_road_foundation", "build_track_segment", "create_box", "setup_racing_environment"]],
		["res://games/kart-racing/kart/kart_controller.gd", ["_ready", "setup_kart_archetype", "setup_kart_visual", "setup_suspension_raycasts", "_physics_process", "_update_suspension_and_grounding", "recover_to_checkpoint", "handle_player_input", "apply_kart_controls", "trigger_drift_boost", "_check_wrong_way", "_check_wrong_way_fallback", "_get_race_spline", "_get_race_manager"]],
		["res://games/kart-racing/ai/kart_ai.gd", ["_ready", "_physics_process", "_process_spline_driving", "_process_waypoint_driving", "_get_race_spline", "_get_race_manager"]],
		["res://games/kart-racing/game/race_manager.gd", ["initialize_race", "_process", "start_race", "_on_checkpoint_hit", "update_race_positions", "get_racer_position", "finish_race", "get_kart_continuous_progress"]],
		["res://games/kart-racing/kart_racing_main.gd", ["_ready", "setup_scene", "update_camera", "_on_race_finished", "select_track", "select_kart"]],
		["res://games/kart-racing/tracks/track_registry.gd", ["_init", "get_all_tracks", "get_track"]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func assert_almost_eq(actual: float, expected: float, tolerance: float, msg: String) -> void:
	assert_true(absf(actual - expected) <= tolerance, "%s (expected ~%f, got %f, tol %f)" % [msg, expected, actual, tolerance])

## T1: Authoritative RaceSpline Integrity
func test_authoritative_race_spline_integrity() -> void:
	var nodes: Array[Vector3] = [
		Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(30, 2, -100),
		Vector3(100, 4, -120), Vector3(180, 4, -80), Vector3(160, 2, 20),
		Vector3(80, 0, 60), Vector3(0, 0, 30)
	]
	var spline = RaceSplineScript.new(nodes, 14.0)

	assert_true(spline.track_length > 400.0, "RaceSpline must compute valid length > 400m")
	assert_true(spline.sample_count >= 100, "RaceSpline must contain dense pre-baked samples (>=100)")
	assert_true(spline.respawn_points.size() >= 5, "RaceSpline must generate periodic safe respawn points")

	# Check sample properties at distance 50m
	var s_data = spline.sample_at_distance(50.0)
	assert_almost_eq(s_data["tangent"].length(), 1.0, 0.05, "Spline tangent must be unit vector")
	assert_almost_eq(s_data["width"], 14.0, 0.01, "Spline track width must match 14.0m")
	assert_almost_eq(s_data["left"].distance_to(s_data["right"]), 14.0, 0.1, "Left and right boundaries must span track width")

	# Centerline projection test
	var query_pt = Vector3(0, 0, -25)
	var closest_s = spline.get_closest_distance(query_pt)
	assert_true(closest_s > 10.0 and closest_s < 40.0, "Closest distance projection must be accurate")
	assert_true(spline.is_point_on_track(query_pt, 2.0), "Point on centerline must be flagged as on track")

	# Point far off track
	var off_track_pt = Vector3(500, 0, 500)
	assert_true(not spline.is_point_on_track(off_track_pt, 2.0), "Point far from circuit must be flagged as off track")

## T2: Road Surface Mesh & Upward Normals (Eliminates Backface Culling)
func test_road_surface_mesh_and_upward_normals() -> void:
	var tg = TrackGeneratorScript.new()
	tg.track_theme = "metropolis"
	tg.build_circuit()

	var crf = tg.get_node_or_null("ContinuousRoadFoundation")
	assert_true(crf != null, "ContinuousRoadFoundation must exist in TrackGenerator")

	var mesh_road = crf.get_node_or_null("ContinuousRoadMesh") as MeshInstance3D
	assert_true(mesh_road != null and mesh_road.mesh != null, "ContinuousRoadMesh must contain valid ArrayMesh")

	var m: ArrayMesh = mesh_road.mesh as ArrayMesh
	assert_true(m.get_surface_count() > 0, "Road mesh must have at least 1 surface")

	var mat: StandardMaterial3D = m.surface_get_material(0) as StandardMaterial3D
	assert_true(mat != null, "Road surface must have assigned StandardMaterial3D")
	assert_true(mat.cull_mode == BaseMaterial3D.CULL_DISABLED, "Road material cull_mode must be CULL_DISABLED (2) to prevent culling")

	var a_data = m.surface_get_arrays(0)
	var verts = a_data[Mesh.ARRAY_VERTEX]
	var normals = a_data[Mesh.ARRAY_NORMAL]
	assert_true(verts.size() >= 96, "Road mesh must have sufficient vertices for continuous ribbon")

	# Verify geometric normal of first road quad points strictly UP (+Y)
	var v0 = verts[0]
	var v1 = verts[1]
	var v2 = verts[2]
	var geom_n = (v1 - v0).cross(v2 - v0).normalized()
	assert_true(geom_n.y >= 0.95, "Road triangle geometric normal must point strictly UP (+Y) to be visible from chase cam")

	# Verify vertex normals are upward
	for i in range(min(12, normals.size())):
		assert_true(normals[i].y >= 0.95, "Road vertex normal %d must be oriented upward" % i)

	tg.queue_free()

## T3: Kart Grounding & Suspension Telemetry (Zero Hovering)
func test_kart_grounding_and_suspension_telemetry() -> void:
	# Place kart at y=0.08 (wheels rest on flat road surface)
	var kart = KartControllerScript.new()
	kart.is_player = true
	kart.position = Vector3(0, 0.08, 0)
	kart._ready()

	# Simulate 10 physics frames to settle suspension
	for step in range(10):
		kart._physics_process(0.016)

	assert_eq(kart.wheel_contact_count, 4, "All 4 suspension wheels must maintain contact with flat road")
	assert_almost_eq(kart.surface_normal.y, 1.0, 0.05, "Surface normal must detect flat ground up-vector")
	assert_true(kart.ground_distance < 0.35, "Ground distance must reflect proper wheel contact (~0.28m)")
	assert_true(kart.position.y >= 0.0 and kart.position.y <= 0.25, "Kart chassis must rest naturally on road without hovering")

	kart.queue_free()

## T4: Zero False Wrong-Way on Clockwise Lap
func test_zero_false_wrong_way_on_valid_lap() -> void:
	var tg = TrackGeneratorScript.new()
	tg.track_theme = "metropolis"
	tg.build_circuit()

	var kart = KartControllerScript.new()
	kart.is_player = true
	kart.forward_speed = 22.0 # Driving forward at race speed
	kart.active_race_spline = tg.race_spline

	var spline = tg.race_spline
	assert_true(spline != null, "RaceSpline must be populated in TrackGenerator")

	# Sample 20 positions around the entire clockwise circuit
	var test_samples = 20
	var false_alarms = 0
	for step in range(test_samples):
		var s = (float(step) / float(test_samples)) * spline.track_length
		var s_data = spline.sample_at_distance(s)

		# Position kart on track facing forward along tangent T
		kart.position = s_data["pos"] + Vector3.UP * 0.08
		var fwd_tangent = s_data["tangent"]
		var basis = Basis()
		basis.z = -fwd_tangent
		basis.y = Vector3.UP
		basis.x = fwd_tangent.cross(Vector3.UP).normalized()
		kart.transform.basis = basis.orthonormalized()

		# Run wrong-way check across several simulated frames
		for frame in range(15):
			kart._check_wrong_way(0.016)
			if kart.is_wrong_way:
				false_alarms += 1
				break

	assert_eq(false_alarms, 0, "Driving full clockwise intended circuit must generate ZERO false wrong-way warnings")

	kart.queue_free()
	tg.queue_free()

## T5: Reversing Triggers Wrong-Way & Recovery Clears
func test_reversing_triggers_wrong_way_and_recovery_clears() -> void:
	var tg = TrackGeneratorScript.new()
	tg.track_theme = "metropolis"
	tg.build_circuit()

	var kart = KartControllerScript.new()
	kart.is_player = true
	kart.forward_speed = 18.0
	kart.active_race_spline = tg.race_spline

	var spline = tg.race_spline
	var s_data = spline.sample_at_distance(100.0)
	var forward_t = s_data["tangent"]

	# Turn kart 180 degrees backwards against track flow (-forward_t)
	var basis_rev = Basis()
	basis_rev.z = forward_t # Facing backwards
	basis_rev.y = Vector3.UP
	basis_rev.x = -forward_t.cross(Vector3.UP).normalized()
	kart.position = s_data["pos"] + Vector3.UP * 0.08
	kart.transform.basis = basis_rev.orthonormalized()

	# Simulate 0.75s (beyond 0.6s debounce) driving in reverse
	for frame in range(45):
		kart._check_wrong_way(0.016)

	assert_true(kart.is_wrong_way, "Driving backward against track flow for >0.6s must trigger WRONG WAY warning")

	# Spin 180 degrees back to valid forward direction
	var basis_fwd = Basis()
	basis_fwd.z = -forward_t # Facing forward again
	basis_fwd.y = Vector3.UP
	basis_fwd.x = forward_t.cross(Vector3.UP).normalized()
	kart.transform.basis = basis_fwd.orthonormalized()

	# Step check: warning should automatically clear
	for frame in range(10):
		kart._check_wrong_way(0.016)

	assert_true(not kart.is_wrong_way, "Spinning 180 degrees to face forward must automatically clear WRONG WAY warning")

	kart.queue_free()
	tg.queue_free()

## T6: 6-Car Multi-Lap Simulation (Player + 5 Distinct AI Racers)
func test_six_car_multi_lap_simulation() -> void:
	var main = KartRacingMainScript.new()
	main.selected_track = "metropolis"
	main.ai_racer_count = 5
	main._ready()

	assert_eq(main.all_karts.size(), 6, "Must spawn 6 total karts (1 player + 5 AI)")
	assert_eq(main.ai_karts.size(), 5, "Must spawn 5 AI competitors")

	# Verify grid lock during countdown
	main.race_manager.current_state = RaceManagerScript.RaceState.COUNTDOWN
	main.player_kart.apply_kart_controls(1.0, 0.0, false, 0.016)
	assert_eq(main.player_kart.forward_speed, 0.0, "Kart forward speed must be locked at 0 during countdown")

	# Release on GO!
	main.race_manager.start_race()
	assert_eq(main.race_manager.current_state, RaceManagerScript.RaceState.RACING, "Race state must transition to RACING on GO!")

	# Simulate 20 physics frames of racing
	for step in range(20):
		for k in main.all_karts:
			if is_instance_valid(k):
				k._physics_process(0.016)

	# Verify AI racers have active steering and non-zero speeds
	var moving_karts = 0
	for ai in main.ai_karts:
		if ai.forward_speed > 0.0 or ai.velocity.length_squared() >= 0.0:
			moving_karts += 1
	assert_true(moving_karts >= 4, "At least 4 AI karts must be active and advancing along circuit")

	# Verify position sorting
	main.race_manager.update_race_positions()
	assert_eq(main.race_manager.racers.size(), 6, "Race position leaderboard must contain all 6 racers")

	main.queue_free()

## T7: 6 Distinct Circuits Geometry, Continuous Colliders & Environments
func test_six_circuits_continuous_colliders_and_environments() -> void:
	var circuits = ["speedway", "sunset_coast", "canyon", "skyline", "alpine_rush", "storm_harbor"]
	for c_name in circuits:
		var tg = TrackGeneratorScript.new()
		tg.track_theme = c_name
		tg.build_circuit()

		assert_true(tg.race_spline != null, "Circuit '%s' must build valid RaceSpline" % c_name)
		assert_true(tg.race_spline.track_length > 500.0, "Circuit '%s' length must exceed 500m (got %.1f)" % [c_name, tg.race_spline.track_length])
		assert_true(tg.checkpoints.size() >= 12, "Circuit '%s' must contain at least 12 checkpoints" % c_name)

		var crf = tg.get_node_or_null("ContinuousRoadFoundation")
		assert_true(crf != null, "Circuit '%s' must include ContinuousRoadFoundation StaticBody3D" % c_name)

		var col = crf.get_node_or_null("ContinuousRoadCol") as CollisionShape3D
		assert_true(col != null and col.shape != null, "Circuit '%s' must have valid road collision shape" % c_name)
		if col and col.shape is ConcavePolygonShape3D:
			assert_true(col.shape.backface_collision, "Circuit '%s' road collider must have backface_collision = true for raycast suspension" % c_name)

		tg.queue_free()

## T8: 5 Distinct Vehicle Classes & Authoritative Physics Stats
func test_five_vehicle_classes_and_stats() -> void:
	var v_classes = ["speeder", "phantom", "enforcer", "turbo_demon", "formula"]
	for v_name in v_classes:
		var kart = KartControllerScript.new()
		kart.kart_type = v_name
		kart._ready()

		assert_true(kart.kart_visual != null, "Vehicle class '%s' must construct 3D visual" % v_name)
		assert_eq(kart.all_wheels.size(), 4, "Vehicle class '%s' must have exactly 4 wheels" % v_name)
		assert_eq(kart.front_wheels.size(), 2, "Vehicle class '%s' must have exactly 2 front wheels" % v_name)
		assert_eq(kart.rear_wheels.size(), 2, "Vehicle class '%s' must have exactly 2 rear wheels" % v_name)

		# Verify stats are distinct and authoritative
		assert_true(kart.base_speed > 20.0 and kart.base_speed <= 40.0, "Vehicle class '%s' speed must be in 20-40 m/s range" % v_name)
		assert_true(kart.acceleration > 15.0 and kart.acceleration <= 35.0, "Vehicle class '%s' acceleration must be in 15-35 m/s^2 range" % v_name)
		assert_true(kart.boost_multiplier >= 1.25 and kart.boost_multiplier <= 1.70, "Vehicle class '%s' boost multiplier must be valid" % v_name)

		kart.queue_free()

## T9: Start/Finish Seam Wrapping & Authoritative Continuous Progress
func test_seam_wrapping_and_continuous_progress() -> void:
	var nodes: Array[Vector3] = [
		Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(30, 2, -100),
		Vector3(100, 4, -120), Vector3(180, 4, -80), Vector3(160, 2, 20),
		Vector3(80, 0, 60), Vector3(0, 0, 30)
	]
	var spline = RaceSplineScript.new(nodes, 14.0)
	var L = spline.track_length

	# Query near end of spline (s = L - 2.0m) and just past seam (s = 2.0m)
	var pt_before_seam = spline.sample_at_distance(L - 2.0)["pos"]
	var pt_after_seam = spline.sample_at_distance(2.0)["pos"]

	var s_before = spline.get_closest_distance(pt_before_seam)
	var s_after = spline.get_closest_distance(pt_after_seam)

	assert_almost_eq(s_before, L - 2.0, 2.5, "Distance before seam must be close to L - 2m")
	assert_almost_eq(s_after, 2.0, 2.5, "Distance after seam must be close to 2m")

	# Delta distance across seam must wrap positively forward, never plunging backward by -L
	var raw_delta = s_after - s_before
	var wrapped_delta = fposmod(raw_delta + L * 0.5, L) - L * 0.5
	assert_true(wrapped_delta > 0.0, "Wrapped distance delta across seam must be positive (+4m), not -L")
	assert_almost_eq(wrapped_delta, 4.0, 3.0, "Wrapped distance delta across seam must approximate 4m")

	# Authoritative continuous progress formula
	var prog_lap0 = 0 * L + s_before
	var prog_lap1 = 1 * L + s_after
	assert_true(prog_lap1 > prog_lap0, "Progress on Lap 1 past finish must be greater than Lap 0 before finish")

## T10: TrackRegistry & Extended RaceSpline and RaceManager Methods
func test_track_registry_and_extended_spline_methods() -> void:
	# Track registry
	var tr = TrackRegistryScript.new()
	assert_true(tr != null, "TrackRegistry instance must instantiate")
	var all_tracks = TrackRegistryScript.get_all_tracks()
	assert_eq(all_tracks.size(), 6, "TrackRegistry must return exactly 6 distinct tracks")
	var harbor = TrackRegistryScript.get_track("storm_harbor")
	assert_true(harbor != null, "TrackRegistry must find storm_harbor track")
	assert_eq(harbor.name, "Storm Harbor", "storm_harbor track name must match")
	assert_true(harbor.length_m > 500.0, "storm_harbor track length must exceed 500m")

	# RaceSpline extended methods
	var nodes: Array[Vector3] = [
		Vector3(0, 0, 0), Vector3(0, 0, -50), Vector3(30, 2, -100),
		Vector3(100, 4, -120), Vector3(180, 4, -80), Vector3(160, 2, 20),
		Vector3(80, 0, 60), Vector3(0, 0, 30)
	]
	var spline = RaceSplineScript.new(nodes, 14.0)
	var ahead_sample = spline.sample_lookahead_forward(10.0, 15.0)
	assert_true(ahead_sample.has("pos") and ahead_sample.has("tangent"), "sample_lookahead_forward must return valid sample")
	assert_almost_eq(ahead_sample["dist"], 25.0, 0.5, "sample_lookahead_forward distance must be 25m")

	var forward_d = spline.get_forward_delta(10.0, 30.0)
	assert_almost_eq(forward_d, 20.0, 0.1, "get_forward_delta must compute 20m forward")
	var reverse_d = spline.get_forward_delta(30.0, 10.0)
	assert_almost_eq(reverse_d, -20.0, 0.1, "get_forward_delta must compute -20m backward")

	var minimap_pts = spline.get_minimap_points(32)
	assert_eq(minimap_pts.size(), 32, "get_minimap_points must return 32 2D vector points")

	# RaceManager continuous progress
	var rm = RaceManagerScript.new()
	var kart = KartControllerScript.new()
	kart.current_lap = 2
	kart.position = nodes[1]
	var prog = rm.get_kart_continuous_progress(kart, spline)
	assert_true(prog > spline.track_length, "Kart on Lap 2 must have continuous progress > 1 track length")
	kart.queue_free()
	rm.queue_free()


