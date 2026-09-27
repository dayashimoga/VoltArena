class_name VehicleVisuals
extends RefCounted

## High-fidelity procedural automotive visual builder for Chroma Rush.
## Generates realistic production vehicles with authentic proportions,
## bodywork, glasshouse canopies, headlights, taillights, alloy wheels with tires,
## dynamic gameplay color panels, accessibility symbols, and paint finishes.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const MaterialGenerator = preload("res://shared/graphics/material_generator.gd")

static func build_vehicle_visual(vehicle_id: String, base_color: int = ChromaConstants.ChromaColor.CRIMSON, paint_finish: String = "metallic") -> Node3D:
	var root = Node3D.new()
	root.name = "VehicleVisual"

	var body_node = Node3D.new()
	body_node.name = "ChassisBody"
	root.add_child(body_node)

	# 1. Build authentic vehicle bodywork for archetype
	match vehicle_id:
		ChromaConstants.VEHICLE_VORTEX:
			_build_vortex_coupe(body_node, paint_finish)
		ChromaConstants.VEHICLE_TITAN:
			_build_titan_muscle(body_node, paint_finish)
		ChromaConstants.VEHICLE_PULSE:
			_build_pulse_ev(body_node, paint_finish)
		ChromaConstants.VEHICLE_DUNE:
			_build_dune_truck(body_node, paint_finish)
		ChromaConstants.VEHICLE_QUANTUM:
			_build_quantum_exotic(body_node, paint_finish)
		_: # Apex Striker
			_build_apex_gt(body_node, paint_finish)

	# 2. Build 4 realistic alloy wheels with radial rubber tires
	_build_wheels(root, vehicle_id)

	# 3. Build dynamic gameplay color emissive panels
	var color_panels = Node3D.new()
	color_panels.name = "GameplayColorPanels"
	root.add_child(color_panels)
	_build_color_panels(color_panels, vehicle_id)

	# 4. Build 3D accessibility symbol billboard
	var symbol_node = _build_symbol_billboard(base_color)
	symbol_node.name = "AccessibilitySymbol"
	symbol_node.position = Vector3(0, 1.85, 0)
	root.add_child(symbol_node)

	# 5. Apply initial gameplay color to color panels
	apply_gameplay_color(root, base_color)

	return root

static func apply_gameplay_color(vehicle_visual: Node3D, color_id: int) -> void:
	if not is_instance_valid(vehicle_visual):
		return

	var col = ChromaConstants.get_color_value(color_id)
	var panels = vehicle_visual.get_node_or_null("GameplayColorPanels")
	if panels:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 2.4
		mat.roughness = 0.25
		mat.metallic = 0.55

		for child in panels.get_children():
			if child is MeshInstance3D:
				child.material_override = mat

	# Update accessibility symbol
	var symbol_node = vehicle_visual.get_node_or_null("AccessibilitySymbol") as Label3D
	if symbol_node:
		symbol_node.text = ChromaConstants.get_color_symbol(color_id)
		symbol_node.modulate = col.lightened(0.2)

# ==============================================================================
# REALISTIC WHEEL BUILDER
# ==============================================================================

