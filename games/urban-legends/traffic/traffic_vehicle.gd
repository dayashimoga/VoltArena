class_name TrafficVehicle
extends CharacterBody3D

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const TrafficVehicleBuilder = preload("res://games/urban-legends/traffic/traffic_vehicle_builder.gd")

## Autonomous metropolitan traffic vehicle for Urban Legends.
## Features:
## - 100% upright basis alignment (lane_forward projected on horizontal plane, zero 25-deg tilt)
## - Self-collision immune sensors (exclude_parent = true, mask = 1 | 2 | 4 | 8)
## - Ground surface height snapping via downward road raycast
## - Continuous circulation at 35 to 65 KM/H (~10 - 18 m/s)
## - Smooth forward obstacle avoidance (18.0m detection) and 3.0s anti-stuck reverse maneuvering
## - 8 authentic contoured vehicle classes with dark rubber tires, alloy rims, and emission 5.0 taillights
## - Zero cyan cylinders or black silhouette boxes.

@export var cruise_speed_ms: float = 14.5 # ~52 km/h (range 35-65 km/h)
@export var current_speed: float = 0.0
@export var is_traffic_active: bool = true
var force_obstacle_detected: bool = false
var stuck_timer: float = 0.0
var reverse_maneuver_timer: float = 0.0
var passing_lane_offset: float = 0.0

var waypoints: Array[Transform3D] = []
var current_waypoint_index: int = 0
var avoidance_ray: RayCast3D = null
var road_snap_ray: RayCast3D = null
var visual_wheels: Array[Node3D] = []
var wheel_roll: float = 0.0

var vehicle_class: String = TrafficVehicleBuilder.CLASS_NYC_TAXI
var is_police: bool = false
var is_ambulance: bool = false

func _ready() -> void:
	# Layer 3 (bit 2 = 4), mask Layer 1 | 2 | 3 | 4 (bits 0,1,2,3 = 15)
	collision_layer = UrbanConstants.LAYER_ENEMIES
	collision_mask = UrbanConstants.LAYER_WORLD | UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES | 8

	add_to_group("ai_traffic")
	add_to_group("urban_vehicles")

	_setup_collision()
	_setup_sensors()
	_build_visuals()

	# Vary cruise speed between 35 and 65 km/h (~10.0 to 18.0 m/s)
	cruise_speed_ms = randf_range(11.0, 17.5)

func _setup_collision() -> void:
	var col = CollisionShape3D.new()
	col.name = "TrafficCollision"
	var box = BoxShape3D.new()
	box.size = Vector3(1.9, 1.35, 4.2)
	col.shape = box
	col.position = Vector3(0, 0.85, 0)
	add_child(col)

func _setup_sensors() -> void:
	# Forward obstacle detection raycast (18.0m range, strictly exclude parent)
	avoidance_ray = RayCast3D.new()
	avoidance_ray.name = "AvoidanceRay"
	avoidance_ray.position = Vector3(0, 0.65, -1.8)
	avoidance_ray.target_position = Vector3(0, 0, -18.0)
	avoidance_ray.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES | UrbanConstants.LAYER_WORLD
	avoidance_ray.exclude_parent = true
	avoidance_ray.enabled = true
	add_child(avoidance_ray)

	# Downward road surface height snapping raycast
	road_snap_ray = RayCast3D.new()
	road_snap_ray.name = "RoadSnapRay"
	road_snap_ray.position = Vector3(0, 1.2, 0)
	road_snap_ray.target_position = Vector3(0, -3.5, 0)
	road_snap_ray.collision_mask = UrbanConstants.LAYER_WORLD
	road_snap_ray.exclude_parent = true
	road_snap_ray.enabled = true
	add_child(road_snap_ray)

func _build_visuals() -> void:
	# Pick from 8 authentic vehicle classes
	var classes = TrafficVehicleBuilder.ALL_CLASSES
	vehicle_class = classes[randi() % classes.size()]

	var res = TrafficVehicleBuilder.build_traffic_vehicle_visual(vehicle_class)
	var visual_root: Node3D = res["visual_root"]
	visual_wheels = res["wheels"]
	is_police = res["is_police"]
	is_ambulance = res["is_ambulance"]

	add_child(visual_root)

func set_waypoints(new_waypoints: Array[Transform3D]) -> void:
	waypoints = new_waypoints
	current_waypoint_index = 0
	if not waypoints.is_empty():
		var wp = waypoints[0]
		var p = wp.origin
		var fwd = -wp.basis.z
		fwd.y = 0.0
		if fwd.length_squared() < 0.001:
			fwd = Vector3.FORWARD
		fwd = fwd.normalized()

		var upright_basis = Basis.looking_at(fwd, Vector3.UP)

		if is_inside_tree():
			global_position = p
			global_basis = upright_basis
		else:
			position = p
			basis = upright_basis

