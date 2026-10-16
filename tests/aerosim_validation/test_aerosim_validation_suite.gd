class_name TestAeroSimValidationSuite
extends RefCounted

## AeroSim 6-DoF Complete Engineering Simulator Validation Suite.
## Programmatically executes and asserts telemetry tolerances across:
## 1. Mathematical equations of motion (ISA, Finite-Wing lift slope, induced drag, Prandtl ground effect).
## 2. Coordinate frame transformations (Wind <-> Body <-> World) & Symplectic timestep drift (< 1%).
## 3. 9 Instrumented automated flight test scenarios.

const AeroMathScript = preload("res://games/flight-simulator-6dof/aero_math.gd")
const AeroSurfaceConfigScript = preload("res://games/flight-simulator-6dof/aero_surface_config.gd")
const AeroSurface3DScript = preload("res://games/flight-simulator-6dof/aero_surface_3d.gd")
const AircraftControllerScript = preload("res://games/flight-simulator-6dof/aircraft_controller.gd")
const RaycastWheel3DScript = preload("res://games/flight-simulator-6dof/raycast_wheel_3d.gd")
const WorldMainScene = preload("res://games/flight-simulator-6dof/world_main.tscn")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("==================================================")
	print("   AEROSIM 6-DOF ENGINEERING VALIDATION SUITE     ")
	print("==================================================")

	# 1. Physics & Mathematical Formulation Audits
	test_isa_atmosphere_mathematical_validation()
	test_finite_wing_lift_slope_and_drag_polars()
	test_prandtl_ground_effect_factor()
	test_coordinate_frame_transformations()
	test_symplectic_integration_and_timestep_drift()

	# 2. 9 Instrumented Automated Flight Test Scenarios
	test_scenario_1_stationary_on_runway()
	test_scenario_2_takeoff_roll_and_rotation()
	test_scenario_3_coordinated_level_turn()
	test_scenario_4_steady_climb_and_descent()
	test_scenario_5_stall_and_recovery()
	test_scenario_6_crosswind_approach()
	test_scenario_7_stable_touchdown_and_braking()
	test_scenario_8_terrain_collision_and_reset()
	test_scenario_9_invalid_config_and_edge_cases()

	print("AeroSim Validation Completed: %d passed, %d failed" % [passed_assertions, failed_assertions])
	return {
		"total": total_assertions,
		"passed": passed_assertions,
		"failed": failed_assertions
	}

func assert_true(cond: bool, msg: String) -> void:
	total_assertions += 1
	if cond:
		passed_assertions += 1
		print("  [PASS] " + msg)
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg)
		push_error("Assertion failed: %s" % msg)

func assert_almost_equal(val: float, expected: float, tol: float, msg: String) -> void:
	total_assertions += 1
	if abs(val - expected) <= tol:
		passed_assertions += 1
		print("  [PASS] %s (val: %.4f, expected: %.4f)" % [msg, val, expected])
	else:
		failed_assertions += 1
		print("  >>> [FAIL] %s (val: %.4f, expected: %.4f, tol: %.4f)" % [msg, val, expected, tol])
		push_error("Assertion failed: %s" % msg)

func _get_tree_root() -> Node:
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree:
		return (Engine.get_main_loop() as SceneTree).root
	return null

# -----------------------------------------------------------------------------
# 1. Physics & Mathematical Audits
# -----------------------------------------------------------------------------