static func _build_wheels(root: Node3D, vehicle_id: String) -> void:
	var is_offroad = (vehicle_id == ChromaConstants.VEHICLE_DUNE)
	var tire_radius = 0.44 if is_offroad else 0.36
	var tire_width = 0.34 if is_offroad else 0.28
	var rim_radius = 0.26 if is_offroad else 0.27

	# Materials
	var mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.12, 0.12, 0.14)
	mat_tire.roughness = 0.90
	mat_tire.metallic = 0.05

	var mat_rim = StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.85, 0.88, 0.92)
	mat_rim.metallic = 0.92
	mat_rim.roughness = 0.18

	var mat_caliper = StandardMaterial3D.new()
	mat_caliper.albedo_color = Color(0.85, 0.15, 0.15)
	mat_caliper.roughness = 0.3

	var positions = [
		Vector3(-0.95, tire_radius, -1.28), # Front-Left
		Vector3(0.95, tire_radius, -1.28),  # Front-Right
		Vector3(-0.98, tire_radius, 1.32),  # Rear-Left
		Vector3(0.98, tire_radius, 1.32)   # Rear-Right
	]
	var names = ["FrontWheelLeft", "FrontWheelRight", "RearWheelLeft", "RearWheelRight"]

	for i in range(4):
		var wheel_root = Node3D.new()
		wheel_root.name = names[i]
		wheel_root.position = positions[i]
		root.add_child(wheel_root)

		# 1. Outer Rubber Tire
		var tire_mesh = CylinderMesh.new()
		tire_mesh.top_radius = tire_radius
		tire_mesh.bottom_radius = tire_radius
		tire_mesh.height = tire_width
		var tire_mi = MeshInstance3D.new()
		tire_mi.name = "TireMesh"
		tire_mi.mesh = tire_mesh
		tire_mi.material_override = mat_tire
		tire_mi.rotation_degrees.z = 90.0
		wheel_root.add_child(tire_mi)

		# 2. Inset Aluminum Alloy Rim
		var rim_mesh = CylinderMesh.new()
		rim_mesh.top_radius = rim_radius
		rim_mesh.bottom_radius = rim_radius
		rim_mesh.height = tire_width + 0.02
		var rim_mi = MeshInstance3D.new()
		rim_mi.name = "RimMesh"
		rim_mi.mesh = rim_mesh
		rim_mi.material_override = mat_rim
		rim_mi.rotation_degrees.z = 90.0
		wheel_root.add_child(rim_mi)

		# 3. Center Cap / Hub
		var hub_mesh = CylinderMesh.new()
		hub_mesh.top_radius = 0.08
		hub_mesh.bottom_radius = 0.08
		hub_mesh.height = tire_width + 0.04
		var hub_mi = MeshInstance3D.new()
		hub_mi.mesh = hub_mesh
		hub_mi.material_override = mat_rim
		hub_mi.rotation_degrees.z = 90.0
		wheel_root.add_child(hub_mi)

# ==============================================================================
# ARCHETYPE 1: APEX STRIKER (GT SPORTS COUPE)
# ==============================================================================

static func _build_apex_gt(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.18, 0.22, 0.28))
	var mat_glass = _get_glass_material()
	var mat_carbon = _get_carbon_material()
	var mat_chrome = _get_chrome_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# 1. Main Lower Monocoque Chassis
	_add_box(body, Vector3(1.78, 0.38, 3.80), Vector3(0, 0.38, 0.0), mat_body)

	# 2. Sloped Aerodynamic Front Hood (-Z is forward)
	var hood = _add_box(body, Vector3(1.64, 0.18, 1.35), Vector3(0, 0.44, -1.25), mat_body)
	hood.rotation_degrees.x = 11.0

	# 3. Front Bumper with Lower Carbon Splitter
	_add_box(body, Vector3(1.82, 0.24, 0.45), Vector3(0, 0.26, -1.90), mat_body)
	_add_box(body, Vector3(1.90, 0.06, 0.50), Vector3(0, 0.14, -1.95), mat_carbon)
	# Radiator Grille Mesh
	_add_box(body, Vector3(1.10, 0.16, 0.08), Vector3(0, 0.28, -2.10), mat_carbon)

	# 4. High-Intensity LED Headlights
	for side in [-0.62, 0.62]:
		var hl = _add_box(body, Vector3(0.28, 0.09, 0.20), Vector3(side, 0.44, -1.82), mat_headlight)
		hl.rotation_degrees.y = -signf(side) * 15.0

	# 5. Cockpit Glasshouse Canopy (Windshield, Roof, Windows)
	# Cabin Roof
	_add_box(body, Vector3(1.30, 0.32, 1.45), Vector3(0, 0.88, 0.05), mat_body)
	# Sloped Windshield
	var win_f = _add_box(body, Vector3(1.28, 0.42, 0.80), Vector3(0, 0.74, -0.65), mat_glass)
	win_f.rotation_degrees.x = 35.0
	# Rear Windshield
	var win_r = _add_box(body, Vector3(1.24, 0.36, 0.75), Vector3(0, 0.74, 0.75), mat_glass)
	win_r.rotation_degrees.x = -28.0
	# Side Windows
	for side in [-0.66, 0.66]:
		_add_box(body, Vector3(0.04, 0.34, 1.30), Vector3(side, 0.80, 0.05), mat_glass)

	# 6. Carbon Rear Spoiler Wing with Pylons (+Z is rear)
	_add_box(body, Vector3(1.95, 0.06, 0.38), Vector3(0, 1.15, 1.70), mat_carbon)
	for side in [-0.65, 0.65]:
		_add_box(body, Vector3(0.06, 0.35, 0.12), Vector3(side, 0.95, 1.68), mat_carbon)

	# 7. Rear Bumper, Diffuser & Taillights
	_add_box(body, Vector3(1.78, 0.30, 0.40), Vector3(0, 0.38, 1.85), mat_body)
	_add_box(body, Vector3(1.65, 0.16, 0.35), Vector3(0, 0.22, 1.95), mat_carbon)
	for side in [-0.58, 0.58]:
		_add_box(body, Vector3(0.32, 0.08, 0.08), Vector3(side, 0.52, 1.98), mat_taillight)

	# Dual Exhaust Tips
	for side in [-0.35, 0.35]:
		var ex = _add_cyl(body, 0.06, 0.06, 0.16, Vector3(side, 0.24, 2.05), mat_chrome)
		ex.rotation_degrees.x = 90.0

