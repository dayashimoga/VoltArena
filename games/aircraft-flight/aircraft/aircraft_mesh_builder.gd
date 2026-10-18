class_name AircraftMeshBuilder
extends RefCounted

## AircraftMeshBuilder: Procedural 3D Aircraft Model & PBR Material Synthesizer.
## Constructs realistic, proportioned, highly detailed 3D aircraft models with
## contoured fuselages, canopies, wings, engines, animated control surfaces,
## retractable landing gear, spinning rotors/props, and PBR materials.

const ModelCache = preload("res://shared/graphics/model_cache.gd")

static func build_aircraft_visuals(aircraft_id: String, primary_col: Color, accent_col: Color) -> Node3D:
	match aircraft_id:
		"fa18_hornet":
			return build_fa18_hornet(primary_col, accent_col)
		"f22_raptor":
			return build_f22_raptor(primary_col, accent_col)
		"a320_airliner":
			return build_a320_airliner(primary_col, accent_col)
		"extra330_sport":
			return build_extra330_sport(primary_col, accent_col)
		"uh60_helicopter":
			return build_uh60_helicopter(primary_col, accent_col)
		_:
			return build_fa18_hornet(primary_col, accent_col)

static func build_aircraft_mesh(aircraft_id: String, primary_col: Color, accent_col: Color) -> Node3D:
	return build_aircraft_visuals(aircraft_id, primary_col, accent_col)

# ==============================================================================
# 1. F/A-18C HORNET (CARRIER MULTIROLE STRIKE FIGHTER)
# ==============================================================================

static func build_fa18_hornet(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "FA18Visuals"

	var model = ModelCache.get_model("res://assets/models/vehicles/aircraft_fighter.glb")
	if is_instance_valid(model):
		model.name = "AirframeModel"
		model.scale = Vector3(0.85, 0.85, 0.85)
		model.rotation.y = PI
		model.position = Vector3(0.0, -0.6, -2.5)
		root.add_child(model)

		var mat_glow = _create_emissive_material(Color(1.0, 0.55, 0.1), 8.5)
		var mat_dark = _create_pbr_material(Color(0.12, 0.13, 0.15), 0.90, 0.15, 0.80)

		# Articulated Control Surface Nodes
		var aileron_l = Node3D.new()
		aileron_l.name = "AileronLeft"
		aileron_l.position = Vector3(-4.6, 0.38, 2.15)
		root.add_child(aileron_l)

		var aileron_r = Node3D.new()
		aileron_r.name = "AileronRight"
		aileron_r.position = Vector3(4.6, 0.38, 2.15)
		root.add_child(aileron_r)

		var flap_l = Node3D.new()
		flap_l.name = "FlapLeft"
		flap_l.position = Vector3(-2.2, 0.38, 2.15)
		root.add_child(flap_l)

		var flap_r = Node3D.new()
		flap_r.name = "FlapRight"
		flap_r.position = Vector3(2.2, 0.38, 2.15)
		root.add_child(flap_r)

		var rudder_l = Node3D.new()
		rudder_l.name = "RudderLeft"
		rudder_l.position = Vector3(-1.15, 1.70, 2.7)
		root.add_child(rudder_l)

		var rudder_r = Node3D.new()
		rudder_r.name = "RudderRight"
		rudder_r.position = Vector3(1.15, 1.70, 2.7)
		root.add_child(rudder_r)

		var elev_l = Node3D.new()
		elev_l.name = "ElevatorLeft"
		elev_l.position = Vector3(-1.9, 0.28, 3.8)
		root.add_child(elev_l)

		var elev_r = Node3D.new()
		elev_r.name = "ElevatorRight"
		elev_r.position = Vector3(1.9, 0.28, 3.8)
		root.add_child(elev_r)

		# Dorsal Speedbrake (articulating)
		var speedbrake = _add_box(root, Vector3(0.55, 0.08, 1.4), Vector3(0.0, 0.85, 0.8), mat_dark)
		speedbrake.name = "Speedbrake"

		# Wingtip AIM-9 Sidewinder Missiles & Underwing Weapon Pylons
		var mat_white = _create_pbr_material(Color(0.92, 0.94, 0.96), 0.4, 0.1)
		_add_missile(root, Vector3(-5.8, 0.32, 0.9), mat_white, mat_dark)
		_add_missile(root, Vector3(5.8, 0.32, 0.9), mat_white, mat_dark)

		# Afterburner Plumes (translucent shock-diamond cones, initialized invisible)
		var ab_l = _add_cone(root, 0.42, 1.8, Vector3(-0.62, 0.36, 4.4), mat_glow)
		ab_l.rotation_degrees.x = -90.0
		ab_l.name = "AfterburnerPlumeLeft"
		ab_l.visible = false

		var ab_r = _add_cone(root, 0.42, 1.8, Vector3(0.62, 0.36, 4.4), mat_glow)
		ab_r.rotation_degrees.x = -90.0
		ab_r.name = "AfterburnerPlumeRight"
		ab_r.visible = false

		# Retractable Landing Gear assembly
		var gear_node = Node3D.new()
		gear_node.name = "LandingGear"
		_add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.70, -2.4), mat_dark)
		_add_wheel(gear_node, 0.22, 0.10, Vector3(-0.14, -1.40, -2.4), mat_dark)
		_add_wheel(gear_node, 0.22, 0.10, Vector3(0.14, -1.40, -2.4), mat_dark)
		for side in [-1.0, 1.0]:
			var mx = side * 1.45
			_add_cyl(gear_node, 0.10, 0.09, 1.5, Vector3(mx, -0.70, 0.9), mat_dark)
			_add_wheel(gear_node, 0.32, 0.16, Vector3(mx * 1.08, -1.40, 0.9), mat_dark)
		root.add_child(gear_node)
	else:
		_build_procedural_fa18(root, hull_color, accent_color)

	return root