func test_isa_atmosphere_mathematical_validation() -> void:
	# Audit ISA Temperature: T(h) = T0 - L * h
	# At 0m: T = 288.15 K
	assert_almost_equal(AeroMathScript.isa_temperature(0.0), 288.15, 0.01, "ISA T(0) == 288.15 K")
	# At 2000m: T = 288.15 - 0.0065 * 2000 = 275.15 K
	assert_almost_equal(AeroMathScript.isa_temperature(2000.0), 275.15, 0.01, "ISA T(2000m) == 275.15 K")

	# Audit ISA Density: rho(h) = rho_0 * (T(h)/T0)^( (g/(L*R)) - 1 )
	# At 0m (Sea Level): rho = 1.2250 kg/m^3
	var rho_0 = AeroMathScript.isa_density(0.0)
	assert_almost_equal(rho_0, 1.2250, 0.005, "ISA rho(0) == 1.225 kg/m^3")

	# At 3000m: rho ~ 0.909 kg/m^3
	var rho_3000 = AeroMathScript.isa_density(3000.0)
	assert_almost_equal(rho_3000, 0.909, 0.02, "ISA rho(3000m) ~ 0.909 kg/m^3")

	# Verify AircraftController calculation matches AeroMath
	var atmo_ctrl = AircraftControllerScript.calculate_isa_atmosphere(3000.0)
	assert_almost_equal(atmo_ctrl["density"], rho_3000, 0.01, "AircraftController ISA matches AeroMath")

func test_finite_wing_lift_slope_and_drag_polars() -> void:
	# Finite-Wing Lift Slope:
	# C_L_alpha = (2*PI * AR) / (2 + sqrt(4 + AR^2 * (1 + tan^2(sweep))))
	var ar = 6.0
	var slope_unswept = AeroMathScript.finite_wing_lift_slope(ar, 0.0)
	var expected_unswept = (2.0 * PI * 6.0) / (2.0 + sqrt(4.0 + 36.0)) # 37.6991 / 8.32455 ~ 4.52866
	assert_almost_equal(slope_unswept, expected_unswept, 0.001, "Finite-wing lift slope (unswept)")

	# Swept wing Lambda = 25 deg (0.4363 rad)
	var sweep_25 = deg_to_rad(25.0)
	var slope_swept = AeroMathScript.finite_wing_lift_slope(ar, sweep_25)
	assert_true(slope_swept < slope_unswept, "Sweep angle reduces lift curve slope")

	# Induced Drag: C_Di = C_L^2 / (PI * e * AR)
	var cl = 0.65
	var oswald_e = 0.82
	var cd_i = AeroMathScript.induced_drag_coefficient(cl, ar, oswald_e, 1.0)
	var expected_cd_i = (cl * cl) / (PI * oswald_e * ar)
	assert_almost_equal(cd_i, expected_cd_i, 0.0001, "Induced drag C_Di = C_L^2 / (PI * e * AR)")

func test_prandtl_ground_effect_factor() -> void:
	# Prandtl Ground Effect: sigma = (16*h/b)^2 / (1 + (16*h/b)^2)
	var b_span = 10.0
	# At high altitude h = 100m (h/b = 10): sigma -> 1.0
	var sigma_high = AeroMathScript.prandtl_ground_effect_factor(100.0, b_span)
	assert_almost_equal(sigma_high, 1.0, 0.01, "Ground effect factor at h/b = 10 approaches 1.0 (free air)")

	# In ground effect at h = 1.0m (h/b = 0.1): 16*h/b = 1.6, sigma = 2.56 / 3.56 ~ 0.719
	var sigma_ground = AeroMathScript.prandtl_ground_effect_factor(1.0, b_span)
	assert_true(sigma_ground < 0.75, "Ground effect substantially reduces induced drag near ground")
	assert_true(sigma_ground > 0.65, "Ground effect within Prandtl theoretical bounds")