# ==============================================================================
# ARCHETYPE 2: VORTEX DRIFT (TUNER DRIFT COUPE)
# ==============================================================================

static func _build_vortex_coupe(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.14, 0.18, 0.24))
	var mat_glass = _get_glass_material()
	var mat_carbon = _get_carbon_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# Widebody Tuner Chassis with Flared Fenders
	_add_box(body, Vector3(1.88, 0.36, 3.75), Vector3(0, 0.36, 0.0), mat_body)
	# Aggressive Hood with Dual Heat Extractors
	var hood = _add_box(body, Vector3(1.68, 0.16, 1.30), Vector3(0, 0.42, -1.22), mat_body)
	hood.rotation_degrees.x = 10.0
	_add_box(body, Vector3(0.70, 0.04, 0.40), Vector3(0, 0.48, -1.25), mat_carbon)

	# Extended Front Drift Splitter & Canards
	_add_box(body, Vector3(1.96, 0.06, 0.55), Vector3(0, 0.12, -1.95), mat_carbon)
	for side in [-0.60, 0.60]:
		_add_box(body, Vector3(0.30, 0.08, 0.18), Vector3(side, 0.40, -1.82), mat_headlight)

	# Low-Profile Cockpit Canopy
	_add_box(body, Vector3(1.28, 0.30, 1.40), Vector3(0, 0.82, 0.05), mat_body)
	var win = _add_box(body, Vector3(1.26, 0.40, 0.78), Vector3(0, 0.70, -0.62), mat_glass)
	win.rotation_degrees.x = 34.0
	_add_box(body, Vector3(1.24, 0.34, 0.70), Vector3(0, 0.70, 0.72), mat_glass).rotation_degrees.x = -26.0

	# Massive Swan-Neck Drift Wing
	_add_box(body, Vector3(2.10, 0.05, 0.42), Vector3(0, 1.25, 1.72), mat_carbon)
	for side in [-0.55, 0.55]:
		_add_box(body, Vector3(0.05, 0.45, 0.15), Vector3(side, 1.05, 1.70), mat_carbon)

	# Full-Width Rear LED Taillight Bar
	_add_box(body, Vector3(1.50, 0.07, 0.06), Vector3(0, 0.48, 1.96), mat_taillight)

# ==============================================================================
# ARCHETYPE 3: TITAN VANGUARD (HEAVY MUSCLE GT)
# ==============================================================================

