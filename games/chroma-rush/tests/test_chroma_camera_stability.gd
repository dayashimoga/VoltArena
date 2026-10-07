class_name TestChromaCameraStability
extends RefCounted

## Automated test suite certifying Chroma Rush camera stability:
## 1. Constant speed for 10s => FOV variance below strict threshold.
## 2. Steady acceleration => Monotonic smooth FOV transition (no pumping).
## 3. Steady braking => Monotonic smooth return to base FOV.
## 4. Frame rate invariance => Equivalent behavior across 30, 60, and 120 FPS.
## 5. Fixed camera distance => Zero dynamic distance pumping.
## 6. Comprehensive frame telemetry instrumentation.

const ChromaRushMain = preload("res://games/chroma-rush/chroma_rush_main.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

var passed: int = 0
var failed: int = 0

func run_tests() -> Dictionary:
	passed = 0
	failed = 0

	test_constant_speed_10s_fov_variance()
	test_steady_acceleration_monotonic_transition()
	test_steady_braking_monotonic_return()
	test_framerate_invariance_30_60_120_fps()
	test_fixed_camera_distance_no_pumping()
	test_telemetry_instrumentation_fields()

	return {"passed": passed, "failed": failed}

func assert_true(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[TestChromaCameraStability FAIL] " + msg)

func assert_lt(a: float, b: float, msg: String) -> void:
	assert_true(a < b, "%s: Expected %f < %f" % [msg, a, b])

func assert_gt(a: float, b: float, msg: String) -> void:
	assert_true(a > b, "%s: Expected %f > %f" % [msg, a, b])

func _create_test_rig() -> Dictionary:
	var main = ChromaRushMain.new()
	var veh = ChromaVehicle.new()
	veh.is_player = true
	main.add_child(veh)
	main.player_vehicle = veh
	main._init_camera()
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(main)
	return {"main": main, "veh": veh}

func _cleanup_rig(rig: Dictionary) -> void:
	var main = rig["main"]
	if is_instance_valid(main):
		if main.get_parent():
			main.get_parent().remove_child(main)
		main.free()

func test_constant_speed_10s_fov_variance() -> void:
	var rig = _create_test_rig()
	var main: ChromaRushMain = rig["main"]
	var veh: ChromaVehicle = rig["veh"]

	veh.forward_speed = 80.0 / 3.6 # 80 km/h constant
	veh.velocity = Vector3(0, 0, -veh.forward_speed)

	# Warm up initial frame
	main._update_camera(0.016)

	var fov_samples: Array[float] = []
	var total_frames = 600 # 10 seconds at 60 FPS
	var delta = 1.0 / 60.0

	for i in range(total_frames):
		main._update_camera(delta)
		# Record after initial 0.5s settling
		if i > 30:
			fov_samples.append(main.chase_camera.fov)

	assert_gt(fov_samples.size(), 500, "Must have recorded sufficient samples")

	# Compute variance
	var sum = 0.0
	for f in fov_samples:
		sum += f
	var mean = sum / float(fov_samples.size())

	var var_sum = 0.0
	for f in fov_samples:
		var diff = f - mean
		var_sum += diff * diff
	var variance = var_sum / float(fov_samples.size())

	# Variance must be strictly below 0.0001 (rock-solid, zero zoom pumping)
	assert_lt(variance, 0.0001, "Constant speed 10s FOV variance must be near zero (got %f)" % variance)
	_cleanup_rig(rig)

func test_steady_acceleration_monotonic_transition() -> void:
	var rig = _create_test_rig()
	var main: ChromaRushMain = rig["main"]
	var veh: ChromaVehicle = rig["veh"]

	veh.forward_speed = 0.0
	main._update_camera(0.016)

	var prev_fov = main.chase_camera.fov
	var pumping_detected = false
	var delta = 1.0 / 60.0

	# Accelerate from 0 to 140 km/h over 3 seconds (180 frames)
	for i in range(180):
		var target_speed_kmh = (float(i) / 180.0) * 140.0
		veh.forward_speed = target_speed_kmh / 3.6
		veh.velocity = Vector3(0, 0, -veh.forward_speed)
		main._update_camera(delta)

		var cur_fov = main.chase_camera.fov
		# Monotonic: FOV should never decrease while accelerating
		if cur_fov < prev_fov - 0.0001:
			pumping_detected = true
		prev_fov = cur_fov

	assert_true(not pumping_detected, "FOV must transition monotonically during steady acceleration with zero pumping")
	assert_gt(main.chase_camera.fov, 74.0, "FOV must have expanded at high speed")
	_cleanup_rig(rig)

func test_steady_braking_monotonic_return() -> void:
	var rig = _create_test_rig()
	var main: ChromaRushMain = rig["main"]
	var veh: ChromaVehicle = rig["veh"]

	veh.forward_speed = 120.0 / 3.6
	veh.velocity = Vector3(0, 0, -veh.forward_speed)

	# Settle at high speed
	for i in range(60):
		main._update_camera(0.016)

	var prev_fov = main.chase_camera.fov
	var pumping_detected = false
	var delta = 1.0 / 60.0

	# Brake from 120 to 0 km/h over 2.5 seconds (150 frames)
	for i in range(150):
		var target_speed_kmh = maxf(0.0, 120.0 * (1.0 - float(i) / 150.0))
		veh.forward_speed = target_speed_kmh / 3.6
		veh.velocity = Vector3(0, 0, -veh.forward_speed)
		main._update_camera(delta)

		var cur_fov = main.chase_camera.fov
		# Monotonic return: FOV should never increase while braking
		if cur_fov > prev_fov + 0.0001:
			pumping_detected = true
		prev_fov = cur_fov

	assert_true(not pumping_detected, "FOV must return monotonically during steady braking without oscillation")
	# Allow slight settling margin for asymptotic approach to 72.0
	assert_lt(absf(main.chase_camera.fov - 72.0), 0.5, "FOV must smoothly return near base FOV 72.0")
	_cleanup_rig(rig)

func test_framerate_invariance_30_60_120_fps() -> void:
	var rates = [30.0, 60.0, 120.0]
	var final_fovs: Array[float] = []

	for fps in rates:
		var rig = _create_test_rig()
		var main: ChromaRushMain = rig["main"]
		var veh: ChromaVehicle = rig["veh"]
		veh.forward_speed = 90.0 / 3.6
		veh.velocity = Vector3(0, 0, -veh.forward_speed)

		var delta = 1.0 / fps
		var steps = int(fps * 2.0) # 2 seconds simulation
		for s in range(steps):
			main._update_camera(delta)

		final_fovs.append(main.chase_camera.fov)
		_cleanup_rig(rig)

	# All FPS rates should converge to virtually identical FOV (diff < 0.2 deg)
	var fov_30 = final_fovs[0]
	var fov_60 = final_fovs[1]
	var fov_120 = final_fovs[2]

	assert_lt(absf(fov_30 - fov_60), 0.25, "30 FPS vs 60 FPS FOV difference must be < 0.25 deg")
	assert_lt(absf(fov_60 - fov_120), 0.25, "60 FPS vs 120 FPS FOV difference must be < 0.25 deg")

func test_fixed_camera_distance_no_pumping() -> void:
	var rig = _create_test_rig()
	var main: ChromaRushMain = rig["main"]
	var veh: ChromaVehicle = rig["veh"]

	var test_speeds = [0.0, 45.0, 90.0, 135.0]
	for spd in test_speeds:
		veh.forward_speed = spd / 3.6
		veh.velocity = Vector3(0, 0, -veh.forward_speed)
		for step in range(30):
			main._update_camera(0.016)

		var dist = main.camera_telemetry.get("camera_distance", 0.0)
		# Distance must remain stable around cam_distance (7.5m) with zero dynamic modulation
		assert_lt(absf(dist - main.cam_distance), 0.35, "Camera distance at %f km/h must stay fixed at %f (got %f)" % [spd, main.cam_distance, dist])

	_cleanup_rig(rig)

func test_telemetry_instrumentation_fields() -> void:
	var rig = _create_test_rig()
	var main: ChromaRushMain = rig["main"]
	var veh: ChromaVehicle = rig["veh"]

	veh.forward_speed = 60.0 / 3.6
	veh.velocity = Vector3(0, 0, -veh.forward_speed)
	main._update_camera(0.016)

	var telem = main.camera_telemetry
	assert_true(telem.has("raw_speed"), "Telemetry must include raw_speed")
	assert_true(telem.has("filtered_speed"), "Telemetry must include filtered_speed")
	assert_true(telem.has("raw_acceleration"), "Telemetry must include raw_acceleration")
	assert_true(telem.has("filtered_acceleration"), "Telemetry must include filtered_acceleration")
	assert_true(telem.has("desired_fov"), "Telemetry must include desired_fov")
	assert_true(telem.has("actual_fov"), "Telemetry must include actual_fov")
	assert_true(telem.has("camera_distance"), "Telemetry must include camera_distance")
	assert_true(telem.has("camera_transform"), "Telemetry must include camera_transform")

	_cleanup_rig(rig)