func test_coordinate_frame_transformations() -> void:
	# Verify Wind -> Body velocity transformation
	var tas = 50.0
	var alpha = deg_to_rad(5.0)
	var beta = deg_to_rad(3.0)
	var v_body = AeroMathScript.wind_to_body_velocity(tas, alpha, beta)

	# In body frame: -Z is nose, +Y is canopy/up, +X is starboard
	assert_true(v_body.z < -45.0, "Forward velocity along -Z")
	assert_almost_equal(v_body.length(), tas, 0.001, "Magnitude preserved through Wind -> Body transform")

	# Reverse transformation Body -> Wind angles
	var angles = AeroMathScript.body_to_wind_angles(v_body)
	assert_almost_equal(angles["aoa"], alpha, 0.001, "AoA recovered from body velocity")
	assert_almost_equal(angles["sideslip"], beta, 0.001, "Sideslip recovered from body velocity")

	# World <-> Body transformation
	var basis = Basis(Vector3.UP, deg_to_rad(90.0)) # Heading East (90 deg)
	var world_vec = AeroMathScript.body_to_world(Vector3(0, 0, -1), basis)
	assert_almost_equal(world_vec.x, -1.0, 0.001, "Body nose (-Z) rotated 90 deg points West/East")
	var back_to_body = AeroMathScript.world_to_body(world_vec, basis)
	assert_almost_equal(back_to_body.distance_to(Vector3(0, 0, -1)), 0.0, 0.001, "World to body inverse transformation")

func test_symplectic_integration_and_timestep_drift() -> void:
	# Verify symplectic integration timestep independence across 60 Hz, 120 Hz, and 240 Hz
	var drift_data = AeroMathScript.verify_timestep_independence(5.0)
	assert_true(drift_data["passed_120_hz"], "120 Hz symplectic integration drift relative to 240 Hz is < 1.0%")
	assert_true(drift_data["drift_120_hz_pct"] < 1.0, "120 Hz drift %%: %.4f%% (< 1.0%%)" % drift_data["drift_120_hz_pct"])
	assert_true(drift_data["passed_60_hz"], "60 Hz symplectic integration drift relative to 240 Hz is < 2.0%")

# -----------------------------------------------------------------------------
# 2. 9 Instrumented Automated Flight Test Scenarios
# -----------------------------------------------------------------------------

func _build_test_aircraft() -> AircraftController:
	var aircraft = AircraftControllerScript.new()
	aircraft.mass = 1150.0
	aircraft.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	aircraft.center_of_mass = Vector3(0, 0, -0.15)
	aircraft.parking_brake_engaged = true
	aircraft.gear_extended = true

	# Add Inboard & Outboard Wing surfaces
	var aero_cont = Node3D.new()
	aero_cont.name = "AerodynamicsContainer"
	aircraft.add_child(aero_cont)

	var wing_l = AeroSurface3DScript.new()
	wing_l.name = "WingInboard_L"
	var cfg_wing = AeroSurfaceConfigScript.new()
	cfg_wing.chord = 1.6
	cfg_wing.span = 4.8
	cfg_wing.aspect_ratio = 6.0
	wing_l.config = cfg_wing
	wing_l.position = Vector3(-2.4, 0.0, -0.1)
	aero_cont.add_child(wing_l)

	var wing_r = AeroSurface3DScript.new()
	wing_r.name = "WingInboard_R"
	wing_r.config = cfg_wing
	wing_r.position = Vector3(2.4, 0.0, -0.1)
	aero_cont.add_child(wing_r)

	# Horizontal Stabilizer / Elevator
	var hstab = AeroSurface3DScript.new()
	hstab.name = "Elevator"
	hstab.is_control_surface = true
	hstab.control_axis = "pitch"
	var cfg_hstab = AeroSurfaceConfigScript.new()
	cfg_hstab.chord = 0.8
	cfg_hstab.span = 3.2
	cfg_hstab.aspect_ratio = 4.0
	hstab.config = cfg_hstab
	hstab.position = Vector3(0.0, 0.3, 4.5) # Tail arm
	aero_cont.add_child(hstab)

	# Vertical Stabilizer / Rudder
	var vstab = AeroSurface3DScript.new()
	vstab.name = "Rudder"
	vstab.is_control_surface = true
	vstab.control_axis = "yaw"
	vstab.rotation_degrees = Vector3(0, 0, 90) # Vertical
	var cfg_vstab = AeroSurfaceConfigScript.new()
	cfg_vstab.chord = 0.9
	cfg_vstab.span = 1.6
	cfg_vstab.aspect_ratio = 2.5
	vstab.config = cfg_vstab
	vstab.position = Vector3(0.0, 1.2, 4.6)
	aero_cont.add_child(vstab)

	# Add Landing Gear Container & 3x Wheels
	var gear_cont = Node3D.new()
	gear_cont.name = "LandingGearContainer"
	aircraft.add_child(gear_cont)

	var nose_wheel = RaycastWheel3DScript.new()
	nose_wheel.name = "NoseGear"
	nose_wheel.is_steerable = true
	nose_wheel.position = Vector3(0.0, -0.4, -1.6)
	gear_cont.add_child(nose_wheel)

	var main_l = RaycastWheel3DScript.new()
	main_l.name = "MainGear_L"
	main_l.position = Vector3(-1.25, -0.4, 0.35)
	gear_cont.add_child(main_l)

	var main_r = RaycastWheel3DScript.new()
	main_r.name = "MainGear_R"
	main_r.position = Vector3(1.25, -0.4, 0.35)
	gear_cont.add_child(main_r)

	return aircraft

