class_name StuntEvaluator
extends RefCounted

## StuntEvaluator: Airborne 3-Axis Attitude Control & Touchdown Evaluation
## Routes air control inputs (pitch, yaw, roll) and evaluates landing precision
## with score bonuses, boost refills, and rollover/crash resets.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

const PITCH_TORQUE_RAD_S: float = 3.2  # Local X pitch torque (W/S)
const YAW_TORQUE_RAD_S: float = 4.0    # Local Y yaw torque (A/D)
const ROLL_TORQUE_RAD_S: float = 4.5   # Local Z roll torque (Space + A/D or Shift + A/D)

const PERFECT_LANDING_ANGLE_DEG: float = 18.0
const CLEAN_LANDING_ANGLE_DEG: float = 38.0
const CRASH_LANDING_ANGLE_DEG: float = 65.0

## Evaluates landing precision from chassis up vector and track ground normal.
static func evaluate_touchdown(chassis_up: Vector3, track_normal: Vector3) -> Dictionary:
	var dot_prod: float = clampf(chassis_up.normalized().dot(track_normal.normalized()), -1.0, 1.0)
	var angle_rad: float = acos(dot_prod)
	var angle_deg: float = rad_to_deg(angle_rad)

	if angle_deg <= PERFECT_LANDING_ANGLE_DEG:
		return {
			"quality": "perfect",
			"angle_deg": angle_deg,
			"score_bonus": 500,
			"boost_refill": 1.0, # Fully recharge nitrous boost (100%)
			"stunt_id": AeroConstants.StuntType.PERFECT_LANDING,
			"is_crash": false,
			"damped_rebound": false,
			"trigger_vfx_ring": true,
			"play_chime": true
		}
	elif angle_deg <= CLEAN_LANDING_ANGLE_DEG:
		return {
			"quality": "clean",
			"angle_deg": angle_deg,
			"score_bonus": 150,
			"boost_refill": 0.25, # 25% recharge
			"stunt_id": -1,
			"is_crash": false,
			"damped_rebound": true, # Critically damped rebound
			"trigger_vfx_ring": false,
			"play_chime": false
		}
	elif angle_deg > CRASH_LANDING_ANGLE_DEG:
		return {
			"quality": "crash",
			"angle_deg": angle_deg,
			"score_bonus": 0,
			"boost_refill": 0.0,
			"stunt_id": -1,
			"is_crash": true,
			"reset_combo": true,
			"reset_delay_sec": 1.2,
			"respawn_speed": 30.0, # 30 m/s aligned with track tangent
			"trigger_vfx_ring": false,
			"play_chime": false
		}
	else:
		return {
			"quality": "rough",
			"angle_deg": angle_deg,
			"score_bonus": 50,
			"boost_refill": 0.0,
			"stunt_id": -1,
			"is_crash": false,
			"damped_rebound": false,
			"trigger_vfx_ring": false,
			"play_chime": false
		}

## Calculates 3-axis rotation delta for airborne attitude control:
## Pitch (W/S) -> Local X (+/- 3.2 rad/s)
## Yaw (A/D) -> Local Y (+/- 4.0 rad/s)
## Roll (Space + A/D) -> Local Z (+/- 4.5 rad/s)
static func calculate_air_rotation(
	throttle_in: float,
	brake_in: float,
	steer_in: float,
	roll_modifier: bool,
	delta: float
) -> Vector3:
	var pitch_rate: float = 0.0
	var yaw_rate: float = 0.0
	var roll_rate: float = 0.0

	# Pitch (W / S)
	if throttle_in > 0.0:
		pitch_rate = PITCH_TORQUE_RAD_S * throttle_in
	elif brake_in > 0.0:
		pitch_rate = -PITCH_TORQUE_RAD_S * brake_in

	# Roll vs Yaw (Space + A/D = Roll, A/D alone = Flat Spin / Yaw)
	if absf(steer_in) > 0.05:
		if roll_modifier:
			# Barrel Roll: local Z axis
			roll_rate = ROLL_TORQUE_RAD_S * steer_in
		else:
			# Flat Spin: local Y axis
			yaw_rate = -YAW_TORQUE_RAD_S * steer_in

	return Vector3(pitch_rate * delta, yaw_rate * delta, roll_rate * delta)
