class_name HumanoidAnimator
extends RefCounted

## HumanoidAnimator: Production runtime locomotion & animation controller.
## Drives Idle ↔ Walk ↔ Run ↔ Jump ↔ Land ↔ Crouch ↔ Aim/Strafe ↔ Attack ↔ Hit ↔ Death ↔ Glide.
## Synchronizes animation playback speed with physical velocity to completely eliminate foot sliding.
## Supports both rigged skeletal AnimationPlayers and articulated procedural biped models.

enum AnimState {
	IDLE,
	WALK,
	RUN,
	JUMP_START,
	JUMP_AIR,
	LAND,
	CROUCH,
	SLIDE,
	AIM,
	ATTACK,
	HIT,
	DEATH,
	GLIDE
}

var current_state: AnimState = AnimState.IDLE
var state_time: float = 0.0
var walk_cycle: float = 0.0
var stride_length: float = 1.65 # Distance covered per full walk cycle
var run_stride_length: float = 2.45
var is_on_floor: bool = true
var was_on_floor: bool = true
var landing_timer: float = 0.0

# Optional procedural nodes (for non-skeletal bipeds like Skybound Explorer / WildCircuit Ranger)
var head_node: Node3D = null
var torso_node: Node3D = null
var left_arm: Node3D = null
var right_arm: Node3D = null
var left_leg: Node3D = null
var right_leg: Node3D = null
var glider_wings: Node3D = null
var weapon_socket: Node3D = null

# Optional skeletal AnimationPlayer
var anim_player: AnimationPlayer = null
var skeleton: Skeleton3D = null

func setup_procedural_biped(root: Node3D) -> void:
	if not root or not is_instance_valid(root):
		return
	head_node = root.find_child("HeadNode", true, false)
	if not head_node: head_node = root.find_child("Head", true, false)
	torso_node = root.find_child("TorsoNode", true, false)
	if not torso_node: torso_node = root.find_child("Torso", true, false)
	left_arm = root.find_child("Shoulder_L", true, false)
	if not left_arm: left_arm = root.find_child("Arm_L", true, false)
	right_arm = root.find_child("Shoulder_R", true, false)
	if not right_arm: right_arm = root.find_child("Arm_R", true, false)
	left_leg = root.find_child("Hip_L", true, false)
	if not left_leg: left_leg = root.find_child("Leg_L", true, false)
	right_leg = root.find_child("Hip_R", true, false)
	if not right_leg: right_leg = root.find_child("Leg_R", true, false)
	glider_wings = root.find_child("GliderWings", true, false)
	weapon_socket = root.find_child("WeaponGrip", true, false)

func setup_skeletal_biped(root: Node3D) -> void:
	if not root or not is_instance_valid(root):
		return
	anim_player = root.find_child("*AnimationPlayer*", true, false) as AnimationPlayer
	skeleton = root.find_child("*Skeleton*", true, false) as Skeleton3D

func update(
	delta: float,
	linear_velocity: Vector3,
	p_is_on_floor: bool,
	is_sprinting: bool = false,
	is_crouching: bool = false,
	is_sliding: bool = false,
	is_aiming: bool = false,
	is_attacking: bool = false,
	is_gliding: bool = false,
	is_dead: bool = false,
	local_move_dir: Vector3 = Vector3.ZERO
) -> void:
	state_time += delta
	var horiz_vel = Vector2(linear_velocity.x, linear_velocity.z)
	var speed = horiz_vel.length()
	is_on_floor = p_is_on_floor

	# Landing impact detection
	if is_on_floor and not was_on_floor and linear_velocity.y <= 0.1:
		landing_timer = 0.22
	was_on_floor = is_on_floor

	if landing_timer > 0.0:
		landing_timer -= delta

	# State resolution
	var prev_state = current_state
	if is_dead:
		current_state = AnimState.DEATH
	elif is_gliding:
		current_state = AnimState.GLIDE
	elif not is_on_floor:
		if linear_velocity.y > 1.5:
			current_state = AnimState.JUMP_START
		else:
			current_state = AnimState.JUMP_AIR
	elif landing_timer > 0.0 and speed < 1.0:
		current_state = AnimState.LAND
	elif is_sliding:
		current_state = AnimState.SLIDE
	elif is_crouching:
		current_state = AnimState.CROUCH
	elif is_attacking:
		current_state = AnimState.ATTACK
	elif is_aiming and speed < 0.5:
		current_state = AnimState.AIM
	elif speed > 5.5 or (is_sprinting and speed > 1.0):
		current_state = AnimState.RUN
	elif speed > 0.35:
		current_state = AnimState.WALK
	else:
		current_state = AnimState.IDLE

	if current_state != prev_state:
		state_time = 0.0

	# Advance walk cycle strictly synchronized with actual distance travelled:
	# distance = speed * delta; cycle += (speed * delta) / (stride * TAU)
	if current_state == AnimState.WALK:
		var cycle_rate = (speed / stride_length) * TAU
		walk_cycle += cycle_rate * delta
	elif current_state == AnimState.RUN:
		var cycle_rate = (speed / run_stride_length) * TAU
		walk_cycle += cycle_rate * delta
	else:
		# Decay smoothly to rest
		walk_cycle = lerp_angle(walk_cycle, 0.0, clampf(delta * 8.0, 0.0, 1.0))

	# Update AnimationPlayer if present
	if anim_player and is_instance_valid(anim_player):
		_update_skeletal_animations(speed, local_move_dir, is_aiming)

	# Update procedural biped nodes if present
	_update_procedural_nodes(delta, speed, is_aiming, is_attacking, is_gliding)

