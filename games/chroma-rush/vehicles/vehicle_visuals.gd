class_name VehicleVisuals
extends RefCounted

## Constructs 3D vehicle visual meshes for all 6 archetypes in Chroma Rush
## Features dynamic gameplay color illumination, accessibility symbols,
## cosmetic paint finishes, and rotating wheels.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")

static func build_vehicle_visual(vehicle_id: String, base_color: int = ChromaConstants.ChromaColor.CRIMSON, paint_finish: String = "metallic") -> Node3D:
	var root = Node3D.new()
	root.name = "VehicleVisual"

	var body_node = Node3D.new()
	body_node.name = "ChassisBody"
	root.add_child(body_node)

	# Build archetype-specific chassis
	match vehicle_id:
		ChromaConstants.VEHICLE_VORTEX:
			_build_vortex_chassis(body_node, paint_finish)
		ChromaConstants.VEHICLE_TITAN:
			_build_titan_chassis(body_node, paint_finish)
		ChromaConstants.VEHICLE_PULSE:
			_build_pulse_chassis(body_node, paint_finish)
		ChromaConstants.VEHICLE_DUNE:
			_build_dune_chassis(body_node, paint_finish)
		ChromaConstants.VEHICLE_QUANTUM:
			_build_quantum_chassis(body_node, paint_finish)
		_: # Apex Striker
			_build_apex_chassis(body_node, paint_finish)

	# Build 4 wheels
	_build_wheels(root, vehicle_id)

	# Build dynamic gameplay color emissive panels
	var color_panels = Node3D.new()
	color_panels.name = "GameplayColorPanels"
	root.add_child(color_panels)
	_build_color_panels(color_panels, vehicle_id)

	# Build 3D accessibility symbol billboard
	var symbol_node = _build_symbol_billboard(base_color)
	symbol_node.name = "AccessibilitySymbol"
	symbol_node.position = Vector3(0, 1.85, 0)
	root.add_child(symbol_node)

	# Apply initial gameplay color to color panels
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
		mat.roughness = 0.2
		mat.metallic = 0.5

		for child in panels.get_children():
			if child is MeshInstance3D:
				child.material_override = mat

	# Update accessibility symbol
	var symbol_node = vehicle_visual.get_node_or_null("AccessibilitySymbol") as Label3D
	if symbol_node:
		symbol_node.text = ChromaConstants.get_color_symbol(color_id)
		symbol_node.modulate = col.lightened(0.2)

static func _build_wheels(root: Node3D, vehicle_id: String) -> void:
	var wheel_mesh = CylinderMesh.new()
	wheel_mesh.top_radius = 0.36
	wheel_mesh.bottom_radius = 0.36
	wheel_mesh.height = 0.26

	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.12, 0.12, 0.14)
	rim_mat.metallic = 0.8
	rim_mat.roughness = 0.3

	var positions = [
		Vector3(-0.85, 0.36, -1.25), # Front-Left
		Vector3(0.85, 0.36, -1.25),  # Front-Right
		Vector3(-0.90, 0.38, 1.30),   # Rear-Left
		Vector3(0.90, 0.38, 1.30)    # Rear-Right
	]
	var names = ["FrontWheelLeft", "FrontWheelRight", "RearWheelLeft", "RearWheelRight"]

	for i in range(4):
		var mi = MeshInstance3D.new()
		mi.name = names[i]
		mi.mesh = wheel_mesh
		mi.material_override = rim_mat
		mi.rotation_degrees = Vector3(0, 0, 90) # Orient cylinder as wheel
		mi.position = positions[i]
		root.add_child(mi)

