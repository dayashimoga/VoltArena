class_name AircraftMeshBuilder
extends RefCounted

## AircraftMeshBuilder: Procedural 3D Aircraft Model & PBR Material Synthesizer.
## Constructs realistic, proportioned, highly detailed 3D aircraft models with
## contoured fuselages, canopies, wings, engines, animated control surfaces,
## retractable landing gear, spinning rotors/props, and PBR materials.

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

	var mat_hull = _create_pbr_material(hull_color, 0.52, 0.45, 0.85) # Semi-metallic naval tactical gray
	var mat_accent = _create_pbr_material(accent_color, 0.40, 0.60, 0.90) # Squadron markings
	var mat_metal = _create_pbr_material(Color(0.20, 0.22, 0.25), 0.85, 0.25, 0.70)
	var mat_dark_metal = _create_pbr_material(Color(0.12, 0.13, 0.15), 0.90, 0.15, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.12, 0.18, 0.26, 0.60)) # Anti-glare tinted acrylic
	var mat_glow = _create_emissive_material(Color(1.0, 0.55, 0.1), 8.5) # Afterburner flame glow
	var mat_white = _create_pbr_material(Color(0.92, 0.94, 0.96), 0.4, 0.1)

	# --- FUSELAGE STRUCTURE ---
	# Forward Radome Nose Cone with Pitot Probe
	var nose = _add_cone(root, 0.65, 3.2, Vector3(0.0, 0.35, -4.8), mat_dark_metal)
	nose.rotation_degrees.x = 90.0
	_add_cyl(root, 0.02, 0.02, 0.8, Vector3(0.0, 0.35, -6.6), mat_metal).rotation_degrees.x = 90.0 # Pitot tube

	# Forward Fuselage (cockpit section)
	_add_box(root, Vector3(1.4, 1.15, 3.6), Vector3(0.0, 0.42, -2.4), mat_hull)
	# Mid Fuselage (wing carry-through box)
	_add_box(root, Vector3(2.0, 1.05, 4.2), Vector3(0.0, 0.40, 0.8), mat_hull)
	# Aft Fuselage (engine tunnels)
	_add_box(root, Vector3(1.85, 0.95, 3.2), Vector3(0.0, 0.38, 3.6), mat_hull)
	# Dorsal Avionics Spine
	_add_box(root, Vector3(0.65, 0.30, 4.8), Vector3(0.0, 0.95, -0.4), mat_hull)

	# --- COCKPIT & CANOPY ---
	var canopy = _add_box(root, Vector3(0.78, 0.62, 2.8), Vector3(0.0, 0.98, -2.2), mat_canopy)
	canopy.name = "Canopy"
	# Canopy Bow Frame Arch
	_add_box(canopy, Vector3(0.82, 0.66, 0.12), Vector3(0.0, 0.0, -0.2), mat_hull)
	# Ejection Seat with Pilot Headrest
	_add_box(root, Vector3(0.42, 0.70, 0.48), Vector3(0.0, 0.72, -2.0), mat_dark_metal)
	_add_box(root, Vector3(0.24, 0.22, 0.20), Vector3(0.0, 1.12, -2.0), _create_pbr_material(Color(0.85, 0.70, 0.1), 0.5, 0.2)) # Helmet
	# HUD Glass Display
	_add_box(root, Vector3(0.25, 0.20, 0.04), Vector3(0.0, 0.98, -3.2), mat_canopy).rotation_degrees.x = -20.0

	# --- LEADING EDGE ROOT EXTENSIONS (LEX / STRAKES) ---
	# Swept gothic strakes generating high-AoA vortex lift
	var lex_l = _add_box(root, Vector3(0.95, 0.10, 3.4), Vector3(-1.15, 0.38, -1.2), mat_hull)
	lex_l.rotation_degrees.y = 12.0
	var lex_r = _add_box(root, Vector3(0.95, 0.10, 3.4), Vector3(1.15, 0.38, -1.2), mat_hull)
	lex_r.rotation_degrees.y = -12.0

	# --- TWIN D-SHAPED AIR INTAKES ---
	# Intakes mounted on fuselage flanks below LEX
	var intake_l = _add_box(root, Vector3(0.65, 0.75, 2.6), Vector3(-1.18, 0.18, -0.6), mat_hull)
	_add_box(intake_l, Vector3(0.55, 0.65, 0.2), Vector3(0.0, 0.0, -1.3), mat_dark_metal) # Intake opening
	var intake_r = _add_box(root, Vector3(0.65, 0.75, 2.6), Vector3(1.18, 0.18, -0.6), mat_hull)
	_add_box(intake_r, Vector3(0.55, 0.65, 0.2), Vector3(0.0, 0.0, -1.3), mat_dark_metal)

	# --- MAIN SWEPT WINGS & CONTROL SURFACES ---
	# Wingspan: 12.3m, 20-degree sweep
	var wing_l = _add_box(root, Vector3(4.8, 0.12, 2.3), Vector3(-3.4, 0.38, 0.9), mat_hull)
	wing_l.rotation_degrees.z = -1.5 # Subtle 1.5 degree anhedral
	var wing_r = _add_box(root, Vector3(4.8, 0.12, 2.3), Vector3(3.4, 0.38, 0.9), mat_hull)
	wing_r.rotation_degrees.z = 1.5

	# Wing Snags / Leading Edge Pylons
	_add_box(root, Vector3(0.12, 0.28, 1.8), Vector3(-2.6, 0.20, 0.8), mat_metal)
	_add_box(root, Vector3(0.12, 0.28, 1.8), Vector3(2.6, 0.20, 0.8), mat_metal)

	# Wingtip Missile Launch Rails
	_add_box(root, Vector3(0.12, 0.12, 2.6), Vector3(-5.8, 0.38, 0.9), mat_metal)
	_add_box(root, Vector3(0.12, 0.12, 2.6), Vector3(5.8, 0.38, 0.9), mat_metal)
	# AIM-9 Sidewinder Air-to-Air Missiles
	_add_missile(root, Vector3(-5.8, 0.32, 0.9), mat_white, mat_dark_metal)
	_add_missile(root, Vector3(5.8, 0.32, 0.9), mat_white, mat_dark_metal)

	# Outboard Ailerons
	var aileron_l = _add_box(root, Vector3(2.1, 0.08, 0.55), Vector3(-4.6, 0.38, 2.15), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.1, 0.08, 0.55), Vector3(4.6, 0.38, 2.15), mat_accent)
	aileron_r.name = "AileronRight"

	# Inboard Trailing Edge Flaps
	var flap_l = _add_box(root, Vector3(2.2, 0.09, 0.65), Vector3(-2.2, 0.38, 2.15), mat_hull)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(2.2, 0.09, 0.65), Vector3(2.2, 0.38, 2.15), mat_hull)
	flap_r.name = "FlapRight"

	# --- TWIN CANTED VERTICAL STABILIZERS ---
	# 20-degree outward cant for vortex ingestion and directional stability
	var fin_l = _add_box(root, Vector3(0.12, 2.5, 1.9), Vector3(-1.15, 1.70, 2.7), mat_accent)
	fin_l.rotation_degrees.z = -20.0
	var fin_r = _add_box(root, Vector3(0.12, 2.5, 1.9), Vector3(1.15, 1.70, 2.7), mat_accent)
	fin_r.rotation_degrees.z = 20.0

	# Top Antenna Pods on fins
	_add_cyl(fin_l, 0.08, 0.08, 0.9, Vector3(0.0, 1.25, -0.3), mat_dark_metal).rotation_degrees.x = 90.0
	_add_cyl(fin_r, 0.08, 0.08, 0.9, Vector3(0.0, 1.25, -0.3), mat_dark_metal).rotation_degrees.x = 90.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 1.9, 0.48), Vector3(0.0, -0.1, 1.05), mat_hull)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 1.9, 0.48), Vector3(0.0, -0.1, 1.05), mat_hull)
	rudder_r.name = "RudderRight"

	# --- ALL-MOVING HORIZONTAL STABILATORS (ELEVATORS) ---
	var elev_l = _add_box(root, Vector3(2.2, 0.10, 1.5), Vector3(-1.9, 0.28, 3.8), mat_hull)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.2, 0.10, 1.5), Vector3(1.9, 0.28, 3.8), mat_hull)
	elev_r.name = "ElevatorRight"

	# --- TWIN F404 TURBOFAN ENGINES & AFTERBURNERS ---
	var eng_l = _add_cyl(root, 0.52, 0.48, 1.6, Vector3(-0.62, 0.36, 4.4), mat_metal)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 0.52, 0.48, 1.6, Vector3(0.62, 0.36, 4.4), mat_metal)
	eng_r.rotation_degrees.x = 90.0

	# Titanium Nozzle Petals
	_add_cyl(eng_l, 0.46, 0.42, 0.4, Vector3(0.0, 0.9, 0.0), mat_dark_metal)
	_add_cyl(eng_r, 0.46, 0.42, 0.4, Vector3(0.0, 0.9, 0.0), mat_dark_metal)

	# Afterburner Plumes
	var ab_l = _add_cone(root, 0.42, 1.8, Vector3(-0.62, 0.36, 5.8), mat_glow)
	ab_l.rotation_degrees.x = -90.0
	ab_l.name = "AfterburnerPlumeLeft"
	var ab_r = _add_cone(root, 0.42, 1.8, Vector3(0.62, 0.36, 5.8), mat_glow)
	ab_r.rotation_degrees.x = -90.0
	ab_r.name = "AfterburnerPlumeRight"

	# Carrier Arresting Tailhook
	var hook = _add_box(root, Vector3(0.08, 0.08, 1.8), Vector3(0.0, -0.05, 3.8), mat_metal)
	hook.name = "ArrestingHook"
	hook.rotation_degrees.x = -8.0

	# --- CARRIER-GRADE TRICYCLE LANDING GEAR ---
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)

	# Nose Gear: Dual wheels with catapult tow bar
	var nose_strut = _add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.70, -2.4), mat_metal)
	_add_box(nose_strut, Vector3(0.06, 0.4, 0.06), Vector3(0.0, -0.1, 0.12), mat_dark_metal) # Torque link scissors
	# Dual nose wheels
	_add_wheel(gear_node, 0.22, 0.10, Vector3(-0.14, -1.40, -2.4), mat_dark_metal)
	_add_wheel(gear_node, 0.22, 0.10, Vector3(0.14, -1.40, -2.4), mat_dark_metal)

	# Main Gear: Heavy-duty trailing-link landing bogies
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

	var mat_stealth = _create_pbr_material(hull_color, 0.60, 0.45, 0.95) # Radar-absorbent composite coating
	var mat_accent = _create_pbr_material(accent_color, 0.55, 0.35, 0.85) # Stealth panel edge trims
	var mat_metal = _create_pbr_material(Color(0.16, 0.18, 0.20), 0.88, 0.20, 0.75)
	var mat_dark = _create_pbr_material(Color(0.10, 0.11, 0.13), 0.92, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.28, 0.22, 0.12, 0.65)) # Gold-tinted indium tin oxide stealth glass
	var mat_glow = _create_emissive_material(Color(0.2, 0.75, 1.0), 9.0) # Supersonic cyan reheat

	# --- FACETED STEALTH CHINE FUSELAGE ---
	# Chined stealth radome nose
	var nose = _add_cone(root, 0.80, 3.6, Vector3(0.0, 0.30, -5.4), mat_stealth)
	nose.rotation_degrees.x = 90.0
	# Cockpit section with diamond cross-section
	_add_box(root, Vector3(1.8, 0.95, 3.8), Vector3(0.0, 0.38, -2.6), mat_stealth)
	# Center blended body
	_add_box(root, Vector3(2.6, 0.90, 4.6), Vector3(0.0, 0.34, 0.6), mat_stealth)
	# Aft stealth engine deck
	_add_box(root, Vector3(2.4, 0.80, 3.8), Vector3(0.0, 0.32, 3.8), mat_stealth)

	# --- INDIUM-TIN-OXIDE STEALTH CANOPY ---
	var canopy = _add_box(root, Vector3(0.88, 0.64, 2.8), Vector3(0.0, 0.92, -2.4), mat_canopy)
	canopy.name = "Canopy"
	# Ejection seat and pilot
	_add_box(root, Vector3(0.44, 0.68, 0.46), Vector3(0.0, 0.68, -2.2), mat_dark)
	_add_box(root, Vector3(0.24, 0.22, 0.20), Vector3(0.0, 1.08, -2.2), _create_pbr_material(Color(0.2, 0.6, 0.3), 0.4, 0.2)) # Stealth helmet

	# --- CARET STEALTH AIR INTAKES ---
	# Rhomboid / parallelogram stealth air intakes with forward-swept boundary layer splitters
	var intake_l = _add_box(root, Vector3(0.85, 0.80, 2.8), Vector3(-1.35, 0.18, -1.0), mat_stealth)
	intake_l.rotation_degrees.z = -15.0
	_add_box(intake_l, Vector3(0.70, 0.65, 0.2), Vector3(0.0, 0.0, -1.4), mat_dark)
	var intake_r = _add_box(root, Vector3(0.85, 0.80, 2.8), Vector3(1.35, 0.18, -1.0), mat_stealth)
	intake_r.rotation_degrees.z = 15.0
	_add_box(intake_r, Vector3(0.70, 0.65, 0.2), Vector3(0.0, 0.0, -1.4), mat_dark)

	# --- DIAMOND DELTA WINGS ---
	# 42-degree leading edge sweep with clipped diamond tips
	var wing_l = _add_box(root, Vector3(5.6, 0.12, 3.6), Vector3(-3.8, 0.34, 0.8), mat_stealth)
	var wing_r = _add_box(root, Vector3(5.6, 0.12, 3.6), Vector3(3.8, 0.34, 0.8), mat_stealth)

	# Flaperons / Ailerons
	var aileron_l = _add_box(root, Vector3(2.6, 0.08, 0.65), Vector3(-4.8, 0.34, 2.5), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.6, 0.08, 0.65), Vector3(4.8, 0.34, 2.5), mat_accent)
	aileron_r.name = "AileronRight"

	# Inboard Flaps
	var flap_l = _add_box(root, Vector3(2.2, 0.09, 0.70), Vector3(-2.2, 0.34, 2.5), mat_stealth)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(2.2, 0.09, 0.70), Vector3(2.2, 0.34, 2.5), mat_stealth)
	flap_r.name = "FlapRight"

	# --- 28-DEGREE CANTED TWIN VERTICAL STABILIZERS ---
	var fin_l = _add_box(root, Vector3(0.12, 2.7, 2.4), Vector3(-1.35, 1.78, 2.8), mat_accent)
	fin_l.rotation_degrees.z = -28.0
	var fin_r = _add_box(root, Vector3(0.12, 2.7, 2.4), Vector3(1.35, 1.78, 2.8), mat_accent)
	fin_r.rotation_degrees.z = 28.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 2.1, 0.55), Vector3(0.0, -0.1, 1.25), mat_stealth)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 2.1, 0.55), Vector3(0.0, -0.1, 1.25), mat_stealth)
	rudder_r.name = "RudderRight"

	# --- ALL-MOVING HORIZONTAL STABILATORS ---
	var elev_l = _add_box(root, Vector3(2.5, 0.10, 1.8), Vector3(-2.3, 0.28, 4.2), mat_stealth)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.5, 0.10, 1.8), Vector3(2.3, 0.28, 4.2), mat_stealth)
	elev_r.name = "ElevatorRight"

	# --- 2D THRUST VECTORING RECTANGULAR NOZZLES ---
	var nozzle_l = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(-0.78, 0.32, 4.8), mat_dark)
	nozzle_l.name = "VectorNozzleLeft"
	var nozzle_r = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(0.78, 0.32, 4.8), mat_dark)
	nozzle_r.name = "VectorNozzleRight"

	# Sawtooth Stealth Edges on Nozzles
	_add_box(nozzle_l, Vector3(0.88, 0.48, 0.15), Vector3(0.0, 0.0, 0.6), mat_metal)
	_add_box(nozzle_r, Vector3(0.88, 0.48, 0.15), Vector3(0.0, 0.0, 0.6), mat_metal)

	# Reheat Plumes
	var ab_l = _add_box(nozzle_l, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
	ab_l.name = "AfterburnerPlumeLeft"
	var ab_r = _add_box(nozzle_r, Vector3(0.72, 0.32, 1.6), Vector3(0.0, 0.0, 1.2), mat_glow)
	ab_r.name = "AfterburnerPlumeRight"

	# --- RETRACTABLE STEALTH TRICYCLE GEAR ---
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)

	# Nose gear
	_add_cyl(gear_node, 0.08, 0.07, 1.5, Vector3(0.0, -0.72, -2.8), mat_metal)
	_add_wheel(gear_node, 0.24, 0.12, Vector3(0.0, -1.45, -2.8), mat_dark)

	# Main gear
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

	var mat_hull = _create_pbr_material(hull_color, 0.20, 0.15, 0.95) # High-gloss white polyurethane
	var mat_accent = _create_pbr_material(accent_color, 0.30, 0.25, 0.90) # Airline livery cheatline
	var mat_metal = _create_pbr_material(Color(0.28, 0.30, 0.34), 0.78, 0.30, 0.75)
	var mat_dark = _create_pbr_material(Color(0.12, 0.13, 0.15), 0.90, 0.10, 0.80)
	var mat_window = _create_pbr_material(Color(0.06, 0.10, 0.16), 0.92, 0.05, 1.0)
	var mat_chrome = _create_pbr_material(Color(0.85, 0.88, 0.92), 0.95, 0.10, 0.90)

	# --- 37.6M SCALE AIRLINER FUSELAGE ---
	# Main Cylindrical Passenger Cabin
	var cabin = _add_cyl(root, 1.95, 1.95, 20.0, Vector3(0.0, 1.2, 0.0), mat_hull)
	cabin.rotation_degrees.x = 90.0

	# Aerodynamic Contoured Nose Section
	var nose = _add_sphere(root, 1.94, Vector3(0.0, 1.2, -10.0), mat_hull)
	nose.scale = Vector3(1.0, 0.95, 1.4)

	# Tapered Aft Tail Cone with APU Exhaust Port
	var tail_cone = _add_cone(root, 1.94, 6.5, Vector3(0.0, 1.6, 12.8), mat_hull)
	tail_cone.rotation_degrees.x = -90.0
	_add_cyl(root, 0.15, 0.15, 0.4, Vector3(0.0, 1.9, 16.2), mat_dark).rotation_degrees.x = 90.0 # APU

	# --- FLIGHT DECK COCKPIT & PASSENGER WINDOWS ---
	# 6-Pane Cockpit Windshield
	var cockpit_glass = _add_box(root, Vector3(1.5, 0.55, 1.0), Vector3(0.0, 2.15, -9.2), mat_window)
	cockpit_glass.rotation_degrees.x = 18.0
	cockpit_glass.name = "Canopy"

	# Passenger Cabin Window Belts (Left & Right)
	_add_box(root, Vector3(3.96, 0.18, 16.5), Vector3(0.0, 1.55, -0.5), mat_window)
	# Airline Livery Color Cheatline Strip along fuselage
	_add_box(root, Vector3(3.98, 0.35, 18.5), Vector3(0.0, 1.15, -0.5), mat_accent)

	# Passenger Doors (Forward L1/R1 and Aft L2/R2)
	_add_box(root, Vector3(3.98, 1.4, 0.8), Vector3(0.0, 1.2, -8.0), mat_accent)
	_add_box(root, Vector3(3.98, 1.4, 0.8), Vector3(0.0, 1.2, 8.5), mat_accent)

	# --- SUPERCRITICAL SWEPT WINGS & SHARKLETS ---
	# 5-degree positive dihedral angle, wingspan 34.1m
	var wing_l = _add_box(root, Vector3(14.5, 0.28, 3.4), Vector3(-9.2, 0.45, 0.6), mat_hull)
	wing_l.rotation_degrees.z = 4.5
	var wing_r = _add_box(root, Vector3(14.5, 0.28, 3.4), Vector3(9.2, 0.45, 0.6), mat_hull)
	wing_r.rotation_degrees.z = -4.5

	# Wing Root Fairings / Belly Karman Fairing
	_add_box(root, Vector3(4.8, 0.65, 6.5), Vector3(0.0, 0.45, 0.6), mat_hull)

	# Blended Wingtip Sharklets (2.4m tall winglets)
	var sharklet_l = _add_box(root, Vector3(0.12, 1.8, 1.2), Vector3(-16.4, 1.7, 1.0), mat_accent)
	sharklet_l.rotation_degrees.z = -8.0
	var sharklet_r = _add_box(root, Vector3(0.12, 1.8, 1.2), Vector3(16.4, 1.7, 1.0), mat_accent)
	sharklet_r.rotation_degrees.z = 8.0

	# Ailerons & High-Lift Fowler Flaps
	var aileron_l = _add_box(root, Vector3(4.2, 0.12, 0.65), Vector3(-13.4, 0.95, 2.2), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(4.2, 0.12, 0.65), Vector3(13.4, 0.95, 2.2), mat_accent)
	aileron_r.name = "AileronRight"

	var flap_l = _add_box(root, Vector3(7.2, 0.16, 0.95), Vector3(-5.8, 0.35, 2.2), mat_metal)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(7.2, 0.16, 0.95), Vector3(5.8, 0.35, 2.2), mat_metal)
	flap_r.name = "FlapRight"

	# Flap Track Fairing Canoes under wings
	for fx in [-4.0, -7.0, 4.0, 7.0]:
		var canoe = _add_cyl(root, 0.18, 0.12, 2.4, Vector3(fx, 0.15, 2.0), mat_hull)
		canoe.rotation_degrees.x = 90.0

	# --- TWIN CFM56 / LEAP HIGH-BYPASS TURBOFANS ---
	for side in [-1.0, 1.0]:
		var ex = side * 5.4
		# Wing Pylon
		_add_box(root, Vector3(0.25, 0.95, 2.8), Vector3(ex, 0.25, -0.6), mat_metal)

		# Nacelle Cowling
		var nacelle = _add_cyl(root, 1.25, 1.25, 4.2, Vector3(ex, -0.45, -0.8), mat_hull)
		nacelle.rotation_degrees.x = 90.0

		# Polished Chrome Inlet Lip
		var lip = _add_cyl(root, 1.28, 1.22, 0.3, Vector3(ex, -0.45, -2.9), mat_chrome)
		lip.rotation_degrees.x = 90.0

		# Spinning Turbofan Blades & Spinner Cone
		var fan = _add_cyl(root, 1.10, 1.10, 0.2, Vector3(ex, -0.45, -2.7), mat_metal)
		fan.rotation_degrees.x = 90.0
		fan.name = "FanBladesLeft" if side < 0 else "FanBladesRight"
		var spinner = _add_cone(fan, 0.32, 0.6, Vector3(0.0, 0.2, 0.0), mat_dark)

		# Hot Exhaust Core Nozzle
		var core = _add_cone(root, 0.55, 0.8, Vector3(ex, -0.45, 1.6), mat_dark)
		core.rotation_degrees.x = -90.0

	# --- EMPENNAGE: SWEPT VERTICAL FIN & HORIZONTAL TAIL ---
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

	# --- MULTI-WHEEL TRICYCLE LANDING GEAR ---
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)

	# Steerable dual-wheel nose gear
	_add_cyl(gear_node, 0.12, 0.12, 2.2, Vector3(0.0, -0.25, -7.5), mat_metal)
	_add_wheel(gear_node, 0.38, 0.16, Vector3(-0.24, -1.35, -7.5), mat_dark)
	_add_wheel(gear_node, 0.38, 0.16, Vector3(0.24, -1.35, -7.5), mat_dark)

	# Twin-wheel main gear bogies
	for side in [-1.0, 1.0]:
		var mx = side * 3.8
		_add_cyl(gear_node, 0.18, 0.18, 2.4, Vector3(mx, -0.40, 1.2), mat_metal)
		_add_wheel(gear_node, 0.52, 0.22, Vector3(mx - 0.30, -1.50, 1.2), mat_dark)
		_add_wheel(gear_node, 0.52, 0.22, Vector3(mx + 0.30, -1.50, 1.2), mat_dark)

	return root