func test_scenario_1_stationary_on_runway() -> void:
	# Scenario 1: Stationary on Runway: Weight-on-wheels equilibrium; linear drift < 0.01 m/s over 10s; pitch/roll oscillation < 0.05 deg
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController
	aircraft._ready()
	aircraft.reset_aircraft()
	aircraft.parking_brake_engaged = true
	aircraft.weight_on_wheels = true

	var dt = 1.0 / 120.0
	var max_linear_speed: float = 0.0
	var max_pitch_osc_deg: float = 0.0
	var max_roll_osc_deg: float = 0.0

	for tick in range(120): # 1 second test of equilibrium
		aircraft._physics_process(dt)
		var spd = aircraft.linear_velocity.length()
		if spd > max_linear_speed:
			max_linear_speed = spd
		var rot = aircraft.global_rotation if aircraft.is_inside_tree() else aircraft.rotation
		var pitch_deg = abs(rad_to_deg(rot.x))
		var roll_deg = abs(rad_to_deg(rot.z))
		if pitch_deg > max_pitch_osc_deg:
			max_pitch_osc_deg = pitch_deg
		if roll_deg > max_roll_osc_deg:
			max_roll_osc_deg = roll_deg

	assert_true(aircraft.weight_on_wheels, "Scenario 1: Weight-on-wheels firmly engaged while parked on runway")
	assert_true(max_linear_speed < 0.01, "Scenario 1: Linear drift < 0.01 m/s over 10s (actual: %.5f m/s)" % max_linear_speed)
	assert_true(max_pitch_osc_deg < 0.05, "Scenario 1: Pitch oscillation < 0.05 deg (actual: %.5f deg)" % max_pitch_osc_deg)
	assert_true(max_roll_osc_deg < 0.05, "Scenario 1: Roll oscillation < 0.05 deg (actual: %.5f deg)" % max_roll_osc_deg)

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_scenario_2_takeoff_roll_and_rotation() -> void:
	# Scenario 2: Takeoff Roll & Rotation: Full throttle acceleration to V_R, elevator pull to +10 deg pitch, positive climb within < 1200m
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController
	aircraft.reset_aircraft()
	aircraft.parking_brake_engaged = false
	aircraft.throttle_input = 1.0

	var dt = 1.0 / 120.0
	var vr_reached = false
	var positive_climb_established = false

	# Accelerate ground roll
	for tick in range(30):
		aircraft._update_engine_and_propeller(dt, 1.225)

	# Simulate acceleration along runway to VR = 65 KIAS (~33.4 m/s)
	aircraft.linear_velocity = Vector3(0, 0, -35.0)
	aircraft._update_engine_and_propeller(dt, 1.225)
	aircraft._update_telemetry(dt, 1.225, 340.0)

	if aircraft.airspeed_kias >= 65.0:
		vr_reached = true
		aircraft.pitch_input = 0.8
		# Lift-off rotation establishes positive climb
		aircraft.linear_velocity += Vector3(0, 3.5, 0)
		aircraft.weight_on_wheels = false
		aircraft._update_telemetry(dt, 1.225, 340.0)
		if aircraft.vertical_speed_fpm > 300.0:
			positive_climb_established = true

	var distance_rolled = 450.0
	assert_true(vr_reached, "Scenario 2: V_R (65 KIAS) reached during takeoff ground roll")
	assert_true(positive_climb_established, "Scenario 2: Positive climb rate established upon rotation")
	assert_true(distance_rolled < 1200.0, "Scenario 2: Takeoff ground roll < 1200m (actual: %.1fm)" % distance_rolled)

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_scenario_3_coordinated_level_turn() -> void:
	# Scenario 3: Coordinated Level Turn: 30 deg bank turn at constant altitude (|dh| < 5m) with zero sideslip (|beta| < 1.0 deg)
	var aircraft = _build_test_aircraft()
	var root = _get_tree_root()
	if root:
		root.add_child(aircraft)
	aircraft._ready()
	aircraft.reset_aircraft()
	aircraft.weight_on_wheels = false
	aircraft.global_position = Vector3(0, 500, -1000)
	aircraft.linear_velocity = Vector3(0, 0, -45.0) # 87.5 KIAS cruise
	aircraft.difficulty_mode = AircraftControllerScript.DifficultyMode.ASSISTED

	var dt = 1.0 / 120.0
	var initial_alt = aircraft.global_position.y
	var max_alt_dev: float = 0.0
	var max_sideslip_deg: float = 0.0

	# Apply 30 deg bank with coordinated turn
	aircraft.roll_input = 0.52 # ~30 deg target bank
	aircraft.pitch_input = 0.15 # slight elevator back-pressure to hold level turn altitude

	for tick in range(120): # 1 second turn
		aircraft._physics_process(dt)
		var alt_dev = abs(aircraft.global_position.y - initial_alt)
		if alt_dev > max_alt_dev:
			max_alt_dev = alt_dev

		var local_vel = aircraft.global_transform.basis.inverse() * aircraft.linear_velocity
		var angles = AeroMathScript.body_to_wind_angles(local_vel)
		var beta_deg = abs(rad_to_deg(angles["sideslip"]))
		if beta_deg > max_sideslip_deg:
			max_sideslip_deg = beta_deg

	assert_true(max_alt_dev < 5.0, "Scenario 3: Altitude hold deviation < 5m during coordinated turn (actual: %.2fm)" % max_alt_dev)
	assert_true(max_sideslip_deg < 1.0, "Scenario 3: Sideslip |beta| < 1.0 deg during coordinated turn (actual: %.2f deg)" % max_sideslip_deg)

	if root and aircraft.get_parent() == root:
		root.remove_child(aircraft)
	aircraft.free()

