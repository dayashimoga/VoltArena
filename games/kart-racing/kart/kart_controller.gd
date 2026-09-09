class_name KartController
extends CharacterBody3D

signal drift_boost_triggered(boost_level: int)

@export var kart_type: String = "speeder" # "speeder", "phantom", "enforcer", "turbo_demon"
@export var base_speed: float = 26.0
@export var boost_top_speed: float = 38.0
@export var acceleration: float = 24.0
@export var brake_deceleration: float = 32.0
@export var steer_speed: float = 3.2
@export var drift_steer_speed: float = 4.2
@export var gravity: float = 25.0

# Aliases for test compatibility
var max_speed: float:
	get: return base_speed
	set(v): base_speed = v

var acceleration_force: float:
	get: return acceleration
	set(v): acceleration = v

var steering_speed: float:
	get: return steer_speed
	set(v): steer_speed = v

var grip_factor: float:
	get: return drift_steer_speed
	set(v): drift_steer_speed = v

@export var racer_id: int = 0
@export var racer_name: String = "Player"
@export var is_player: bool = true

# Drift & Boost Mechanics
var is_drifting: bool = false
var drift_direction: float = 0.0 # -1 left, +1 right
var drift_charge_time: float = 0.0
var boost_timer: float = 0.0
var forward_speed: float = 0.0
var current_steer_input: float = 0.0

# Race Progression
var current_lap: int = 1
var next_checkpoint_index: int = 0
var total_checkpoints_hit: int = 0
var lap_start_time: float = 0.0
var best_lap_time: float = 999.0
var race_finished: bool = false
var last_valid_checkpoint_pos: Vector3 = Vector3.ZERO
var last_valid_checkpoint_rot: float = 0.0

# Visual & Wheel Attachment
var kart_visual: Node3D
var front_wheels: Array[Node3D] = []
var rear_wheels: Array[Node3D] = []
var all_wheels: Array[Node3D] = []
var wheel_raycasts: Array[RayCast3D] = []
var wheel_roll_angle: float = 0.0

# Telemetry System (Verified Physics & Grounding)
var wheel_contact_count: int = 4
var ground_distance: float = 0.0
var suspension_compression: Array[float] = [0.0, 0.0, 0.0, 0.0]
var surface_normal: Vector3 = Vector3.UP
var vehicle_speed: float:
	get: return absf(forward_speed) * 3.6 # km/h
var nearest_spline_distance: float = 0.0

# Wrong-Way Detection & Hysteresis
var is_wrong_way: bool = false
var wrong_way_timer: float = 0.0
var active_race_spline: RefCounted = null

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

func _ready() -> void:
	collision_layer = GameConstants.LAYER_PLAYER if is_player else GameConstants.LAYER_ENEMIES
	collision_mask = GameConstants.LAYER_WORLD | GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	add_to_group("karts")
	add_to_group("racers")
	if is_player:
		add_to_group("players")
	else:
		add_to_group("ai_racers")

	last_valid_checkpoint_pos = global_position
	last_valid_checkpoint_rot = rotation.y

	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(65.0)
	floor_constant_speed = false
	floor_block_on_wall = false
	floor_stop_on_slope = false
	wall_min_slide_angle = 0.0
	up_direction = Vector3.UP
	max_slides = 4

	setup_kart_archetype()
	setup_kart_visual()
	setup_suspension_raycasts()

func setup_kart_archetype() -> void:
	match kart_type:
		"phantom":
			# High-speed drift specialist
			base_speed = 29.0
			boost_top_speed = 43.0
			acceleration = 20.0
			brake_deceleration = 30.0
			steer_speed = 2.9
			drift_steer_speed = 4.8
		"enforcer":
			# Heavy chassis, high grip, fast off the line
			base_speed = 24.0
			boost_top_speed = 35.0
			acceleration = 29.0
			brake_deceleration = 36.0
			steer_speed = 3.6
			drift_steer_speed = 3.6
		"turbo_demon":
			# Rocket burst racer
			base_speed = 25.5
			boost_top_speed = 45.0
			acceleration = 26.0
			brake_deceleration = 32.0
			steer_speed = 3.4
			drift_steer_speed = 4.4
		_: # "speeder"
			# Balanced all-rounder
			base_speed = 26.0
			boost_top_speed = 38.0
			acceleration = 24.0
			brake_deceleration = 32.0
			steer_speed = 3.2
			drift_steer_speed = 4.2