func _update_skeletal_animations(speed: float, local_move_dir: Vector3, is_aiming: bool) -> void:
	var target_anim = "Idle"
	var custom_speed_scale = 1.0

	match current_state:
		AnimState.IDLE:
			target_anim = "Idle"
			custom_speed_scale = 1.0
		AnimState.WALK:
			if is_aiming:
				if local_move_dir.z > 0.3: target_anim = "WalkBack"
				elif local_move_dir.x > 0.3: target_anim = "StrafeRight"
				elif local_move_dir.x < -0.3: target_anim = "StrafeLeft"
				else: target_anim = "Walk"
			else:
				target_anim = "Walk"
			# Match animation playback speed to linear speed
			custom_speed_scale = clampf(speed / 3.2, 0.6, 1.6)
		AnimState.RUN:
			if is_aiming and abs(local_move_dir.x) > 0.4:
				target_anim = "StrafeRight" if local_move_dir.x > 0.0 else "StrafeLeft"
			else:
				target_anim = "Run"
			custom_speed_scale = clampf(speed / 7.5, 0.7, 1.8)
		AnimState.JUMP_START, AnimState.JUMP_AIR:
			target_anim = "Run"
			custom_speed_scale = 0.5
		AnimState.LAND:
			target_anim = "Idle"
			custom_speed_scale = 1.2
		AnimState.AIM:
			target_anim = "Aim"
			custom_speed_scale = 1.0
		AnimState.ATTACK:
			target_anim = "Fire"
			custom_speed_scale = 1.0
		AnimState.HIT:
			target_anim = "HitReact"
			custom_speed_scale = 1.0
		AnimState.DEATH:
			target_anim = "Idle"
			custom_speed_scale = 1.0
		_:
			target_anim = "Idle"

	ModelCache.play_animation(anim_player.get_parent() as Node3D, target_anim, 0.15)
	if anim_player.is_playing():
		anim_player.speed_scale = custom_speed_scale

