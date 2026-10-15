class_name AircraftMeshBuilder
extends RefCounted

## AircraftMeshBuilder: Procedural 3D Aircraft Model & PBR Material Synthesizer.
## Constructs realistic, proportioned 3D models with wings, cockpits,
## animated control surfaces, retractable landing gear, engines, and PBR shaders.

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
# 1. F/A-18 HORNET (CARRIER MULTIROLE FIGHTER)
# ==============================================================================

static func build_fa18_hornet(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "FA18Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.55, 0.45, 0.85) # Semi-metallic naval tactical paint
	var mat_accent = _create_pbr_material(accent_color, 0.40, 0.60, 0.90)
	var mat_metal = _create_pbr_material(Color(0.2, 0.22, 0.25), 0.85, 0.25, 0.70)
	var mat_canopy = _create_canopy_material(Color(0.12, 0.16, 0.22, 0.65))
	var mat_glow = _create_emissive_material(Color(1.0, 0.55, 0.1), 8.0) # Afterburner glow

	# Main Fuselage (Cylindrical tapered)
	_add_box(root, Vector3(1.6, 1.1, 7.8), Vector3(0.0, 0.4, 0.2), mat_hull)
	# Radome / Nose Cone
	var nose = _add_cone(root, 0.75, 2.6, Vector3(0.0, 0.35, -4.6), mat_hull)
	nose.rotation_degrees.x = 90.0

	# Cockpit Bubble Canopy
	var canopy = _add_box(root, Vector3(0.85, 0.65, 2.4), Vector3(0.0, 0.95, -1.8), mat_canopy)
	canopy.name = "Canopy"
	# Pilot Ejection Seat & Helmet
	_add_box(root, Vector3(0.45, 0.6, 0.45), Vector3(0.0, 0.75, -1.6), mat_metal)
	_add_sphere(root, 0.18, Vector3(0.0, 1.1, -1.5), _create_pbr_material(Color(0.15, 0.75, 0.2), 0.2, 0.3))

	# Leading Edge Root Extensions (LEX)
	var lex_l = _add_wedge(root, Vector3(0.9, 0.15, 3.2), Vector3(-1.1, 0.35, -1.2), mat_hull)
	var lex_r = _add_wedge(root, Vector3(0.9, 0.15, 3.2), Vector3(1.1, 0.35, -1.2), mat_hull)
	lex_r.scale.x = -1.0

	# Main Swept Wings
	_add_box(root, Vector3(5.2, 0.12, 2.2), Vector3(-3.4, 0.35, 0.6), mat_hull)
	_add_box(root, Vector3(5.2, 0.12, 2.2), Vector3(3.4, 0.35, 0.6), mat_hull)
	# Wingtip Missile Launch Rails
	_add_box(root, Vector3(0.08, 0.1, 2.4), Vector3(-6.0, 0.35, 0.6), mat_metal)
	_add_box(root, Vector3(0.08, 0.1, 2.4), Vector3(6.0, 0.35, 0.6), mat_metal)

	# Control Surfaces: Ailerons
	var aileron_l = _add_box(root, Vector3(2.2, 0.08, 0.55), Vector3(-4.6, 0.35, 1.8), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.2, 0.08, 0.55), Vector3(4.6, 0.35, 1.8), mat_accent)
	aileron_r.name = "AileronRight"

	# Control Surfaces: Trailing Edge Flaps
	var flap_l = _add_box(root, Vector3(2.2, 0.08, 0.65), Vector3(-2.2, 0.35, 1.8), mat_hull)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(2.2, 0.08, 0.65), Vector3(2.2, 0.35, 1.8), mat_hull)
	flap_r.name = "FlapRight"

	# Twin Canted Vertical Stabilizers (20 degrees outward cant)
	var fin_l = _add_box(root, Vector3(0.12, 2.4, 1.8), Vector3(-1.1, 1.6, 2.4), mat_accent)
	fin_l.rotation_degrees.z = -20.0
	var fin_r = _add_box(root, Vector3(0.12, 2.4, 1.8), Vector3(1.1, 1.6, 2.4), mat_accent)
	fin_r.rotation_degrees.z = 20.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 1.8, 0.45), Vector3(0.0, 0.0, 1.0), mat_hull)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 1.8, 0.45), Vector3(0.0, 0.0, 1.0), mat_hull)
	rudder_r.name = "RudderRight"

	# All-Moving Horizontal Stabilators (Elevators)
	var elev_l = _add_box(root, Vector3(2.1, 0.1, 1.4), Vector3(-1.8, 0.25, 3.4), mat_hull)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.1, 0.1, 1.4), Vector3(1.8, 0.25, 3.4), mat_hull)
	elev_r.name = "ElevatorRight"

	# Twin Turbofan Engine Exhausts
	var eng_l = _add_cyl(root, 0.52, 0.52, 1.4, Vector3(-0.65, 0.35, 3.8), mat_metal)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 0.52, 0.52, 1.4, Vector3(0.65, 0.35, 3.8), mat_metal)
	eng_r.rotation_degrees.x = 90.0

	# Afterburner Plume Rings
	var ab_l = _add_cyl(root, 0.45, 0.45, 0.2, Vector3(-0.65, 0.35, 4.4), mat_glow)
	ab_l.rotation_degrees.x = 90.0
	ab_l.name = "AfterburnerPlumeLeft"
	var ab_r = _add_cyl(root, 0.45, 0.45, 0.2, Vector3(0.65, 0.35, 4.4), mat_glow)
	ab_r.rotation_degrees.x = 90.0
	ab_r.name = "AfterburnerPlumeRight"

	# Tricycle Landing Gear Node
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	# Nose Gear (Forward)
	_add_cyl(gear_node, 0.06, 0.06, 1.4, Vector3(0.0, -0.7, -2.4), mat_metal)
	_add_cyl(gear_node, 0.22, 0.22, 0.12, Vector3(0.0, -1.35, -2.4), mat_metal)
	# Main Gear (Left & Right)
	_add_cyl(gear_node, 0.08, 0.08, 1.4, Vector3(-1.4, -0.7, 0.8), mat_metal)
	_add_cyl(gear_node, 0.28, 0.28, 0.18, Vector3(-1.4, -1.35, 0.8), mat_metal)
	_add_cyl(gear_node, 0.08, 0.08, 1.4, Vector3(1.4, -0.7, 0.8), mat_metal)
	_add_cyl(gear_node, 0.28, 0.28, 0.18, Vector3(1.4, -1.35, 0.8), mat_metal)

	return root