static func _build_procedural_fa18(root: Node3D, hull_color: Color, accent_color: Color) -> Node3D:
	var mat_hull = _create_pbr_material(hull_color, 0.52, 0.45, 0.85)
	var mat_accent = _create_pbr_material(accent_color, 0.40, 0.60, 0.90)
	var mat_metal = _create_pbr_material(Color(0.20, 0.22, 0.25), 0.85, 0.25, 0.70)
	var mat_dark_metal = _create_pbr_material(Color(0.12, 0.13, 0.15), 0.90, 0.15, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.12, 0.18, 0.26, 0.60))
	var mat_glow = _create_emissive_material(Color(1.0, 0.55, 0.1), 8.5)
	var mat_white = _create_pbr_material(Color(0.92, 0.94, 0.96), 0.4, 0.1)

	# Forward Radome Nose Cone with Pitot Probe
	var nose = _add_cone(root, 0.65, 3.2, Vector3(0.0, 0.35, -4.8), mat_dark_metal)
	nose.rotation_degrees.x = 90.0
	_add_cyl(root, 0.02, 0.02, 0.8, Vector3(0.0, 0.35, -6.6), mat_metal).rotation_degrees.x = 90.0

	# Forward Fuselage (cockpit section)
	_add_box(root, Vector3(1.4, 1.15, 3.6), Vector3(0.0, 0.42, -2.4), mat_hull)
	# Mid Fuselage (wing carry-through box)
	_add_box(root, Vector3(2.0, 1.05, 4.2), Vector3(0.0, 0.40, 0.8), mat_hull)
	# Aft Fuselage (engine tunnels)
	_add_box(root, Vector3(1.85, 0.95, 3.2), Vector3(0.0, 0.38, 3.6), mat_hull)
	# Dorsal Avionics Spine
	_add_box(root, Vector3(0.65, 0.30, 4.8), Vector3(0.0, 0.95, -0.4), mat_hull)
	var speedbrake = _add_box(root, Vector3(0.55, 0.08, 1.4), Vector3(0.0, 1.10, 0.8), mat_dark_metal)
	speedbrake.name = "Speedbrake"

	# Cockpit & Canopy
	var canopy = _add_box(root, Vector3(0.78, 0.62, 2.8), Vector3(0.0, 0.98, -2.2), mat_canopy)
	canopy.name = "Canopy"
	_add_box(canopy, Vector3(0.82, 0.66, 0.12), Vector3(0.0, 0.0, -0.2), mat_hull)
	_add_box(root, Vector3(0.42, 0.70, 0.48), Vector3(0.0, 0.72, -2.0), mat_dark_metal)
	_add_box(root, Vector3(0.24, 0.22, 0.20), Vector3(0.0, 1.12, -2.0), _create_pbr_material(Color(0.85, 0.70, 0.1), 0.5, 0.2))
	_add_box(root, Vector3(0.25, 0.20, 0.04), Vector3(0.0, 0.98, -3.2), mat_canopy).rotation_degrees.x = -20.0

	# LEX
	var lex_l = _add_box(root, Vector3(0.95, 0.10, 3.4), Vector3(-1.15, 0.38, -1.2), mat_hull)
	lex_l.rotation_degrees.y = 12.0
	var lex_r = _add_box(root, Vector3(0.95, 0.10, 3.4), Vector3(1.15, 0.38, -1.2), mat_hull)
	lex_r.rotation_degrees.y = -12.0

	# Intakes
	var intake_l = _add_box(root, Vector3(0.65, 0.75, 2.6), Vector3(-1.18, 0.18, -0.6), mat_hull)
	_add_box(intake_l, Vector3(0.55, 0.65, 0.2), Vector3(0.0, 0.0, -1.3), mat_dark_metal)
	var intake_r = _add_box(root, Vector3(0.65, 0.75, 2.6), Vector3(1.18, 0.18, -0.6), mat_hull)
	_add_box(intake_r, Vector3(0.55, 0.65, 0.2), Vector3(0.0, 0.0, -1.3), mat_dark_metal)

	# Wings
	var wing_l = _add_box(root, Vector3(4.8, 0.12, 2.3), Vector3(-3.4, 0.38, 0.9), mat_hull)
	wing_l.rotation_degrees.z = -1.5
	var wing_r = _add_box(root, Vector3(4.8, 0.12, 2.3), Vector3(3.4, 0.38, 0.9), mat_hull)
	wing_r.rotation_degrees.z = 1.5

	_add_box(root, Vector3(0.12, 0.28, 1.8), Vector3(-2.6, 0.20, 0.8), mat_metal)
	_add_box(root, Vector3(0.12, 0.28, 1.8), Vector3(2.6, 0.20, 0.8), mat_metal)
	_add_box(root, Vector3(0.12, 0.12, 2.6), Vector3(-5.8, 0.38, 0.9), mat_metal)
	_add_box(root, Vector3(0.12, 0.12, 2.6), Vector3(5.8, 0.38, 0.9), mat_metal)
	_add_missile(root, Vector3(-5.8, 0.32, 0.9), mat_white, mat_dark_metal)
	_add_missile(root, Vector3(5.8, 0.32, 0.9), mat_white, mat_dark_metal)

	var aileron_l = _add_box(root, Vector3(2.1, 0.08, 0.55), Vector3(-4.6, 0.38, 2.15), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.1, 0.08, 0.55), Vector3(4.6, 0.38, 2.15), mat_accent)
	aileron_r.name = "AileronRight"

	var flap_l = _add_box(root, Vector3(2.2, 0.09, 0.65), Vector3(-2.2, 0.38, 2.15), mat_hull)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(2.2, 0.09, 0.65), Vector3(2.2, 0.38, 2.15), mat_hull)
	flap_r.name = "FlapRight"

	var fin_l = _add_box(root, Vector3(0.12, 2.5, 1.9), Vector3(-1.15, 1.70, 2.7), mat_accent)
	fin_l.rotation_degrees.z = -20.0
	var fin_r = _add_box(root, Vector3(0.12, 2.5, 1.9), Vector3(1.15, 1.70, 2.7), mat_accent)
	fin_r.rotation_degrees.z = 20.0
	_add_cyl(fin_l, 0.08, 0.08, 0.9, Vector3(0.0, 1.25, -0.3), mat_dark_metal).rotation_degrees.x = 90.0
	_add_cyl(fin_r, 0.08, 0.08, 0.9, Vector3(0.0, 1.25, -0.3), mat_dark_metal).rotation_degrees.x = 90.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 1.9, 0.48), Vector3(0.0, -0.1, 1.05), mat_hull)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 1.9, 0.48), Vector3(0.0, -0.1, 1.05), mat_hull)
	rudder_r.name = "RudderRight"

	var elev_l = _add_box(root, Vector3(2.2, 0.10, 1.5), Vector3(-1.9, 0.28, 3.8), mat_hull)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.2, 0.10, 1.5), Vector3(1.9, 0.28, 3.8), mat_hull)
	elev_r.name = "ElevatorRight"

	var eng_l = _add_cyl(root, 0.52, 0.48, 1.6, Vector3(-0.62, 0.36, 4.4), mat_metal)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 0.52, 0.48, 1.6, Vector3(0.62, 0.36, 4.4), mat_metal)
	eng_r.rotation_degrees.x = 90.0
	_add_cyl(eng_l, 0.46, 0.42, 0.4, Vector3(0.0, 0.9, 0.0), mat_dark_metal)
	_add_cyl(eng_r, 0.46, 0.42, 0.4, Vector3(0.0, 0.9, 0.0), mat_dark_metal)

	var ab_l = _add_cone(root, 0.42, 1.8, Vector3(-0.62, 0.36, 5.8), mat_glow)
	ab_l.rotation_degrees.x = -90.0
	ab_l.name = "AfterburnerPlumeLeft"
	ab_l.visible = false
	var ab_r = _add_cone(root, 0.42, 1.8, Vector3(0.62, 0.36, 5.8), mat_glow)
	ab_r.rotation_degrees.x = -90.0
	ab_r.name = "AfterburnerPlumeRight"
	ab_r.visible = false

	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	var nose_strut = _add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.70, -2.4), mat_metal)
	_add_box(nose_strut, Vector3(0.06, 0.4, 0.06), Vector3(0.0, -0.1, 0.12), mat_dark_metal)
	_add_wheel(gear_node, 0.22, 0.10, Vector3(-0.14, -1.40, -2.4), mat_dark_metal)
	_add_wheel(gear_node, 0.22, 0.10, Vector3(0.14, -1.40, -2.4), mat_dark_metal)
	for side in [-1.0, 1.0]:
		var mx = side * 1.45
		var m_strut = _add_cyl(gear_node, 0.10, 0.09, 1.5, Vector3(mx, -0.70, 0.9), mat_metal)
		m_strut.rotation_degrees.z = side * 10.0
		_add_wheel(gear_node, 0.32, 0.16, Vector3(mx * 1.08, -1.40, 0.9), mat_dark_metal)

	return root

# ==============================================================================
# 2. F-22A RAPTOR (5TH-GEN STEALTH AIR SUPERIORITY FIGHTER)
# ==============================================================================