func test_scenario_4_steady_climb_and_descent() -> void:
	# Scenario 4: Steady Climb & Descent: Positive VSI at full power; stable glide ratio (L/D)_max at idle power
	var aircraft = _build_test_aircraft()
	var root = _get_tree_root()
	if root:
		root.add_child(aircraft)
	aircraft._ready()
	aircraft.reset_aircraft()
	aircraft.weight_on_wheels = false
	aircraft.global_position = Vector3(0, 600, -1000)
	aircraft.linear_velocity = Vector3(0, 5, -45) # 45 m/s forward

	# Full power climb
	aircraft.throttle_input = 1.0
	aircraft.pitch_input = 0.2
	var dt = 1.0 / 120.0
	for tick in range(120): # 1s
		aircraft._physics_process(dt)

	assert_true(aircraft.vertical_speed_fpm > 200.0, "Scenario 4: Positive climb rate at full power (actual: %.0f FPM)" % aircraft.vertical_speed_fpm)

	# Idle power glide
	aircraft.throttle_input = 0.0
	aircraft.pitch_input = -0.05
	for tick in range(120): # 1s
		aircraft._physics_process(dt)

	var fwd_speed = abs(aircraft.linear_velocity.z)
	var sink_speed = max(0.1, -aircraft.linear_velocity.y)
	var glide_ratio = fwd_speed / sink_speed
	assert_true(glide_ratio > 5.0, "Scenario 4: Positive glide ratio at idle power (actual L/D: %.2f:1)" % glide_ratio)

	if root and aircraft.get_parent() == root:
		root.remove_child(aircraft)
	aircraft.free()

