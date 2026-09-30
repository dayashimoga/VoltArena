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
var waypoint_reach_dist: float = 6.0
var traffic_id: String = ""

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

func update(delta: float) -> void:
	if not vehicle or not is_instance_valid(vehicle) or waypoints.is_empty():
		return

	var target_wp = waypoints[current_waypoint_idx]
	var vpos = vehicle.global_position if vehicle.is_inside_tree() else vehicle.position
	var dist = vpos.distance_to(target_wp)

	if dist < waypoint_reach_dist:
		# Advance to next waypoint (looping circuit)
		current_waypoint_idx = (current_waypoint_idx + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_idx]
		driver.set_target(target_wp, cruise_speed)

	driver.update_driving(delta)

func get_current_color() -> int:
	if swap_engine:
		return swap_engine.get_vehicle_color(traffic_id)
	elif vehicle:
		return vehicle.current_color
	return ChromaConstants.ChromaColor.NONE

func set_cruise_speed(spd: float) -> void:
	cruise_speed = spd
	if waypoints.size() > 0:
		driver.set_target(waypoints[current_waypoint_idx], cruise_speed)

func cleanup() -> void:
	if swap_engine and traffic_id != "":
		swap_engine.unregister_vehicle(traffic_id)