static func _build_titan_muscle(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.24, 0.16, 0.16))
	var mat_glass = _get_glass_material()
	var mat_carbon = _get_carbon_material()
	var mat_chrome = _get_chrome_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# Muscular, Boxy High-Shoulder Chassis
	_add_box(body, Vector3(1.92, 0.44, 3.90), Vector3(0, 0.42, 0.0), mat_body)
	# Domed Hood with Massive Supercharger Air Intake
	var hood = _add_box(body, Vector3(1.74, 0.22, 1.45), Vector3(0, 0.52, -1.25), mat_body)
	hood.rotation_degrees.x = 7.0
	_add_box(body, Vector3(0.55, 0.14, 0.55), Vector3(0, 0.65, -1.15), mat_chrome)

	# Aggressive Chrome Honeycomb Grille & Bumper
	_add_box(body, Vector3(1.50, 0.28, 0.10), Vector3(0, 0.35, -2.00), mat_chrome)
	# Quad Round Halo Headlights
	for side in [-0.68, -0.45, 0.45, 0.68]:
		var hl = _add_cyl(body, 0.08, 0.08, 0.10, Vector3(side, 0.42, -1.98), mat_headlight)
		hl.rotation_degrees.x = 90.0

	# Fastback Muscle Cabin
	_add_box(body, Vector3(1.36, 0.35, 1.50), Vector3(0, 0.90, 0.08), mat_body)
	var win = _add_box(body, Vector3(1.32, 0.44, 0.75), Vector3(0, 0.78, -0.65), mat_glass)
	win.rotation_degrees.x = 32.0
	_add_box(body, Vector3(1.30, 0.38, 0.85), Vector3(0, 0.76, 0.85), mat_glass).rotation_degrees.x = -22.0

	# Integrated Ducktail Spoiler
	_add_box(body, Vector3(1.85, 0.12, 0.25), Vector3(0, 0.72, 1.90), mat_carbon)
	# Dual Quad Taillights
	for side in [-0.65, -0.40, 0.40, 0.65]:
		_add_box(body, Vector3(0.14, 0.10, 0.06), Vector3(side, 0.48, 1.98), mat_taillight)

# ==============================================================================
# ARCHETYPE 4: PULSE CYBER (MODERN HYPER EV)
# ==============================================================================

static func _build_pulse_ev(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.12, 0.16, 0.22))
	var mat_glass = _get_glass_material()
	var mat_carbon = _get_carbon_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# Teardrop Low-Drag Aerodynamic Monocoque
	_add_box(body, Vector3(1.82, 0.34, 3.80), Vector3(0, 0.35, 0.0), mat_body)
	# Sloped Low Nose
	var hood = _add_box(body, Vector3(1.60, 0.16, 1.40), Vector3(0, 0.38, -1.30), mat_body)
	hood.rotation_degrees.x = 14.0

	# Full-Width Seamless LED Laser Headlight Bar
	_add_box(body, Vector3(1.65, 0.05, 0.08), Vector3(0, 0.38, -1.96), mat_headlight)

	# Continuous Glass Canopy Roof
	_add_box(body, Vector3(1.32, 0.38, 2.20), Vector3(0, 0.78, 0.05), mat_glass)

	# Active Aero Underfloor Diffuser
	_add_box(body, Vector3(1.70, 0.14, 0.45), Vector3(0, 0.18, 1.85), mat_carbon)
	# Thin Horizontal Rear LED Strip
	_add_box(body, Vector3(1.70, 0.04, 0.06), Vector3(0, 0.52, 1.95), mat_taillight)

# ==============================================================================
# ARCHETYPE 5: DUNE NOMAD (ALL-TERRAIN TROPHY BUGGY)
# ==============================================================================

