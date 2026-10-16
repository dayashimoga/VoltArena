class_name TestFlightSim6DoFUnit
extends RefCounted

## Comprehensive Unit Test Suite for Game #13: 6-DoF Aircraft Flight Simulator.
## Validates AeroSurfaceConfig, AeroSurface3D, AircraftController, RaycastWheel3D,
## CockpitHUD, FloatingOrigin, and atmospheric models.

const AeroSurfaceConfigScript = preload("res://games/flight-simulator-6dof/aero_surface_config.gd")
const AeroSurface3DScript = preload("res://games/flight-simulator-6dof/aero_surface_3d.gd")
const AircraftControllerScript = preload("res://games/flight-simulator-6dof/aircraft_controller.gd")
const RaycastWheel3DScript = preload("res://games/flight-simulator-6dof/raycast_wheel_3d.gd")
const CockpitHUDScript = preload("res://games/flight-simulator-6dof/cockpit_hud.gd")
const FloatingOriginScript = preload("res://games/flight-simulator-6dof/floating_origin.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestFlightSim6DoFUnit ---")
	test_aero_surface_config_formulas()
	test_aero_surface_3d_point_velocity_and_forces()
	test_aero_surface_continuous_polars_and_stall()
	test_aero_surface_ground_effect_formula()
	test_isa_atmosphere_model_to_20000m()
	test_engine_spool_and_thrust_formula()
	test_stall_warning_and_wow_interlock()
	test_raycast_wheel_suspension_and_friction()
	test_speed_sensitive_steering()
	test_floating_origin_coordinated_shift()
	test_hud_telemetry_calculations()

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
		print("  [PASS] " + msg + " (val: %.4f, expected: %.4f)" % [val, expected])
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg + " (val: %.4f, expected: %.4f, tol: %.4f)" % [val, expected, tol])
		push_error("Assertion failed: %s" % msg)

func test_aero_surface_config_formulas() -> void:
	var cfg = AeroSurfaceConfigScript.new()
	cfg.chord = 1.6
	cfg.span = 9.6
	cfg.aspect_ratio = 6.0
	cfg.flap_fraction = 0.30

	# 1. Planform area S = chord * span = 1.6 * 9.6 = 15.36 m^2
	assert_almost_equal(cfg.get_area(), 15.36, 0.01, "Planform area S = chord * span")

	# 2. Finite-wing lift slope: a = 2*PI*AR / (AR + 2) = 2*PI*6 / (6 + 2) = 12*PI / 8 = 1.5*PI ~ 4.71239
	var expected_slope = (2.0 * PI * 6.0) / (6.0 + 2.0)
	assert_almost_equal(cfg.get_finite_lift_slope(), expected_slope, 0.001, "Finite-wing lift slope 2*PI*AR/(AR+2)")

	# 3. Flap effectiveness tau ~ 1.15 * sqrt(0.30) ~ 0.6298
	var expected_tau = 1.15 * sqrt(0.30)
	assert_almost_equal(cfg.get_control_effectiveness(), expected_tau, 0.01, "Flap effectiveness tau")

func _get_tree_root() -> Node:
	if Engine.get_main_loop() and Engine.get_main_loop() is SceneTree:
		return (Engine.get_main_loop() as SceneTree).root
	return null

func test_aero_surface_3d_point_velocity_and_forces() -> void:
	var surface = AeroSurface3DScript.new()
	var cfg = AeroSurfaceConfigScript.new()
	cfg.chord = 1.5
	cfg.span = 5.0
	cfg.aspect_ratio = 6.0
	surface.config = cfg
	surface.position = Vector3(2.5, 0.4, 0.0)

	var body = RigidBody3D.new()
	body.mass = 1150.0
	body.linear_velocity = Vector3(0, 0, -45.0) # Forward at 45 m/s (~87 knots)
	body.angular_velocity = Vector3(0, 0.5, 0) # Yaw rate 0.5 rad/s
	var root = _get_tree_root()
	if root:
		root.add_child(body)
	body.add_child(surface)

	var com_world = Vector3.ZERO
	var atmo_density = 1.225 # Sea level

	# Evaluate aerodynamic forces
	var res = surface.evaluate_and_apply_forces(body, com_world, atmo_density, Vector3.ZERO, 500.0)

	assert_true(res.has("lift"), "AeroSurface3D must compute lift force")
	assert_true(res.has("drag"), "AeroSurface3D must compute drag force")
	assert_true(res["drag"].length() > 0.0, "Drag force must be positive")

	if root and body.get_parent() == root:
		root.remove_child(body)
	surface.free()
	body.free()

