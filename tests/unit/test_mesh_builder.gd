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
	test_subway_and_stadium()
	test_vehicle_classes()
	test_scenery_props()
	return {"passed": assertions_passed, "failed": assertions_failed}

func get_coverage_entries() -> Array:
	return [
		[
			"res://shared/graphics/mesh_builder.gd",
			[
				"build_pulse_rifle", "build_scatter_cannon", "build_rail_driver",
				"build_grenade_launcher", "build_plasma_cutter", "build_cyber_soldier",
				"build_crawler_mesh", "build_stalker_mesh", "build_brute_mesh",
				"build_spitter_mesh", "build_colossus_boss_mesh",
				"build_rocket_car", "build_rocket_sports_coupe", "build_rocket_rally_buggy",
				"build_rocket_muscle_gt", "build_rocket_cyber_ev",
				"build_drift_kart", "build_speed_demon_kart",
				"build_drift_king_kart", "build_turbo_tank_kart",
				"build_energy_ball", "build_item_box", "build_pickup_mesh",
				"build_cyber_crate", "build_subway_car_mesh", "build_stadium_goal_mesh",
				"build_race_gantry_mesh", "build_blast_door_mesh", "build_upgrade_kiosk_mesh",
				"build_boost_orb_mesh", "build_scrap_gear_mesh", "build_start_gantry",
				"build_ticket_turnstile", "build_subway_bench", "build_vending_machine",
				"build_stadium_grandstand", "build_stadium_floodlight_tower",
				"build_track_barrier", "build_grandstand_with_crowd",
				"build_racing_kart", "build_street_tuner", "build_offroad_buggy",
				"build_futuristic_ev", "build_formula_racer",
				"build_palm_tree", "build_pine_tree", "build_shipping_container",
				"build_harbor_crane", "build_neon_skyscraper", "build_rock_arch"
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

	var sp = MeshBuilderScript.build_spitter_mesh()
	assert_true(sp != null and sp.get_child_count() > 0, "Spitter must have parts")
	sp.queue_free()

	var boss = MeshBuilderScript.build_colossus_boss_mesh()
	assert_true(boss != null and boss.get_child_count() > 0, "Boss must have parts")
	boss.queue_free()

func test_vehicles() -> void:
	var car = MeshBuilderScript.build_rocket_car(0)
	assert_true(car != null and car.get_child_count() > 0, "Rocket car must have wheels and chassis")
	car.queue_free()

	var c1 = MeshBuilderScript.build_rocket_sports_coupe(0)
	assert_true(c1 != null and c1.get_child_count() > 0, "Sports coupe must build")
	c1.queue_free()

	var c2 = MeshBuilderScript.build_rocket_rally_buggy(1)
	assert_true(c2 != null and c2.get_child_count() > 0, "Rally buggy must build")
	c2.queue_free()

	var c3 = MeshBuilderScript.build_rocket_muscle_gt(0)
	assert_true(c3 != null and c3.get_child_count() > 0, "Muscle GT must build")
	c3.queue_free()

	var c4 = MeshBuilderScript.build_rocket_cyber_ev(1)
	assert_true(c4 != null and c4.get_child_count() > 0, "Cyber EV must build")
	c4.queue_free()

	var kart = MeshBuilderScript.build_drift_kart(Color.GREEN)
	assert_true(kart != null and kart.get_child_count() > 0, "Drift kart must have wheels and chassis")
	kart.queue_free()

	var k1 = MeshBuilderScript.build_speed_demon_kart()
	assert_true(k1 != null, "Speed demon kart must build")
	k1.queue_free()

	var k2 = MeshBuilderScript.build_drift_king_kart()
	assert_true(k2 != null, "Drift king kart must build")
	k2.queue_free()

	var k3 = MeshBuilderScript.build_turbo_tank_kart()
	assert_true(k3 != null, "Turbo tank kart must build")
	k3.queue_free()

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

	var orb = MeshBuilderScript.build_boost_orb_mesh()
	assert_true(orb != null and orb.get_child_count() > 0, "Boost orb must have parts")
	orb.queue_free()

	var gear = MeshBuilderScript.build_scrap_gear_mesh()
	assert_true(gear != null and gear.get_child_count() > 0, "Scrap gear must have parts")
	gear.queue_free()

	var kiosk = MeshBuilderScript.build_upgrade_kiosk_mesh()
	assert_true(kiosk != null and kiosk.get_child_count() > 0, "Upgrade kiosk must have parts")
	kiosk.queue_free()

func test_subway_and_stadium() -> void:
	var train = MeshBuilderScript.build_subway_car_mesh()
	assert_true(train != null and train.get_child_count() > 0, "Subway car must have parts")
	train.queue_free()

	var goal = MeshBuilderScript.build_stadium_goal_mesh(0)
	assert_true(goal != null and goal.get_child_count() > 0, "Goal mesh must have posts and net")
	goal.queue_free()

	var gantry = MeshBuilderScript.build_race_gantry_mesh()
	assert_true(gantry != null and gantry.get_child_count() > 0, "Race gantry must have towers and lamps")
	gantry.queue_free()

	var door = MeshBuilderScript.build_blast_door_mesh()
	assert_true(door != null and door.get_child_count() > 0, "Blast door must have frame and panel")
	door.queue_free()

	var start_g = MeshBuilderScript.build_start_gantry(14.0)
	assert_true(start_g != null and start_g.get_child_count() > 0, "Start gantry must have bridge and banner")
	start_g.queue_free()

func test_vehicle_classes() -> void:
	var vk1 = MeshBuilderScript.build_racing_kart(Color(1, 0.2, 0.2))
	assert_true(vk1 != null and vk1.get_child_count() > 0, "Racing kart mesh must build")
	vk1.queue_free()

	var vk2 = MeshBuilderScript.build_street_tuner(Color(0.2, 0.5, 1.0))
	assert_true(vk2 != null and vk2.get_child_count() > 0, "Street tuner mesh must build")
	vk2.queue_free()

	var vk3 = MeshBuilderScript.build_offroad_buggy(Color(0.9, 0.6, 0.1))
	assert_true(vk3 != null and vk3.get_child_count() > 0, "Offroad buggy mesh must build")
	vk3.queue_free()

	var vk4 = MeshBuilderScript.build_futuristic_ev(Color(0.1, 0.9, 0.8))
	assert_true(vk4 != null and vk4.get_child_count() > 0, "Futuristic EV mesh must build")
	vk4.queue_free()

	var vk5 = MeshBuilderScript.build_formula_racer(Color(0.8, 0.1, 0.9))
	assert_true(vk5 != null and vk5.get_child_count() > 0, "Formula racer mesh must build")
	vk5.queue_free()

func test_scenery_props() -> void:
	var p1 = MeshBuilderScript.build_palm_tree()
	assert_true(p1 != null and p1.get_child_count() > 0, "Palm tree prop must build")
	p1.queue_free()

	var p2 = MeshBuilderScript.build_pine_tree()
	assert_true(p2 != null and p2.get_child_count() > 0, "Pine tree prop must build")
	p2.queue_free()

	var p3 = MeshBuilderScript.build_shipping_container()
	assert_true(p3 != null and p3.get_child_count() > 0, "Shipping container prop must build")
	p3.queue_free()

	var p4 = MeshBuilderScript.build_harbor_crane()
	assert_true(p4 != null and p4.get_child_count() > 0, "Harbor crane prop must build")
	p4.queue_free()

	var p5 = MeshBuilderScript.build_neon_skyscraper(55.0, 18.0, 18.0, "neon_cyan")
	assert_true(p5 != null and p5.get_child_count() > 0, "Neon skyscraper prop must build")
	p5.queue_free()

	var p6 = MeshBuilderScript.build_rock_arch()
	assert_true(p6 != null and p6.get_child_count() > 0, "Rock arch prop must build")
	p6.queue_free()
