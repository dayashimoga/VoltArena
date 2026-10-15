class_name TestFlightPhysicsUnit
extends RefCounted

## TestFlightPhysicsUnit: Unit tests for 6-DOF aerodynamics, lift, drag, stalls,
## ground effect, gear suspension, progressive braking, and rotorcraft flight.

const FlightConst = preload("res://games/aircraft-flight/core/flight_constants.gd")
const FlightPhysicsScript = preload("res://games/aircraft-flight/core/flight_physics.gd")
const AircraftCatalog = preload("res://games/aircraft-flight/aircraft/aircraft_catalog.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_aircraft_specs_setup()
	test_atmospheric_density_lapse()
	test_lift_curve_and_stall_polar()
	test_drag_polar_and_induced_drag()
	test_ground_effect_cushion()
	test_engine_thrust_and_afterburner()
	test_landing_gear_and_wheel_brakes()
	test_control_surfaces_deflections()
	test_helicopter_rotorcraft_physics()
	test_flight_modes_and_recovery()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_aircraft_specs_setup() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)

	_assert_true(plane.aircraft_name == "F/A-18C Hornet", "Aircraft name correctly configured")
	_assert_true(plane.mass_kg == 11200.0, "Aircraft mass correctly configured")
	_assert_true(plane.wingspan == 12.3, "Wingspan configured")
	_assert_true(plane.wing_area == 38.0, "Wing area configured")
	_assert_true(plane.has_afterburner == true, "Afterburner capability configured")
	plane.free()

func test_atmospheric_density_lapse() -> void:
	var plane = FlightPhysicsScript.new()
	var rho_sea = plane._compute_air_density(0.0)
	var rho_5000 = plane._compute_air_density(5000.0)
	var rho_10000 = plane._compute_air_density(10000.0)

	_assert_true(absf(rho_sea - FlightConst.AIR_DENSITY_SEA_LEVEL) < 0.05, "Sea level air density matches 1.225 kg/m^3")
	_assert_true(rho_5000 < rho_sea, "Air density decreases at 5,000m altitude")
	_assert_true(rho_10000 < rho_5000, "Air density further decreases at 10,000m")
	plane.free()

func test_lift_curve_and_stall_polar() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)
	plane.gear_position = 0.0

	# Linear Lift Range (AoA = 5 deg)
	plane.angle_of_attack_deg = 5.0
	plane.velocity = Vector3(0.0, 0.0, -100.0)
	var force_normal = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)
	_assert_true(force_normal.y > 0.0, "Normal lift produced in linear AoA range")
	_assert_true(not plane.is_stalling, "Aircraft not stalling at 5 deg AoA")

	# Stall Trigger (AoA = 22 deg > 16 deg critical)
	plane.angle_of_attack_deg = 22.0
	var force_stall = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)
	_assert_true(plane.is_stalling, "Stall triggered when AoA exceeds critical 16 deg")
	_assert_true(plane.stall_severity > 0.0, "Stall severity calculated")
	plane.free()

func test_drag_polar_and_induced_drag() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)

	# Clean Configuration Drag
	plane.angle_of_attack_deg = 2.0
	plane.gear_position = 0.0
	plane.flaps_step = 0
	plane.airbrake_deployed = false
	var forces_clean = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)

	# Dirty Configuration Drag (Gear Down + Flaps Landing + Airbrake)
	plane.gear_position = 1.0
	plane.flaps_step = 2
	plane.airbrake_deployed = true
	var forces_dirty = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)

	_assert_true(absf(forces_dirty.z) > absf(forces_clean.z), "Drag increases significantly with gear, flaps, and airbrakes deployed")
	plane.free()

func test_ground_effect_cushion() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)
	plane.angle_of_attack_deg = 4.0

	# High altitude (Out of ground effect)
	plane.radar_altitude_m = 500.0
	var force_high = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)

	# Near ground (< 1 wingspan = 12.3m)
	plane.radar_altitude_m = 3.0
	var force_ground = plane._compute_fixed_wing_forces(0.016, 1.225, 6125.0)

	_assert_true(force_ground.y > force_high.y, "Ground effect cushion increases lift near runway surface")
	plane.free()