static func build_f22_raptor(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "F22Visuals"

	var model = ModelCache.get_model("res://assets/models/vehicles/aircraft_f22.glb")
	if is_instance_valid(model):
		model.name = "AirframeModel"
		model.scale = Vector3(0.10, 0.10, 0.10)
		model.rotation.y = PI * 0.5
		model.position = Vector3(0.0, -0.8, -4.0)
		root.add_child(model)

		var mat_glow = _create_emissive_material(Color(0.2, 0.75, 1.0), 9.0)
		var mat_dark = _create_pbr_material(Color(0.10, 0.11, 0.13), 0.92, 0.10, 0.80)

		# 2D Thrust Vectoring Nozzles & Reheat Plumes
		var nozzle_l = Node3D.new()
		nozzle_l.name = "VectorNozzleLeft"
		nozzle_l.position = Vector3(-0.78, 0.32, 4.8)
		root.add_child(nozzle_l)

		var nozzle_r = Node3D.new()
		nozzle_r.name = "VectorNozzleRight"
		nozzle_r.position = Vector3(0.78, 0.32, 4.8)
		root.add_child(nozzle_r)

		var ab_l = _add_box(nozzle_l, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
		ab_l.name = "AfterburnerPlumeLeft"
		ab_l.visible = false

		var ab_r = _add_box(nozzle_r, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
		ab_r.name = "AfterburnerPlumeRight"
		ab_r.visible = false

		# Control Surfaces
		var aileron_l = Node3D.new()
		aileron_l.name = "AileronLeft"
		root.add_child(aileron_l)
		var aileron_r = Node3D.new()
		aileron_r.name = "AileronRight"
		root.add_child(aileron_r)

		var flap_l = Node3D.new()
		flap_l.name = "FlapLeft"
		root.add_child(flap_l)
		var flap_r = Node3D.new()
		flap_r.name = "FlapRight"
		root.add_child(flap_r)

		var rudder_l = Node3D.new()
		rudder_l.name = "RudderLeft"
		root.add_child(rudder_l)
		var rudder_r = Node3D.new()
		rudder_r.name = "RudderRight"
		root.add_child(rudder_r)

		var elev_l = Node3D.new()
		elev_l.name = "ElevatorLeft"
		root.add_child(elev_l)
		var elev_r = Node3D.new()
		elev_r.name = "ElevatorRight"
		root.add_child(elev_r)

		# Retractable Landing Gear assembly
		var gear_node = Node3D.new()
		gear_node.name = "LandingGear"
		_add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.72, -2.8), mat_dark)
		_add_wheel(gear_node, 0.24, 0.12, Vector3(0.0, -1.45, -2.8), mat_dark)
		for side in [-1.0, 1.0]:
			var mx = side * 1.65
			_add_cyl(gear_node, 0.10, 0.09, 1.5, Vector3(mx, -0.72, 1.1), mat_dark)
			_add_wheel(gear_node, 0.32, 0.18, Vector3(mx, -1.45, 1.1), mat_dark)
		root.add_child(gear_node)
	else:
		_build_procedural_f22(root, hull_color, accent_color)

	return root

static func _build_procedural_f22(root: Node3D, hull_color: Color, accent_color: Color) -> Node3D:
	var mat_stealth = _create_pbr_material(hull_color, 0.60, 0.45, 0.95)
	var mat_accent = _create_pbr_material(accent_color, 0.55, 0.35, 0.85)
	var mat_metal = _create_pbr_material(Color(0.16, 0.18, 0.20), 0.88, 0.20, 0.75)
	var mat_dark = _create_pbr_material(Color(0.10, 0.11, 0.13), 0.92, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.28, 0.22, 0.12, 0.65))
	var mat_glow = _create_emissive_material(Color(0.2, 0.75, 1.0), 9.0)

	var nose = _add_cone(root, 0.80, 3.6, Vector3(0.0, 0.30, -5.4), mat_stealth)
	nose.rotation_degrees.x = 90.0
	_add_box(root, Vector3(1.8, 0.95, 3.8), Vector3(0.0, 0.38, -2.6), mat_stealth)
	_add_box(root, Vector3(2.6, 0.90, 4.6), Vector3(0.0, 0.34, 0.6), mat_stealth)
	_add_box(root, Vector3(2.4, 0.80, 3.8), Vector3(0.0, 0.32, 3.8), mat_stealth)

	var canopy = _add_box(root, Vector3(0.88, 0.64, 2.8), Vector3(0.0, 0.92, -2.4), mat_canopy)
	canopy.name = "Canopy"
	_add_box(root, Vector3(0.44, 0.68, 0.46), Vector3(0.0, 0.68, -2.2), mat_dark)
	_add_box(root, Vector3(0.24, 0.22, 0.20), Vector3(0.0, 1.08, -2.2), _create_pbr_material(Color(0.2, 0.6, 0.3), 0.4, 0.2))

	var intake_l = _add_box(root, Vector3(0.85, 0.80, 2.8), Vector3(-1.35, 0.18, -1.0), mat_stealth)
	intake_l.rotation_degrees.z = -15.0
	_add_box(intake_l, Vector3(0.70, 0.65, 0.2), Vector3(0.0, 0.0, -1.4), mat_dark)
	var intake_r = _add_box(root, Vector3(0.85, 0.80, 2.8), Vector3(1.35, 0.18, -1.0), mat_stealth)
	intake_r.rotation_degrees.z = 15.0
	_add_box(intake_r, Vector3(0.70, 0.65, 0.2), Vector3(0.0, 0.0, -1.4), mat_dark)

	var wing_l = _add_box(root, Vector3(5.6, 0.12, 3.6), Vector3(-3.8, 0.34, 0.8), mat_stealth)
	var wing_r = _add_box(root, Vector3(5.6, 0.12, 3.6), Vector3(3.8, 0.34, 0.8), mat_stealth)

	var aileron_l = _add_box(root, Vector3(2.6, 0.08, 0.65), Vector3(-4.8, 0.34, 2.5), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.6, 0.08, 0.65), Vector3(4.8, 0.34, 2.5), mat_accent)
	aileron_r.name = "AileronRight"

	var flap_l = _add_box(root, Vector3(2.2, 0.09, 0.70), Vector3(-2.2, 0.34, 2.5), mat_stealth)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(2.2, 0.09, 0.70), Vector3(2.2, 0.34, 2.5), mat_stealth)
	flap_r.name = "FlapRight"

	var fin_l = _add_box(root, Vector3(0.12, 2.7, 2.4), Vector3(-1.35, 1.78, 2.8), mat_accent)
	fin_l.rotation_degrees.z = -28.0
	var fin_r = _add_box(root, Vector3(0.12, 2.7, 2.4), Vector3(1.35, 1.78, 2.8), mat_accent)
	fin_r.rotation_degrees.z = 28.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 2.1, 0.55), Vector3(0.0, -0.1, 1.25), mat_stealth)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 2.1, 0.55), Vector3(0.0, -0.1, 1.25), mat_stealth)
	rudder_r.name = "RudderRight"

	var elev_l = _add_box(root, Vector3(2.5, 0.10, 1.8), Vector3(-2.3, 0.28, 4.2), mat_stealth)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.5, 0.10, 1.8), Vector3(2.3, 0.28, 4.2), mat_stealth)
	elev_r.name = "ElevatorRight"

	var nozzle_l = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(-0.78, 0.32, 4.8), mat_dark)
	nozzle_l.name = "VectorNozzleLeft"
	var nozzle_r = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(0.78, 0.32, 4.8), mat_dark)
	nozzle_r.name = "VectorNozzleRight"

	_add_box(nozzle_l, Vector3(0.88, 0.48, 0.15), Vector3(0.0, 0.0, 0.6), mat_metal)
	_add_box(nozzle_r, Vector3(0.88, 0.48, 0.15), Vector3(0.0, 0.0, 0.6), mat_metal)

	var ab_l = _add_box(nozzle_l, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
	ab_l.name = "AfterburnerPlumeLeft"
	ab_l.visible = false
	var ab_r = _add_box(nozzle_r, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
	ab_r.name = "AfterburnerPlumeRight"
	ab_r.visible = false

	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.72, -2.8), mat_metal)
	_add_wheel(gear_node, 0.24, 0.12, Vector3(0.0, -1.45, -2.8), mat_dark)
	for side in [-1.0, 1.0]:
		var mx = side * 1.65
		_add_cyl(gear_node, 0.10, 0.09, 1.5, Vector3(mx, -0.72, 1.1), mat_metal)
		_add_wheel(gear_node, 0.32, 0.18, Vector3(mx, -1.45, 1.1), mat_dark)

	return root

