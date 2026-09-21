class_name TestHumanoidAnimator
extends RefCounted

## Unit tests for HumanoidAnimator (shared/animation/humanoid_animator.gd)

const HumanoidAnimatorScript = preload("res://shared/animation/humanoid_animator.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_animator_initial_state()
	test_locomotion_speed_sync()
	test_jump_and_landing_states()
	test_aim_and_glide_states()
	test_procedural_biped_posing()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://shared/animation/humanoid_animator.gd", [
			"setup_procedural_biped", "setup_skeletal_biped", "update",
			"_update_skeletal_animations", "_update_procedural_nodes"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit HumanoidAnimator FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_animator_initial_state() -> void:
	var anim = HumanoidAnimatorScript.new()
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.IDLE, "Initial state should be IDLE")

func test_locomotion_speed_sync() -> void:
	var anim = HumanoidAnimatorScript.new()
	# Update with walking speed
	anim.update(0.1, Vector3(2.5, 0, 0), true)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.WALK, "State should be WALK at 2.5 m/s")
	assert_true(anim.walk_cycle > 0.0, "Walk cycle should advance proportionally to speed")

	# Update with sprinting speed
	anim.update(0.1, Vector3(8.0, 0, 0), true, true)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.RUN, "State should be RUN at 8.0 m/s")

func test_jump_and_landing_states() -> void:
	var anim = HumanoidAnimatorScript.new()
	# Upward airborne
	anim.update(0.1, Vector3(0, 5.0, 0), false)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.JUMP_START, "State should be JUMP_START when ascending")

	# Downward airborne
	anim.update(0.1, Vector3(0, -3.0, 0), false)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.JUMP_AIR, "State should be JUMP_AIR when descending")

	# Touch down
	anim.update(0.01, Vector3(0, 0, 0), true)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.LAND, "State should be LAND upon ground contact")

func test_aim_and_glide_states() -> void:
	var anim = HumanoidAnimatorScript.new()
	# Gliding
	anim.update(0.1, Vector3(5.0, -1.0, 0), false, false, false, false, false, false, true)
	assert_eq(anim.current_state, HumanoidAnimatorScript.AnimState.GLIDE, "State should be GLIDE when is_gliding=true")

	# Aiming while stationary
	var anim_aim = HumanoidAnimatorScript.new()
	anim_aim.update(0.1, Vector3.ZERO, true, false, false, false, true)
	assert_eq(anim_aim.current_state, HumanoidAnimatorScript.AnimState.AIM, "State should be AIM when stationary and aiming")

func test_procedural_biped_posing() -> void:
	var root = Node3D.new()
	var torso = Node3D.new(); torso.name = "Torso"; root.add_child(torso)
	var hip_l = Node3D.new(); hip_l.name = "Hip_L"; root.add_child(hip_l)
	var hip_r = Node3D.new(); hip_r.name = "Hip_R"; root.add_child(hip_r)
	var arm_l = Node3D.new(); arm_l.name = "Shoulder_L"; root.add_child(arm_l)
	var arm_r = Node3D.new(); arm_r.name = "Shoulder_R"; root.add_child(arm_r)

	var anim = HumanoidAnimatorScript.new()
	anim.setup_procedural_biped(root)

	# Simulate walk step
	anim.update(0.2, Vector3(3.0, 0, 0), true)
	assert_true(hip_l.rotation.x != 0.0 or hip_r.rotation.x != 0.0, "Legs should rotate during walk cycle")
	assert_true(arm_l.rotation.x != 0.0 or arm_r.rotation.x != 0.0, "Arms should swing during walk cycle")

	root.queue_free()