func set_kart_type(new_type: String) -> void:
	kart_type = new_type
	setup_kart_archetype()
	setup_kart_visual()

func setup_kart_visual() -> void:
	if kart_visual and is_instance_valid(kart_visual):
		kart_visual.queue_free()
		front_wheels.clear()
		rear_wheels.clear()
		all_wheels.clear()

	var kart_col = Color(0.0, 0.88, 1.0) # Player 1: Volt Cyan
	if not is_player:
		match racer_id % 5:
			1: kart_col = Color(1.0, 0.45, 0.05) # Blaze Orange (Apex Nova)
			2: kart_col = Color(0.95, 0.15, 0.25) # Crimson Red (Blaze Raptor)
			3: kart_col = Color(0.80, 0.20, 1.0)  # Neon Purple (Viper Strike)
			4: kart_col = Color(0.20, 0.95, 0.35) # Acid Green (Turbo Titan)
			_: kart_col = Color(1.0, 0.85, 0.10) # Solar Gold (Cyber Ghost)

	kart_visual = MeshBuilder.build_drift_kart(kart_col, kart_type, racer_id if not is_player else 7)
	kart_visual.position = Vector3.ZERO
	add_child(kart_visual)

	for child in kart_visual.get_children():
		if child is Node3D:
			if child.name.begins_with("FrontWheel"):
				front_wheels.append(child)
				all_wheels.append(child)
			elif child.name.begins_with("RearWheel"):
				rear_wheels.append(child)
				all_wheels.append(child)

	# Collision - Low center-of-gravity sphere resting perfectly on asphalt
	if not has_node("KartCollision"):
		var col = CollisionShape3D.new()
		col.name = "KartCollision"
		var sphere = SphereShape3D.new()
		sphere.radius = 0.36
		col.shape = sphere
		col.position = Vector3(0, 0.36, 0)
		add_child(col)

func setup_suspension_raycasts() -> void:
	for r in wheel_raycasts:
		if is_instance_valid(r):
			r.queue_free()
	wheel_raycasts.clear()

	# 4 Suspension Raycasts located at wheel hubs: FL, FR, RL, RR
	var ray_offsets = [
		Vector3(-0.58, 0.28, -0.62), # Front Left
		Vector3(0.58, 0.28, -0.62),  # Front Right
		Vector3(-0.64, 0.28, 0.62),  # Rear Left
		Vector3(0.64, 0.28, 0.62)   # Rear Right
	]
	for i in range(4):
		var ray = RayCast3D.new()
		ray.name = "SuspensionRay_%d" % i
		ray.position = ray_offsets[i]
		ray.target_position = Vector3(0, -0.48, 0)
		ray.collision_mask = GameConstants.LAYER_WORLD
		ray.enabled = true
		add_child(ray)
		wheel_raycasts.append(ray)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		if is_player and not race_finished:
			handle_player_input(delta)
		_update_suspension_and_grounding(delta)
		return

	# Automatic recovery if fallen off track or irrecoverable out-of-bounds
	if global_position.y < -3.5 or global_position.distance_to(last_valid_checkpoint_pos) > 150.0:
		recover_to_checkpoint()
		return

	# Process 4-Wheel Raycast Suspension & Grounding Telemetry
	_update_suspension_and_grounding(delta)

	if not is_on_floor() and wheel_contact_count == 0:
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0 # Clean asphalt glide, zero internal edge bump

	# Check wrong-way progression against authoritative RaceSpline
	_check_wrong_way(delta)

	# Only accept controls if race has started
	var rm = _get_race_manager()
	var is_countdown = (rm and rm.get("current_state") == 0) # RaceState.COUNTDOWN

	if is_player and not race_finished and not is_countdown:
		handle_player_input(delta)

	# Process boost timer
	if boost_timer > 0.0:
		boost_timer -= delta

	move_and_slide()