func _physics_process(delta: float) -> void:
	if not is_traffic_active or waypoints.is_empty():
		return

	# Flashing emergency lightbar animations
	if is_police or is_ambulance:
		var flash = fmod(Time.get_ticks_msec() * 0.005, 2.0) < 1.0
		var r_light = get_node_or_null("Visuals/BeaconRed")
		var b_light = get_node_or_null("Visuals/BeaconBlue")
		var w_light = get_node_or_null("Visuals/BeaconWhite")
		if r_light:
			r_light.visible = flash
		if b_light:
			b_light.visible = not flash
		if w_light:
			w_light.visible = flash

	# 1. Forward Obstacle Detection & Dynamic Passing Lane Shift
	var target_speed = cruise_speed_ms
	var is_blocked = false

	if force_obstacle_detected:
		target_speed = 0.0
		is_blocked = true
	elif avoidance_ray and avoidance_ray.is_colliding():
		var hit_pt = avoidance_ray.get_collision_point()
		var my_p = global_position if is_inside_tree() else position
		var dist = my_p.distance_to(hit_pt)
		if dist < 6.0:
			target_speed = 0.0 # Stop before collision
			is_blocked = true
		elif dist < 18.0:
			# Progressive deceleration & lateral nudge into adjacent passing lane
			target_speed = lerpf(0.0, cruise_speed_ms * 0.5, (dist - 6.0) / 12.0)
			is_blocked = true
			passing_lane_offset = move_toward(passing_lane_offset, 2.8, 3.5 * delta)

	if not is_blocked:
		passing_lane_offset = move_toward(passing_lane_offset, 0.0, 2.0 * delta)

	# 2. Reverse Maneuvering & Anti-Stuck Watchdog
	if current_speed < 0.5 and not force_obstacle_detected:
		stuck_timer += delta
		if stuck_timer > 3.0:
			# Trigger 1.5s reverse maneuver to steer around obstacle
			reverse_maneuver_timer = 1.5
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0

	if reverse_maneuver_timer > 0.0:
		reverse_maneuver_timer -= delta
		# Back up smoothly at 4 m/s and rotate steering outward
		target_speed = -4.0
		passing_lane_offset = -3.2

	# Smooth acceleration / braking
	current_speed = move_toward(current_speed, target_speed, 14.0 * delta)

	# 3. Waypoint Navigation with Upright Road-Plane Projection
	var target_wp = waypoints[current_waypoint_index].origin
	var my_pos = global_position if is_inside_tree() else position
	var to_wp = target_wp - my_pos
	to_wp.y = 0.0

	if to_wp.length() < 9.0:
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		target_wp = waypoints[current_waypoint_index].origin
		to_wp = target_wp - my_pos
		to_wp.y = 0.0

	var lane_forward = to_wp.normalized()
	if lane_forward.length_squared() > 0.001:
		var target_rot_y = atan2(-lane_forward.x, -lane_forward.z)
		var curr_y = (global_rotation if is_inside_tree() else rotation).y
		var diff = wrapf(target_rot_y - curr_y, -PI, PI)
		var new_y = curr_y + diff * clampf(5.0 * delta, 0.0, 1.0)
		if is_inside_tree():
			global_rotation.y = new_y
		else:
			rotation.y = new_y

	# 4. Strictly Enforce Upright Basis (Roll = 0, Pitch = 0 on road plane)
	if is_inside_tree():
		global_rotation.x = 0.0
		global_rotation.z = 0.0
	else:
		rotation.x = 0.0
		rotation.z = 0.0

	# 5. Drive Continuous Motion along Lane Spline
	var fwd = -(global_basis if is_inside_tree() else transform.basis).z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right_vec = (global_basis if is_inside_tree() else transform.basis).x

	var forward_step = fwd * current_speed * delta
	var lateral_step = right_vec * passing_lane_offset * delta * 0.8

	if is_inside_tree():
		global_position += forward_step + lateral_step

		# 6. Snap global_position.y to Exact Road Surface Height via Downward Raycast
		if road_snap_ray and road_snap_ray.is_colliding():
			var ground_y = road_snap_ray.get_collision_point().y
			global_position.y = lerpf(global_position.y, ground_y + 0.05, clampf(18.0 * delta, 0.0, 1.0))
		else:
			# Soft gravity fallback
			global_position.y = maxf(0.05, global_position.y - 9.8 * delta)
	else:
		position += forward_step + lateral_step

	# 7. Rotate All 4 Wheels continuously at omega = v / r
	var wheel_r = 0.35
	wheel_roll += -(current_speed * delta) / wheel_r
	for w in visual_wheels:
		if is_instance_valid(w):
			w.rotation.x = wheel_roll

func reset_traffic_state(new_pos: Vector3, new_forward: Vector3) -> void:
	current_speed = cruise_speed_ms * 0.75
	stuck_timer = 0.0
	reverse_maneuver_timer = 0.0
	passing_lane_offset = 0.0

	var fwd = new_forward
	fwd.y = 0.0
	if fwd.length_squared() < 0.001:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()

	var upright_basis = Basis.looking_at(fwd, Vector3.UP)

	if is_inside_tree():
		global_position = new_pos
		global_basis = upright_basis
	else:
		position = new_pos
		basis = upright_basis
