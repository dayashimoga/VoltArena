class_name TestUrbanPerformanceAndStreamingUnit
extends RefCounted

## Unit tests for Urban Legends world spatial grid chunk streaming, distance LOD,
## and prop visibility culling.

const UrbanWorldManager = preload("res://games/urban-legends/world/urban_world_manager.gd")
const UrbanPropFactory = preload("res://games/urban-legends/world/urban_prop_factory.gd")

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0

func run_tests() -> Dictionary:
	total_assertions = 0
	passed_assertions = 0
	failed_assertions = 0

	print("--- Running TestUrbanPerformanceAndStreamingUnit ---")
	test_cell_coordinate_calculation()
	test_spatial_registration_and_culling()

	return {
		"total": total_assertions,
		"passed": passed_assertions,
		"failed": failed_assertions
	}

func assert_true(condition: bool, msg: String) -> void:
	total_assertions += 1
	if condition:
		passed_assertions += 1
		print("  [PASS] " + msg)
	else:
		failed_assertions += 1
		print("  >>> [FAIL] " + msg)
		push_error("Assertion failed: %s" % msg)

func test_cell_coordinate_calculation() -> void:
	var mgr = UrbanWorldManager.new()
	mgr._ready()

	# Coordinates on 200m grid with (-1000, -1000) offset
	var c_origin = mgr.get_cell_coord(Vector3(-1000, 0, -1000))
	assert_true(c_origin == Vector2i(0, 0), "Origin (-1000, -1000) should map to cell (0, 0) (was: %s)" % str(c_origin))

	var c_center = mgr.get_cell_coord(Vector3(0, 0, 0))
	assert_true(c_center == Vector2i(5, 5), "Center (0, 0) should map to cell (5, 5) (was: %s)" % str(c_center))

	var c_max = mgr.get_cell_coord(Vector3(999, 0, 999))
	assert_true(c_max == Vector2i(9, 9), "Max edge (999, 999) should map to cell (9, 9) (was: %s)" % str(c_max))

	mgr.free()

func test_spatial_registration_and_culling() -> void:
	var world_root = Node3D.new()

	# Near prop at (0, 0, 0)
	var near_prop = Node3D.new()
	near_prop.name = "NearProp"
	near_prop.position = Vector3(0, 0, 0)
	world_root.add_child(near_prop)

	# Far prop at (800, 0, 800)
	var far_prop = Node3D.new()
	far_prop.name = "FarProp"
	far_prop.position = Vector3(800, 0, 800)
	world_root.add_child(far_prop)

	var player = Node3D.new()
	player.position = Vector3(0, 0, 0)

	var mgr = UrbanWorldManager.new()
	mgr.culling_distance = 400.0
	mgr.setup(player, world_root)

	# Trigger update
	mgr._process(0.016)

	assert_true(near_prop.visible, "Near prop within 400m must be visible")
	assert_true(not far_prop.visible, "Far prop beyond 400m must be culled (visible = false)")
	assert_true(mgr.get_active_chunk_count() >= 1, "Active chunk count should be >= 1")

	mgr.free()
	player.free()
	world_root.free()

func get_coverage_entries() -> Array:
	return [
		["res://games/urban-legends/world/urban_world_manager.gd", [
			"_ready", "setup", "_register_existing_world_props",
			"get_cell_coord", "_process", "_update_chunk_visibility",
			"get_active_chunk_count"
		]]
	]