# ==============================================================================
# 4. EXTRA 330SC (UNLIMITED COMPETITION AEROBATIC MONOPLANE)
# ==============================================================================

static func build_extra330_sport(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "Extra330Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.18, 0.20, 0.95) # High-gloss competition paint
	var mat_accent = _create_pbr_material(accent_color, 0.22, 0.25, 0.90) # Sunburst racing trim
	var mat_metal = _create_pbr_material(Color(0.20, 0.22, 0.25), 0.85, 0.20, 0.70)
	var mat_dark = _create_pbr_material(Color(0.10, 0.11, 0.12), 0.90, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.12, 0.18, 0.28, 0.50))
	var mat_white = _create_pbr_material(Color(0.95, 0.95, 0.95), 0.3, 0.1)

	# --- SLENDER COMPOSITE AEROBATIC FUSELAGE ---
	# Tapered cockpit & tail boom
	_add_box(root, Vector3(0.85, 0.98, 4.2), Vector3(0.0, 0.30, 0.2), mat_hull)
	# Engine Cowling (Lycoming AEIO-580)
	var cowl = _add_cyl(root, 0.48, 0.48, 1.4, Vector3(0.0, 0.30, -2.4), mat_accent)
	cowl.rotation_degrees.x = 90.0

	# Engine Cooling Air Inlets & Oil Cooler Scoop
	_add_box(root, Vector3(0.25, 0.15, 0.3), Vector3(-0.25, 0.32, -3.1), mat_dark)
	_add_box(root, Vector3(0.25, 0.15, 0.3), Vector3(0.25, 0.32, -3.1), mat_dark)
	_add_box(root, Vector3(0.30, 0.18, 0.4), Vector3(0.0, -0.05, -2.2), mat_dark) # Chin scoop

	# Tuned Stainless Exhaust Pipes (Dual 3-into-1 headers)
	_add_cyl(root, 0.05, 0.05, 0.6, Vector3(-0.35, -0.08, -1.8), mat_metal).rotation_degrees.x = 45.0
	_add_cyl(root, 0.05, 0.05, 0.6, Vector3(0.35, -0.08, -1.8), mat_metal).rotation_degrees.x = 45.0

	# --- 360-DEGREE TEARDROP BUBBLE CANOPY ---
	var canopy = _add_box(root, Vector3(0.68, 0.58, 2.1), Vector3(0.0, 0.90, -0.3), mat_canopy)
	canopy.name = "Canopy"
	# Steel tube cockpit roll cage truss visible inside
	_add_box(canopy, Vector3(0.62, 0.52, 0.08), Vector3(0.0, 0.0, 0.2), mat_dark)
	# Pilot with Aerobatic Helmet
	_add_box(root, Vector3(0.36, 0.55, 0.38), Vector3(0.0, 0.68, 0.0), mat_dark)
	_add_sphere(root, 0.15, Vector3(0.0, 1.05, 0.0), _create_pbr_material(Color(0.9, 0.15, 0.1), 0.2, 0.2)) # Red helmet

	# --- 3-BLADE COMPOSITE SPINNING PROPELLER ---
	var prop_root = Node3D.new()
	prop_root.name = "Propeller"
	prop_root.position = Vector3(0.0, 0.30, -3.15)
	root.add_child(prop_root)

	# Polished Spinner Cone
	var spinner = _add_cone(prop_root, 0.25, 0.55, Vector3(0.0, 0.0, -0.15), mat_accent)
	spinner.rotation_degrees.x = 90.0

	# 3 Carbon Composite Propeller Blades (120 degrees apart)
	for i in range(3):
		var blade = _add_box(prop_root, Vector3(0.08, 1.05, 0.04), Vector3(0.0, 0.55, 0.0), mat_metal)
		blade.rotation_degrees.z = i * 120.0
		# High-visibility yellow blade tips
		_add_box(blade, Vector3(0.09, 0.18, 0.05), Vector3(0.0, 0.45, 0.0), _create_pbr_material(Color(0.95, 0.85, 0.1), 0.4, 0.1))

	# --- MID-MOUNT SYMMETRICAL WINGS ---
	# Wingspan: 7.5m, zero dihedral for inverted and knife-edge flight
	_add_box(root, Vector3(7.2, 0.10, 1.45), Vector3(0.0, 0.25, -0.3), mat_hull)

	# Full-Span Counterbalanced Ailerons with Aerodynamic Spades
	var aileron_l = _add_box(root, Vector3(3.0, 0.07, 0.45), Vector3(-2.1, 0.25, 0.55), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(3.0, 0.07, 0.45), Vector3(2.1, 0.25, 0.55), mat_accent)
	aileron_r.name = "AileronRight"

	# Aerodynamic Spade Counterbalances extending underneath wings
	_add_box(aileron_l, Vector3(0.25, 0.04, 0.30), Vector3(0.0, -0.20, -0.15), mat_metal)
	_add_box(aileron_r, Vector3(0.25, 0.04, 0.30), Vector3(0.0, -0.20, -0.15), mat_metal)

	# Wingtip Sighting Devices (Triangular evaluation devices for aerobatic competition angles)
	_add_box(root, Vector3(0.04, 0.25, 0.35), Vector3(-3.65, 0.25, -0.3), mat_white)
	_add_box(root, Vector3(0.04, 0.25, 0.35), Vector3(3.65, 0.25, -0.3), mat_white)

	# --- EMPENNAGE & OVERSIZED AEROBATIC RUDDER ---
	var fin = _add_box(root, Vector3(0.09, 1.4, 1.1), Vector3(0.0, 1.05, 2.3), mat_hull)
	# Oversized balanced rudder extending below fuselage for knife-edge authority
	var rudder = _add_box(fin, Vector3(0.11, 1.6, 0.75), Vector3(0.0, -0.1, 0.85), mat_accent)
	rudder.name = "RudderLeft"
	var rudder_r = _add_box(fin, Vector3(0.11, 1.6, 0.75), Vector3(0.0, -0.1, 0.85), mat_accent)
	rudder_r.name = "RudderRight"

	# Counterbalanced Elevator
	var elev_l = _add_box(root, Vector3(1.3, 0.07, 0.70), Vector3(-0.75, 0.38, 2.6), mat_accent)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(1.3, 0.07, 0.70), Vector3(0.75, 0.38, 2.6), mat_accent)
	elev_r.name = "ElevatorRight"

	# --- TAILDRAGGER GEAR WITH AERODYNAMIC WHEEL SPATS ---
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)

	# Spring composite main gear legs
	for side in [-1.0, 1.0]:
		var gx = side * 1.05
		var strut = _add_box(gear_node, Vector3(0.06, 0.8, 0.12), Vector3(gx * 0.75, -0.25, -1.1), mat_metal)
		strut.rotation_degrees.z = -side * 18.0
		# Teardrop aerodynamic wheel spats/fairings
		var spat = _add_box(gear_node, Vector3(0.22, 0.36, 0.72), Vector3(gx, -0.72, -1.1), mat_accent)
		_add_wheel(spat, 0.18, 0.10, Vector3(0.0, -0.05, 0.0), mat_dark)

	# Steerable Pneumatic Tailwheel
	_add_wheel(gear_node, 0.10, 0.06, Vector3(0.0, -0.20, 2.5), mat_dark)

	return root