func _update_suspension_and_grounding(delta: float) -> void:
	var hits = 0
	var sum_normals = Vector3.ZERO
	var min_dist = 999.0
	var rest_len = 0.28

	for i in range(wheel_raycasts.size()):
		var ray = wheel_raycasts[i]
		if not is_instance_valid(ray):
			continue
		if is_inside_tree():
			ray.force_raycast_update()
		var colliding = ray.is_colliding() if is_inside_tree() else false
		var col_pt = Vector3.ZERO
		var col_norm = Vector3.UP
		if colliding:
			col_pt = ray.get_collision_point()
			col_norm = ray.get_collision_normal()
		elif not is_inside_tree() and position.y >= -0.2 and position.y <= 0.4:
			colliding = true
			col_pt = Vector3(ray.position.x, 0.0, ray.position.z)
			col_norm = Vector3.UP

		if colliding:
			hits += 1
			sum_normals += col_norm
			var dist = ray.position.distance_to(col_pt) if not is_inside_tree() else ray.global_position.distance_to(col_pt)
			min_dist = minf(min_dist, dist)
			var comp = clampf(rest_len - dist, 0.0, 0.12)
			if i < suspension_compression.size():
				suspension_compression[i] = comp

			# Update visual wheel position based on physical suspension compression
			if i < all_wheels.size() and is_instance_valid(all_wheels[i]):
				var w = all_wheels[i]
				var base_y = 0.15 if i < 2 else 0.16
				w.position.y = base_y + comp * 0.4
		else:
			if i < suspension_compression.size():
				suspension_compression[i] = 0.0
			if i < all_wheels.size() and is_instance_valid(all_wheels[i]):
				var w = all_wheels[i]
				var base_y = 0.15 if i < 2 else 0.16
				w.position.y = base_y

	wheel_contact_count = hits
	ground_distance = min_dist if hits > 0 else 0.48
	surface_normal = (sum_normals / float(hits)).normalized() if hits > 0 else Vector3.UP

	# Visual wheel roll rotation proportional to travel distance (v / r)
	var avg_r = 0.155
	wheel_roll_angle -= (forward_speed * delta / avg_r)

	# Visual steering angle for front wheels
	for fw in front_wheels:
		if is_instance_valid(fw):
			fw.rotation_degrees.y = -current_steer_input * 28.0

	# Track telemetry: nearest spline distance
	var spline = _get_race_spline()
	if spline:
		var s = spline.get_closest_distance(global_position)
		var s_data = spline.sample_at_distance(s)
		nearest_spline_distance = global_position.distance_to(s_data["pos"])

func recover_to_checkpoint() -> void:
	var spline = _get_race_spline()
	var cur_pos = global_position if is_inside_tree() else position
	if spline:
		var safe_tr = spline.get_safe_respawn_transform(cur_pos)
		if is_inside_tree():
			global_transform = safe_tr
		else:
			transform = safe_tr
		velocity = -safe_tr.basis.z * 12.0
		forward_speed = 12.0
	elif last_valid_checkpoint_pos != Vector3.ZERO:
		var respawn_pos = last_valid_checkpoint_pos + Vector3(0, 0.6, 0)
		if is_inside_tree():
			global_position = respawn_pos
			rotation.y = last_valid_checkpoint_rot
		else:
			position = respawn_pos
			rotation.y = last_valid_checkpoint_rot
		velocity = -transform.basis.z * 12.0
		forward_speed = 12.0

	is_drifting = false
	drift_charge_time = 0.0
	wrong_way_timer = 0.0
	is_wrong_way = false

	var bus = GameConstants.get_autoload(self, "EventBus")
	if bus and is_player:
		bus.show_toast_requested.emit("RECOVERED TO TRACK", Color(1.0, 0.8, 0.2))

