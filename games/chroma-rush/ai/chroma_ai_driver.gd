class_name ChromaAIDriver
extends RefCounted

## Physical driving translation layer for AI vehicles in Chroma Rush
## Translates 3D navigation waypoints into realistic vehicle inputs (steer, throttle, brake)
## respecting physical turning constraints, deceleration, obstacle avoidance, and recovery.

const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

var vehicle: ChromaVehicle
var target_position: Vector3 = Vector3.ZERO
var target_speed: float = 28.0
var desired_lane_offset: float = 0.0

# Difficulty and smoothing factors
var steer_sensitivity: float = 2.4
var cornering_slowdown_factor: float = 0.65
var obstacle_lookahead: float = 12.0

func _init(p_vehicle: ChromaVehicle = null) -> void:
	vehicle = p_vehicle

func set_vehicle(p_vehicle: ChromaVehicle) -> void:
	vehicle = p_vehicle

func set_target(pos: Vector3, desired_speed: float = -1.0) -> void:
	target_position = pos
	if desired_speed > 0.0:
		target_speed = desired_speed
	elif vehicle:
		target_speed = vehicle.top_speed

func update_driving(delta: float) -> void:
	if not vehicle or not is_instance_valid(vehicle):
		return

	# Transform target position into vehicle local space
	var local_target = vehicle.to_local(target_position)
	local_target.x += desired_lane_offset

	var dist = Vector2(local_target.x, local_target.z).length()
	if dist < 0.5:
		# Very close to target, coast
		vehicle.set_inputs(0.0, 0.2, 0.0, false, false)
		return

	# Compute local yaw angle to target
	# Forward is -Z, Right is +X
	var target_angle = atan2(local_target.x, -local_target.z)
	var steer = clampf(target_angle * steer_sensitivity, -1.0, 1.0)

	# Calculate speed target based on corner sharpness
	var angle_abs_deg = rad_to_deg(absf(target_angle))
	var corner_speed_scale = 1.0
	var need_drift = false

	if angle_abs_deg > 65.0:
		corner_speed_scale = cornering_slowdown_factor * 0.7
		need_drift = (vehicle.forward_speed > 16.0)
	elif angle_abs_deg > 35.0:
		corner_speed_scale = cornering_slowdown_factor
	elif angle_abs_deg > 20.0:
		corner_speed_scale = 0.85

	var effective_target_speed = minf(target_speed, vehicle.top_speed * corner_speed_scale)

	# Longitudinal throttle / brake control
	var current_spd = vehicle.forward_speed
	var throttle = 0.0
	var brake = 0.0

	if current_spd < effective_target_speed - 1.0:
		throttle = 1.0
		brake = 0.0
	elif current_spd > effective_target_speed + 2.0:
		throttle = 0.0
		brake = clampf((current_spd - effective_target_speed) / 6.0, 0.3, 1.0)
	else:
		# Maintain speed smoothly
		throttle = 0.4
		brake = 0.0

	# Nitro boost on straightaways if charged
	var use_boost = (angle_abs_deg < 10.0 and dist > 35.0 and vehicle.drift_charge >= 1.0)

	# Obstacle avoidance raycast simulation
	var avoidance_steer = _compute_obstacle_avoidance()
	if absf(avoidance_steer) > 0.1:
		steer = clampf(steer + avoidance_steer, -1.0, 1.0)
		throttle = 0.0
		brake = maxf(brake, 0.75)

	# Feed inputs to vehicle controller
	vehicle.set_inputs(steer, throttle, brake, need_drift, use_boost)

func _compute_obstacle_avoidance() -> float:
	if not vehicle or not vehicle.is_inside_tree():
		return 0.0

	var space_state = vehicle.get_world_3d().direct_space_state
	if not space_state:
		return 0.0

	var origin = vehicle.global_position + Vector3(0, 0.6, 0)
	var forward = -vehicle.global_transform.basis.z.normalized()
	var right = vehicle.global_transform.basis.x.normalized()
	var mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	# Cast forward center, left, and right rays
	var ray_center = origin + forward * obstacle_lookahead
	var query_center = PhysicsRayQueryParameters3D.create(origin, ray_center, mask, [vehicle.get_rid()])
	var hit_center = space_state.intersect_ray(query_center)

	if hit_center:
		# Something ahead, check left and right to pick avoidance direction
		var ray_left = origin + (forward - right * 0.6).normalized() * (obstacle_lookahead * 0.75)
		var query_left = PhysicsRayQueryParameters3D.create(origin, ray_left, mask, [vehicle.get_rid()])
		var hit_left = space_state.intersect_ray(query_left)

		var ray_right = origin + (forward + right * 0.6).normalized() * (obstacle_lookahead * 0.75)
		var query_right = PhysicsRayQueryParameters3D.create(origin, ray_right, mask, [vehicle.get_rid()])
		var hit_right = space_state.intersect_ray(query_right)

		if not hit_right:
			return 0.85 # Steer right into open lane
		elif not hit_left:
			return -0.85 # Steer left into open lane
		else:
			return 1.0 # Hard steer right

	return 0.0