func test_engine_thrust_and_afterburner() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)

	# Military dry thrust (100% throttle, no afterburner)
	plane.throttle = 1.0
	plane.afterburner_active = false
	plane.engine_rpm_pct = 100.0
	var f_dry = plane._compute_fixed_wing_forces(0.016, 1.225, 100.0)

	# Afterburner reheat
	plane.afterburner_active = true
	var f_ab = plane._compute_fixed_wing_forces(0.016, 1.225, 100.0)

	_assert_true(f_ab.z < f_dry.z, "Afterburner produces higher forward thrust (-Z vector)")
	plane.free()

func test_landing_gear_and_wheel_brakes() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)

	# On runway surface
	plane.radar_altitude_m = 1.2
	plane.gear_position = 1.0

	# Free rolling
	plane.wheel_brakes_active = false
	var f_roll = plane._compute_ground_reaction_forces(0.016, 30.0, 0.0)

	# Hard wheel brakes
	plane.wheel_brakes_active = true
	var f_brake = plane._compute_ground_reaction_forces(0.016, 30.0, 0.0)

	_assert_true(absf(f_brake.z) > absf(f_roll.z), "Wheel brakes generate strong deceleration force")
	plane.free()

func test_control_surfaces_deflections() -> void:
	var plane = FlightPhysicsScript.new()
	plane.set_pilot_inputs(0.8, -0.6, 0.4)
	_assert_true(plane.input_pitch == 0.8, "Pitch input registered")
	_assert_true(plane.input_roll == -0.6, "Roll input registered")
	_assert_true(plane.input_yaw == 0.4, "Yaw input registered")

	plane.toggle_landing_gear()
	_assert_true(plane.gear_deployed == false, "Gear toggle successfully retracts landing gear")

	plane.cycle_flaps()
	_assert_true(plane.flaps_step == 1, "Flap cycle advances to takeoff position (15 deg)")
	plane.cycle_flaps()
	_assert_true(plane.flaps_step == 2, "Flap cycle advances to landing position (35 deg)")
	plane.cycle_flaps()
	_assert_true(plane.flaps_step == 0, "Flap cycle retracts to clean position")
	plane.free()

func test_helicopter_rotorcraft_physics() -> void:
	var heli = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("uh60_helicopter")
	heli.setup_aircraft_specs(spec)

	_assert_true(heli.is_rotorcraft == true, "Helicopter identified as rotorcraft")
	_assert_true(heli.stall_speed_ms == 0.0, "Helicopter has zero stall speed (can hover)")

	# Collective pitch hover test
	heli.set_throttle(0.65) # 65% collective
	heli.rotor_rpm_pct = 100.0
	heli.radar_altitude_m = 15.0
	var f_hover = heli._compute_rotorcraft_forces(0.016, 1.225)

	_assert_true(f_hover.y > 0.0, "Main rotor produces upward thrust to overcome gravity")
	heli.free()

func test_flight_modes_and_recovery() -> void:
	var plane = FlightPhysicsScript.new()
	plane.recover_to_safe_flight(Vector3(100.0, 500.0, -200.0), 90.0, 450.0, true)

	var pos = plane.global_position if plane.is_inside_tree() else plane.position
	_assert_true(pos == Vector3(100.0, 500.0, -200.0), "Spawn position correctly set")
	_assert_true(plane.is_airborne == true, "Airborne recovery state flag active")
	_assert_true(plane.gear_deployed == false, "Gear retracted for airborne spawn")
	_assert_true(plane.velocity.length() > 100.0, "Initial airspeed applied on airborne spawn")
	plane.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/core/flight_physics.gd",
			[
				"setup_aircraft_specs", "_physics_process", "_compute_air_density",
				"_update_radar_altitude", "_compute_fixed_wing_forces", "_compute_rotorcraft_forces",
				"_compute_ground_reaction_forces", "_integrate_aerodynamic_moments",
				"_update_control_surfaces_and_gear", "set_pilot_inputs", "set_throttle",
				"adjust_throttle", "set_afterburner", "toggle_landing_gear", "cycle_flaps",
				"set_airbrake", "set_wheel_brakes", "recover_to_safe_flight"
			]
		]
	]
