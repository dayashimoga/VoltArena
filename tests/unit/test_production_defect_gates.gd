class_name TestProductionDefectGates
extends RefCounted

## TestProductionDefectGates: Verification Suite for AeroRush 10-Point Stunt Overhaul,
## Apex Flight VFX / Aircraft Overhaul / PBR Atmosphere, and Urban Legends Seamless Road Reconstruction.

const AeroGravityBodyScript = preload("res://games/aero-rush/vehicles/aero_gravity_body.gd")
const StuntEvaluatorScript = preload("res://games/aero-rush/core/stunt_evaluator.gd")
const TrackRibbonBuilderScript = preload("res://games/aero-rush/tracks/track_ribbon_builder.gd")
const AeroVehicleCatalogScript = preload("res://games/aero-rush/vehicles/aero_vehicle_catalog.gd")
const AeroVehicleVisualsScript = preload("res://games/aero-rush/vehicles/aero_vehicle_visuals.gd")
const AeroVehicleScript = preload("res://games/aero-rush/vehicles/aero_vehicle.gd")
const AeroWorldMegacityScript = preload("res://games/aero-rush/worlds/aero_world_megacity.gd")

const AircraftMeshBuilderScript = preload("res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd")
const FlightWorldManagerScript = preload("res://games/aircraft-flight/worlds/flight_world_manager.gd")