# ==============================================================================
# 2. F-22 RAPTOR (5TH-GEN STEALTH AIR SUPERIORITY)
# ==============================================================================

static func build_f22_raptor(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "F22Visuals"

	var mat_stealth = _create_pbr_material(hull_color, 0.65, 0.35, 0.95)
	var mat_accent = _create_pbr_material(accent_color, 0.50, 0.50, 0.90)
	var mat_metal = _create_pbr_material(Color(0.18, 0.19, 0.22), 0.90, 0.20, 0.70)
	var mat_canopy = _create_canopy_material(Color(0.25, 0.20, 0.12, 0.60)) # Gold-tinted indium tin oxide
	var mat_glow = _create_emissive_material(Color(0.2, 0.7, 1.0), 9.0) # Supersonic cyan reheat

	# Blended Wing-Body Faceted Fuselage
	_add_box(root, Vector3(2.4, 0.95, 8.6), Vector3(0.0, 0.35, 0.1), mat_stealth)
	var nose = _add_cone(root, 0.9, 3.2, Vector3(0.0, 0.28, -5.2), mat_stealth)
	nose.rotation_degrees.x = 90.0

	# Golden Stealth Canopy
	var canopy = _add_box(root, Vector3(0.9, 0.65, 2.6), Vector3(0.0, 0.88, -2.0), mat_canopy)
	canopy.name = "Canopy"

	# Diamond Delta Wings
	_add_box(root, Vector3(6.2, 0.1, 3.4), Vector3(-3.8, 0.32, 0.8), mat_stealth)
	_add_box(root, Vector3(6.2, 0.1, 3.4), Vector3(3.8, 0.32, 0.8), mat_stealth)

	# Control Surfaces: Ailerons / Flaperons
	var aileron_l = _add_box(root, Vector3(2.6, 0.08, 0.6), Vector3(-4.8, 0.32, 2.4), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.6, 0.08, 0.6), Vector3(4.8, 0.32, 2.4), mat_accent)
	aileron_r.name = "AileronRight"

	# Twin 28-Degree Canted Vertical Stabilizers
	var fin_l = _add_box(root, Vector3(0.12, 2.6, 2.2), Vector3(-1.3, 1.7, 2.6), mat_accent)
	fin_l.rotation_degrees.z = -28.0
	var fin_r = _add_box(root, Vector3(0.12, 2.6, 2.2), Vector3(1.3, 1.7, 2.6), mat_accent)
	fin_r.rotation_degrees.z = 28.0

	var rudder_l = _add_box(fin_l, Vector3(0.14, 2.0, 0.5), Vector3(0.0, 0.0, 1.1), mat_stealth)
	rudder_l.name = "RudderLeft"
	var rudder_r = _add_box(fin_r, Vector3(0.14, 2.0, 0.5), Vector3(0.0, 0.0, 1.1), mat_stealth)
	rudder_r.name = "RudderRight"

	# All-Moving Horizontal Stabilators
	var elev_l = _add_box(root, Vector3(2.4, 0.1, 1.6), Vector3(-2.2, 0.25, 4.0), mat_stealth)
	elev_l.name = "ElevatorLeft"
	var elev_r = _add_box(root, Vector3(2.4, 0.1, 1.6), Vector3(2.2, 0.25, 4.0), mat_stealth)
	elev_r.name = "ElevatorRight"

	# Thrust Vectoring 2D Pitch Nozzles (Rectangular stealth nozzles)
	var nozzle_l = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(-0.8, 0.32, 4.5), mat_metal)
	nozzle_l.name = "VectorNozzleLeft"
	var nozzle_r = _add_box(root, Vector3(0.85, 0.45, 1.2), Vector3(0.8, 0.32, 4.5), mat_metal)
	nozzle_r.name = "VectorNozzleRight"

	var ab_l = _add_box(nozzle_l, Vector3(0.7, 0.3, 0.15), Vector3(0.0, 0.0, 0.6), mat_glow)
	ab_l.name = "AfterburnerPlumeLeft"
	var ab_r = _add_box(nozzle_r, Vector3(0.7, 0.3, 0.15), Vector3(0.0, 0.0, 0.6), mat_glow)
	ab_r.name = "AfterburnerPlumeRight"

	# Retractable Gear
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_cyl(gear_node, 0.06, 0.06, 1.5, Vector3(0.0, -0.75, -2.8), mat_metal)
	_add_cyl(gear_node, 0.24, 0.24, 0.14, Vector3(0.0, -1.45, -2.8), mat_metal)
	_add_cyl(gear_node, 0.08, 0.08, 1.5, Vector3(-1.6, -0.75, 1.2), mat_metal)
	_add_cyl(gear_node, 0.30, 0.30, 0.20, Vector3(-1.6, -1.45, 1.2), mat_metal)
	_add_cyl(gear_node, 0.08, 0.08, 1.5, Vector3(1.6, -0.75, 1.2), mat_metal)
	_add_cyl(gear_node, 0.30, 0.30, 0.20, Vector3(1.6, -1.45, 1.2), mat_metal)

	return root