static func _build_dune_truck(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.28, 0.22, 0.16))
	var mat_metal = _get_chrome_material()
	var mat_carbon = _get_carbon_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# Raised High-Clearance Trophy Chassis
	_add_box(body, Vector3(1.70, 0.38, 3.40), Vector3(0, 0.52, 0.0), mat_body)
	# Heavy Steel Bullbar with Front Skid Plate
	var skid = _add_box(body, Vector3(1.50, 0.08, 0.85), Vector3(0, 0.32, -1.65), mat_metal)
	skid.rotation_degrees.x = 24.0

	# Tubular Roll Cage Exoskeleton Frame
	for sx in [-0.70, 0.70]:
		_add_box(body, Vector3(0.06, 0.85, 0.06), Vector3(sx, 1.05, -0.65), mat_metal)
		_add_box(body, Vector3(0.06, 0.95, 0.06), Vector3(sx, 1.10, 0.45), mat_metal)
		_add_box(body, Vector3(0.06, 0.06, 1.20), Vector3(sx, 1.50, -0.10), mat_metal)
	_add_box(body, Vector3(1.46, 0.06, 0.06), Vector3(0, 1.50, -0.65), mat_metal)
	_add_box(body, Vector3(1.46, 0.06, 0.06), Vector3(0, 1.50, 0.45), mat_metal)

	# Roof-Mounted Quad LED High-Beam Rally Pods
	for lx in [-0.45, -0.15, 0.15, 0.45]:
		var pod = _add_cyl(body, 0.06, 0.08, 0.12, Vector3(lx, 1.60, -0.62), mat_headlight)
		pod.rotation_degrees.x = 90.0

	# Dual Front Bumper Headlights
	for bx in [-0.55, 0.55]:
		var hl = _add_cyl(body, 0.08, 0.10, 0.10, Vector3(bx, 0.52, -1.75), mat_headlight)
		hl.rotation_degrees.x = 90.0

	# Rear High-Mounted Taillight Strip
	_add_box(body, Vector3(1.20, 0.08, 0.08), Vector3(0, 0.75, 1.70), mat_taillight)

# ==============================================================================
# ARCHETYPE 6: QUANTUM PHANTOM (LE MANS EXOTIC PROTOTYPE)
# ==============================================================================

static func _build_quantum_exotic(body: Node3D, finish: String) -> void:
	var mat_body = _get_paint_material(finish, Color(0.14, 0.14, 0.18))
	var mat_glass = _get_glass_material()
	var mat_carbon = _get_carbon_material()
	var mat_headlight = _get_headlight_material()
	var mat_taillight = _get_taillight_material()

	# Ultra-Low Prototype Monocoque Chassis
	_add_box(body, Vector3(1.85, 0.28, 4.10), Vector3(0, 0.30, 0.0), mat_body)
	# Dual Front Wheel Pontoon Fenders with Air Tunnels
	for side in [-0.75, 0.75]:
		_add_box(body, Vector3(0.35, 0.28, 1.50), Vector3(side, 0.38, -1.30), mat_body)
		_add_box(body, Vector3(0.18, 0.06, 0.15), Vector3(side, 0.42, -1.95), mat_headlight)

	# Central Needle Nose & Front Carbon Wing
	_add_box(body, Vector3(0.60, 0.18, 1.40), Vector3(0, 0.30, -1.40), mat_body)
	_add_box(body, Vector3(1.95, 0.05, 0.35), Vector3(0, 0.12, -2.05), mat_carbon)

	# Bubble Canopy Cockpit
	var canopy = _add_cyl(body, 0.35, 0.55, 1.20, Vector3(0, 0.70, -0.10), mat_glass)
	canopy.rotation_degrees.x = 75.0

	# Dorsal Shark Fin Stabilizer along Spine
	_add_box(body, Vector3(0.04, 0.50, 1.80), Vector3(0, 0.90, 0.90), mat_carbon)

	# Dual-Plane High-Downforce Rear Wing
	_add_box(body, Vector3(2.05, 0.05, 0.45), Vector3(0, 1.15, 1.95), mat_carbon)
	_add_box(body, Vector3(1.90, 0.04, 0.35), Vector3(0, 0.95, 1.90), mat_carbon)

	# Vertical Rear LED Blades
	for side in [-0.85, 0.85]:
		_add_box(body, Vector3(0.04, 0.45, 0.06), Vector3(side, 0.85, 2.05), mat_taillight)

# ==============================================================================
# DYNAMIC GAMEPLAY COLOR ILLUMINATION PANELS
# ==============================================================================

