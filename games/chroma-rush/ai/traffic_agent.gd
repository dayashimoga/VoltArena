class_name TrafficAgent
extends RefCounted

## Controls an ambient traffic vehicle navigating connected road networks
## Transports colors through the world for player and rival strategy.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")
const ChromaAIDriver = preload("res://games/chroma-rush/ai/chroma_ai_driver.gd")
const ColorSwapEngine = preload("res://games/chroma-rush/core/color_swap_engine.gd")

var vehicle: ChromaVehicle
var driver: ChromaAIDriver
var swap_engine: ColorSwapEngine
var waypoints: Array[Vector3] = []
var current_waypoint_idx: int = 0
var cruise_speed: float = 22.0
var base_speed: float = 22.0
var waypoint_reach_dist: float = 6.0
var traffic_id: String = ""

# Evasion Dynamics
var evasion_threat: Node3D = null
var evasion_aggressiveness: float = 1.0
var evasion_active: bool = false
var lane_shift_timer: float = 0.0

func _init(p_vehicle: ChromaVehicle, p_engine: ColorSwapEngine, p_id: String, p_color: int) -> void:
	vehicle = p_vehicle
	swap_engine = p_engine
	traffic_id = p_id
	driver = ChromaAIDriver.new(vehicle)

	if swap_engine and vehicle:
		swap_engine.register_vehicle(traffic_id, vehicle, p_color, true)

func set_waypoints(wp_list: Array[Vector3], starting_idx: int = 0) -> void:
	waypoints = wp_list
	current_waypoint_idx = starting_idx % max(1, waypoints.size())
	if waypoints.size() > 0:
		driver.set_target(waypoints[current_waypoint_idx], cruise_speed)

func set_evasion_threat(p_threat: Node3D, p_aggressiveness: float = 1.0) -> void:
	evasion_threat = p_threat
	evasion_aggressiveness = clampf(p_aggressiveness, 0.5, 2.0)

func is_evading() -> bool:
	return evasion_active

func update(delta: float) -> void:
	if not vehicle or not is_instance_valid(vehicle) or waypoints.is_empty():
		return

	var vpos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position

	# Check evasion triggers when pursued by threat vehicle
	var current_target_speed = cruise_speed
	evasion_active = false

	if is_instance_valid(evasion_threat) and vehicle.is_inside_tree():
		var t_pos = evasion_threat.global_position
		var dist_to_threat = vpos.distance_to(t_pos)
		if dist_to_threat < 35.0:
			var to_threat = (t_pos - vpos).normalized()
			var heading = -vehicle.global_transform.basis.z.normalized()
			# Dot product < -0.1 means threat vehicle is approaching from behind
			if to_threat.dot(heading) < -0.1:
				evasion_active = true
				current_target_speed = base_speed * (1.15 + 0.25 * evasion_aggressiveness)
				lane_shift_timer += delta
				if lane_shift_timer > 3.0:
					lane_shift_timer = 0.0
					driver.desired_lane_offset = -driver.desired_lane_offset if absf(driver.desired_lane_offset) > 0.5 else 1.8

	var target_wp = waypoints[current_waypoint_idx]
	var dist = vpos.distance_to(target_wp)

	if dist < waypoint_reach_dist:
		# Advance to next waypoint (looping circuit)
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_idx]

	driver.set_target(target_wp, current_target_speed)
	driver.update_driving(delta)

func get_current_color() -> int:
	if swap_engine:
		return swap_engine.get_vehicle_color(traffic_id)
	elif vehicle:
		return vehicle.current_color
	return ChromaConstants.ChromaColor.NONE

func set_cruise_speed(spd: float) -> void:
	base_speed = spd
	cruise_speed = spd
	if waypoints.size() > 0:
		driver.set_target(waypoints[current_waypoint_idx], cruise_speed)

func cleanup() -> void:
	if swap_engine and traffic_id != "":
		swap_engine.unregister_vehicle(traffic_id)
