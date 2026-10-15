class_name TestAircraftCatalogUnit
extends RefCounted

## TestAircraftCatalogUnit: Unit tests for aircraft specifications, procedural
## 3D model construction, and real-time articulation visuals.

const AircraftCatalog = preload("res://games/aircraft-flight/aircraft/aircraft_catalog.gd")
const AircraftMeshBuilder = preload("res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd")
const AircraftVisualsScript = preload("res://games/aircraft-flight/aircraft/aircraft_visuals.gd")
const FlightPhysicsScript = preload("res://games/aircraft-flight/core/flight_physics.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_aircraft_catalog_specs()
	test_procedural_fa18_mesh_builder()
	test_procedural_f22_mesh_builder()
	test_procedural_a320_mesh_builder()
	test_procedural_extra330_mesh_builder()
	test_procedural_uh60_mesh_builder()
	test_aircraft_visuals_articulation()

	return {"passed": assertions_passed, "failed": assertions_failed}

func _assert_true(condition: bool, msg: String) -> void:
	if condition:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("FAIL: %s" % msg)

func test_aircraft_catalog_specs() -> void:
	var roster = AircraftCatalog.get_all_aircraft()
	_assert_true(roster.size() == 5, "Catalog contains all 5 advertised aircraft")

	var fa18 = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	_assert_true(fa18.get("max_speed_ms") > 500.0, "F/A-18 supersonic top speed verified")

	var f22 = AircraftCatalog.get_aircraft_spec("f22_raptor")
	_assert_true(f22.get("cd0") < 0.02, "F-22 stealth low-drag coefficient verified")

	var a320 = AircraftCatalog.get_aircraft_spec("a320_airliner")
	_assert_true(a320.get("aspect_ratio") > 8.0, "A320 high aspect ratio verified")

	var extra = AircraftCatalog.get_aircraft_spec("extra330_sport")
	_assert_true(extra.get("roll_authority") >= 7.0, "Extra 330 extreme aerobatic roll rate verified")

	var uh60 = AircraftCatalog.get_aircraft_spec("uh60_helicopter")
	_assert_true(uh60.get("is_rotorcraft") == true, "UH-60 rotorcraft type verified")

func test_procedural_fa18_mesh_builder() -> void:
	var mesh = AircraftMeshBuilder.build_fa18_hornet(Color(0.45, 0.48, 0.52), Color(0.1, 0.65, 1.0))
	_assert_true(mesh != null, "F/A-18 3D model generated")
	_assert_true(mesh.find_child("AileronLeft", true, false) != null, "F/A-18 left aileron articulated node exists")
	_assert_true(mesh.find_child("AileronRight", true, false) != null, "F/A-18 right aileron exists")
	_assert_true(mesh.find_child("LandingGear", true, false) != null, "F/A-18 landing gear assembly exists")
	_assert_true(mesh.find_child("AfterburnerPlumeLeft", true, false) != null, "F/A-18 afterburner VFX node exists")
	mesh.free()

func test_procedural_f22_mesh_builder() -> void:
	var mesh = AircraftMeshBuilder.build_f22_raptor(Color(0.25, 0.28, 0.32), Color(0.9, 0.3, 0.1))
	_assert_true(mesh != null, "F-22 3D model generated")
	_assert_true(mesh.find_child("VectorNozzleLeft", true, false) != null, "F-22 2D thrust vectoring nozzle exists")
	_assert_true(mesh.find_child("RudderLeft", true, false) != null, "F-22 canted fin rudder exists")
	mesh.free()

func test_procedural_a320_mesh_builder() -> void:
	var mesh = AircraftMeshBuilder.build_a320_airliner(Color(0.92, 0.94, 0.96), Color(0.12, 0.35, 0.85))
	_assert_true(mesh != null, "A320 commercial airliner 3D model generated")
	_assert_true(mesh.find_child("FanBladesLeft", true, false) != null, "A320 turbofan blades exist")
	_assert_true(mesh.find_child("FlapLeft", true, false) != null, "A320 high-lift flaps exist")
	mesh.free()

func test_procedural_extra330_mesh_builder() -> void:
	var mesh = AircraftMeshBuilder.build_extra330_sport(Color(0.9, 0.15, 0.15), Color(1.0, 0.9, 0.1))
	_assert_true(mesh != null, "Extra 330 aerobatic monoplane 3D model generated")
	_assert_true(mesh.find_child("Propeller", true, false) != null, "Extra 330 spinning propeller exists")
	_assert_true(mesh.find_child("LandingGear", true, false) != null, "Extra 330 taildragger gear exists")
	mesh.free()

func test_procedural_uh60_mesh_builder() -> void:
	var mesh = AircraftMeshBuilder.build_uh60_helicopter(Color(0.18, 0.22, 0.19), Color(0.85, 0.65, 0.15))
	_assert_true(mesh != null, "UH-60 tactical rotorcraft 3D model generated")
	_assert_true(mesh.find_child("MainRotor", true, false) != null, "UH-60 4-blade main rotor exists")
	_assert_true(mesh.find_child("TailRotor", true, false) != null, "UH-60 canted tail rotor exists")
	_assert_true(mesh.find_child("RescueHoist", true, false) != null, "UH-60 rescue hoist exists")
	mesh.free()

func test_aircraft_visuals_articulation() -> void:
	var plane = FlightPhysicsScript.new()
	var spec = AircraftCatalog.get_aircraft_spec("fa18_hornet")
	plane.setup_aircraft_specs(spec)

	var mesh_root = AircraftMeshBuilder.build_aircraft_visuals("fa18_hornet", Color.GRAY, Color.CYAN)
	plane.add_child(mesh_root)

	var visuals = AircraftVisualsScript.new()
	visuals.aircraft_physics = plane
	plane.add_child(visuals)

	# Trigger control surface inputs
	plane.elevator_deflection = 0.5
	plane.aileron_left_deflection = -0.75
	plane.rudder_deflection = 0.4
	plane.flaps_step = 2
	plane.engine_rpm_pct = 95.0
	plane.afterburner_active = true
	plane.throttle = 1.0

	visuals._process(0.016)

	_assert_true(visuals.elevator_l != null, "Elevator visual node bound")
	_assert_true(visuals.aileron_l != null, "Aileron visual node bound")
	_assert_true(visuals.afterburner_l != null and visuals.afterburner_l.visible, "Afterburner active visual plume visible")

	plane.free()

func get_coverage_entries() -> Array:
	return [
		[
			"res://games/aircraft-flight/aircraft/aircraft_catalog.gd",
			["get_aircraft_spec", "get_all_aircraft"]
		],
		[
			"res://games/aircraft-flight/aircraft/aircraft_mesh_builder.gd",
			[
				"build_aircraft_visuals", "build_fa18_hornet", "build_f22_raptor",
				"build_a320_airliner", "build_extra330_sport", "build_uh60_helicopter",
				"_add_box", "_add_cyl", "_add_cone", "_add_sphere", "_add_wedge",
				"_create_pbr_material", "_create_canopy_material", "_create_emissive_material"
			]
		],
		[
			"res://games/aircraft-flight/aircraft/aircraft_visuals.gd",
			["_ready", "_bind_visual_nodes", "_setup_nav_lights", "_process"]
		]
	]