static func _build_color_panels(panels_root: Node3D, vehicle_id: String) -> void:
	# 1. Dual Racing Stripes along Hood and Roof
	var stripe_mesh = BoxMesh.new()
	stripe_mesh.size = Vector3(0.24, 0.03, 2.40)
	var stripe_l = MeshInstance3D.new()
	stripe_l.name = "ColorStripeLeft"
	stripe_l.mesh = stripe_mesh
	stripe_l.position = Vector3(-0.25, 0.75, -0.40)
	panels_root.add_child(stripe_l)

	var stripe_r = MeshInstance3D.new()
	stripe_r.name = "ColorStripeRight"
	stripe_r.mesh = stripe_mesh
	stripe_r.position = Vector3(0.25, 0.75, -0.40)
	panels_root.add_child(stripe_r)

	# 2. Left & Right Flank Aero Accent Blades
	var blade_mesh = BoxMesh.new()
	blade_mesh.size = Vector3(0.08, 0.10, 2.20)

	var blade_l = MeshInstance3D.new()
	blade_l.name = "ColorBladeLeft"
	blade_l.mesh = blade_mesh
	blade_l.position = Vector3(-0.92, 0.46, 0.0)
	panels_root.add_child(blade_l)

	var blade_r = MeshInstance3D.new()
	blade_r.name = "ColorBladeRight"
	blade_r.mesh = blade_mesh
	blade_r.position = Vector3(0.92, 0.46, 0.0)
	panels_root.add_child(blade_r)

	# 3. Rear Wing Emissive Accent Strip
	var wing_accent = MeshInstance3D.new()
	wing_accent.name = "ColorWingAccent"
	var wa_mesh = BoxMesh.new()
	wa_mesh.size = Vector3(1.70, 0.03, 0.12)
	wing_accent.mesh = wa_mesh
	wing_accent.position = Vector3(0, 1.18, 1.70)
	panels_root.add_child(wing_accent)

	# 4. Chassis Ground Underglow Bar
	var underglow = MeshInstance3D.new()
	underglow.name = "Underglow"
	var ug_mesh = BoxMesh.new()
	ug_mesh.size = Vector3(1.50, 0.04, 2.80)
	underglow.mesh = ug_mesh
	underglow.position = Vector3(0, 0.15, 0.0)
	panels_root.add_child(underglow)

# ==============================================================================
# ACCESSIBILITY 3D SYMBOL BILLBOARD
# ==============================================================================

static func _build_symbol_billboard(color_id: int) -> Label3D:
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.text = ChromaConstants.get_color_symbol(color_id)
	label.font_size = 46
	label.outline_size = 8
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.95)
	var col = ChromaConstants.get_color_value(color_id)
	label.modulate = col.lightened(0.2)
	return label

# ==============================================================================
# PBR MATERIAL FACTORY HELPERS
# ==============================================================================

static func _get_paint_material(finish: String, base_tint: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_tint
	match finish.to_lower():
		"matte":
			mat.metallic = 0.05
			mat.roughness = 0.82
			mat.clearcoat_enabled = false
		"gloss":
			mat.metallic = 0.35
			mat.roughness = 0.12
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.70
		"pearl", "iridescent":
			mat.metallic = 0.75
			mat.roughness = 0.22
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.95
		_: # Metallic
			mat.metallic = 0.88
			mat.roughness = 0.20
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.50
	return mat

static func _get_glass_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.08, 0.12, 0.90)
	mat.metallic = 0.90
	mat.roughness = 0.06
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	return mat

static func _get_carbon_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.10, 0.12)
	mat.roughness = 0.45
	mat.metallic = 0.60
	return mat

static func _get_chrome_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.94, 0.96)
	mat.metallic = 0.98
	mat.roughness = 0.08
	return mat

static func _get_headlight_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.98, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.92, 0.96, 1.0)
	mat.emission_energy_multiplier = 3.5
	return mat

static func _get_taillight_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.10, 0.12)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.05, 0.08)
	mat.emission_energy_multiplier = 3.0
	return mat

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _add_cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = h
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
