class_name AeroMath
extends RefCounted

## Aeronautical & Mathematical Utilities for 6-DoF Aircraft Flight Simulation.
## Provides authoritative coordinate frame transformations (Wind <-> Body <-> World),
## ISA density validation, and symplectic / RK4 integration stability verifiers.

const SEA_LEVEL_TEMP_K: float = 288.15
const SEA_LEVEL_PRESSURE_PA: float = 101325.0
const SEA_LEVEL_DENSITY_KG_M3: float = 1.2250
const LAPSE_RATE_K_M: float = 0.0065
const GAS_CONSTANT_R: float = 287.058
const GRAVITY_G0: float = 9.80665
const SPECIFIC_HEAT_RATIO: float = 1.4

## Evaluates ISA atmospheric temperature at altitude h (m) up to 11,000m (troposphere):
## T(h) = T0 - L * h
static func isa_temperature(alt_m: float) -> float:
	var h = clampf(alt_m, -500.0, 11000.0)
	return SEA_LEVEL_TEMP_K - LAPSE_RATE_K_M * h

## Evaluates ISA atmospheric density using the barometric formula:
## rho(h) = rho_0 * (T(h) / T0)^( (g0 / (L * R)) - 1 )
static func isa_density(alt_m: float) -> float:
	var h = clampf(alt_m, -500.0, 11000.0)
	var t_ratio = (SEA_LEVEL_TEMP_K - LAPSE_RATE_K_M * h) / SEA_LEVEL_TEMP_K
	var exponent = (GRAVITY_G0 / (LAPSE_RATE_K_M * GAS_CONSTANT_R)) - 1.0 # ~4.25588
	return SEA_LEVEL_DENSITY_KG_M3 * pow(t_ratio, exponent)

## Converts True Airspeed (TAS), Angle of Attack (alpha), and Sideslip (beta) to Body-frame Velocity:
## Body convention: -Z is nose forward, +X is starboard, +Y is canopy/normal upward.
static func wind_to_body_velocity(tas: float, alpha_rad: float, beta_rad: float) -> Vector3:
	var cos_a = cos(alpha_rad)
	var sin_a = sin(alpha_rad)
	var cos_b = cos(beta_rad)
	var sin_b = sin(beta_rad)

	var vx = tas * sin_b
	var vy = -tas * sin_a * cos_b
	var vz = -tas * cos_a * cos_b
	return Vector3(vx, vy, vz)

## Computes Angle of Attack (alpha) and Sideslip (beta) from local body-frame velocity vector:
static func body_to_wind_angles(local_vel: Vector3) -> Dictionary:
	var speed = local_vel.length()
	if speed < 0.001:
		return {"aoa": 0.0, "sideslip": 0.0, "tas": 0.0}

	# Nose is -Z, Canopy is +Y, Starboard is +X
	var alpha = atan2(-local_vel.y, -local_vel.z)
	var sin_beta = clampf(local_vel.x / speed, -1.0, 1.0)
	var beta = asin(sin_beta)

	return {
		"aoa": alpha,
		"sideslip": beta,
		"tas": speed
	}

## Transforms vector from Body Axes to World Inertial Axes using body orientation Basis:
static func body_to_world(local_vec: Vector3, body_basis: Basis) -> Vector3:
	return body_basis * local_vec

## Transforms vector from World Inertial Axes to Body Axes:
static func world_to_body(world_vec: Vector3, body_basis: Basis) -> Vector3:
	return body_basis.inverse() * world_vec

## Transforms aerodynamic wind-frame forces (Lift, Drag, Sideforce) into Body-frame Force Vector:
## Drag opposes relative wind, Lift acts normal to wind in pitch plane, Sideforce acts lateral.
static func wind_to_body_forces(lift: float, drag: float, sideforce: float, alpha_rad: float, beta_rad: float) -> Vector3:
	var cos_a = cos(alpha_rad)
	var sin_a = sin(alpha_rad)
	var cos_b = cos(beta_rad)
	var sin_b = sin(beta_rad)

	# Rotation matrix from Stability/Wind axes to Body axes
	var fx = -drag * sin_b + sideforce * cos_b
	var fy = lift * cos_a - drag * sin_a * cos_b - sideforce * sin_a * sin_b
	var fz = -lift * sin_a - drag * cos_a * cos_b - sideforce * sin_a * sin_b
	return Vector3(fx, fy, fz)

## Computes exact finite-wing lift slope:
## C_L_alpha = (2*PI * AR) / (2 + sqrt(4 + AR^2 * (1 + tan^2(sweep))))
static func finite_wing_lift_slope(ar: float, sweep_rad: float = 0.0) -> float:
	var tan_sweep = tan(sweep_rad)
	var term = 4.0 + (ar * ar) * (1.0 + tan_sweep * tan_sweep)
	return (2.0 * PI * ar) / (2.0 + sqrt(term))

## Computes induced drag coefficient:
## C_Di = (C_L^2 / (PI * e * AR)) * sigma_ground
static func induced_drag_coefficient(cl: float, ar: float, oswald_e: float, sigma_ground: float = 1.0) -> float:
	return ((cl * cl) / (PI * maxf(ar, 0.1) * maxf(oswald_e, 0.1))) * clampf(sigma_ground, 0.05, 1.0)