static func _build_color_panels(panels_root: Node3D, vehicle_id: String) -> void:
	# Roof beacon / dorsal fin
	var fin = MeshInstance3D.new()
	fin.name = "DorsalFin"
	var fin_mesh = BoxMesh.new()
	fin_mesh.size = Vector3(0.08, 0.35, 0.9)
	fin.mesh = fin_mesh
	fin.position = Vector3(0, 1.35, 0.2)
	panels_root.add_child(fin)

	# Left & Right body contour light runners
	var runner_mesh = BoxMesh.new()
	runner_mesh.size = Vector3(0.12, 0.12, 2.8)

	var left_runner = MeshInstance3D.new()
	left_runner.name = "LeftRunner"
	left_runner.mesh = runner_mesh
	left_runner.position = Vector3(-0.82, 0.55, 0.0)
	panels_root.add_child(left_runner)

	var right_runner = MeshInstance3D.new()
	right_runner.name = "RightRunner"
	right_runner.mesh = runner_mesh
	right_runner.position = Vector3(0.82, 0.55, 0.0)
	panels_root.add_child(right_runner)

	# Underglow ground illuminator
	var underglow = MeshInstance3D.new()
	underglow.name = "Underglow"
	var ug_mesh = BoxMesh.new()
	ug_mesh.size = Vector3(1.4, 0.04, 2.6)
	underglow.mesh = ug_mesh
	underglow.position = Vector3(0, 0.15, 0.0)
	panels_root.add_child(underglow)

static func _build_symbol_billboard(base_color: int) -> Label3D:
	var label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.pixel_size = 0.012
	label.font_size = 48
	label.outline_size = 8
	label.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	label.text = ChromaConstants.get_color_symbol(base_color)
	label.modulate = ChromaConstants.get_color_value(base_color)
	return label

static func _build_apex_chassis(body: Node3D, paint_finish: String) -> void:
	# Wedge supercar body
	var mat = _create_paint_material(Color(0.15, 0.16, 0.20), paint_finish)

	var lower = MeshInstance3D.new()
	var lower_mesh = BoxMesh.new()
	lower_mesh.size = Vector3(1.7, 0.45, 3.8)
	lower.mesh = lower_mesh
	lower.position = Vector3(0, 0.45, 0)
	lower.material_override = mat
	body.add_child(lower)

	var cabin = MeshInstance3D.new()
	var cabin_mesh = PrismMesh.new()
	cabin_mesh.size = Vector3(1.3, 0.65, 1.8)
	cabin.mesh = cabin_mesh
	cabin.rotation_degrees = Vector3(0, 180, 0)
	cabin.position = Vector3(0, 0.95, -0.2)
	cabin.material_override = mat
	body.add_child(cabin)

	# Rear GT Wing
	var wing = MeshInstance3D.new()
	var wing_mesh = BoxMesh.new()
	wing_mesh.size = Vector3(1.6, 0.08, 0.4)
	wing.mesh = wing_mesh
	wing.position = Vector3(0, 1.15, 1.6)
	wing.material_override = mat
	body.add_child(wing)

static func _build_vortex_chassis(body: Node3D, paint_finish: String) -> void:
	# Wide-body street tuner
	var mat = _create_paint_material(Color(0.22, 0.12, 0.18), paint_finish)

	var main_box = MeshInstance3D.new()
	var mb_mesh = BoxMesh.new()
	mb_mesh.size = Vector3(1.8, 0.52, 3.6)
	main_box.mesh = mb_mesh
	main_box.position = Vector3(0, 0.48, 0)
	main_box.material_override = mat
	body.add_child(main_box)

	var greenhouse = MeshInstance3D.new()
	var gh_mesh = BoxMesh.new()
	gh_mesh.size = Vector3(1.25, 0.55, 1.6)
	greenhouse.mesh = gh_mesh
	greenhouse.position = Vector3(0, 0.98, 0.1)
	greenhouse.material_override = mat
	body.add_child(greenhouse)

static func _build_titan_chassis(body: Node3D, paint_finish: String) -> void:
	# Heavy armored interceptor
	var mat = _create_paint_material(Color(0.18, 0.20, 0.18), paint_finish)

	var heavy_box = MeshInstance3D.new()
	var hb_mesh = BoxMesh.new()
	hb_mesh.size = Vector3(1.95, 0.75, 4.0)
	heavy_box.mesh = hb_mesh
	heavy_box.position = Vector3(0, 0.65, 0)
	heavy_box.material_override = mat
	body.add_child(heavy_box)

	# Bull bar
	var bull_bar = MeshInstance3D.new()
	var bb_mesh = BoxMesh.new()
	bb_mesh.size = Vector3(1.8, 0.5, 0.25)
	bull_bar.mesh = bb_mesh
	bull_bar.position = Vector3(0, 0.55, -2.1)
	var bb_mat = StandardMaterial3D.new()
	bb_mat.albedo_color = Color(0.08, 0.08, 0.09)
	bb_mat.metallic = 0.9
	bull_bar.material_override = bb_mat
	body.add_child(bull_bar)