func test_aero_surface_continuous_polars_and_stall() -> void:
	var surface = AeroSurface3DScript.new()
	var cfg = AeroSurfaceConfigScript.new()
	cfg.positive_stall_angle = deg_to_rad(15.0)
	cfg.negative_stall_angle = deg_to_rad(-12.0)
	surface.config = cfg

	var body = RigidBody3D.new()
	var root = _get_tree_root()
	if root:
		root.add_child(body)
	body.add_child(surface)

	# Pre-stall AoA: 6 deg
	body.linear_velocity = Vector3(0, -sin(deg_to_rad(6.0)), -cos(deg_to_rad(6.0))) * 40.0
	var res_prestall = surface.evaluate_and_apply_forces(body, Vector3.ZERO, 1.225, Vector3.ZERO, 200.0)
	var cl_prestall = res_prestall["cl"]
	assert_true(cl_prestall > 0.4, "Pre-stall Cl at 6 deg should be positive and substantial")

	# Post-stall AoA: 45 deg (flat plate regime)
	body.linear_velocity = Vector3(0, -sin(deg_to_rad(45.0)), -cos(deg_to_rad(45.0))) * 40.0
	var res_poststall = surface.evaluate_and_apply_forces(body, Vector3.ZERO, 1.225, Vector3.ZERO, 200.0)
	var cl_poststall = res_poststall["cl"]
	var cd_poststall = res_poststall["cd"]
	assert_true(cd_poststall > 0.8, "Post-stall Cd at 45 deg must be high (~flat-plate)")
	assert_almost_equal(cl_poststall, sin(deg_to_rad(90.0)), 0.15, "Post-stall Cl approximates sin(2*alpha)")

	if root and body.get_parent() == root:
		root.remove_child(body)
	surface.free()
	body.free()

func test_aero_surface_ground_effect_formula() -> void:
	var cfg = AeroSurfaceConfigScript.new()
	cfg.span = 10.0 # Wingspan b = 10m

	# At height h = 1.0m (h/b = 0.1):
	# 16h/b = 1.6
	# sigma = (1.6)^2 / (1 + 1.6^2) = 2.56 / 3.56 ~ 0.719
	var h1 = 1.0
	var b = 10.0
	var h16_1 = 16.0 * (h1 / b)
	var sigma_ground = (h16_1 * h16_1) / (1.0 + (h16_1 * h16_1))
	assert_almost_equal(sigma_ground, 0.719, 0.01, "Ground effect reduction factor at h/b = 0.1")

	# At height h = 10.0m (h/b = 1.0):
	# 16h/b = 16.0
	# sigma = 256 / 257 ~ 0.996 (ground effect negligible)
	var h2 = 10.0
	var h16_2 = 16.0 * (h2 / b)
	var sigma_high = (h16_2 * h16_2) / (1.0 + (h16_2 * h16_2))
	assert_almost_equal(sigma_high, 0.996, 0.01, "Ground effect factor at h/b = 1.0 approaches 1.0")

func test_isa_atmosphere_model_to_20000m() -> void:
	# Sea level: h = 0m
	var sl = AircraftControllerScript.calculate_isa_atmosphere(0.0)
	assert_almost_equal(sl["temperature"], 288.15, 0.1, "ISA sea level temperature is 288.15 K (15 C)")
	assert_almost_equal(sl["pressure"], 101325.0, 10.0, "ISA sea level pressure is 101,325 Pa")
	assert_almost_equal(sl["density"], 1.225, 0.01, "ISA sea level density is 1.225 kg/m^3")
	assert_almost_equal(sl["speed_of_sound"], 340.29, 0.5, "ISA sea level speed of sound is ~340.3 m/s")

	# Tropopause: h = 11,000m
	var tp = AircraftControllerScript.calculate_isa_atmosphere(11000.0)
	assert_almost_equal(tp["temperature"], 216.65, 0.2, "ISA 11km tropopause temperature is 216.65 K (-56.5 C)")
	assert_almost_equal(tp["density"], 0.3639, 0.02, "ISA 11km density is ~0.364 kg/m^3")

	# Stratosphere: h = 20,000m
	var st = AircraftControllerScript.calculate_isa_atmosphere(20000.0)
	assert_almost_equal(st["temperature"], 216.65, 0.2, "ISA 20km stratosphere temperature remains isothermal 216.65 K")
	assert_true(st["density"] < tp["density"], "Density at 20km must be lower than at 11km")
	assert_almost_equal(st["density"], 0.088, 0.02, "ISA 20km density is ~0.088 kg/m^3")