var input_override: bool = false
var override_throttle: float = 0.0
var override_steer: float = 0.0
var override_drift: bool = false

func handle_player_input(delta: float) -> void:
	if input_override:
		apply_kart_controls(override_throttle, override_steer, override_drift, delta)
		return
	var im = GameConstants.get_autoload(self, "InputManager")
	var throttle = 0.0
	var steer = 0.0

	if Input.is_action_pressed("move_forward"): throttle += 1.0
	if Input.is_action_pressed("move_back"): throttle -= 1.0
	if Input.is_action_pressed("move_left"): steer += 1.0
	if Input.is_action_pressed("move_right"): steer -= 1.0

	if im and im.virtual_move_vector.length_squared() > 0.01:
		steer = -im.virtual_move_vector.x
		throttle = -im.virtual_move_vector.y

	var want_drift = Input.is_action_pressed("drift") or Input.is_action_pressed("jump")
	apply_kart_controls(throttle, steer, want_drift, delta)

func apply_kart_controls(throttle: float, steer: float, want_drift: bool, delta: float) -> void:
	var rm = _get_race_manager()
	if rm and rm.get("current_state") == 0: # RaceState.COUNTDOWN
		throttle = 0.0
		forward_speed = 0.0

	current_steer_input = steer

	# Drift mechanics handling
	if want_drift and abs(steer) > 0.2 and (is_on_floor() or wheel_contact_count >= 2) and forward_speed > 10.0:
		if not is_drifting:
			is_drifting = true
			drift_direction = sign(steer)
			drift_charge_time = 0.0
			var am = GameConstants.get_autoload(self, "AudioManager")
			if am:
				am.play_sound("drift_screech", 1.2)
		drift_charge_time += delta
	else:
		if is_drifting:
			# Release drift to trigger boost!
			trigger_drift_boost()
			is_drifting = false

	# Steering
	var effective_steer_speed = drift_steer_speed if is_drifting else steer_speed
	var steer_multiplier = 1.0
	if is_drifting:
		steer_multiplier = 1.35 * drift_direction

	if abs(forward_speed) > 0.5:
		rotate_y(steer * effective_steer_speed * steer_multiplier * delta)

	# Target top speed
	var max_active_speed = base_speed
	if boost_timer > 0.0:
		max_active_speed = boost_top_speed
	elif is_drifting:
		max_active_speed = base_speed * 0.92

	if throttle > 0.0:
		forward_speed = move_toward(forward_speed, max_active_speed, acceleration * delta)
	elif throttle < 0.0:
		forward_speed = move_toward(forward_speed, -10.0, brake_deceleration * delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, 10.0 * delta)

	var fwd = -transform.basis.z
	velocity.x = fwd.x * forward_speed
	velocity.z = fwd.z * forward_speed

func trigger_drift_boost() -> void:
	var boost_level = 0
	var am = GameConstants.get_autoload(self, "AudioManager")
	var bus = GameConstants.get_autoload(self, "EventBus")

	if drift_charge_time >= 2.5:
		boost_level = 3 # Tier 3: Ultra Mini-Turbo
		boost_timer = 3.2
		if am:
			am.play_sound("drift_turbo_3", 1.0, 1.8)
		if bus and is_player:
			bus.show_toast_requested.emit("ULTRA MINI-TURBO! +++", Color(1.0, 0.2, 0.9))
	elif drift_charge_time >= 1.5:
		boost_level = 2 # Tier 2: Super Mini-Turbo
		boost_timer = 2.0
		if am:
			am.play_sound("drift_turbo_2", 1.0, 1.4)
		if bus and is_player:
			bus.show_toast_requested.emit("SUPER MINI-TURBO! ++", Color(1.0, 0.6, 0.1))
	elif drift_charge_time >= 0.7:
		boost_level = 1 # Tier 1: Mini-Turbo
		boost_timer = 1.0
		if am:
			am.play_sound("drift_turbo_1", 1.0, 1.2)
		if bus and is_player:
			bus.show_toast_requested.emit("MINI-TURBO! +", Color(0.2, 0.8, 1.0))

	if boost_level > 0:
		drift_boost_triggered.emit(boost_level)
	drift_charge_time = 0.0