# ==============================================================================
# 3. A320 AIRLINER (COMMERCIAL TWIN-JET TRANSPORT)
# ==============================================================================

static func build_a320_airliner(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "A320Visuals"

	var model = ModelCache.get_model("res://assets/models/vehicles/aircraft_a320.glb")
	if is_instance_valid(model):
		model.name = "AirframeModel"
		# Orient: model nose points along +X, rotate -90 deg around Y to align with Godot -Z
		model.rotation_degrees.y = -90.0
		model.position = Vector3(0.0, -0.6, 1.5)
		model.scale = Vector3(0.60, 0.60, 0.60)
		root.add_child(model)

		_ensure_double_sided_materials(model)

		# Articulated Fowler Flaps (0 deg - 40 deg)
		var flap_l = Node3D.new()
		flap_l.name = "FlapLeft"
		flap_l.position = Vector3(-6.2, 0.2, 1.8)
		root.add_child(flap_l)

		var flap_r = Node3D.new()
		flap_r.name = "FlapRight"
		flap_r.position = Vector3(6.2, 0.2, 1.8)
		root.add_child(flap_r)

		# Articulated Ailerons & Rudders
		var aileron_l = Node3D.new()
		aileron_l.name = "AileronLeft"
		aileron_l.position = Vector3(-9.5, 0.35, 2.8)
		root.add_child(aileron_l)

		var aileron_r = Node3D.new()
		aileron_r.name = "AileronRight"
		aileron_r.position = Vector3(9.5, 0.35, 2.8)
		root.add_child(aileron_r)

		var rudder_l = Node3D.new()
		rudder_l.name = "RudderLeft"
		rudder_l.position = Vector3(0.0, 3.5, 9.2)
		root.add_child(rudder_l)

		var rudder_r = Node3D.new()
		rudder_r.name = "RudderRight"
		rudder_r.position = Vector3(0.0, 3.5, 9.2)
		root.add_child(rudder_r)

		var elev_l = Node3D.new()
		elev_l.name = "ElevatorLeft"
		elev_l.position = Vector3(-2.8, 1.4, 10.5)
		root.add_child(elev_l)

		var elev_r = Node3D.new()
		elev_r.name = "ElevatorRight"
		elev_r.position = Vector3(2.8, 1.4, 10.5)
		root.add_child(elev_r)

		# Spinning N1 turbofan disks inside CFM LEAP engine nacelles
		var fan_mat = _create_prop_blur_material(16)
		var fan_l = _add_disc(root, 0.85, Vector3(-4.8, -0.45, -0.8), fan_mat)
		fan_l.name = "FanBladesLeft"
		var fan_r = _add_disc(root, 0.85, Vector3(4.8, -0.45, -0.8), fan_mat)
		fan_r.name = "FanBladesRight"

		# Retractable Landing Gear assembly
		var gear_node = Node3D.new()
		gear_node.name = "LandingGear"
		root.add_child(gear_node)

		return root
	else:
		return _build_procedural_a320(root, hull_color, accent_color)

static func _ensure_double_sided_materials(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for s in range(node.mesh.get_surface_count()):
			var mat = node.get_surface_override_material(s)
			if not mat:
				mat = node.mesh.surface_get_material(s)
			if mat and mat is BaseMaterial3D:
				var dup = mat.duplicate() as BaseMaterial3D
				dup.cull_mode = BaseMaterial3D.CULL_DISABLED
				node.set_surface_override_material(s, dup)
	for child in node.get_children():
		_ensure_double_sided_materials(child)

static func _build_procedural_a320(root: Node3D, hull_color: Color, accent_color: Color) -> Node3D:
	var mat_hull = _create_pbr_material(hull_color, 0.20, 0.15, 0.95)
	var mat_accent = _create_pbr_material(accent_color, 0.30, 0.25, 0.90)
	var mat_metal = _create_pbr_material(Color(0.28, 0.30, 0.34), 0.78, 0.30, 0.75)
	var mat_dark = _create_pbr_material(Color(0.12, 0.13, 0.15), 0.90, 0.10, 0.80)
	var mat_window = _create_pbr_material(Color(0.06, 0.10, 0.16), 0.92, 0.05, 1.0)
	var mat_chrome = _create_pbr_material(Color(0.85, 0.88, 0.92), 0.95, 0.10, 0.90)

	var cabin = _add_cyl(root, 1.95, 1.95, 20.0, Vector3(0.0, 1.2, 0.0), mat_hull)
	cabin.rotation_degrees.x = 90.0

	var nose = _add_sphere(root, 1.94, Vector3(0.0, 1.2, -10.0), mat_hull)
	nose.scale = Vector3(1.0, 0.95, 1.4)

	var tail_cone = _add_cone(root, 1.94, 6.5, Vector3(0.0, 1.6, 12.8), mat_hull)
	tail_cone.rotation_degrees.x = -90.0
	_add_cyl(root, 0.15, 0.15, 0.4, Vector3(0.0, 1.9, 16.2), mat_dark).rotation_degrees.x = 90.0

	var cockpit_glass = _add_box(root, Vector3(1.5, 0.55, 1.0), Vector3(0.0, 2.15, -9.2), mat_window)
	cockpit_glass.rotation_degrees.x = 18.0
	cockpit_glass.name = "Canopy"

	_add_box(root, Vector3(3.96, 0.18, 16.5), Vector3(0.0, 1.55, -0.5), mat_window)
	_add_box(root, Vector3(3.98, 0.35, 18.5), Vector3(0.0, 1.15, -0.5), mat_accent)

	_add_box(root, Vector3(3.98, 1.4, 0.8), Vector3(0.0, 1.2, -8.0), mat_accent)
	_add_box(root, Vector3(3.98, 1.4, 0.8), Vector3(0.0, 1.2, 8.5), mat_accent)

	var wing_l = _add_box(root, Vector3(14.5, 0.28, 3.4), Vector3(-9.2, 0.45, 0.6), mat_hull)
	wing_l.rotation_degrees.z = 4.5
	var wing_r = _add_box(root, Vector3(14.5, 0.28, 3.4), Vector3(9.2, 0.45, 0.6), mat_hull)
	wing_r.rotation_degrees.z = -4.5

	_add_box(root, Vector3(4.8, 0.65, 6.5), Vector3(0.0, 0.45, 0.6), mat_hull)

	var sharklet_l = _add_box(root, Vector3(0.12, 1.8, 1.2), Vector3(-16.4, 1.7, 1.0), mat_accent)
	sharklet_l.rotation_degrees.z = -8.0
	var sharklet_r = _add_box(root, Vector3(0.12, 1.8, 1.2), Vector3(16.4, 1.7, 1.0), mat_accent)
	sharklet_r.rotation_degrees.z = 8.0

	var aileron_l = _add_box(root, Vector3(4.2, 0.12, 0.65), Vector3(-13.4, 0.95, 2.2), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(4.2, 0.12, 0.65), Vector3(13.4, 0.95, 2.2), mat_accent)
	aileron_r.name = "AileronRight"

	var flap_l = _add_box(root, Vector3(7.2, 0.16, 0.95), Vector3(-5.8, 0.35, 2.2), mat_metal)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(7.2, 0.16, 0.95), Vector3(5.8, 0.35, 2.2), mat_metal)
	flap_r.name = "FlapRight"

	var sp_l = _add_box(root, Vector3(5.5, 0.08, 0.65), Vector3(-6.0, 0.55, 0.8), mat_metal)
	sp_l.name = "SpoilerLeft"
	var sp_r = _add_box(root, Vector3(5.5, 0.08, 0.65), Vector3(6.0, 0.55, 0.8), mat_metal)
	sp_r.name = "SpoilerRight"

	for fx in [-4.0, -7.0, 4.0, 7.0]:
		var canoe = _add_cyl(root, 0.18, 0.12, 2.4, Vector3(fx, 0.15, 2.0), mat_hull)
		canoe.rotation_degrees.x = 90.0

	for side in [-1.0, 1.0]:
		var ex = side * 5.4
		_add_box(root, Vector3(0.25, 0.95, 2.8), Vector3(ex, 0.25, -0.6), mat_metal)
		var nacelle = _add_cyl(root, 1.25, 1.25, 4.2, Vector3(ex, -0.45, -0.8), mat_hull)
		nacelle.rotation_degrees.x = 90.0
		var lip = _add_cyl(root, 1.28, 1.22, 0.3, Vector3(ex, -0.45, -2.9), mat_chrome)
		lip.rotation_degrees.x = 90.0
		var fan = _add_cyl(root, 1.10, 1.10, 0.2, Vector3(ex, -0.45, -2.7), mat_metal)
		fan.rotation_degrees.x = 90.0
		fan.name = "FanBladesLeft" if side < 0 else "FanBladesRight"
		var spinner = _add_cone(fan, 0.32, 0.6, Vector3(0.0, 0.2, 0.0), mat_dark)
		var core = _add_cone(root, 0.55, 0.8, Vector3(ex, -0.45, 1.6), mat_dark)
		core.rotation_degrees.x = -90.0

	var fin = _add_box(root, Vector3(0.28, 5.2, 4.2), Vector3(0.0, 4.6, 11.2), mat_accent)
	fin.rotation_degrees.x = -12.0
	var rudder = _add_box(fin, Vector3(0.30, 4.4, 1.2), Vector3(0.0, -0.2, 2.4), mat_hull)
	rudder.name = "RudderLeft"
	var rudder_r = _add_box(fin, Vector3(0.30, 4.4, 1.2), Vector3(0.0, -0.2, 2.4), mat_hull)
	rudder_r.name = "RudderRight"

	var htail_l = _add_box(root, Vector3(5.2, 0.16, 2.2), Vector3(-3.2, 2.4, 12.6), mat_hull)
	htail_l.name = "ElevatorLeft"
	var htail_r = _add_box(root, Vector3(5.2, 0.16, 2.2), Vector3(3.2, 2.4, 12.6), mat_hull)
	htail_r.name = "ElevatorRight"

	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_cyl(gear_node, 0.12, 0.12, 2.2, Vector3(0.0, -0.25, -7.5), mat_metal)
	_add_wheel(gear_node, 0.38, 0.16, Vector3(-0.24, -1.35, -7.5), mat_dark)
	_add_wheel(gear_node, 0.38, 0.16, Vector3(0.24, -1.35, -7.5), mat_dark)
	for side in [-1.0, 1.0]:
		var mx = side * 3.8
		_add_cyl(gear_node, 0.18, 0.18, 2.4, Vector3(mx, -0.40, 1.2), mat_metal)
		_add_wheel(gear_node, 0.52, 0.22, Vector3(mx - 0.30, -1.50, 1.2), mat_dark)
		_add_wheel(gear_node, 0.52, 0.22, Vector3(mx + 0.30, -1.50, 1.2), mat_dark)

	return root

static func build_extra330_sport(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "Extra330Visuals"
	return _build_procedural_extra330(root, hull_color, accent_color)

static func _build_procedural_extra330(root: Node3D, hull_color: Color, accent_color: Color) -> Node3D:
	var mat_hull = _create_pbr_material(hull_color, 0.18, 0.20, 0.95)
	var mat_accent = _create_pbr_material(accent_color, 0.22, 0.25, 0.90)
	var mat_metal = _create_pbr_material(Color(0.20, 0.22, 0.25), 0.85, 0.20, 0.70)
	var mat_dark = _create_pbr_material(Color(0.10, 0.11, 0.12), 0.90, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.12, 0.18, 0.28, 0.50))
	var mat_white = _create_pbr_material(Color(0.95, 0.95, 0.95), 0.3, 0.1)

	# 1. Streamlined Composite Fuselage (Contoured NACA Cowling + Tapered Tail Boom)
	var cowl = _add_cyl(root, 0.44, 0.48, 1.35, Vector3(0.0, 0.30, -2.4), mat_accent)
	cowl.rotation_degrees.x = 90.0

	var nose_cap = _add_sphere(root, 0.45, Vector3(0.0, 0.30, -3.05), mat_accent)
	nose_cap.scale = Vector3(0.98, 0.98, 0.5)

	# Mid-fuselage cockpit section
	var mid_body = _add_cyl(root, 0.48, 0.44, 2.2, Vector3(0.0, 0.30, -0.65), mat_hull)
	mid_body.rotation_degrees.x = 90.0
	mid_body.scale = Vector3(0.95, 1.15, 1.0)

	# Slender tapered tail boom extending to empennage
	var tail_boom = _add_cone(root, 0.44, 2.8, Vector3(0.0, 0.32, 1.8), mat_hull)
	tail_boom.rotation_degrees.x = -90.0
	tail_boom.scale = Vector3(0.90, 1.10, 1.0)

	# Engine air intakes & tuned exhaust pipes
	_add_box(root, Vector3(0.20, 0.12, 0.28), Vector3(-0.24, 0.30, -3.1), mat_dark)
	_add_box(root, Vector3(0.20, 0.12, 0.28), Vector3(0.24, 0.30, -3.1), mat_dark)
	_add_cyl(root, 0.045, 0.045, 0.55, Vector3(-0.35, -0.06, -1.8), mat_metal).rotation_degrees.x = 45.0
	_add_cyl(root, 0.045, 0.045, 0.55, Vector3(0.35, -0.06, -1.8), mat_metal).rotation_degrees.x = 45.0

	# 2. Aerodynamic Teardrop Bubble Canopy with Cockpit Interior & Pilot
	var canopy = _add_sphere(root, 0.42, Vector3(0.0, 0.65, -0.45), mat_canopy)
	canopy.name = "Canopy"
	canopy.scale = Vector3(0.85, 0.75, 2.4)

	# Cockpit tub interior & instrument coaming
	_add_box(root, Vector3(0.38, 0.35, 1.4), Vector3(0.0, 0.45, -0.45), mat_dark)
	_add_box(root, Vector3(0.36, 0.22, 0.15), Vector3(0.0, 0.58, -1.1), mat_dark)
	# Pilot helmet & torso
	_add_sphere(root, 0.14, Vector3(0.0, 0.72, -0.15), _create_pbr_material(Color(0.95, 0.20, 0.15), 0.2, 0.2))
	_add_box(root, Vector3(0.32, 0.30, 0.22), Vector3(0.0, 0.50, -0.15), mat_dark)
	# Control stick
	var stick = _add_cyl(root, 0.015, 0.015, 0.28, Vector3(0.0, 0.52, -0.45), mat_metal)
	stick.rotation_degrees.x = -15.0

	# 3. 3-Blade Curved Scimitar Propeller paired with Motion Blur Disk Shader
	var prop_root = Node3D.new()
	prop_root.name = "Propeller"
	prop_root.position = Vector3(0.0, 0.30, -3.15)
	root.add_child(prop_root)

	var spinner = _add_cone(prop_root, 0.28, 0.65, Vector3(0.0, 0.0, -0.18), mat_metal)
	spinner.rotation_degrees.x = 90.0

	for i in range(3):
		var blade_root = Node3D.new()
		blade_root.rotation_degrees.z = i * 120.0
		prop_root.add_child(blade_root)

		var blade = _add_box(blade_root, Vector3(0.08, 1.10, 0.04), Vector3(0.0, 0.58, 0.0), mat_dark)
		blade.rotation_degrees.y = 15.0
		_add_box(blade, Vector3(0.09, 0.20, 0.05), Vector3(0.0, 0.46, 0.0), _create_pbr_material(Color(0.96, 0.85, 0.1), 0.3, 0.1))

	var blur_mat = _create_prop_blur_material(3)
	var blur_disk = _add_disc(prop_root, 1.20, Vector3(0.0, 0.0, -0.05), blur_mat)
	blur_disk.name = "PropBlurDisk"
	blur_disk.visible = false

	# 4. Aerobatic Wings, Spade Ailerons & Wingtip Triangle Sight Devices
	_add_box(root, Vector3(7.2, 0.10, 1.45), Vector3(0.0, 0.25, -0.3), mat_hull)

	var aileron_l = _add_box(root, Vector3(3.0, 0.07, 0.45), Vector3(-2.1, 0.25, 0.55), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(3.0, 0.07, 0.45), Vector3(2.1, 0.25, 0.55), mat_accent)
	aileron_r.name = "AileronRight"

	_add_box(aileron_l, Vector3(0.25, 0.04, 0.30), Vector3(0.0, -0.20, -0.15), mat_metal)
	_add_box(aileron_r, Vector3(0.25, 0.04, 0.30), Vector3(0.0, -0.20, -0.15), mat_metal)

	_add_box(root, Vector3(0.04, 0.25, 0.35), Vector3(-3.65, 0.25, -0.3), mat_white)
	_add_box(root, Vector3(0.04, 0.25, 0.35), Vector3(3.65, 0.25, -0.3), mat_white)

	# 5. Vertical Fin & Oversized Aerobatic Rudder
	var fin = _add_box(root, Vector3(0.09, 1.4, 1.1), Vector3(0.0, 1.05, 2.3), mat_hull)
	var rudder = _add_box(fin, Vector3(0.11, 1.6, 0.75), Vector3(0.0, -0.1, 0.85), mat_accent)
	rudder.name = "RudderLeft"
	var rudder_r = _add_box(fin, Vector3(0.11, 1.6, 0.75), Vector3(0.0, -0.1, 0.85), mat_accent)
	rudder_r.name = "RudderRight"

	# Horizontal Stabilizers & Elevators
	var elev_l = _add_box(root, Vector3(1.3, 0.07, 0.70), Vector3(-0.75, 0.38, 2.6), mat_accent)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(1.3, 0.07, 0.70), Vector3(0.75, 0.38, 2.6), mat_accent)
	elev_r.name = "ElevatorRight"

	# 6. Sculpted Carbon Fiber Main Gear Legs with Flush Teardrop Wheel Pants (ZERO FLOATING BOXES!)
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	for side in [-1.0, 1.0]:
		var gx = side * 1.05
		# Main carbon gear leg swept down and outward from belly to wheel center
		var strut = _add_box(gear_node, Vector3(0.06, 0.76, 0.14), Vector3(gx * 0.65, -0.28, -1.05), mat_metal)
		strut.rotation_degrees.z = -side * 26.0
		strut.rotation_degrees.x = -6.0

		# Aerodynamic teardrop wheel spat/pant attaching FLUSH to the carbon leg
		var spat = Node3D.new()
		spat.position = Vector3(gx, -0.66, -1.05)
		spat.rotation_degrees.x = -4.0
		gear_node.add_child(spat)

		# Teardrop sculpted wheel pant
		var spat_body = _add_sphere(spat, 0.20, Vector3(0.0, 0.0, -0.08), mat_accent)
		spat_body.scale = Vector3(0.9, 1.25, 2.0)
		var spat_tail = _add_cone(spat, 0.20, 0.50, Vector3(0.0, 0.0, 0.32), mat_accent)
		spat_tail.rotation_degrees.x = -90.0

		# Flush collar blending leg seamlessly into pant
		var spat_collar = _add_box(spat, Vector3(0.12, 0.18, 0.24), Vector3(0.0, 0.14, -0.02), mat_accent)
		spat_collar.rotation_degrees.z = -side * 14.0

		# Recessed main tire nestled cleanly inside pant
		_add_wheel(spat, 0.17, 0.09, Vector3(0.0, -0.06, 0.0), mat_dark)

	# Steerable Tailwheel assembly
	var tailwheel_strut = _add_cyl(gear_node, 0.03, 0.03, 0.35, Vector3(0.0, 0.0, 2.3), mat_metal)
	tailwheel_strut.rotation_degrees.x = -45.0
	_add_wheel(gear_node, 0.09, 0.05, Vector3(0.0, -0.22, 2.45), mat_dark)

	return root