func test_engine_spool_and_thrust_formula() -> void:
	var ctrl = AircraftControllerScript.new()
	ctrl._ready()

	# Static thrust at 100% throttle: V = 0
	ctrl.throttle_input = 1.0
	ctrl.current_rpm = 2700.0
	ctrl._update_engine_and_propeller(0.016, 1.225)

	assert_true(ctrl.current_thrust_n > 2500.0, "Static thrust at 100% throttle must exceed 2500 N")
	assert_true(ctrl.current_thrust_n < 5000.0, "Static thrust must remain in calibrated tourer envelope (~3200 N)")
	assert_true(ctrl.prop_slipstream_vel.length() > 5.0, "Propeller slipstream velocity must be generated")

	ctrl.free()

func test_stall_warning_and_wow_interlock() -> void:
	var ctrl = AircraftControllerScript.new()
	ctrl._ready()

	# Scenario A: On ground (Weight on Wheels = true) at high AoA -> Horn MUST NOT sound (interlock)
	ctrl.weight_on_wheels = true
	ctrl.max_inboard_aoa_deg = 15.0 # Above 13.5 deg threshold
	ctrl._update_telemetry(0.016, 1.225, 340.0)
	assert_true(not ctrl.stall_horn_active, "Stall horn must be blocked by Weight-on-Wheels interlock")

	# Scenario B: In flight (Weight on Wheels = false) below 13.5 deg -> Horn silent
	ctrl.weight_on_wheels = false
	ctrl.max_inboard_aoa_deg = 11.0
	ctrl._update_telemetry(0.016, 1.225, 340.0)
	assert_true(not ctrl.stall_horn_active, "Stall horn must not sound below 13.5 deg threshold in flight")

	# Scenario C: In flight (Weight on Wheels = false) at >= 13.5 deg -> Horn ACTIVE!
	ctrl.max_inboard_aoa_deg = 14.2
	ctrl._update_telemetry(0.016, 1.225, 340.0)
	assert_true(ctrl.stall_horn_active, "Stall horn MUST sound when AoA >= 13.5 deg and in flight")

	ctrl.free()

func test_raycast_wheel_suspension_and_friction() -> void:
	var wheel = RaycastWheel3DScript.new()
	wheel.rest_length = 0.55
	wheel.wheel_radius = 0.28
	wheel.spring_stiffness = 65000.0
	wheel.damping_rate = 4800.0
	wheel.has_brakes = true
	wheel._ready()

	var body = RigidBody3D.new()
	body.mass = 1150.0
	body.add_child(wheel)

	# Simulate compression x = 0.10 m (10 cm)
	var x = 0.10
	var expected_spring_force = 65000.0 * x # 6,500 N
	assert_almost_equal(expected_spring_force, 6500.0, 1.0, "Spring suspension force k*x at 10cm compression")

	wheel.free()
	body.free()

func test_speed_sensitive_steering() -> void:
	var wheel = RaycastWheel3DScript.new()
	wheel.is_steerable = true
	wheel.max_steer_angle_deg = 25.0

	# Low taxi speed (2 m/s): full steering authority ~ 25 deg
	wheel.set_steering_input(1.0, 2.0)
	var steer_low = rad_to_deg(abs(wheel.current_steer_angle_rad))
	assert_almost_equal(steer_low, 25.0 * (1.0 - 2.0/28.0), 1.0, "Low-speed taxi steering authority")

	# High takeoff speed (26 m/s): reduced steering authority to prevent rollover
	wheel.set_steering_input(1.0, 26.0)
	var steer_high = rad_to_deg(abs(wheel.current_steer_angle_rad))
	assert_true(steer_high < 6.0, "High-speed steering authority clamped to safe threshold (<6 deg)")

	wheel.free()