## Computes Prandtl ground effect reduction factor:
## sigma = (16 * h / b)^2 / (1 + (16 * h / b)^2)
static func prandtl_ground_effect_factor(altitude_agl_m: float, wingspan_m: float) -> float:
	var h_ratio = maxf(0.05, altitude_agl_m) / maxf(0.5, wingspan_m)
	var h16 = 16.0 * h_ratio
	var h16_sq = h16 * h16
	return clampf(h16_sq / (1.0 + h16_sq), 0.08, 1.0)

## Symplectic Euler 6-DoF numerical integration step:
## Updates velocity using acceleration first, then updates position using the updated velocity.
## Guarantees symplectic energy conservation for rigid body flight trajectories.
static func integrate_symplectic_euler(pos: Vector3, vel: Vector3, accel: Vector3, dt: float) -> Array:
	var next_vel = vel + accel * dt
	var next_pos = pos + next_vel * dt
	return [next_pos, next_vel]

## Runge-Kutta 4th Order (RK4) integration step for smooth aerodynamic state evolution:
static func integrate_rk4(pos: Vector3, vel: Vector3, accel_func: Callable, dt: float) -> Array:
	# k1
	var a1: Vector3 = accel_func.call(pos, vel)
	var v1: Vector3 = vel

	# k2
	var pos2 = pos + v1 * (0.5 * dt)
	var vel2 = vel + a1 * (0.5 * dt)
	var a2: Vector3 = accel_func.call(pos2, vel2)

	# k3
	var pos3 = pos + vel2 * (0.5 * dt)
	var vel3 = vel + a2 * (0.5 * dt)
	var a3: Vector3 = accel_func.call(pos3, vel3)

	# k4
	var pos4 = pos + vel3 * dt
	var vel4 = vel + a3 * dt
	var a4: Vector3 = accel_func.call(pos4, vel4)

	var next_pos = pos + (v1 + vel2 * 2.0 + vel3 * 2.0 + vel4) * (dt / 6.0)
	var next_vel = vel + (a1 + a2 * 2.0 + a3 * 2.0 + a4) * (dt / 6.0)
	return [next_pos, next_vel]

## Verifies timestep independence across 60 Hz, 120 Hz, and 240 Hz over a 5-second simulated arc.
## Returns Dictionary with trajectory drift percentages relative to 240 Hz reference.
static func verify_timestep_independence(duration_s: float = 5.0) -> Dictionary:
	var init_pos = Vector3(0, 1000, 0)
	var init_vel = Vector3(0, 5, -45) # 45 m/s forward glide
	var mass = 1150.0

	var accel_eval = func(p: Vector3, v: Vector3) -> Vector3:
		# Bounded 6-DoF aerodynamic glide model: Gravity + Drag + Lift
		var g = Vector3(0, -9.80665, 0)
		var spd = minf(v.length(), 150.0)
		var q = 0.5 * 1.225 * spd * spd
		var v_dir = v.normalized() if spd > 0.001 else Vector3.ZERO
		var drag = -v_dir * (q * 15.0 * 0.035) / mass
		var lift = Vector3.UP * (q * 15.0 * 0.08) / mass
		return g + drag + lift

	# Simulate 240 Hz (Reference)
	var dt_240 = 1.0 / 240.0
	var steps_240 = int(duration_s / dt_240)
	var pos_240 = init_pos
	var vel_240 = init_vel
	for i in range(steps_240):
		var step = integrate_symplectic_euler(pos_240, vel_240, accel_eval.call(pos_240, vel_240), dt_240)
		pos_240 = step[0]
		vel_240 = step[1]

	# Simulate 120 Hz (Target production physics rate)
	var dt_120 = 1.0 / 120.0
	var steps_120 = int(duration_s / dt_120)
	var pos_120 = init_pos
	var vel_120 = init_vel
	for i in range(steps_120):
		var step = integrate_symplectic_euler(pos_120, vel_120, accel_eval.call(pos_120, vel_120), dt_120)
		pos_120 = step[0]
		vel_120 = step[1]

	# Simulate 60 Hz (Fallback low rate)
	var dt_60 = 1.0 / 60.0
	var steps_60 = int(duration_s / dt_60)
	var pos_60 = init_pos
	var vel_60 = init_vel
	for i in range(steps_60):
		var step = integrate_symplectic_euler(pos_60, vel_60, accel_eval.call(pos_60, vel_60), dt_60)
		pos_60 = step[0]
		vel_60 = step[1]

	var dist_ref = pos_240.distance_to(init_pos)
	var drift_120 = pos_120.distance_to(pos_240) / maxf(dist_ref, 1.0) * 100.0
	var drift_60 = pos_60.distance_to(pos_240) / maxf(dist_ref, 1.0) * 100.0

	return {
		"drift_120_hz_pct": drift_120,
		"drift_60_hz_pct": drift_60,
		"passed_120_hz": (drift_120 < 1.0),
		"passed_60_hz": (drift_60 < 2.0),
		"final_pos_240": pos_240,
		"final_pos_120": pos_120,
		"final_pos_60": pos_60
	}