# ==============================================================================
# 3. A320 AIRLINER (COMMERCIAL TWIN-JET)
# ==============================================================================

static func build_a320_airliner(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "A320Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.2, 0.15, 0.95) # High-gloss white polyurethane
	var mat_accent = _create_pbr_material(accent_color, 0.3, 0.25, 0.90) # Airline blue cheatline
	var mat_metal = _create_pbr_material(Color(0.3, 0.32, 0.35), 0.75, 0.30, 0.75)
	var mat_window = _create_pbr_material(Color(0.05, 0.08, 0.12), 0.9, 0.05, 1.0)

	# Main Passenger Cabin Fuselage (37m scale cylinder)
	var cabin = _add_cyl(root, 1.8, 1.8, 18.0, Vector3(0.0, 1.2, 0.0), mat_hull)
	cabin.rotation_degrees.x = 90.0
	var nose = _add_sphere(root, 1.8, Vector3(0.0, 1.2, -9.0), mat_hull)
	var tail_cone = _add_cone(root, 1.8, 5.0, Vector3(0.0, 1.5, 10.5), mat_hull)
	tail_cone.rotation_degrees.x = -90.0

	# Cockpit Windshield & Passenger Window Strips
	_add_box(root, Vector3(1.4, 0.5, 0.8), Vector3(0.0, 2.1, -8.2), mat_window)
	_add_box(root, Vector3(3.62, 0.15, 13.0), Vector3(0.0, 1.6, -0.5), mat_window) # Window beltline

	# High-Aspect Swept Wings with Upward Winglets
	_add_box(root, Vector3(14.0, 0.22, 3.2), Vector3(-8.5, 0.4, 0.5), mat_hull)
	_add_box(root, Vector3(14.0, 0.22, 3.2), Vector3(8.5, 0.4, 0.5), mat_hull)
	var winglet_l = _add_box(root, Vector3(0.1, 1.2, 0.8), Vector3(-15.5, 1.0, 0.8), mat_accent)
	var winglet_r = _add_box(root, Vector3(0.1, 1.2, 0.8), Vector3(15.5, 1.0, 0.8), mat_accent)

	# Ailerons & Flaps
	var aileron_l = _add_box(root, Vector3(4.0, 0.1, 0.6), Vector3(-12.5, 0.4, 2.0), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(4.0, 0.1, 0.6), Vector3(12.5, 0.4, 2.0), mat_accent)
	aileron_r.name = "AileronRight"

	var flap_l = _add_box(root, Vector3(6.5, 0.14, 0.9), Vector3(-5.2, 0.35, 2.0), mat_metal)
	flap_l.name = "FlapLeft"
	var flap_r = _add_box(root, Vector3(6.5, 0.14, 0.9), Vector3(5.2, 0.35, 2.0), mat_metal)
	flap_r.name = "FlapRight"

	# Twin Underslung Turbofan Nacelles
	var eng_l = _add_cyl(root, 1.1, 1.1, 3.8, Vector3(-5.0, -0.4, -0.8), mat_hull)
	eng_l.rotation_degrees.x = 90.0
	var eng_r = _add_cyl(root, 1.1, 1.1, 3.8, Vector3(5.0, -0.4, -0.8), mat_hull)
	eng_r.rotation_degrees.x = 90.0

	var fan_l = _add_cyl(root, 0.95, 0.95, 0.2, Vector3(-5.0, -0.4, -2.6), mat_metal)
	fan_l.rotation_degrees.x = 90.0
	fan_l.name = "FanBladesLeft"
	var fan_r = _add_cyl(root, 0.95, 0.95, 0.2, Vector3(5.0, -0.4, -2.6), mat_metal)
	fan_r.rotation_degrees.x = 90.0
	fan_r.name = "FanBladesRight"

	# Vertical Fin & Rudder
	var fin = _add_box(root, Vector3(0.25, 4.8, 3.8), Vector3(0.0, 4.4, 9.8), mat_accent)
	var rudder = _add_box(fin, Vector3(0.28, 4.0, 1.1), Vector3(0.0, -0.2, 2.2), mat_hull)
	rudder.name = "Rudder"

	# Horizontal Tailplane & Elevators
	var htail_l = _add_box(root, Vector3(4.8, 0.15, 2.0), Vector3(-3.0, 2.2, 11.2), mat_hull)
	htail_l.name = "ElevatorLeft"
	var htail_r = _add_box(root, Vector3(4.8, 0.15, 2.0), Vector3(3.0, 2.2, 11.2), mat_hull)
	htail_r.name = "ElevatorRight"

	# Landing Gear (Multi-wheel)
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_cyl(gear_node, 0.12, 0.12, 2.2, Vector3(0.0, -0.2, -6.5), mat_metal)
	_add_cyl(gear_node, 0.38, 0.38, 0.30, Vector3(0.0, -1.3, -6.5), mat_metal)
	_add_cyl(gear_node, 0.16, 0.16, 2.2, Vector3(-3.5, -0.4, 0.8), mat_metal)
	_add_cyl(gear_node, 0.48, 0.48, 0.40, Vector3(-3.5, -1.4, 0.8), mat_metal)
	_add_cyl(gear_node, 0.16, 0.16, 2.2, Vector3(3.5, -0.4, 0.8), mat_metal)
	_add_cyl(gear_node, 0.48, 0.48, 0.40, Vector3(3.5, -1.4, 0.8), mat_metal)

	return root

# ==============================================================================
# 4. EXTRA 330 (UNLIMITED SPORT AEROBATIC MONOPLANE)
# ==============================================================================

static func build_extra330_sport(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "Extra330Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.15, 0.2, 0.95) # Red high gloss racing coat
	var mat_accent = _create_pbr_material(accent_color, 0.2, 0.25, 0.90)
	var mat_metal = _create_pbr_material(Color(0.2, 0.22, 0.24), 0.85, 0.20, 0.70)
	var mat_canopy = _create_canopy_material(Color(0.1, 0.15, 0.25, 0.55))

	# Tapered Aerobatic Fuselage
	_add_box(root, Vector3(0.85, 0.95, 4.8), Vector3(0.0, 0.25, 0.0), mat_hull)
	var cowl = _add_cyl(root, 0.48, 0.48, 1.1, Vector3(0.0, 0.25, -2.8), mat_accent)
	cowl.rotation_degrees.x = 90.0

	# Aerobatic Bubble Canopy
	var canopy = _add_box(root, Vector3(0.65, 0.55, 1.8), Vector3(0.0, 0.85, -0.4), mat_canopy)
	canopy.name = "Canopy"

	# Front 3-Blade Spinning Propeller
	var prop_root = Node3D.new()
	prop_root.name = "Propeller"
	prop_root.position = Vector3(0.0, 0.25, -3.4)
	root.add_child(prop_root)
	_add_cone(prop_root, 0.22, 0.45, Vector3(0.0, 0.0, -0.1), mat_accent).rotation_degrees.x = 90.0
	for i in range(3):
		var blade = _add_box(prop_root, Vector3(0.08, 0.95, 0.04), Vector3(0.0, 0.5, 0.0), mat_metal)
		blade.rotation_degrees.z = i * 120.0

	# Mid-Mount Symmetrical Wings
	_add_box(root, Vector3(6.8, 0.08, 1.4), Vector3(0.0, 0.18, -0.4), mat_hull)
	# Full-Span Counterbalanced Ailerons
	var aileron_l = _add_box(root, Vector3(2.8, 0.06, 0.45), Vector3(-2.0, 0.18, 0.45), mat_accent)
	aileron_l.name = "AileronLeft"
	var aileron_r = _add_box(root, Vector3(2.8, 0.06, 0.45), Vector3(2.0, 0.18, 0.45), mat_accent)
	aileron_r.name = "AileronRight"

	# Empennage & Large Aerobatic Rudder
	var fin = _add_box(root, Vector3(0.08, 1.3, 0.95), Vector3(0.0, 0.95, 2.2), mat_hull)
	var rudder = _add_box(fin, Vector3(0.1, 1.4, 0.65), Vector3(0.0, 0.0, 0.75), mat_accent)
	rudder.name = "Rudder"

	# Elevator
	var elev = _add_box(root, Vector3(2.4, 0.06, 0.65), Vector3(0.0, 0.35, 2.4), mat_accent)
	elev.name = "Elevator"

	# Taildragger Landing Gear with Aerodynamic Wheel Spats
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_box(gear_node, Vector3(0.18, 0.32, 0.55), Vector3(-0.95, -0.65, -1.1), mat_accent) # Left spat
	_add_box(gear_node, Vector3(0.18, 0.32, 0.55), Vector3(0.95, -0.65, -1.1), mat_accent) # Right spat
	_add_sphere(gear_node, 0.12, Vector3(0.0, -0.22, 2.4), mat_metal) # Tailwheel

	return root

# ==============================================================================
# 5. UH-60 BLACKHAWK (TACTICAL TRANSPORT ROTORCRAFT)
# ==============================================================================

static func build_uh60_helicopter(hull_color: Color, accent_color: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "UH60Visuals"

	var mat_hull = _create_pbr_material(hull_color, 0.85, 0.15, 0.10) # Low-reflective matte olive / tactical drab
	var mat_accent = _create_pbr_material(accent_color, 0.65, 0.25, 0.40)
	var mat_metal = _create_pbr_material(Color(0.18, 0.20, 0.22), 0.75, 0.25, 0.70)
	var mat_canopy = _create_canopy_material(Color(0.08, 0.12, 0.14, 0.75))

	# Fuselage Body & Cabin
	_add_box(root, Vector3(1.85, 1.75, 6.4), Vector3(0.0, 0.7, -0.2), mat_hull)
	# Cockpit Glazing
	_add_box(root, Vector3(1.65, 0.95, 1.4), Vector3(0.0, 0.85, -3.2), mat_canopy)

	# Main Rotor Mast & 4 Articulated Blades (16m diameter)
	var mast = _add_cyl(root, 0.25, 0.25, 0.75, Vector3(0.0, 1.9, -0.4), mat_metal)
	var rotor_root = Node3D.new()
	rotor_root.name = "MainRotor"
	rotor_root.position = Vector3(0.0, 2.3, -0.4)
	root.add_child(rotor_root)
	for i in range(4):
		var blade = _add_box(rotor_root, Vector3(0.22, 0.05, 7.8), Vector3(0.0, 0.0, 3.9), mat_metal)
		blade.rotation_degrees.y = i * 90.0

	# Angled Tail Boom & Canted Tail Rotor
	_add_box(root, Vector3(0.65, 0.65, 6.2), Vector3(0.0, 0.9, 5.8), mat_hull)
	var tail_pylon = _add_box(root, Vector3(0.2, 1.8, 1.2), Vector3(0.0, 1.8, 8.6), mat_hull)

	var tail_rotor_root = Node3D.new()
	tail_rotor_root.name = "TailRotor"
	tail_rotor_root.position = Vector3(0.25, 2.4, 8.8)
	root.add_child(tail_rotor_root)
	tail_rotor_root.rotation_degrees.z = 20.0 # 20 degree canted tail rotor
	for i in range(4):
		var t_blade = _add_box(tail_rotor_root, Vector3(0.08, 1.2, 0.04), Vector3(0.0, 0.6, 0.0), mat_metal)
		t_blade.rotation_degrees.x = i * 90.0

	# Horizontal Stabilator
	var stab = _add_box(root, Vector3(3.2, 0.1, 0.9), Vector3(0.0, 0.85, 8.4), mat_accent)
	stab.name = "Stabilator"

	# Fixed Heavy-Duty Main Gear Sponsons
	var gear_node = Node3D.new()
	gear_node.name = "LandingGear"
	root.add_child(gear_node)
	_add_cyl(gear_node, 0.1, 0.1, 1.4, Vector3(-1.3, -0.4, -0.6), mat_metal)
	_add_cyl(gear_node, 0.35, 0.35, 0.25, Vector3(-1.3, -1.0, -0.6), mat_metal)
	_add_cyl(gear_node, 0.1, 0.1, 1.4, Vector3(1.3, -0.4, -0.6), mat_metal)
	_add_cyl(gear_node, 0.35, 0.35, 0.25, Vector3(1.3, -1.0, -0.6), mat_metal)
	_add_cyl(gear_node, 0.22, 0.22, 0.18, Vector3(0.0, -0.4, 8.2), mat_metal) # Tailwheel

	# Rescue Hoist Boom
	var hoist = _add_box(root, Vector3(0.12, 0.12, 1.2), Vector3(1.05, 1.6, -1.8), mat_metal)
	hoist.name = "RescueHoist"

	return root

# ==============================================================================
# PRIMITIVE BUILDERS & PBR MATERIAL GENERATORS
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
	mi.mesh = cyl
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_cone(parent: Node, radius: float, height: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	return _add_cyl(parent, 0.01, radius, height, pos, mat)

static func _add_sphere(parent: Node, radius: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	mi.mesh = sph
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _add_wedge(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = _add_box(parent, size, pos, mat)
	mi.rotation_degrees.y = 15.0
	return mi

static func _create_pbr_material(albedo: Color, roughness: float, metallic: float, clearcoat: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	if clearcoat > 0.0:
		mat.clearcoat_enabled = true
		mat.clearcoat = clearcoat
		mat.clearcoat_roughness = 0.05
	return mat

static func _create_canopy_material(tint: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = tint
	mat.roughness = 0.05
	mat.metallic = 0.85
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