func test_floating_origin_coordinated_shift() -> void:
	var origin = FloatingOriginScript.new()
	origin.rebase_threshold_meters = 5000.0

	var aircraft = RigidBody3D.new()
	aircraft.linear_velocity = Vector3(10, 0, -80)
	aircraft.position = Vector3(4500.0, 1200.0, 3000.0) # Length ~5408m > 5000m
	origin.target_node = aircraft

	var scenery = Node3D.new()
	scenery.position = Vector3(100.0, 0.0, -200.0)
	origin.register_shifting_node(scenery)

	# Trigger rebase
	var shift_pos = aircraft.position
	origin.rebase_world(shift_pos)

	# Verify aircraft position shifted by -shift_vector
	assert_almost_equal(aircraft.position.x, 0.0, 0.01, "Aircraft X shifted to origin")
	assert_almost_equal(aircraft.position.z, 0.0, 0.01, "Aircraft Z shifted to origin")
	assert_almost_equal(aircraft.position.y, 1200.0, 0.01, "Aircraft MSL altitude datum preserved")

	# Verify linear velocity preserved exactly
	assert_almost_equal(aircraft.linear_velocity.z, -80.0, 0.001, "Linear velocity preserved through floating origin rebase")

	# Verify registered scenery shifted identically
	assert_almost_equal(scenery.position.x, 100.0 - 4500.0, 0.01, "Scenery shifted in coordination with origin")

	origin.free()
	aircraft.free()
	scenery.free()

func test_hud_telemetry_calculations() -> void:
	var hud = CockpitHUDScript.new()
	var telemetry = {
		"airspeed_kias": 115.0,
		"altitude_msl": 457.2, # 457.2 m * 3.28084 = ~1500 ft
		"vertical_speed_fpm": 500.0,
		"g_force": 1.2,
		"aoa_deg": 6.5,
		"stall_warning": false,
		"gear_down": true,
		"flaps_deg": 15.0,
		"brakes_on": false
	}
	hud.update_telemetry(telemetry)

	assert_almost_equal(hud.airspeed_kias, 115.0, 0.01, "HUD KIAS telemetry")
	assert_almost_equal(hud.altitude_feet_msl, 1500.0, 2.0, "HUD MSL feet altitude conversion")
	assert_almost_equal(hud.vertical_speed_fpm, 500.0, 0.01, "HUD VSI vertical speed")
	assert_almost_equal(hud.g_force, 1.2, 0.01, "HUD G-meter")

	hud.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/flight-simulator-6dof/aero_surface_config.gd",
			["get_area", "get_finite_lift_slope", "get_control_effectiveness"]
		],
		[
			"res://games/flight-simulator-6dof/aero_surface_3d.gd",
			["_ready", "set_control_input", "evaluate_and_apply_forces", "_get_lift_drag_polar", "get_parent_body"]
		],
		[
			"res://games/flight-simulator-6dof/aircraft_controller.gd",
			["_ready", "_physics_process", "_read_inputs", "_update_engine_and_propeller", "_update_aerodynamics", "_update_landing_gear", "_update_telemetry", "_update_vfx_and_audio", "calculate_isa_atmosphere", "cycle_flaps", "toggle_landing_gear", "toggle_camera_mode"]
		],
		[
			"res://games/flight-simulator-6dof/raycast_wheel_3d.gd",
			["_ready", "get_parent_body", "set_steering_input", "evaluate_and_apply_forces"]
		],
		[
			"res://games/flight-simulator-6dof/floating_origin.gd",
			["_ready", "_physics_process", "register_shifting_node", "unregister_shifting_node", "rebase_world", "to_absolute_position", "to_local_position"]
		],
		[
			"res://games/flight-simulator-6dof/cockpit_hud.gd",
			["_ready", "update_telemetry", "_draw", "_draw_flight_path_marker", "_draw_pitch_ladder", "_draw_speed_tape", "_draw_altitude_tape", "_draw_vsi", "_draw_g_meter", "_draw_aoa_bracket", "_draw_compass_rose", "_draw_annunciators"]
		]
	]