static func build_uh60_helicopter(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "UH60Visuals"

	var model = ModelCache.get_model("res://assets/models/vehicles/aircraft_helicopter.glb")
	if is_instance_valid(model):
		model.name = "AirframeModel"
		model.scale = Vector3(1.0, 1.0, 1.0)
		model.rotation.y = PI
		model.position = Vector3(0.0, 0.0, 0.0)
		root.add_child(model)

		# Bind or alias main and tail rotor nodes
		var glb_main = model.find_child("AW101_propellar", true, false)
		if glb_main:
			glb_main.name = "MainRotor"
		else:
			var mr = Node3D.new()
			mr.name = "MainRotor"
			root.add_child(mr)

		var glb_tail = model.find_child("AW101_backrotor", true, false)
		if glb_tail:
			glb_tail.name = "TailRotor"
		else:
			var tr = Node3D.new()
			tr.name = "TailRotor"
			root.add_child(tr)

		var mat_metal = _create_pbr_material(Color(0.18, 0.20, 0.22), 0.80, 0.25, 0.70)
		var mat_dark = _create_pbr_material(Color(0.10, 0.12, 0.14), 0.90, 0.10, 0.80)

		# External Rescue Hoist Boom
		var hoist = _add_box(root, Vector3(0.12, 0.12, 1.4), Vector3(1.15, 1.85, -1.8), mat_metal)
		hoist.name = "RescueHoist"
		_add_cyl(hoist, 0.16, 0.16, 0.35, Vector3(0.0, -0.15, -0.5), mat_dark).rotation_degrees.x = 90.0

		# Rotor Motion Blur Disks
		var main_blur_mat = _create_prop_blur_material(4)
		var main_blur = _add_disc(root, 8.2, Vector3(0.0, 3.2, -0.4), main_blur_mat)
		main_blur.rotation_degrees.x = 90.0
		main_blur.name = "MainRotorBlur"
		main_blur.visible = false

		var tail_blur_mat = _create_prop_blur_material(4)
		var tail_blur = _add_disc(root, 1.6, Vector3(0.35, 2.65, 9.0), tail_blur_mat)
		tail_blur.rotation_degrees.y = 90.0
		tail_blur.name = "TailRotorBlur"
		tail_blur.visible = false

		var elev_l = Node3D.new()
		elev_l.name = "ElevatorLeft"
		root.add_child(elev_l)
		var elev_r = Node3D.new()
		elev_r.name = "ElevatorRight"
		root.add_child(elev_r)

		# Rugged Fixed Landing Gear
		var gear_node = Node3D.new()
		gear_node.name = "LandingGear"
		for side in [-1.0, 1.0]:
			var gx = side * 1.35
			var strut = _add_cyl(gear_node, 0.12, 0.10, 1.5, Vector3(gx, -0.45, -0.5), mat_metal)
			strut.rotation_degrees.z = side * 12.0
			_add_wheel(gear_node, 0.38, 0.22, Vector3(gx * 1.15, -1.15, -0.5), mat_dark)
		var tw_strut = _add_cyl(gear_node, 0.08, 0.08, 0.9, Vector3(0.0, 0.25, 6.5), mat_metal)
		_add_wheel(gear_node, 0.24, 0.14, Vector3(0.0, -0.35, 6.5), mat_dark)
		root.add_child(gear_node)
	else:
		_build_procedural_uh60(root, hull_color, accent_color)

	return root

static func _build_procedural_uh60(root: Node3D, hull_color: Color, accent_color: Color) -> Node3D:
	var mat_hull = _create_pbr_material(hull_color, 0.82, 0.20, 0.10)
	var mat_accent = _create_pbr_material(accent_color, 0.70, 0.25, 0.30)
	var mat_metal = _create_pbr_material(Color(0.18, 0.20, 0.22), 0.80, 0.25, 0.70)
	var mat_dark = _create_pbr_material(Color(0.10, 0.12, 0.14), 0.90, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.08, 0.12, 0.16, 0.75))

	var cockpit = _add_box(root, Vector3(1.85, 1.25, 1.8), Vector3(0.0, 0.75, -3.1), mat_canopy)
	cockpit.name = "Canopy"
	_add_box(cockpit, Vector3(0.10, 1.30, 1.82), Vector3(0.0, 0.0, 0.0), mat_hull)

	_add_box(root, Vector3(2.15, 1.75, 5.2), Vector3(0.0, 0.75, 0.2), mat_hull)
	_add_box(root, Vector3(2.20, 1.30, 1.8), Vector3(0.0, 0.70, 0.4), mat_accent)

	_add_sphere(root, 0.28, Vector3(0.0, 0.15, -4.2), mat_dark)
	_add_box(root, Vector3(0.04, 0.35, 0.25), Vector3(0.0, 1.55, -2.8), mat_metal)

	var eng_l = _add_cyl(root, 0.52, 0.52, 3.2, Vector3(-0.85, 1.65, -0.6), mat_hull)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 0.52, 0.52, 3.2, Vector3(0.85, 1.65, -0.6), mat_hull)
	eng_r.rotation_degrees.x = 90.0

	var exh_l = _add_box(root, Vector3(0.55, 0.45, 0.8), Vector3(-0.95, 1.75, 1.2), mat_dark)
	exh_l.rotation_degrees.y = -25.0
	var exh_r = _add_box(root, Vector3(0.55, 0.45, 0.8), Vector3(0.95, 1.75, 1.2), mat_dark)
	exh_r.rotation_degrees.y = 25.0

	_add_box(root, Vector3(1.2, 0.65, 2.6), Vector3(0.0, 1.85, -0.5), mat_hull)

	var mast = _add_cyl(root, 0.22, 0.22, 0.8, Vector3(0.0, 2.25, -0.4), mat_metal)
	var rotor_root = Node3D.new()
	rotor_root.name = "MainRotor"
	rotor_root.position = Vector3(0.0, 2.65, -0.4)
	root.add_child(rotor_root)
	_add_cyl(rotor_root, 0.55, 0.55, 0.25, Vector3(0.0, 0.0, 0.0), mat_dark)

	for i in range(4):
		var blade_root = Node3D.new()
		blade_root.rotation_degrees.y = i * 90.0
		rotor_root.add_child(blade_root)
		_add_box(blade_root, Vector3(0.24, 0.12, 0.8), Vector3(0.0, 0.0, 0.6), mat_metal)
		var blade = _add_box(blade_root, Vector3(0.26, 0.06, 7.2), Vector3(0.0, 0.0, 4.4), mat_metal)
		var tip = _add_box(blade, Vector3(0.22, 0.04, 0.8), Vector3(0.0, -0.04, 3.8), mat_dark)
		tip.rotation_degrees.y = -20.0

	_add_box(root, Vector3(0.75, 0.75, 6.4), Vector3(0.0, 0.95, 5.8), mat_hull)
	var pylon = _add_box(root, Vector3(0.24, 2.1, 1.4), Vector3(0.0, 2.0, 8.8), mat_hull)

	var tail_rotor_root = Node3D.new()
	tail_rotor_root.name = "TailRotor"
	tail_rotor_root.position = Vector3(0.28, 2.65, 9.0)
	root.add_child(tail_rotor_root)
	tail_rotor_root.rotation_degrees.z = 20.0

	_add_cyl(tail_rotor_root, 0.18, 0.18, 0.15, Vector3(0.0, 0.0, 0.0), mat_metal).rotation_degrees.z = 90.0
	for i in range(4):
		var t_blade = _add_box(tail_rotor_root, Vector3(0.06, 1.35, 0.04), Vector3(0.0, 0.70, 0.0), mat_metal)
		t_blade.rotation_degrees.x = i * 90.0

	var stab = _add_box(root, Vector3(3.6, 0.10, 0.95), Vector3(0.0, 0.90, 8.6), mat_accent)
	stab.name = "ElevatorLeft"
	var stab_r = _add_box(root, Vector3(3.6, 0.10, 0.95), Vector3(0.0, 0.90, 8.6), mat_accent)
	stab_r.name = "ElevatorRight"

	var hoist = _add_box(root, Vector3(0.12, 0.12, 1.4), Vector3(1.15, 1.85, -1.8), mat_metal)
	hoist.name = "RescueHoist"
	_add_cyl(hoist, 0.16, 0.16, 0.35, Vector3(0.0, -0.15, -0.5), mat_dark).rotation_degrees.x = 90.0

	# Rotor Motion Blur Disks
	var main_blur_mat = _create_prop_blur_material(4)
	var main_blur = _add_disc(root, 8.2, Vector3(0.0, 2.75, -0.4), main_blur_mat)
	main_blur.rotation_degrees.x = 90.0
	main_blur.name = "MainRotorBlur"
	main_blur.visible = false

	var tail_blur_mat = _create_prop_blur_material(4)
	var tail_blur = _add_disc(root, 1.6, Vector3(0.35, 2.65, 9.0), tail_blur_mat)
	tail_blur.rotation_degrees.y = 90.0
	tail_blur.name = "TailRotorBlur"
	tail_blur.visible = false

	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	for side in [-1.0, 1.0]:
		var gx = side * 1.35
		var strut = _add_cyl(gear_node, 0.12, 0.10, 1.5, Vector3(gx, -0.45, -0.5), mat_metal)
		strut.rotation_degrees.z = side * 12.0
		_add_wheel(gear_node, 0.38, 0.22, Vector3(gx * 1.15, -1.15, -0.5), mat_dark)
	var tw_strut = _add_cyl(gear_node, 0.08, 0.08, 0.9, Vector3(0.0, 0.25, 8.2), mat_metal)
	_add_wheel(gear_node, 0.24, 0.14, Vector3(0.0, -0.35, 8.2), mat_dark)

	return root

