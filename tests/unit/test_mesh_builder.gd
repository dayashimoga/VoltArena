class_name TestMeshBuilder
extends RefCounted

const MeshBuilderScript = preload("res://shared/graphics/mesh_builder.gd")

var assertions_passed: int = 0
var assertions_failed: int = 0

func run_tests() -> Dictionary:
	test_weapons()
	test_characters()
	test_vehicles()
	test_props()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/graphics/mesh_builder.gd",
			[
				"build_pulse_rifle", "build_scatter_cannon", "build_rail_driver",
				"build_grenade_launcher", "build_plasma_cutter", "build_cyber_soldier",
				"build_crawler_mesh", "build_stalker_mesh", "build_brute_mesh",
				"build_rocket_car", "build_drift_kart", "build_energy_ball",
				"build_item_box", "build_pickup_mesh", "build_cyber_crate"
			]
		]
	]

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		assertions_passed += 1
	else:
		assertions_failed += 1
		push_error("Unit MeshBuilder FAIL: " + msg)

func test_weapons() -> void:
	var w1 = MeshBuilderScript.build_pulse_rifle()
	assert_true(w1 != null and w1.get_child_count() > 0, "Pulse rifle must contain parts")
	w1.queue_free()

	var w2 = MeshBuilderScript.build_scatter_cannon()
	assert_true(w2 != null and w2.get_child_count() > 0, "Scatter cannon must contain parts")
	w2.queue_free()

	var w3 = MeshBuilderScript.build_rail_driver()
	assert_true(w3 != null and w3.get_child_count() > 0, "Rail driver must contain parts")
	w3.queue_free()

	var w4 = MeshBuilderScript.build_grenade_launcher()
	assert_true(w4 != null and w4.get_child_count() > 0, "Grenade launcher must contain parts")
	w4.queue_free()

	var w5 = MeshBuilderScript.build_plasma_cutter()
	assert_true(w5 != null and w5.get_child_count() > 0, "Plasma cutter must contain parts")
	w5.queue_free()

func test_characters() -> void:
	var s = MeshBuilderScript.build_cyber_soldier(false, Color.CYAN)
	assert_true(s != null and s.get_child_count() > 0, "Cyber soldier must have limbs")
	s.queue_free()

	var c = MeshBuilderScript.build_crawler_mesh()
	assert_true(c != null and c.get_child_count() > 0, "Crawler must have parts")
	c.queue_free()

	var st = MeshBuilderScript.build_stalker_mesh()
	assert_true(st != null and st.get_child_count() > 0, "Stalker must have parts")
	st.queue_free()

	var b = MeshBuilderScript.build_brute_mesh()
	assert_true(b != null and b.get_child_count() > 0, "Brute must have parts")
	b.queue_free()

func test_vehicles() -> void:
	var car = MeshBuilderScript.build_rocket_car(0)
	assert_true(car != null and car.get_child_count() > 0, "Rocket car must have wheels and chassis")
	car.queue_free()

	var kart = MeshBuilderScript.build_drift_kart(Color.GREEN)
	assert_true(kart != null and kart.get_child_count() > 0, "Drift kart must have wheels and chassis")
	kart.queue_free()

func test_props() -> void:
	var ball = MeshBuilderScript.build_energy_ball()
	assert_true(ball != null and ball.get_child_count() > 0, "Energy ball must have rings")
	ball.queue_free()

	var ib = MeshBuilderScript.build_item_box()
	assert_true(ib != null and ib.get_child_count() > 0, "Item box must have meshes")
	ib.queue_free()

	var p = MeshBuilderScript.build_pickup_mesh(0)
	assert_true(p != null and p.get_child_count() > 0, "Pickup mesh must have core and ring")
	p.queue_free()

	var crate = MeshBuilderScript.build_cyber_crate()
	assert_true(crate != null and crate.get_child_count() > 0, "Cyber crate must have meshes")
	crate.queue_free()