func apply_item_boost(duration: float) -> void:
	boost_timer = max(boost_timer, duration)
	var am = GameConstants.get_autoload(self, "AudioManager")
	if am:
		am.play_sound("jump", 1.5)

## Authoritative Wrong-Way Detection:
## Compares vehicle planar forward vector F against authoritative RaceSpline tangent T.
## Triggers ONLY when heading against track direction inside track corridor, debounced with hysteresis.
func _check_wrong_way(delta: float) -> void:
	if not is_player or absf(forward_speed) < 3.0:
		is_wrong_way = false
		wrong_way_timer = 0.0
		return

	var spline = _get_race_spline()
	if not spline:
		# Fallback to checkpoint tangent if spline is unassigned
		_check_wrong_way_fallback(delta)
		return

	var cur_pos = global_position if is_inside_tree() else position
	var cur_basis = global_transform.basis if is_inside_tree() else transform.basis

	var fwd = -cur_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var tangent = spline.get_tangent_at_pos(cur_pos)
	tangent.y = 0.0
	tangent = tangent.normalized()

	var dot = fwd.dot(tangent)
	var on_track = spline.is_point_on_track(cur_pos, 5.0)

	# Only trigger wrong-way if driving backward against spline flow inside track corridor
	if dot < -0.30 and on_track and forward_speed > 3.0:
		wrong_way_timer += delta
		if wrong_way_timer > 0.6:
			is_wrong_way = true
	else:
		wrong_way_timer = maxf(0.0, wrong_way_timer - delta * 3.5)
		if wrong_way_timer <= 0.0 or dot >= 0.0:
			is_wrong_way = false

func _check_wrong_way_fallback(delta: float) -> void:
	var rm = _get_race_manager()
	if not rm or rm.checkpoints.size() < 2:
		return

	var n_cp = rm.checkpoints.size()
	var curr_cp_idx = posmod(next_checkpoint_index - 1, n_cp)
	var next_cp_idx = posmod(next_checkpoint_index, n_cp)
	var cp_curr = rm.checkpoints[curr_cp_idx]
	var cp_next = rm.checkpoints[next_cp_idx]
	if not is_instance_valid(cp_curr) or not is_instance_valid(cp_next):
		return

	var track_tangent = cp_next.global_position - cp_curr.global_position
	track_tangent.y = 0.0
	if track_tangent.length_squared() < 0.1:
		return
	track_tangent = track_tangent.normalized()

	var fwd = -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()

	var dot = fwd.dot(track_tangent)
	if dot < -0.35 and forward_speed > 3.0:
		wrong_way_timer += delta
		if wrong_way_timer > 0.6:
			is_wrong_way = true
	else:
		wrong_way_timer = maxf(0.0, wrong_way_timer - delta * 3.5)
		if wrong_way_timer <= 0.0:
			is_wrong_way = false

func _get_race_spline() -> RefCounted:
	if active_race_spline:
		return active_race_spline
	var p = get_parent()
	while p:
		var tg = p.get_node_or_null("TrackGenerator")
		if tg and tg.get("race_spline"):
			return tg.race_spline
		p = p.get_parent()
	if get_tree() and get_tree().root:
		var tg = get_tree().root.find_child("TrackGenerator", true, false)
		if tg and tg.get("race_spline"):
			return tg.race_spline
	return null

func _get_race_manager() -> Node:
	var p = get_parent()
	while p:
		var rm = p.get_node_or_null("RaceManager")
		if rm:
			return rm
		p = p.get_parent()
	if get_tree() and get_tree().root:
		return get_tree().root.find_child("RaceManager", true, false)
	return null