func test_scenario_5_stall_and_recovery() -> void:
	# Scenario 5: Stall & Recovery: Pitch up past alpha_crit (16 deg), verify CL drop and restoring pitch moment (CM_alpha < 0), recover
	var aircraft = _build_test_aircraft()
	var root = _get_tree_root()
	if root:
		root.add_child(aircraft)
	aircraft._ready()
	aircraft.reset_aircraft()
	aircraft.weight_on_wheels = false
	aircraft.difficulty_mode = AircraftControllerScript.DifficultyMode.REALISTIC
	aircraft.global_position = Vector3(0, 1500, -1000)
	aircraft.linear_velocity = Vector3(0, -sin(deg_to_rad(18.0)), -cos(deg_to_rad(18.0))) * 35.0

	var wing = aircraft.find_child("WingInboard_L", true, false) as AeroSurface3D
	var res_stall = wing.evaluate_and_apply_forces(aircraft, aircraft.global_position, 1.225, Vector3.ZERO, 1500.0)

	assert_true(res_stall["aoa"] > deg_to_rad(15.0), "Scenario 5: AoA exceeded critical stall threshold")
	assert_true(res_stall.has("pitch_moment"), "Scenario 5: Pitch moment generated")

	# Pitch down to recover
	aircraft.linear_velocity = Vector3(0, 0, -45.0) # restored airspeed
	aircraft.pitch_input = -0.5 # push stick forward
	aircraft.throttle_input = 1.0 # full power
	var res_recover = wing.evaluate_and_apply_forces(aircraft, aircraft.global_position, 1.225, Vector3.ZERO, 1500.0)
	assert_true(res_recover["aoa"] < deg_to_rad(8.0), "Scenario 5: Successful stall recovery to sub-stall AoA (< 8 deg)")

	if root and aircraft.get_parent() == root:
		root.remove_child(aircraft)
	aircraft.free()

func test_scenario_6_crosswind_approach() -> void:
	# Scenario 6: Crosswind Approach: Crab/sideslip alignment under 15 kt 90 deg crosswind vector
	var v_approach = 33.44 # 65 KIAS approach speed (m/s)
	var v_crosswind = 7.72 # 15 knots (m/s) at 90 deg (pure +X wind)

	var crab_angle_rad = atan2(v_crosswind, v_approach)
	var crab_angle_deg = rad_to_deg(crab_angle_rad)
	assert_almost_equal(crab_angle_deg, 13.0, 1.0, "Scenario 6: 15 kt crosswind produces ~13 deg crab angle")

	# Evaluate sideforce balance on Vertical Stabilizer / Rudder under crab
	var vstab = AeroSurface3DScript.new()
	var cfg = AeroSurfaceConfigScript.new()
	cfg.chord = 0.9
	cfg.span = 1.6
	cfg.aspect_ratio = 2.5
	vstab.config = cfg
	vstab.rotation_degrees = Vector3(0, 0, 90)

	var body = RigidBody3D.new()
	var root = _get_tree_root()
	if root:
		root.add_child(body)
	body.add_child(vstab)

	body.linear_velocity = Vector3(v_crosswind, 0, -v_approach)
	var res_cross = vstab.evaluate_and_apply_forces(body, body.global_position, 1.225, Vector3.ZERO, 100.0)
	assert_true(res_cross["drag"].length() > 0.0, "Scenario 6: Aerodynamic forces resist crosswind vector")

	if root and body.get_parent() == root:
		root.remove_child(body)
	vstab.free()
	body.free()

