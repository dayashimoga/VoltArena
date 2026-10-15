class_name FlightAutopilot
extends RefCounted

## FlightAutopilot: Functional Aviation Autopilot & Flight Director System.
## Provides PID-stabilized Heading Hold, Altitude Hold, Airspeed Hold,
## and 3D Waypoint Navigation.

var enabled: bool = false
var heading_hold_enabled: bool = false
var altitude_hold_enabled: bool = false
var airspeed_hold_enabled: bool = false
var waypoint_nav_enabled: bool = false

var target_heading_deg: float = 0.0
var target_altitude_m: float = 1000.0
var target_airspeed_kmh: float = 450.0
var target_waypoint: Vector3 = Vector3.ZERO
var waypoint_arrival_radius: float = 120.0

# PID internal state
var _pitch_integral: float = 0.0
var _roll_integral: float = 0.0
var _yaw_integral: float = 0.0

signal waypoint_reached(pos: Vector3)

func set_target_waypoint(wp: Vector3) -> void:
	target_waypoint = wp
	waypoint_nav_enabled = true
	target_altitude_m = wp.y

func update_autopilot(aircraft: CharacterBody3D, delta: float) -> Dictionary:
	if not enabled or not is_instance_valid(aircraft) or delta <= 0.0:
		return {"pitch": 0.0, "roll": 0.0, "yaw": 0.0, "throttle": aircraft.throttle if is_instance_valid(aircraft) else 0.0}

	var cur_pos = aircraft.global_position
	var cur_fwd = -aircraft.global_transform.basis.z.normalized()
	var cur_heading_deg = rad_to_deg(atan2(cur_fwd.x, -cur_fwd.z))
	if cur_heading_deg < 0.0:
		cur_heading_deg += 360.0

	var cmd_pitch: float = 0.0
	var cmd_roll: float = 0.0
	var cmd_yaw: float = 0.0
	var cmd_throttle: float = aircraft.throttle

	# 1. Waypoint Navigation
	if waypoint_nav_enabled:
		var dist_to_wp = cur_pos.distance_to(target_waypoint)
		if dist_to_wp <= waypoint_arrival_radius:
			waypoint_reached.emit(target_waypoint)
			waypoint_nav_enabled = false
		else:
			var to_wp = (target_waypoint - cur_pos).normalized()
			var desired_heading = rad_to_deg(atan2(to_wp.x, -to_wp.z))
			if desired_heading < 0.0:
				desired_heading += 360.0
			target_heading_deg = desired_heading
			target_altitude_m = target_waypoint.y
			heading_hold_enabled = true
			altitude_hold_enabled = true

	# 2. Heading Hold (Bank turn toward target heading)
	if heading_hold_enabled:
		var heading_diff = target_heading_deg - cur_heading_deg
		while heading_diff > 180.0: heading_diff -= 360.0
		while heading_diff < -180.0: heading_diff += 360.0

		var target_bank_deg = clampf(heading_diff * 1.5, -45.0, 45.0)
		var cur_bank_deg = rad_to_deg(aircraft.global_transform.basis.get_euler().z)
		var bank_err = target_bank_deg - cur_bank_deg
		cmd_roll = clampf(bank_err * 0.045, -1.0, 1.0)
		cmd_yaw = clampf(cmd_roll * 0.35, -0.5, 0.5)

	# 3. Altitude Hold
	if altitude_hold_enabled:
		var alt_err = target_altitude_m - aircraft.barometric_altitude_m
		var target_vs_ms = clampf(alt_err * 0.25, -25.0, 25.0)
		var vs_err = target_vs_ms - aircraft.vertical_speed_ms
		_pitch_integral = clampf(_pitch_integral + vs_err * delta * 0.01, -0.3, 0.3)
		cmd_pitch = clampf(vs_err * 0.08 + _pitch_integral, -0.85, 0.85)

	# 4. Airspeed Hold (Throttle adjustment)
	if airspeed_hold_enabled:
		var speed_err = target_airspeed_kmh - aircraft.indicated_airspeed_kmh
		var throttle_adj = clampf(speed_err * 0.005, -0.05, 0.05)
		cmd_throttle = clampf(aircraft.throttle + throttle_adj * delta * 10.0, 0.1, 1.0)

	return {
		"pitch": cmd_pitch,
		"roll": cmd_roll,
		"yaw": cmd_yaw,
		"throttle": cmd_throttle
	}