# ==============================================================================
# PRIMITIVE BUILDERS, WHEELS & PBR MATERIAL GENERATORS
# ==============================================================================

static func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = size.x * 0.5
	var hh = size.y * 0.5
	var hd = size.z * 0.5

	var faces = [
		[Vector3.FORWARD, [Vector3(-hw, -hh, -hd), Vector3(hw, -hh, -hd), Vector3(hw, hh, -hd), Vector3(-hw, hh, -hd)]],
		[Vector3.BACK,    [Vector3(hw, -hh, hd), Vector3(-hw, -hh, hd), Vector3(-hw, hh, hd), Vector3(hw, hh, hd)]],
		[Vector3.UP,      [Vector3(-hw, hh, -hd), Vector3(hw, hh, -hd), Vector3(hw, hh, hd), Vector3(-hw, hh, hd)]],
		[Vector3.DOWN,    [Vector3(-hw, -hh, hd), Vector3(hw, -hh, hd), Vector3(hw, -hh, -hd), Vector3(-hw, -hh, -hd)]],
		[Vector3.LEFT,    [Vector3(-hw, -hh, hd), Vector3(-hw, -hh, -hd), Vector3(-hw, hh, -hd), Vector3(-hw, hh, hd)]],
		[Vector3.RIGHT,   [Vector3(hw, -hh, -hd), Vector3(hw, -hh, hd), Vector3(hw, hh, hd), Vector3(hw, hh, -hd)]],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var v: Array = f[1]
		st.set_normal(n)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v[0])
		st.set_uv(Vector2(1, 1)); st.add_vertex(v[1])
		st.set_uv(Vector2(1, 0)); st.add_vertex(v[2])
		st.set_uv(Vector2(0, 1)); st.add_vertex(v[0])
		st.set_uv(Vector2(1, 0)); st.add_vertex(v[2])
		st.set_uv(Vector2(0, 0)); st.add_vertex(v[3])

	mi.mesh = st.commit()
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node, r_top: float, r_bot: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments = 16
	var hh = height * 0.5

	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var c0 = cos(a0); var s0 = sin(a0)
		var c1 = cos(a1); var s1 = sin(a1)

		var pb0 = Vector3(c0 * r_bot, -hh, s0 * r_bot)
		var pb1 = Vector3(c1 * r_bot, -hh, s1 * r_bot)
		var pt0 = Vector3(c0 * r_top, hh, s0 * r_top)
		var pt1 = Vector3(c1 * r_top, hh, s1 * r_top)

		var n0 = Vector3(c0, 0.0, s0)
		var n1 = Vector3(c1, 0.0, s1)

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pb1)
		st.set_normal(n1); st.add_vertex(pt1)

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pt1)
		st.set_normal(n0); st.add_vertex(pt0)

		if r_top > 0.01:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(0, hh, 0)); st.add_vertex(pt0); st.add_vertex(pt1)
		if r_bot > 0.01:
			st.set_normal(Vector3.DOWN)
			st.add_vertex(Vector3(0, -hh, 0)); st.add_vertex(pb1); st.add_vertex(pb0)

	mi.mesh = st.commit()
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cone(parent: Node, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	return _add_cyl(parent, 0.02, radius, height, pos, mat)

static func _add_sphere(parent: Node, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings = 8
	var sectors = 14

	for r in range(rings):
		var phi0 = float(r) * PI / float(rings)
		var phi1 = float(r + 1) * PI / float(rings)
		var y0 = cos(phi0) * radius; var r0 = sin(phi0) * radius
		var y1 = cos(phi1) * radius; var r1 = sin(phi1) * radius

		for s in range(sectors):
			var th0 = float(s) * TAU / float(sectors)
			var th1 = float(s + 1) * TAU / float(sectors)

			var v0 = Vector3(cos(th0) * r0, y0, sin(th0) * r0)
			var v1 = Vector3(cos(th1) * r0, y0, sin(th1) * r0)
			var v2 = Vector3(cos(th1) * r1, y1, sin(th1) * r1)
			var v3 = Vector3(cos(th0) * r1, y1, sin(th0) * r1)

			var n0 = v0.normalized()
			var n1 = v1.normalized()
			var n2 = v2.normalized()
			var n3 = v3.normalized()

			st.set_normal(n0); st.add_vertex(v0)
			st.set_normal(n1); st.add_vertex(v1)
			st.set_normal(n2); st.add_vertex(v2)

			st.set_normal(n0); st.add_vertex(v0)
			st.set_normal(n2); st.add_vertex(v2)
			st.set_normal(n3); st.add_vertex(v3)

	mi.mesh = st.commit()
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_wheel(parent: Node, radius: float, width: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = _add_cyl(parent, radius, radius, width, pos, mat)
	mi.rotation_degrees.z = 90.0
	return mi

static func _add_missile(parent: Node, pos: Vector3, mat_body: Material, mat_fins: Material) -> void:
	# AIM-9 Sidewinder: Body + seeker dome + guidance canards + rear fins
	var m_body = _add_cyl(parent, 0.06, 0.06, 2.4, pos, mat_body)
	m_body.rotation_degrees.x = 90.0
	_add_sphere(parent, 0.06, pos + Vector3(0.0, 0.0, -1.2), mat_fins) # Glass IR seeker dome
	# 4 Forward canards
	_add_box(parent, Vector3(0.28, 0.02, 0.20), pos + Vector3(0.0, 0.0, -0.8), mat_fins)
	_add_box(parent, Vector3(0.02, 0.28, 0.20), pos + Vector3(0.0, 0.0, -0.8), mat_fins)
	# 4 Rear rollerons
	_add_box(parent, Vector3(0.42, 0.02, 0.30), pos + Vector3(0.0, 0.0, 1.0), mat_fins)
	_add_box(parent, Vector3(0.02, 0.42, 0.30), pos + Vector3(0.0, 0.0, 1.0), mat_fins)

static func _create_pbr_material(albedo: Color, roughness: float, metallic: float, clearcoat: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	if clearcoat > 0.0:
		mat.clearcoat_enabled = true
		mat.clearcoat = clearcoat
		mat.clearcoat_roughness = 0.04
	return mat

static func _create_canopy_material(tint: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = tint
	mat.roughness = 0.04
	mat.metallic = 0.80
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	mat.clearcoat_roughness = 0.02
	return mat

static func _create_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

static func _add_disc(parent: Node, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sectors = 24
	for s in range(sectors):
		var th0 = float(s) * TAU / float(sectors)
		var th1 = float(s + 1) * TAU / float(sectors)
		var p0 = Vector3(0.0, 0.0, 0.0)
		var p1 = Vector3(cos(th0) * radius, sin(th0) * radius, 0.0)
		var p2 = Vector3(cos(th1) * radius, sin(th1) * radius, 0.0)
		var uv0 = Vector2(0.5, 0.5)
		var uv1 = Vector2(0.5 + 0.5 * cos(th0), 0.5 + 0.5 * sin(th0))
		var uv2 = Vector2(0.5 + 0.5 * cos(th1), 0.5 + 0.5 * sin(th1))
		st.set_normal(Vector3.FORWARD)
		st.set_uv(uv0); st.add_vertex(p0)
		st.set_uv(uv1); st.add_vertex(p1)
		st.set_uv(uv2); st.add_vertex(p2)
	mi.mesh = st.commit()
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _create_prop_blur_material(blade_count: int, tip_col: Color = Color(0.95, 0.85, 0.15, 0.70)) -> ShaderMaterial:
	var shader = load("res://games/aircraft-flight/aircraft/prop_blur.gdshader")
	if not shader:
		return null
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blade_count", blade_count)
	mat.set_shader_parameter("tip_color", tip_col)
	mat.set_shader_parameter("rpm_normalized", 1.0)
	return mat