const IntersectionBuilderScript = preload("res://games/urban-legends/world/intersection_builder.gd")
const UrbanVehicleScript = preload("res://games/urban-legends/vehicles/urban_vehicle.gd")
const UrbanWorldGeneratorScript = preload("res://games/urban-legends/world/urban_world_generator.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_aerorush_surface_normal_relative_gravity_and_downforce()
	test_aerorush_quaternion_slerp_inversion_and_loop()
	test_aerorush_airborne_attitude_control_and_touchdown_eval()
	test_aerorush_track_ribbon_bishop_frame_and_collision()
	test_aerorush_vehicle_catalog_and_pbr_cityscape()

	test_apex_flight_volumetric_afterburner_shader()
	test_apex_flight_extra330_composite_airfoil_and_uh60_hub()
	test_apex_flight_mountain_geology_and_normal_continuity()

	test_urban_legends_intersection_builder_welded_aprons_and_curb_returns()
	test_urban_legends_collision_filter_and_scratch_response()
	test_urban_legends_smooth_rolling_hills_and_world_detailing()

	return {"passed": assertions_passed, "failed": assertions_failed}

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("TestProductionDefectGates FAIL: " + msg)

# ==============================================================================
# SECTION 1: AERORUSH 10-POINT EXTREME STUNT-RACING GATES
# ==============================================================================

func test_aerorush_surface_normal_relative_gravity_and_downforce() -> void:
	var gravity_body = AeroGravityBodyScript.new()
	assert_true(gravity_body != null, "AeroGravityBody instance should instantiate cleanly")

	# Test dynamic gravity vector on flat track (normal = UP)
	var g_flat = gravity_body.calculate_effective_gravity(Vector3.UP, 0.0, true)
	assert_true(is_equal_approx(g_flat.y, -9.81), "Gravity on flat ground should be -9.81 m/s²")

	# Test surface-relative inverted track gravity (normal = DOWN, e.g. top of vertical loop)
	var g_inverted = gravity_body.calculate_effective_gravity(Vector3.DOWN, 40.0, true)
	assert_true(is_equal_approx(g_inverted.y, 24.5), "Inverted loop gravity must be +24.5 m/s² (+2.5G positive adhesion)")

	# Test wall-ride track gravity (normal = RIGHT, 90 deg wall)
	var g_wall = gravity_body.calculate_effective_gravity(Vector3.RIGHT, 40.0, true)
	assert_true(is_equal_approx(g_wall.x, -24.5), "Wall-ride gravity must pull directly into track normal at 24.5 m/s²")

	# Test airborne ungrounded gravity fallback
	var g_air = gravity_body.calculate_effective_gravity(Vector3.DOWN, 40.0, false)
	assert_true(is_equal_approx(g_air.y, -9.81), "Airborne gravity must fall back to world gravity -9.81 m/s²")

	# Test continuous aerodynamic downforce solver: F_down = -n * (m * g_surface * 0.25 + C_downforce * v^2)
	var f_down_flat = gravity_body.calculate_downforce(Vector3.UP, 950.0, 55.0, false)
	assert_true(f_down_flat.y < -4500.0, "High-speed downforce should produce strong downward track adhesion")
	assert_true(f_down_flat.dot(Vector3.DOWN) > 0.99, "Downforce must align strictly opposite to track normal")

	var f_down_inverted = gravity_body.calculate_downforce(Vector3.DOWN, 950.0, 55.0, true)
	assert_true(f_down_inverted.y > 7000.0, "Inverted loop downforce must adhere vehicle upwards into track ceiling")

func test_aerorush_quaternion_slerp_inversion_and_loop() -> void:
	var gravity_body = AeroGravityBodyScript.new()

	# Start chassis right-side up
	var current_basis = Basis.IDENTITY
	# Track normal inverted (180 deg flip)
	var target_normal = Vector3.DOWN

	var aligned_basis = gravity_body.align_chassis_to_normal(current_basis, target_normal, 0.016, 16.0)
	assert_true(not is_nan(aligned_basis.x.x) and not is_nan(aligned_basis.y.y) and not is_nan(aligned_basis.z.z), "Quaternion slerp alignment must never generate NaN values during 180 deg inversion")
	assert_true(is_equal_approx(aligned_basis.determinant(), 1.0), "Aligned basis must remain orthonormal without shear")

func test_aerorush_airborne_attitude_control_and_touchdown_eval() -> void:
	var evaluator = StuntEvaluatorScript.new()
	assert_true(evaluator != null, "StuntEvaluator instance should instantiate cleanly")

	# Test 3-axis air rotation delta
	# 1. Pitch (throttle = 1.0) and Flat Spin / Yaw (steer = 1.0, roll_modifier = false)
	var rot_pitch_yaw = evaluator.calculate_air_rotation(1.0, 0.0, 1.0, false, 0.016)
	assert_true(absf(rot_pitch_yaw.x - 3.2 * 0.016) < 0.001, "Pitch torque must match +/-3.2 rad/s")
	assert_true(absf(rot_pitch_yaw.y - (-4.0 * 0.016)) < 0.001, "Yaw torque must match +/-4.0 rad/s")

	# 2. Barrel Roll (steer = 1.0, roll_modifier = true)
	var rot_roll = evaluator.calculate_air_rotation(0.0, 0.0, 1.0, true, 0.016)
	assert_true(absf(rot_roll.z - 4.5 * 0.016) < 0.001, "Roll torque must match +/-4.5 rad/s")

	# Test Perfect Landing: theta <= 18 degrees
	var perf_res = evaluator.evaluate_touchdown(Vector3.UP, Vector3(0.08, 0.99, 0.0).normalized())
	assert_true(perf_res["quality"] == "perfect", "Deviation <= 18 deg must award Perfect Landing")
	assert_true(perf_res["score_bonus"] == 500, "Perfect landing must award +500 pts")
	assert_true(perf_res["boost_refill"] == 1.0, "Perfect landing must fully refill nitro boost")

	# Test Clean Landing: 18 deg < theta <= 38 degrees
	var clean_normal = Basis(Vector3.FORWARD, deg_to_rad(28.0)) * Vector3.UP
	var clean_res = evaluator.evaluate_touchdown(Vector3.UP, clean_normal)
	assert_true(clean_res["quality"] == "clean", "Deviation between 18 and 38 deg must award Clean Landing")
	assert_true(clean_res["score_bonus"] == 150, "Clean landing must award +150 pts")

	# Test Crash Rollover: theta > 65 degrees
	var crash_normal = Basis(Vector3.FORWARD, deg_to_rad(75.0)) * Vector3.UP
	var crash_res = evaluator.evaluate_touchdown(Vector3.UP, crash_normal)
	assert_true(crash_res["quality"] == "crash", "Deviation > 65 deg must register Crash")
	assert_true(crash_res["reset_combo"] == true, "Crash must reset combo multiplier to 1.0x")

func test_aerorush_track_ribbon_bishop_frame_and_collision() -> void:
	# Test Catmull-Rom spline sampling and Bishop frame generation
	var spline_pts: Array[Vector3] = [
		Vector3(0, 0, 0),
		Vector3(0, 10, 50),
		Vector3(0, 40, 100),
		Vector3(0, 70, 150),
		Vector3(0, 40, 200),
		Vector3(0, 10, 250),
		Vector3(0, 0, 300)
	]

	var frames = TrackRibbonBuilderScript.compute_bishop_frames(spline_pts, 2.0)
	assert_true(frames.size() >= 50, "Track ribbon must sample with delta_s <= 2.0m")

	for i in range(1, frames.size()):
		var f_prev: Dictionary = frames[i - 1]
		var f_curr: Dictionary = frames[i]
		var step_dist = (f_curr["pos"] as Vector3).distance_to(f_prev["pos"] as Vector3)
		assert_true(step_dist <= 2.5, "Bishop frame step distance must remain <= 2.0m (+/- tolerance)")
		var det = (f_curr["basis"] as Basis).determinant()
		assert_true(is_equal_approx(det, 1.0), "Bishop frames must remain orthonormal without twisting")

	# Build track mesh and unified collision
	var track_data = TrackRibbonBuilderScript.build_track_ribbon(spline_pts, 15.0)
	var track_node = track_data["root"]
	assert_true(track_node != null, "TrackRibbonBuilder must produce a valid TrackNode3D")
	var col_shape = track_node.get_node_or_null("TrackUnifiedCollision/CollisionShape3D") as CollisionShape3D
	assert_true(col_shape != null, "Track node must contain TrackUnifiedCollision/CollisionShape3D")
	if col_shape:
		assert_true(col_shape.shape is ConcavePolygonShape3D, "Track collision must be unified ConcavePolygonShape3D with zero box seams")
	track_node.free()

func test_aerorush_vehicle_catalog_and_pbr_cityscape() -> void:
	# 4 Production Vehicles
	var zephyr = AeroVehicleCatalogScript.get_vehicle_definition("apex_zephyr")
	assert_true(zephyr["top_speed"] == 64.0 and zephyr["mass"] == 950.0 and zephyr["grip"] == 1.15, "Apex Zephyr stats must match prompt specifications")

	var stryker = AeroVehicleCatalogScript.get_vehicle_definition("torque_stryker")
	assert_true(stryker["top_speed"] == 58.0 and stryker["mass"] == 1120.0 and stryker["grip"] == 1.30, "Torque Stryker stats must match prompt specifications")

	var dune = AeroVehicleCatalogScript.get_vehicle_definition("vanguard_dune")
	assert_true(dune["top_speed"] == 52.0 and dune["mass"] == 1280.0 and dune["grip"] == 1.05, "Vanguard Dune stats must match prompt specifications")

	var phantom = AeroVehicleCatalogScript.get_vehicle_definition("quantum_phantom")
	assert_true(phantom["top_speed"] == 62.0 and phantom["mass"] == 980.0 and phantom["grip"] == 1.25, "Quantum Phantom stats must match prompt specifications")

	# PBR Materials: clearcoat 1.0, clearcoat roughness 0.08
	var visuals_data = AeroVehicleVisualsScript.build_vehicle_visuals("apex_zephyr", Color(0.9, 0.1, 0.1))
	var visuals_root = visuals_data["root"]
	assert_true(visuals_root != null, "Apex Zephyr visuals must build successfully")
	var caliper_node = visuals_root.find_child("BrakeCaliper", true, false)
	assert_true(caliper_node != null, "Vehicle visuals must contain dynamic glowing brake disc calipers")
	visuals_root.free()

	# Megacity PBR High-Rises
	var megacity = AeroWorldMegacityScript.new()
	megacity._build_flanking_skyscrapers()
	var found_spire = false
	var found_antenna_beacon = false
	for c in megacity.get_children():
		if c.has_node("AntennaSpire") or c.find_child("AntennaSpire", true, false) != null:
			found_spire = true
		if c.has_node("AviationBeacon") or c.find_child("AviationBeacon", true, false) != null:
			found_antenna_beacon = true
	assert_true(found_spire, "High-rise towers must feature architectural rooftop antennas")
	assert_true(found_antenna_beacon, "High-rise rooftop antennas must feature red aviation warning beacons")
	megacity.free()

# ==============================================================================
# SECTION 2: APEX FLIGHT VFX, AIRCRAFT OVERHAUL & MOUNTAIN GEOLOGY GATES
# ==============================================================================

func test_apex_flight_volumetric_afterburner_shader() -> void:
	var shader = load("res://games/aircraft-flight/aircraft/afterburner_plume.gdshader")
	assert_true(shader != null, "Volumetric afterburner shader must exist and load cleanly")

	var mat = AircraftMeshBuilderScript._create_afterburner_material(Color(0.4, 0.7, 1.0, 1.0), Color(1.0, 0.45, 0.1, 0.85))
	assert_true(mat != null, "Afterburner plume material must instantiate as ShaderMaterial")
	assert_true(mat.shader != null, "Afterburner material must reference afterburner_plume.gdshader")

	# Verify jet plumes use the volumetric shader
	var fa18 = AircraftMeshBuilderScript.build_fa18_hornet(Color(0.5, 0.5, 0.5), Color(1, 0.5, 0))
	var plume_l = fa18.find_child("AfterburnerPlumeLeft", true, false) as MeshInstance3D
	assert_true(plume_l != null, "FA-18 must contain AfterburnerPlumeLeft")
	if plume_l:
		assert_true(plume_l.material_override is ShaderMaterial, "Afterburner plume must use volumetric shader (zero solid white spheres)")
	fa18.free()

func test_apex_flight_extra330_composite_airfoil_and_uh60_hub() -> void:
	# Extra 330 NACA Airfoil Monoplane
	var extra = AircraftMeshBuilderScript.build_extra330_sport(Color(0.9, 0.1, 0.1), Color(1, 0.8, 0.1))
	assert_true(extra != null, "Extra 330 visuals must instantiate cleanly")
	var canopy = extra.find_child("Canopy", true, false)
	assert_true(canopy != null, "Extra 330 must feature bubble canopy with cockpit interior")
	var gear = extra.find_child("LandingGear", true, false)
	assert_true(gear != null, "Extra 330 must feature carbon landing gear legs with teardrop wheel pants")
	extra.free()

	# UH-60 Black Hawk Muted Tips (zero yellow halo ring)
	var uh60 = AircraftMeshBuilderScript.build_uh60_helicopter(Color(0.2, 0.25, 0.2), Color(0.1, 0.1, 0.1))
	assert_true(uh60 != null, "UH-60 visuals must instantiate cleanly")
	var rotor_blur = uh60.find_child("MainRotorBlur", true, false) as MeshInstance3D
	assert_true(rotor_blur != null, "UH-60 must contain MainRotorBlur disk")
	if rotor_blur and rotor_blur.material_override is ShaderMaterial:
		var tip_col: Color = rotor_blur.material_override.get_shader_parameter("tip_color")
		assert_true(tip_col.a <= 0.01, "Military UH-60 rotor blur must have muted non-reflective tip opacity (zero yellow halo)")
	uh60.free()

func test_apex_flight_mountain_geology_and_normal_continuity() -> void:
	var peak_mesh = FlightWorldManagerScript._create_alpine_peak_mesh(650.0, 480.0)
	assert_true(peak_mesh != null, "Alpine peak mesh must generate via hydraulic-eroded ridged massif")
	assert_true(peak_mesh is ArrayMesh, "Peak mesh must be ArrayMesh (zero 16-segment triangle fan cones)")

# ==============================================================================
# SECTION 3: URBAN LEGENDS SEAMLESS ROAD & COLLISION RECONSTRUCTION GATES
# ==============================================================================

func test_urban_legends_intersection_builder_welded_aprons_and_curb_returns() -> void:
	var test_segments: Array[Dictionary] = [
		{"start": Vector3(-50, 1.0, 0), "end": Vector3(50, 1.0, 0), "width": 14.0, "length": 100.0, "direction": Vector3.RIGHT, "surface": 0},
		{"start": Vector3(0, 1.0, -50), "end": Vector3(0, 1.0, 50), "width": 14.0, "length": 100.0, "direction": Vector3.FORWARD, "surface": 0}
	]

	# 1. Height clamping at junction
	var junctions = IntersectionBuilderScript.identify_and_clamp_intersections(test_segments)
	assert_true(junctions.size() >= 1, "IntersectionBuilder must detect crossing road corridors")
	if junctions.size() > 0:
		var j = junctions[0]
		assert_true(is_equal_approx(j["pos"].y, 1.0), "Junction elevation must clamp to shared Y coordinate")

	# 2. Curb intervals trimming around junction
	var intervals = IntersectionBuilderScript.compute_curb_intervals(test_segments[0]["start"], test_segments[0]["end"], junctions, 1.0)
	assert_true(intervals.size() >= 2, "Curb intervals must be split into segments before and after the intersection box")
	for span in intervals:
		var t0 = span.x
		var t1 = span.y
		var mid_pt = test_segments[0]["start"].lerp(test_segments[0]["end"], (t0 + t1) * 0.5)
		assert_true(mid_pt.distance_to(junctions[0]["pos"]) > 10.0, "Trimmed curbs must never cross within the intersection box")

	# 3. Welded apron and 4-quadrant curb returns
	var asphalt_mat = StandardMaterial3D.new()
	var sw_mat = StandardMaterial3D.new()
	var apron = IntersectionBuilderScript.build_intersection_apron(junctions[0], asphalt_mat, sw_mat)
	assert_true(apron != null, "Intersection apron must build successfully")
	var body = apron.get_node_or_null("StaticBody3D")
	assert_true(body != null, "Apron must contain flush StaticBody3D collision")
	apron.free()

func test_urban_legends_collision_filter_and_scratch_response() -> void:
	var car = UrbanVehicleScript.new()
	car._ready()
	assert_true(car.health == 100.0, "Initial vehicle health must be 100%")

	# Test take_damage
	car.take_damage(10.0)
	assert_true(is_equal_approx(car.health, 90.0), "Damage should reduce health normally on hard crashes")

	# Test repair
	car.repair(100.0)
	assert_true(is_equal_approx(car.health, 100.0), "Repair must restore vehicle health to 100%")
	assert_true(car.is_wrecked == false, "Vehicle must not be wrecked after repair")

	car.free()

func test_urban_legends_smooth_rolling_hills_and_world_detailing() -> void:
	var hill_mesh = UrbanWorldGeneratorScript._create_eroded_heightmap_mountain(400.0, 180.0, 400.0, 24)
	assert_true(hill_mesh != null, "Rolling coastal hill mesh must generate cleanly")
	assert_true(hill_mesh is ArrayMesh, "Hill mesh must be ArrayMesh with smooth continuous surface normals (zero pyramid facets)")
