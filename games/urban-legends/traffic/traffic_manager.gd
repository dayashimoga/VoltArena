class_name TrafficManager
extends Node3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const TrafficVehicle = preload("res://games/urban-legends/traffic/traffic_vehicle.gd")
const UrbanRoadNetwork = preload("res://games/urban-legends/world/urban_road_network.gd")

## Metropolitan ambient traffic management director for Urban Legends.
## Spawns, streams, and recycles an autonomous pool of civilian vehicles
## around the player's active position and velocity vector.

@export var max_traffic_pool: int = 16
@export var spawn_radius_min: float = 65.0
@export var spawn_radius_max: float = 240.0
@export var despawn_radius: float = 300.0

var traffic_pool: Array[TrafficVehicle] = []
var player_vehicle: Node3D = null
var road_network: UrbanRoadNetwork = null
var waypoints: Array[Transform3D] = []

func _ready() -> void:
	pass

func setup_traffic(road_net: UrbanRoadNetwork, player: Node3D, pool_size: int = 16) -> void:
	road_network = road_net
	player_vehicle = player
	max_traffic_pool = pool_size

	if road_network:
		waypoints = road_network.get_traffic_waypoints()

	_initialize_pool()

func _initialize_pool() -> void:
	for v in traffic_pool:
		if is_instance_valid(v):
			v.queue_free()
	traffic_pool.clear()

	if waypoints.is_empty():
		return

	for i in range(max_traffic_pool):
		var tv = TrafficVehicle.new()
		tv.name = "TrafficCar_%d" % i
		# Distribute along road waypoints
		var wp_idx = (i * (waypoints.size() / maxi(1, max_traffic_pool))) % waypoints.size()
		var sub_wps: Array[Transform3D] = []
		for w in range(waypoints.size()):
			sub_wps.append(waypoints[(wp_idx + w) % waypoints.size()])

		tv.set_waypoints(sub_wps)
		add_child(tv)
		traffic_pool.append(tv)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player_vehicle) or waypoints.is_empty():
		return

	var p_pos = player_vehicle.global_position if player_vehicle.is_inside_tree() else player_vehicle.position

	for tv in traffic_pool:
		if not is_instance_valid(tv) or not tv.is_traffic_active:
			continue

		var tv_pos = tv.global_position if tv.is_inside_tree() else tv.position
		var dist_to_player = p_pos.distance_to(tv_pos)

		# Despawn and recycle cars that fall too far behind or outside active bubble
		if dist_to_player > despawn_radius:
			_recycle_vehicle_ahead_of_player(tv, p_pos)

func _recycle_vehicle_ahead_of_player(tv: TrafficVehicle, p_pos: Vector3) -> void:
	# Find a waypoint ahead of player along road
	var attempts = 0
	while attempts < 10:
		attempts += 1
		var rand_wp = waypoints[randi() % waypoints.size()]
		var wp_pos = rand_wp.origin
		var d = p_pos.distance_to(wp_pos)

		if d >= spawn_radius_min and d <= spawn_radius_max:
			# Verify distance to other traffic cars
			var too_close = false
			for other in traffic_pool:
				if other != tv and is_instance_valid(other):
					var o_pos = other.global_position if other.is_inside_tree() else other.position
					if wp_pos.distance_to(o_pos) < 18.0:
						too_close = true
						break
			if not too_close:
				var fwd = -rand_wp.basis.z
				tv.reset_traffic_state(wp_pos, fwd)
				break

func get_active_traffic_count() -> int:
	var count = 0
	for tv in traffic_pool:
		if is_instance_valid(tv) and tv.is_traffic_active:
			count += 1
	return count

func clear_all_traffic() -> void:
	for tv in traffic_pool:
		if is_instance_valid(tv):
			tv.queue_free()
	traffic_pool.clear()