# ==============================================================================
# 5. UH-60 BLACKHAWK (TACTICAL UTILITY ROTORCRAFT)
# ==============================================================================

static func build_uh60_helicopter(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "UH60Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.82, 0.20, 0.10) # Low-reflective CARC tactical olive drab
	var mat_accent = _create_pbr_material(accent_color, 0.70, 0.25, 0.30)
	var mat_metal = _create_pbr_material(Color(0.18, 0.20, 0.22), 0.80, 0.25, 0.70)
	var mat_dark = _create_pbr_material(Color(0.10, 0.12, 0.14), 0.90, 0.10, 0.80)
	var mat_canopy = _create_canopy_material(Color(0.08, 0.12, 0.16, 0.75)) # Armored tinted flight glass

	# --- FACETED CABIN FUSELAGE ---
	# Forward Cockpit Glazing & Chin Windows
	var cockpit = _add_box(root, Vector3(1.85, 1.25, 1.8), Vector3(0.0, 0.75, -3.1), mat_canopy)
	cockpit.name = "Canopy"
	# Cockpit Center Mullion & Armor Frames
	_add_box(cockpit, Vector3(0.10, 1.30, 1.82), Vector3(0.0, 0.0, 0.0), mat_hull)

	# Main Troop/Cargo Cabin (Slide door section)
	_add_box(root, Vector3(2.15, 1.75, 5.2), Vector3(0.0, 0.75, 0.2), mat_hull)
	# Cabin Sliding Cargo Doors (Left & Right)
	_add_box(root, Vector3(2.20, 1.30, 1.8), Vector3(0.0, 0.70, 0.4), mat_accent)

	# FLIR (Forward Looking Infrared) Turret Ball on nose
	_add_sphere(root, 0.28, Vector3(0.0, 0.15, -4.2), mat_dark)
	# Wire Strike Cutter (Windshield upper blade)
	_add_box(root, Vector3(0.04, 0.35, 0.25), Vector3(0.0, 1.55, -2.8), mat_metal)

	# --- TWIN T700 TURBOSHAFT ENGINES & HIRSS SUPPRESSORS ---
	# Shoulder-mounted engine cowlings
	var eng_l = _add_cyl(root, 0.52, 0.52, 3.2, Vector3(-0.85, 1.65, -0.6), mat_hull)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 0.52, 0.52, 3.2, Vector3(0.85, 1.65, -0.6), mat_hull)
	eng_r.rotation_degrees.x = 90.0

	# HIRSS (Hover Infrared Suppressor System) Angled Exhaust Baffles
	var exh_l = _add_box(root, Vector3(0.55, 0.45, 0.8), Vector3(-0.95, 1.75, 1.2), mat_dark)
	exh_l.rotation_degrees.y = -25.0
	var exh_r = _add_box(root, Vector3(0.55, 0.45, 0.8), Vector3(0.95, 1.75, 1.2), mat_dark)
	exh_r.rotation_degrees.y = 25.0

	# Main Transmission Doghouse Fairing
	_add_box(root, Vector3(1.2, 0.65, 2.6), Vector3(0.0, 1.85, -0.5), mat_hull)

	# --- 4-BLADE ARTICULATED MAIN ROTOR SYSTEM ---
	var mast = _add_cyl(root, 0.22, 0.22, 0.8, Vector3(0.0, 2.25, -0.4), mat_metal)
	var rotor_root = Node3D.new()
	rotor_root.name = "MainRotor"
	rotor_root.position = Vector3(0.0, 2.65, -0.4)
	root.add_child(rotor_root)

	# Rotor Hub & Swashplate Assembly
	_add_cyl(rotor_root, 0.55, 0.55, 0.25, Vector3(0.0, 0.0, 0.0), mat_dark)

	# 4 Fully Articulated Rotor Blades (16.4m diameter)
	for i in range(4):
		var blade_root = Node3D.new()
		blade_root.rotation_degrees.y = i * 90.0
		rotor_root.add_child(blade_root)

		# Pitch Cuff & Damper Links
		_add_box(blade_root, Vector3(0.24, 0.12, 0.8), Vector3(0.0, 0.0, 0.6), mat_metal)
		# Aerodynamic Blade with 20-degree swept anhedral tip
		var blade = _add_box(blade_root, Vector3(0.26, 0.06, 7.2), Vector3(0.0, 0.0, 4.4), mat_metal)
		# Swept Anhedral Tip
		var tip = _add_box(blade, Vector3(0.22, 0.04, 0.8), Vector3(0.0, -0.04, 3.8), mat_dark)
		tip.rotation_degrees.y = -20.0

	# --- TAPERED TAIL BOOM & CANTED TAIL ROTOR ---
	_add_box(root, Vector3(0.75, 0.75, 6.4), Vector3(0.0, 0.95, 5.8), mat_hull)
	# Tail Pylon canted 20 degrees for vertical lift contribution
	var pylon = _add_box(root, Vector3(0.24, 2.1, 1.4), Vector3(0.0, 2.0, 8.8), mat_hull)

	# 4-Blade Cross-Beam Tail Rotor
	var tail_rotor_root = Node3D.new()
	tail_rotor_root.name = "TailRotor"
	tail_rotor_root.position = Vector3(0.28, 2.65, 9.0)
	root.add_child(tail_rotor_root)
	tail_rotor_root.rotation_degrees.z = 20.0 # 20-degree canted tail rotor axis

	_add_cyl(tail_rotor_root, 0.18, 0.18, 0.15, Vector3(0.0, 0.0, 0.0), mat_metal).rotation_degrees.z = 90.0
	for i in range(4):
		var t_blade = _add_box(tail_rotor_root, Vector3(0.06, 1.35, 0.04), Vector3(0.0, 0.70, 0.0), mat_metal)
		t_blade.rotation_degrees.x = i * 90.0

	# Large Variable-Incidence Horizontal Stabilator
	var stab = _add_box(root, Vector3(3.6, 0.10, 0.95), Vector3(0.0, 0.90, 8.6), mat_accent)
	stab.name = "ElevatorLeft"
	var stab_r = _add_box(root, Vector3(3.6, 0.10, 0.95), Vector3(0.0, 0.90, 8.6), mat_accent)
	stab_r.name = "ElevatorRight"

	# --- EXTERNAL RESCUE HOIST BOOM ---
	var hoist = _add_box(root, Vector3(0.12, 0.12, 1.4), Vector3(1.15, 1.85, -1.8), mat_metal)
	hoist.name = "RescueHoist"
	_add_cyl(hoist, 0.16, 0.16, 0.35, Vector3(0.0, -0.15, -0.5), mat_dark).rotation_degrees.x = 90.0 # Cable drum

	# --- RUGGED FIXED LANDING GEAR ---
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)

	# Heavy-duty dual-stage oleo shock struts
	for side in [-1.0, 1.0]:
		var gx = side * 1.35
		var strut = _add_cyl(gear_node, 0.12, 0.10, 1.5, Vector3(gx, -0.45, -0.5), mat_metal)
		strut.rotation_degrees.z = side * 12.0
		_add_wheel(gear_node, 0.38, 0.22, Vector3(gx * 1.15, -1.15, -0.5), mat_dark)

	# Heavy Tailwheel assembly under rear boom
	var tw_strut = _add_cyl(gear_node, 0.08, 0.08, 0.9, Vector3(0.0, 0.25, 8.2), mat_metal)
	_add_wheel(gear_node, 0.24, 0.14, Vector3(0.0, -0.35, 8.2), mat_dark)

	return root

# ==============================================================================
# PRIMITIVE BUILDERS, WHEELS & PBR MATERIAL GENERATORS
# ==============================================================================

static func _add_box(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node, r_top: float, r_bot: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = r_top
	cyl.bottom_radius = r_bot
	cyl.height = height
	cyl.radial_segments = 16
	mi.mesh = cyl
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cone(parent: Node, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	return _add_cyl(parent, 0.02, radius, height, pos, mat)

static func _add_sphere(parent: Node, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = 16
	sph.rings = 8
	mi.mesh = sph
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_wheel(parent: Node, radius: float, width: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = width
	cyl.radial_segments = 14
	mi.mesh = cyl
	mi.position = pos
	mi.rotation_degrees.z = 90.0
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
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