func _update_procedural_nodes(
	delta: float,
	speed: float,
	is_aiming: bool,
	is_attacking: bool,
	is_gliding: bool
) -> void:
	if not torso_node and not left_leg and not right_leg:
		return

	var cycle = walk_cycle
	var leg_amp = 0.48
	var arm_amp = 0.42

	match current_state:
		AnimState.IDLE:
			var breathe = sin(state_time * 2.4) * 0.035
			if torso_node:
				torso_node.position.y = lerpf(torso_node.position.y, 0.9 + breathe * 0.5, delta * 8.0)
				torso_node.rotation.x = lerpf(torso_node.rotation.x, 0.0, delta * 8.0)
			if head_node:
				head_node.rotation.x = lerpf(head_node.rotation.x, -breathe * 0.5, delta * 8.0)
			if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, delta * 10.0)
			if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, delta * 10.0)
			if left_arm:
				left_arm.rotation.x = lerpf(left_arm.rotation.x, breathe, delta * 8.0)
				left_arm.rotation.z = lerpf(left_arm.rotation.z, 0.08, delta * 8.0)
			if right_arm:
				if is_aiming or is_attacking:
					right_arm.rotation.x = lerpf(right_arm.rotation.x, -PI * 0.45, delta * 14.0)
					right_arm.rotation.z = lerpf(right_arm.rotation.z, 0.0, delta * 14.0)
				else:
					right_arm.rotation.x = lerpf(right_arm.rotation.x, -breathe, delta * 8.0)
					right_arm.rotation.z = lerpf(right_arm.rotation.z, -0.08, delta * 8.0)

		AnimState.WALK, AnimState.RUN:
			var is_run = (current_state == AnimState.RUN)
			if is_run:
				leg_amp = 0.68
				arm_amp = 0.60

			# Speed-synchronized physical leg swing
			var swing_l = sin(cycle) * leg_amp
			var swing_r = -swing_l
			if left_leg: left_leg.rotation.x = swing_l
			if right_leg: right_leg.rotation.x = swing_r

			# Natural opposing arm swing (unless aiming/attacking)
			if left_arm:
				left_arm.rotation.x = -swing_l * (arm_amp / leg_amp)
				left_arm.rotation.z = lerpf(left_arm.rotation.z, 0.12, delta * 10.0)

			if right_arm:
				if is_aiming or is_attacking:
					right_arm.rotation.x = lerpf(right_arm.rotation.x, -PI * 0.45, delta * 14.0)
					right_arm.rotation.z = lerpf(right_arm.rotation.z, 0.0, delta * 14.0)
				else:
					right_arm.rotation.x = -swing_r * (arm_amp / leg_amp)
					right_arm.rotation.z = lerpf(right_arm.rotation.z, -0.12, delta * 10.0)

			# Locomotion bob & forward lean
			if torso_node:
				var bob = abs(sin(cycle)) * (0.05 if is_run else 0.03)
				torso_node.position.y = 0.9 + bob
				var lean = 0.14 if is_run else 0.05
				torso_node.rotation.x = lerpf(torso_node.rotation.x, lean, delta * 10.0)
				torso_node.rotation.y = sin(cycle) * 0.06

		AnimState.JUMP_START, AnimState.JUMP_AIR:
			if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.35, delta * 10.0)
			if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.25, delta * 10.0)
			if left_arm: left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.6, delta * 10.0)
			if right_arm and not is_aiming: right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.6, delta * 10.0)
			if torso_node: torso_node.position.y = lerpf(torso_node.position.y, 0.95, delta * 8.0)

		AnimState.LAND:
			# Compression impact on landing
			if torso_node:
				torso_node.position.y = lerpf(torso_node.position.y, 0.72, delta * 18.0)
				torso_node.rotation.x = lerpf(torso_node.rotation.x, 0.18, delta * 14.0)
			if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.25, delta * 14.0)
			if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.25, delta * 14.0)

		AnimState.GLIDE:
			if glider_wings:
				glider_wings.visible = true
			if left_arm:
				left_arm.rotation.z = lerpf(left_arm.rotation.z, 1.15, delta * 12.0)
				left_arm.rotation.x = 0.0
			if right_arm:
				right_arm.rotation.z = lerpf(right_arm.rotation.z, -1.15, delta * 12.0)
				right_arm.rotation.x = 0.0
			if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, -0.25, delta * 8.0)
			if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, -0.20, delta * 8.0)
			if torso_node:
				torso_node.rotation.x = lerpf(torso_node.rotation.x, 0.45, delta * 8.0)

		AnimState.CROUCH, AnimState.SLIDE:
			if torso_node:
				torso_node.position.y = lerpf(torso_node.position.y, 0.62, delta * 14.0)
				torso_node.rotation.x = -0.32 if current_state == AnimState.SLIDE else 0.12
			if left_leg: left_leg.rotation.x = 0.45
			if right_leg: right_leg.rotation.x = -0.35

		AnimState.DEATH:
			if torso_node:
				torso_node.position.y = lerpf(torso_node.position.y, 0.2, delta * 12.0)
				torso_node.rotation.x = lerpf(torso_node.rotation.x, -PI * 0.45, delta * 12.0)
			if left_arm: left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.8, delta * 10.0)
			if right_arm: right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.8, delta * 10.0)
			if left_leg: left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.5, delta * 10.0)
			if right_leg: right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.5, delta * 10.0)