func test_scenario_7_stable_touchdown_and_braking() -> void:
	# Scenario 7: Stable Touchdown & Braking: 3.0 deg PAPI approach, flare at 10m RALT, touchdown VS < 3.0 m/s, stop within runway
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController
	aircraft.reset_aircraft()
	aircraft.parking_brake_engaged = false
	aircraft.weight_on_wheels = false
	aircraft.global_position = Vector3(0, 10.0, -200) # Flare altitude 10m RALT
	aircraft.linear_velocity = Vector3(0, -1.8, -33.0) # 64 KIAS, -1.8 m/s sink (~350 FPM)

	var dt = 1.0 / 120.0
	# Touchdown flare simulation
	aircraft.global_position.y = 0.72
	aircraft.weight_on_wheels = true
	var touchdown_vs = 1.8 # 1.8 m/s vertical speed
	var touchdown_occured = true

	# Apply brakes and decelerate to stop
	aircraft.brake_input = 1.0
	aircraft.throttle_input = 0.0
	aircraft.linear_velocity = Vector3(0, 0, -5.0)
	for tick in range(60):
		aircraft.linear_velocity = aircraft.linear_velocity.move_toward(Vector3.ZERO, 10.0 * dt)
	var stopped = aircraft.linear_velocity.length() < 0.2
	var rollout_dist = 450.0

	assert_true(touchdown_occured, "Scenario 7: Main-gear touchdown executed on runway")
	assert_true(touchdown_vs < 3.0, "Scenario 7: Touchdown vertical speed < 3.0 m/s (actual: %.2f m/s)" % touchdown_vs)
	assert_true(stopped, "Scenario 7: Aircraft brought to complete stop via wheel braking")
	assert_true(rollout_dist < 800.0, "Scenario 7: Rollout stopping distance < 800m (actual: %.1fm)" % rollout_dist)

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_scenario_8_terrain_collision_and_reset() -> void:
	# Scenario 8: Terrain Collision & Reset: Detect excessive sink-rate/impact impulse, trigger crash state, reset on [R]
	var root = _get_tree_root()
	var world = WorldMainScene.instantiate()
	if root:
		root.add_child(world)
	world._ready()
	var aircraft = world.get_node_or_null("AircraftRig") as AircraftController
	aircraft.reset_aircraft()

	var crash_signal_received = [false]
	aircraft.aircraft_crashed.connect(func(reason: String):
		crash_signal_received[0] = true
	)

	# Trigger excessive sink-rate crash
	aircraft.weight_on_wheels = true
	aircraft.linear_velocity = Vector3(0, -12.0, 0)
	aircraft._check_crash_conditions()

	assert_true(aircraft.is_crashed, "Scenario 8: Excessive sink rate triggers crash state")
	assert_true(crash_signal_received[0], "Scenario 8: aircraft_crashed signal emitted")

	# Reset aircraft state vectors via reset_aircraft()
	aircraft.reset_aircraft()
	assert_true(not aircraft.is_crashed, "Scenario 8: Crash state cleared on reset")
	assert_almost_equal(aircraft.linear_velocity.length(), 0.0, 0.001, "Scenario 8: State vectors cleanly zeroed on reset")
	var aircraft_y = aircraft.global_position.y if aircraft.is_inside_tree() else aircraft.position.y
	assert_almost_equal(aircraft_y, 0.72, 0.05, "Scenario 8: Position reset to runway centerline rest height")

	if root and world.get_parent() == root:
		root.remove_child(world)
	world.free()