static func _build_pulse_chassis(body: Node3D, paint_finish: String) -> void:
	# Sleek cyber EV
	var mat = _create_paint_material(Color(0.10, 0.18, 0.25), paint_finish)

	var monocoque = MeshInstance3D.new()
	var mono_mesh = CapsuleMesh.new()
	mono_mesh.radius = 0.65
	mono_mesh.height = 3.6
	monocoque.mesh = mono_mesh
	monocoque.rotation_degrees = Vector3(90, 0, 0)
	monocoque.position = Vector3(0, 0.65, 0)
	monocoque.material_override = mat
	body.add_child(monocoque)

static func _build_dune_chassis(body: Node3D, paint_finish: String) -> void:
	# All-terrain trophy truck
	var mat = _create_paint_material(Color(0.25, 0.20, 0.14), paint_finish)

	var cab = MeshInstance3D.new()
	var cab_mesh = BoxMesh.new()
	cab_mesh.size = Vector3(1.6, 0.75, 2.2)
	cab.mesh = cab_mesh
	cab.position = Vector3(0, 0.85, -0.4)
	cab.material_override = mat
	body.add_child(cab)

	# Rollcage tubes
	var cage = MeshInstance3D.new()
	var cage_mesh = BoxMesh.new()
	cage_mesh.size = Vector3(1.5, 0.70, 1.4)
	cage.mesh = cage_mesh
	cage.position = Vector3(0, 0.85, 1.2)
	var cage_mat = StandardMaterial3D.new()
	cage_mat.albedo_color = Color(0.1, 0.1, 0.1)
	cage.material_override = cage_mat
	body.add_child(cage)

static func _build_quantum_chassis(body: Node3D, paint_finish: String) -> void:
	# Experimental lev-chassis
	var mat = _create_paint_material(Color(0.12, 0.14, 0.28), paint_finish)

	var needle = MeshInstance3D.new()
	var needle_mesh = CylinderMesh.new()
	needle_mesh.top_radius = 0.2
	needle_mesh.bottom_radius = 0.7
	needle_mesh.height = 3.8
	needle.mesh = needle_mesh
	needle.rotation_degrees = Vector3(90, 0, 0)
	needle.position = Vector3(0, 0.55, 0)
	needle.material_override = mat
	body.add_child(needle)

	# Dual outriggers
	var left_pod = MeshInstance3D.new()
	var pod_mesh = BoxMesh.new()
	pod_mesh.size = Vector3(0.35, 0.35, 2.4)
	left_pod.mesh = pod_mesh
	left_pod.position = Vector3(-0.95, 0.45, 0.2)
	left_pod.material_override = mat
	body.add_child(left_pod)

	var right_pod = MeshInstance3D.new()
	right_pod.mesh = pod_mesh
	right_pod.position = Vector3(0.95, 0.45, 0.2)
	right_pod.material_override = mat
	body.add_child(right_pod)

static func _create_paint_material(base_tint: Color, finish: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = base_tint
	match finish:
		"matte":
			mat.metallic = 0.1
			mat.roughness = 0.85
		"gloss":
			mat.metallic = 0.2
			mat.roughness = 0.15
			mat.clearcoat_enabled = true
			mat.clearcoat = 1.0
		"iridescent":
			mat.metallic = 0.75
			mat.roughness = 0.25
			mat.rim_enabled = true
			mat.rim = 0.8
		"carbon":
			mat.albedo_color = Color(0.08, 0.08, 0.10)
			mat.metallic = 0.4
			mat.roughness = 0.5
		_: # "metallic"
			mat.metallic = 0.85
			mat.roughness = 0.25
	return mat
