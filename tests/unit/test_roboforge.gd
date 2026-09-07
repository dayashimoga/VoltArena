class_name TestRoboForge
extends RefCounted

## Unit tests for RoboForge Arena Robot Construction & Physics (games/roboforge-arena/)

const RobotDataScript = preload("res://games/roboforge-arena/robot/robot_data.gd")
const ModularRobotScript = preload("res://games/roboforge-arena/robot/modular_robot.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_robot_data_component_catalog()
	test_stat_calculations()
	test_modular_robot_assembly()
	test_grabber_module_actions()
	test_rollover_recovery()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		["res://games/roboforge-arena/robot/robot_data.gd", [
			"get_default_blueprint", "calculate_stats"
		]],
		["res://games/roboforge-arena/robot/modular_robot.gd", [
			"_ready", "_physics_process", "rebuild_robot", "update_physics_stats",
			"trigger_grabber", "release_grabbed_object", "trigger_booster", "self_right",
			"load_blueprint", "rebuild_visuals", "handle_player_input", "toggle_grab",
			"try_grab_object", "release_object"
		]]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit RoboForge FAIL: " + msg)

func assert_eq(actual, expected, msg: String) -> void:
	assert_true(actual == expected, "%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func test_robot_data_component_catalog() -> void:
	assert_true(RobotDataScript.CHASSIS.size() >= 3, "Catalog must have at least 3 chassis options")
	assert_true(RobotDataScript.LOCOMOTION.size() >= 3, "Catalog must have at least 3 locomotion options")
	assert_true(RobotDataScript.POWER_CORES.size() >= 3, "Catalog must have at least 3 power core options")
	assert_true(RobotDataScript.MODULES.size() >= 4, "Catalog must have at least 4 module options")

func test_stat_calculations() -> void:
	var scout_bp = {
		"chassis": "scout",
		"locomotion": "wheels",
		"power_core": "battery_pack",
		"modules": ["rocket_booster"]
	}
	var titan_bp = {
		"chassis": "titan",
		"locomotion": "tracks",
		"power_core": "fusion_reactor",
		"modules": ["kinetic_shield", "cargo_bed"]
	}

	var scout_stats = RobotDataScript.calculate_stats(scout_bp)
	var titan_stats = RobotDataScript.calculate_stats(titan_bp)

	assert_true(scout_stats["top_speed"] > titan_stats["top_speed"], "Scout speed must exceed Titan speed")
	assert_true(titan_stats["total_mass"] > scout_stats["total_mass"], "Titan mass must exceed Scout mass")
	assert_true(titan_stats["durability"] > scout_stats["durability"], "Titan durability must exceed Scout durability")

func test_modular_robot_assembly() -> void:
	var robot = ModularRobotScript.new()
	robot.build_chassis = "combat"
	robot.build_locomotion = "legs"
	robot.build_core = "fission_cell"
	robot.build_modules = ["hydraulic_grabber"]
	robot.rebuild_robot()

	assert_true(robot.total_mass > 0.0, "Robot mass must be positive")
	assert_true(robot.base_move_speed > 0.0, "Robot speed must be positive")
	assert_true(robot.has_node("ChassisMesh"), "Robot must have ChassisMesh")
	robot.queue_free()

func test_grabber_module_actions() -> void:
	var robot = ModularRobotScript.new()
	robot.build_modules = ["hydraulic_grabber"]
	robot.rebuild_robot()

	assert_true(robot.grabbed_object == null, "Initially no grabbed object")
	var target = RigidBody3D.new()
	target.name = "TargetBox"
	robot.grabbed_object = target
	assert_true(robot.grabbed_object != null, "Grabbed object set")

	robot.release_grabbed_object()
	assert_true(robot.grabbed_object == null, "Grabbed object should be released")
	target.queue_free()
	robot.queue_free()

func test_rollover_recovery() -> void:
	var robot = ModularRobotScript.new()
	robot.rebuild_robot()
	robot.rotation.z = PI # Fully upside down
	robot.self_right()
	assert_true(robot.rotation.z == 0.0, "Self right should reset roll angle to 0")
	robot.queue_free()