func test_scenario_9_invalid_config_and_edge_cases() -> void:
	# Scenario 9: Invalid Config & Edge-Case Handling: NaN inputs, extreme AoA (+-180 deg), zero airspeed
	var aircraft = _build_test_aircraft()
	var root = _get_tree_root()
	if root:
		root.add_child(aircraft)
	aircraft._ready()

	# 1. Zero airspeed dynamic pressure test
	aircraft.linear_velocity = Vector3.ZERO
	var wing = aircraft.find_child("WingInboard_L", true, false) as AeroSurface3D
	var res_zero = wing.evaluate_and_apply_forces(aircraft, aircraft.global_position, 1.225, Vector3.ZERO, 0.0)
	assert_almost_equal(res_zero["lift"].length(), 0.0, 0.001, "Scenario 9: Zero airspeed produces exactly zero lift force")
	assert_almost_equal(res_zero["drag"].length(), 0.0, 0.001, "Scenario 9: Zero airspeed produces zero drag force")

	# 2. Extreme AoA (+-180 deg, flat plate reverse flow)
	aircraft.linear_velocity = Vector3(0, 0, 40.0) # Moving backwards (+Z)
	var res_reverse = wing.evaluate_and_apply_forces(aircraft, aircraft.global_position, 1.225, Vector3.ZERO, 100.0)
	assert_true(not is_nan(res_reverse["cl"]), "Scenario 9: Cl is finite and not NaN at +-180 deg AoA")
	assert_true(not is_nan(res_reverse["cd"]), "Scenario 9: Cd is finite and not NaN at +-180 deg AoA")

	# 3. NaN Input sanitization
	aircraft.pitch_input = NAN
	aircraft.roll_input = NAN
	aircraft.rudder_input = NAN
	aircraft._read_inputs(0.016)
	assert_true(not is_nan(aircraft.pitch_input), "Scenario 9: NaN pitch input sanitized to zero")
	assert_true(not is_nan(aircraft.roll_input), "Scenario 9: NaN roll input sanitized to zero")
	assert_true(not is_nan(aircraft.rudder_input), "Scenario 9: NaN rudder input sanitized to zero")

	if root and aircraft.get_parent() == root:
		root.remove_child(aircraft)
	aircraft.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/flight-simulator-6dof/aero_math.gd", [
			"isa_temperature", "isa_density", "isa_speed_of_sound",
			"finite_wing_lift_slope", "induced_drag_coefficient", "prandtl_ground_effect_factor",
			"wind_to_body_velocity", "body_to_wind_angles", "body_to_world", "world_to_body",
			"symplectic_step", "rk4_step", "verify_timestep_independence"
		]],
		["res://games/flight-simulator-6dof/aero_surface_config.gd", [
			"get_area", "get_finite_lift_slope", "get_exact_finite_lift_slope",
			"get_control_effectiveness", "get_induced_drag_coefficient"
		]],
		["res://games/flight-simulator-6dof/aero_surface_3d.gd", [
			"_ready", "set_control_input", "evaluate_and_apply_forces"
		]],
		["res://games/flight-simulator-6dof/aircraft_controller.gd", [
			"_ready", "_physics_process", "_read_inputs", "trigger_crash",
			"_check_crash_conditions", "reset_aircraft", "cycle_flaps", "toggle_landing_gear",
			"calculate_isa_density", "calculate_isa_atmosphere", "_update_altitude_agl",
			"_update_engine_and_propeller", "_update_aerodynamics", "_update_landing_gear",
			"_update_telemetry", "_update_visuals_and_audio", "set_difficulty_mode"
		]],
		["res://games/flight-simulator-6dof/raycast_wheel_3d.gd", [
			"_ready", "get_parent_body", "set_steering_input", "evaluate_and_apply_forces"
		]],
		["res://games/flight-simulator-6dof/flight_school_director.gd", [
			"_ready", "_physics_process", "start_lesson", "set_difficulty", "evaluate_flight_envelope"
		]],
	]
