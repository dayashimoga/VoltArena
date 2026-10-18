class_name RunwayBuilder
extends Node3D

## Procedural builder for the 60m x 3000m precision runway complex.
## Constructs asphalt surface, centerline stripes, threshold piano keys,
## touchdown zone bars, runway designators (09L/27R), edge lights, PAPI system,
## full taxiway network, 45m ATC tower, passenger terminal with jetways, perimeter fence,
## and surrounding rolling terrain with animated wind turbines.

const RUNWAY_WIDTH: float = 60.0
const RUNWAY_LENGTH: float = 3000.0
const EDGE_LIGHT_SPACING: float = 60.0
const GLIDE_SLOPE_DEG: float = 3.0

var runway_mesh_instance: MeshInstance3D
var runway_collision: CollisionShape3D
var papi_lights_container: Node3D
var edge_lights_container: Node3D

var turbine_rotors: Array[Node3D] = []
var beacon_light: OmniLight3D = null
var beacon_mesh: MeshInstance3D = null
var beacon_timer: float = 0.0

func _ready() -> void:
	build_runway_complex()

func _process(delta: float) -> void:
	# Rotate wind turbine blades
	for rotor in turbine_rotors:
		if is_instance_valid(rotor):
			rotor.rotate_z(1.2 * delta)
	
	# Pulsing ATC tower obstruction beacon
	beacon_timer += delta
	var beacon_state: bool = fmod(beacon_timer, 1.2) < 0.6
	if beacon_light:
		beacon_light.visible = beacon_state
	if beacon_mesh and beacon_mesh.material_override:
		var b_mat = beacon_mesh.material_override as StandardMaterial3D
		if b_mat:
			b_mat.emission_energy_multiplier = 4.0 if beacon_state else 0.2

func build_runway_complex() -> void:
	# Root position is at (0, 0.05, 0)
	position = Vector3(0.0, 0.05, 0.0)

	_build_asphalt_deck()
	_build_runway_markings()
	_build_edge_lights()
	_build_papi_system()
	_build_taxiway_network()
	_build_airport_structures()

func _build_asphalt_deck() -> void:
	runway_mesh_instance = MeshInstance3D.new()
	runway_mesh_instance.name = "RunwayAsphalt"

	var plane_size = Vector3(RUNWAY_WIDTH, 0.15, RUNWAY_LENGTH)
	var plane_mesh = _create_box_mesh(plane_size)
	runway_mesh_instance.mesh = plane_mesh
	runway_mesh_instance.position = Vector3(0.0, -0.075, -RUNWAY_LENGTH * 0.5 + 50.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.14, 0.14, 0.15)
	mat.roughness = 0.85
	mat.metallic = 0.02
	runway_mesh_instance.material_override = mat

	# Add StaticBody3D collision for runway deck
	var static_body = StaticBody3D.new()
	static_body.name = "RunwayCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 2
	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = plane_size
	col_shape.shape = box_shape
	static_body.add_child(col_shape)
	runway_mesh_instance.add_child(static_body)

	add_child(runway_mesh_instance)

func _build_runway_markings() -> void:
	var markings_node = Node3D.new()
	markings_node.name = "RunwayMarkings"

	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.96, 0.96, 0.97)
	white_mat.roughness = 0.70

	# 1. Dashed Centerline (30m long dashes with 20m gaps)
	var dash_len = 30.0
	var gap_len = 20.0
	var total_step = dash_len + gap_len
	var z_start = 50.0
	var z_end = -RUNWAY_LENGTH + 50.0

	var multimesh_inst = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var dash_count = int(RUNWAY_LENGTH / total_step)
	mm.instance_count = dash_count
	var dash_mesh = _create_box_mesh(Vector3(1.2, 0.02, dash_len))
	mm.mesh = dash_mesh
	multimesh_inst.material_override = white_mat

	var idx = 0
	var cur_z = z_start - 60.0
	while cur_z > z_end + 60.0 and idx < dash_count:
		var t = Transform3D(Basis(), Vector3(0.0, 0.085, cur_z))
		mm.set_instance_transform(idx, t)
		cur_z -= total_step
		idx += 1
	multimesh_inst.multimesh = mm
	markings_node.add_child(multimesh_inst)

	# 2. Threshold Piano Keys (Approach End 09L at Z = +20, and Departure End 27R at Z = z_end + 20)
	for end_z in [z_start - 25.0, z_end + 25.0]:
		for side in [-1, 1]:
			for k in range(6):
				var key = MeshInstance3D.new()
				var km = _create_box_mesh(Vector3(2.2, 0.02, 35.0))
				key.mesh = km
				key.material_override = white_mat
				var x_pos = side * (6.0 + k * 4.0)
				key.position = Vector3(x_pos, 0.085, end_z)
				markings_node.add_child(key)

	# 3. Touchdown Zone Bars (150m, 300m Aim Point, 450m, 600m from both thresholds)
	for base_threshold in [z_start, z_end]:
		var dir_sign: float = -1.0 if base_threshold == z_start else 1.0
		# Standard distances: 150m (3 bars), 300m (aiming point block), 450m (2 bars), 600m (1 bar)
		var tdz_distances = [150.0, 300.0, 450.0, 600.0]
		for d in tdz_distances:
			var tdz_z = base_threshold + dir_sign * d
			if d == 300.0:
				# Aiming point marker: large high-visibility rectangular blocks (45m x 10m each side)
				for side in [-1, 1]:
					var aim_block = MeshInstance3D.new()
					aim_block.mesh = _create_box_mesh(Vector3(9.0, 0.02, 45.0))
					aim_block.material_override = white_mat
					aim_block.position = Vector3(side * 16.0, 0.085, tdz_z)
					markings_node.add_child(aim_block)
			else:
				# Pairs of touchdown zone bars
				var bar_count: int = 3 if d == 150.0 else (2 if d == 450.0 else 1)
				for side in [-1, 1]:
					for b in range(bar_count):
						var bar = MeshInstance3D.new()
						bar.mesh = _create_box_mesh(Vector3(1.8, 0.02, 22.5))
						bar.material_override = white_mat
						bar.position = Vector3(side * (13.0 + b * 3.5), 0.085, tdz_z)
						markings_node.add_child(bar)

	# 4. Runway Designators (09L at threshold 09, 27R at threshold 27)
	_build_runway_designators(markings_node, z_start - 75.0, "09L")
	_build_runway_designators(markings_node, z_end + 75.0, "27R")

	add_child(markings_node)

func _build_runway_designators(parent: Node3D, z_pos: float, text_label: String) -> void:
	var des_mat = StandardMaterial3D.new()
	des_mat.albedo_color = Color(0.96, 0.96, 0.97)
	des_mat.roughness = 0.7

	# Build distinct geometric designation blocks for "09L" / "27R"
	var des_node = Node3D.new()
	des_node.name = "Designator_" + text_label
	des_node.position = Vector3(0.0, 0.085, z_pos)

	if text_label == "09L":
		# Left numeral "0"
		var box0_l = MeshInstance3D.new()
		box0_l.mesh = _create_box_mesh(Vector3(1.6, 0.02, 14.0))
		box0_l.material_override = des_mat
		box0_l.position = Vector3(-8.0, 0, 0)
		des_node.add_child(box0_l)

		var box0_r = MeshInstance3D.new()
		box0_r.mesh = _create_box_mesh(Vector3(1.6, 0.02, 14.0))
		box0_r.material_override = des_mat
		box0_r.position = Vector3(-4.0, 0, 0)
		des_node.add_child(box0_r)

		var box0_t = MeshInstance3D.new()
		box0_t.mesh = _create_box_mesh(Vector3(5.6, 0.02, 1.6))
		box0_t.material_override = des_mat
		box0_t.position = Vector3(-6.0, 0, 6.2)
		des_node.add_child(box0_t)

		var box0_b = MeshInstance3D.new()
		box0_b.mesh = _create_box_mesh(Vector3(5.6, 0.02, 1.6))
		box0_b.material_override = des_mat
		box0_b.position = Vector3(-6.0, 0, -6.2)
		des_node.add_child(box0_b)

		# Right numeral "9"
		var box9_stem = MeshInstance3D.new()
		box9_stem.mesh = _create_box_mesh(Vector3(1.6, 0.02, 14.0))
		box9_stem.material_override = des_mat
		box9_stem.position = Vector3(2.0, 0, 0)
		des_node.add_child(box9_stem)

		var box9_loop = MeshInstance3D.new()
		box9_loop.mesh = _create_box_mesh(Vector3(4.5, 0.02, 7.0))
		box9_loop.material_override = des_mat
		box9_loop.position = Vector3(-0.5, 0, 3.5)
		des_node.add_child(box9_loop)

		# Sub-designator "L"
		var box_l_stem = MeshInstance3D.new()
		box_l_stem.mesh = _create_box_mesh(Vector3(1.6, 0.02, 12.0))
		box_l_stem.material_override = des_mat
		box_l_stem.position = Vector3(7.5, 0, 0)
		des_node.add_child(box_l_stem)

		var box_l_foot = MeshInstance3D.new()
		box_l_foot.mesh = _create_box_mesh(Vector3(5.0, 0.02, 1.6))
		box_l_foot.material_override = des_mat
		box_l_foot.position = Vector3(9.2, 0, -5.2)
		des_node.add_child(box_l_foot)
	else:
		# Designator "27R"
		var box2 = MeshInstance3D.new()
		box2.mesh = _create_box_mesh(Vector3(6.0, 0.02, 14.0))
		box2.material_override = des_mat
		box2.position = Vector3(-7.0, 0, 0)
		des_node.add_child(box2)

		var box7 = MeshInstance3D.new()
		box7.mesh = _create_box_mesh(Vector3(6.0, 0.02, 14.0))
		box7.material_override = des_mat
		box7.position = Vector3(0.0, 0, 0)
		des_node.add_child(box7)

		var box_r = MeshInstance3D.new()
		box_r.mesh = _create_box_mesh(Vector3(5.5, 0.02, 14.0))
		box_r.material_override = des_mat
		box_r.position = Vector3(7.0, 0, 0)
		des_node.add_child(box_r)

	parent.add_child(des_node)

func _build_edge_lights() -> void:
	edge_lights_container = Node3D.new()
	edge_lights_container.name = "RunwayEdgeLights"

	var light_mat = StandardMaterial3D.new()
	light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light_mat.albedo_color = Color(1.0, 0.95, 0.85)

	var z_start = 50.0
	var steps = int(RUNWAY_LENGTH / EDGE_LIGHT_SPACING)

	for i in range(steps + 1):
		var z = z_start - i * EDGE_LIGHT_SPACING
		# Left edge light (X = -RUNWAY_WIDTH * 0.5)
		_create_fixture(Vector3(-RUNWAY_WIDTH * 0.5 - 0.6, 0.35, z), light_mat)
		# Right edge light (X = +RUNWAY_WIDTH * 0.5)
		_create_fixture(Vector3(RUNWAY_WIDTH * 0.5 + 0.6, 0.35, z), light_mat)

	add_child(edge_lights_container)

func _create_fixture(pos: Vector3, mat: Material) -> void:
	var post = MeshInstance3D.new()
	var post_mesh = _create_cyl_mesh(0.08, 0.08, 0.5, 12)
	post.mesh = post_mesh
	post.position = pos

	var lens = MeshInstance3D.new()
	var lens_mesh = _create_sphere_mesh(0.12, 6, 8)
	lens.mesh = lens_mesh
	lens.material_override = mat
	lens.position = Vector3(0.0, 0.25, 0.0)
	post.add_child(lens)

	edge_lights_container.add_child(post)

func _build_papi_system() -> void:
	papi_lights_container = Node3D.new()
	papi_lights_container.name = "PAPI_Lights"

	# Located 300m down the runway on the left side (standard touchdown aim point)
	var papi_z = -300.0
	var base_x = -RUNWAY_WIDTH * 0.5 - 16.0 # 16m off left runway edge

	# 4 PAPI light units spaced 9m apart laterally
	for u in range(4):
		var unit_node = Node3D.new()
		unit_node.name = "PAPI_Unit_%d" % (u + 1)
		var ux = base_x - u * 9.0
		unit_node.position = Vector3(ux, 0.5, papi_z)

		var housing = MeshInstance3D.new()
		var hm = _create_box_mesh(Vector3(1.4, 0.6, 1.2))
		housing.mesh = hm
		var h_mat = StandardMaterial3D.new()
		h_mat.albedo_color = Color(0.85, 0.8, 0.1) # Aviation Yellow housing
		housing.material_override = h_mat
		unit_node.add_child(housing)

		# Light projector
		var projector = MeshInstance3D.new()
		var pm = _create_sphere_mesh(0.2, 6, 8)
		projector.mesh = pm
		var p_mat = StandardMaterial3D.new()
		p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# 2 White / 2 Red at nominal 3.0 deg
		p_mat.albedo_color = Color(1.0, 1.0, 1.0) if u < 2 else Color(1.0, 0.1, 0.05)
		projector.material_override = p_mat
		projector.position = Vector3(0.0, 0.05, 0.6)
		unit_node.add_child(projector)

		papi_lights_container.add_child(unit_node)

	add_child(papi_lights_container)

## Builds 24m wide parallel taxiway at X = +75m, with 5 high-speed turnoff connectors,
## blue taxiway edge lights, green centerline lights, and collision bodies.
func _build_taxiway_network() -> void:
	var twy_node = Node3D.new()
	twy_node.name = "TaxiwayNetwork"

	var twy_mat = StandardMaterial3D.new()
	twy_mat.albedo_color = Color(0.18, 0.18, 0.20)
	twy_mat.roughness = 0.88

	var blue_mat = StandardMaterial3D.new()
	blue_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blue_mat.albedo_color = Color(0.15, 0.45, 1.0)

	var green_mat = StandardMaterial3D.new()
	green_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	green_mat.albedo_color = Color(0.15, 0.95, 0.25)

	var twy_x: float = 75.0
	var twy_width: float = 24.0
	var z_start: float = 50.0
	var z_end: float = -RUNWAY_LENGTH + 50.0

	# 1. Parallel Taxiway Deck
	var main_twy = MeshInstance3D.new()
	main_twy.name = "ParallelTaxiwayDeck"
	var twy_size = Vector3(twy_width, 0.14, RUNWAY_LENGTH)
	main_twy.mesh = _create_box_mesh(twy_size)
	main_twy.material_override = twy_mat
	main_twy.position = Vector3(twy_x, -0.075, -RUNWAY_LENGTH * 0.5 + 50.0)

	var static_twy = StaticBody3D.new()
	static_twy.collision_layer = 1
	var twy_col = CollisionShape3D.new()
	var twy_box = BoxShape3D.new()
	twy_box.size = twy_size
	twy_col.shape = twy_box
	static_twy.add_child(twy_col)
	main_twy.add_child(static_twy)
	twy_node.add_child(main_twy)

	# 2. Taxiway High-Speed Turnoff & Threshold Connectors
	var connector_zs = [z_start - 10.0, -500.0, -1200.0, -2000.0, z_end + 10.0]
	for cz in connector_zs:
		var conn = MeshInstance3D.new()
		var conn_len: float = twy_x
		var conn_size = Vector3(conn_len, 0.14, twy_width)
		conn.mesh = _create_box_mesh(conn_size)
		conn.material_override = twy_mat
		conn.position = Vector3(conn_len * 0.5, -0.075, cz)

		var static_conn = StaticBody3D.new()
		static_conn.collision_layer = 1
		var conn_col = CollisionShape3D.new()
		var c_box = BoxShape3D.new()
		c_box.size = conn_size
		conn_col.shape = c_box
		static_conn.add_child(conn_col)
		conn.add_child(static_conn)
		twy_node.add_child(conn)

	# 3. Taxiway Edge Lights (Blue) and Centerline Lights (Green)
	var twy_light_step: float = 40.0
	var total_twy_steps = int(RUNWAY_LENGTH / twy_light_step)
	for s in range(total_twy_steps + 1):
		var z = z_start - s * twy_light_step
		# Blue edge lights
		_create_marker_light(twy_node, Vector3(twy_x - twy_width * 0.5 - 0.4, 0.28, z), blue_mat)
		_create_marker_light(twy_node, Vector3(twy_x + twy_width * 0.5 + 0.4, 0.28, z), blue_mat)
		# Green centerline in-pavement light
		_create_marker_light(twy_node, Vector3(twy_x, 0.08, z), green_mat, 0.08)

	add_child(twy_node)

func _create_marker_light(parent: Node3D, pos: Vector3, mat: Material, radius: float = 0.1) -> void:
	var light = MeshInstance3D.new()
	light.mesh = _create_sphere_mesh(radius, 4, 6)
	light.material_override = mat
	light.position = pos
	parent.add_child(light)

## Builds 45m concrete ATC tower with observation cab, radome, beacon,
## passenger terminal with jetways, perimeter fence, and wind turbines in surrounding terrain.
func _build_airport_structures() -> void:
	var struct_node = Node3D.new()
	struct_node.name = "AirportStructures"

	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.78, 0.79, 0.82)
	concrete_mat.roughness = 0.65

	var dark_metal_mat = StandardMaterial3D.new()
	dark_metal_mat.albedo_color = Color(0.25, 0.26, 0.28)
	dark_metal_mat.metallic = 0.8
	dark_metal_mat.roughness = 0.3

	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.18, 0.45, 0.65, 0.6)
	glass_mat.metallic = 0.95
	glass_mat.roughness = 0.08

	var terminal_wall_mat = StandardMaterial3D.new()
	terminal_wall_mat.albedo_color = Color(0.85, 0.86, 0.90)
	terminal_wall_mat.metallic = 0.3
	terminal_wall_mat.roughness = 0.4

	# 1. 45m Air Traffic Control (ATC) Tower (At X = +135m, Z = -1500m)
	var tower_root = Node3D.new()
	tower_root.name = "ATCTower"
	tower_root.position = Vector3(135.0, 0.0, -1500.0)

	# Shaft (40m high, 4m radius)
	var shaft = MeshInstance3D.new()
	shaft.mesh = _create_cyl_mesh(3.6, 4.6, 40.0, 16)
	shaft.material_override = concrete_mat
	shaft.position = Vector3(0, 20.0, 0)
	tower_root.add_child(shaft)

	# Observation Cab (Height 6m, radius 7.5m, glass)
	var cab = MeshInstance3D.new()
	cab.mesh = _create_cyl_mesh(7.8, 6.2, 6.0, 16)
	cab.material_override = glass_mat
	cab.position = Vector3(0, 43.0, 0)
	tower_root.add_child(cab)

	# Cab Roof
	var cab_roof = MeshInstance3D.new()
	cab_roof.mesh = _create_cyl_mesh(8.2, 8.2, 0.8, 16)
	cab_roof.material_override = dark_metal_mat
	cab_roof.position = Vector3(0, 46.4, 0)
	tower_root.add_child(cab_roof)

	# Radome Dome on Roof
	var radome = MeshInstance3D.new()
	radome.mesh = _create_sphere_mesh(2.8, 8, 12)
	var radome_mat = StandardMaterial3D.new()
	radome_mat.albedo_color = Color(0.95, 0.95, 0.96)
	radome.material_override = radome_mat
	radome.position = Vector3(0, 48.8, 0)
	tower_root.add_child(radome)

	# Obstruction Red Beacon on top of Radome
	beacon_mesh = MeshInstance3D.new()
	beacon_mesh.mesh = _create_sphere_mesh(0.45, 6, 8)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(1.0, 0.05, 0.05)
	b_mat.emission_enabled = true
	b_mat.emission = Color(1.0, 0.05, 0.05)
	b_mat.emission_energy_multiplier = 4.0
	beacon_mesh.material_override = b_mat
	beacon_mesh.position = Vector3(0, 52.0, 0)
	tower_root.add_child(beacon_mesh)

	beacon_light = OmniLight3D.new()
	beacon_light.light_color = Color(1.0, 0.1, 0.1)
	beacon_light.light_energy = 3.5
	beacon_light.omni_range = 180.0
	beacon_mesh.add_child(beacon_light)

	# Tower Collider
	var tower_body = StaticBody3D.new()
	tower_body.collision_layer = 1
	var tower_col = CollisionShape3D.new()
	var t_cyl = CylinderShape3D.new()
	t_cyl.height = 46.0
	t_cyl.radius = 5.0
	tower_col.shape = t_cyl
	tower_col.position = Vector3(0, 23.0, 0)
	tower_body.add_child(tower_col)
	tower_root.add_child(tower_body)

	struct_node.add_child(tower_root)

	# 2. Modern Passenger Terminal with Jetways (At X = +150m, Z = -1100m)
	var term_root = Node3D.new()
	term_root.name = "PassengerTerminal"
	term_root.position = Vector3(150.0, 0.0, -1100.0)

	# Main Terminal Building (180m length, 45m width, 16m height)
	var term_mesh = MeshInstance3D.new()
	var term_size = Vector3(45.0, 16.0, 180.0)
	term_mesh.mesh = _create_box_mesh(term_size)
	term_mesh.material_override = terminal_wall_mat
	term_mesh.position = Vector3(0, 8.0, 0)
	term_root.add_child(term_mesh)

	# Glass facade facing the runway/apron
	var facade = MeshInstance3D.new()
	facade.mesh = _create_box_mesh(Vector3(1.2, 12.0, 170.0))
	facade.material_override = glass_mat
	facade.position = Vector3(-22.0, 8.0, 0)
	term_root.add_child(facade)

	# 4 Passenger Jetways extending toward apron
	for j in range(4):
		var jz: float = -60.0 + j * 40.0
		var jetway = Node3D.new()
		jetway.name = "Jetway_%d" % (j + 1)
		jetway.position = Vector3(-22.0, 5.0, jz)

		var bridge = MeshInstance3D.new()
		bridge.mesh = _create_box_mesh(Vector3(18.0, 3.4, 3.2))
		bridge.material_override = dark_metal_mat
		bridge.position = Vector3(-9.0, 0, 0)
		jetway.add_child(bridge)

		var cab_head = MeshInstance3D.new()
		cab_head.mesh = _create_box_mesh(Vector3(4.0, 3.8, 4.0))
		cab_head.material_override = terminal_wall_mat
		cab_head.position = Vector3(-18.0, 0, 0)
		jetway.add_child(cab_head)

		term_root.add_child(jetway)

	# Terminal Collider
	var term_body = StaticBody3D.new()
	term_body.collision_layer = 1
	var term_col = CollisionShape3D.new()
	var t_box = BoxShape3D.new()
	t_box.size = term_size
	term_col.shape = t_box
	term_col.position = Vector3(0, 8.0, 0)
	term_body.add_child(term_col)
	term_root.add_child(term_body)

	struct_node.add_child(term_root)

	# 3. Perimeter Security Fencing
	var fence_mat = StandardMaterial3D.new()
	fence_mat.albedo_color = Color(0.45, 0.48, 0.52)
	fence_mat.metallic = 0.7
	fence_mat.roughness = 0.5

	# West side fence line (at X = -75m, running full length)
	var west_fence = MeshInstance3D.new()
	west_fence.mesh = _create_box_mesh(Vector3(0.4, 3.0, RUNWAY_LENGTH + 200.0))
	west_fence.material_override = fence_mat
	west_fence.position = Vector3(-75.0, 1.5, -RUNWAY_LENGTH * 0.5 + 50.0)
	struct_node.add_child(west_fence)

	# East side fence line (at X = +210m, running full length)
	var east_fence = MeshInstance3D.new()
	east_fence.mesh = _create_box_mesh(Vector3(0.4, 3.0, RUNWAY_LENGTH + 200.0))
	east_fence.material_override = fence_mat
	east_fence.position = Vector3(210.0, 1.5, -RUNWAY_LENGTH * 0.5 + 50.0)
	struct_node.add_child(east_fence)

	# 4. Foothill Wind Turbines with 3-blade Spinning Rotors
	var turbine_positions = [
		Vector3(-550.0, 45.0, -400.0),
		Vector3(-720.0, 85.0, -1400.0),
		Vector3(-610.0, 60.0, -2400.0),
		Vector3(650.0, 50.0, -600.0),
		Vector3(780.0, 90.0, -1600.0),
		Vector3(690.0, 70.0, -2600.0)
	]

	var turbine_mat = StandardMaterial3D.new()
	turbine_mat.albedo_color = Color(0.92, 0.93, 0.95)
	turbine_mat.roughness = 0.45

	for i in range(turbine_positions.size()):
		var t_pos = turbine_positions[i]
		var turbine = Node3D.new()
		turbine.name = "WindTurbine_%d" % (i + 1)
		turbine.position = t_pos

		# 75m Tower
		var tower = MeshInstance3D.new()
		tower.mesh = _create_cyl_mesh(1.6, 3.5, 75.0, 12)
		tower.material_override = turbine_mat
		tower.position = Vector3(0, 37.5, 0)
		turbine.add_child(tower)

		# Nacelle at top
		var nacelle = MeshInstance3D.new()
		nacelle.mesh = _create_box_mesh(Vector3(3.2, 3.0, 9.0))
		nacelle.material_override = turbine_mat
		nacelle.position = Vector3(0, 75.0, 0)
		turbine.add_child(nacelle)

		# Hub and 3-Blade Rotor
		var rotor_hub = Node3D.new()
		rotor_hub.name = "RotorHub"
		rotor_hub.position = Vector3(0, 75.0, 4.8)

		var nose_cone = MeshInstance3D.new()
		nose_cone.mesh = _create_sphere_mesh(1.8, 6, 8)
		nose_cone.material_override = turbine_mat
		rotor_hub.add_child(nose_cone)

		# 3 aerodynamic blades spaced 120 degrees apart
		for b in range(3):
			var blade_pivot = Node3D.new()
			blade_pivot.rotation.z = deg_to_rad(b * 120.0)

			var blade = MeshInstance3D.new()
			blade.mesh = _create_box_mesh(Vector3(1.2, 36.0, 0.3))
			blade.material_override = turbine_mat
			blade.position = Vector3(0, 18.0, 0)
			blade_pivot.add_child(blade)

			rotor_hub.add_child(blade_pivot)

		turbine.add_child(rotor_hub)
		turbine_rotors.append(rotor_hub)

		struct_node.add_child(turbine)

	add_child(struct_node)

static func _create_box_mesh(size: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var faces = [
		[Vector3(0, 0, 1), [Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]],
		[Vector3(0, 0, -1), [Vector3(hx, -hy, -hz), Vector3(-hx, -hy, -hz), Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz)]],
		[Vector3(1, 0, 0), [Vector3(hx, -hy, hz), Vector3(hx, -hy, -hz), Vector3(hx, hy, -hz), Vector3(hx, hy, hz)]],
		[Vector3(-1, 0, 0), [Vector3(-hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(-hx, hy, hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, 1, 0), [Vector3(-hx, hy, hz), Vector3(hx, hy, hz), Vector3(hx, hy, -hz), Vector3(-hx, hy, -hz)]],
		[Vector3(0, -1, 0), [Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz)]]
	]
	for f in faces:
		var norm: Vector3 = f[0]
		var v: Array = f[1]
		st.set_normal(norm)
		st.add_vertex(v[0]); st.add_vertex(v[1]); st.add_vertex(v[2])
		st.add_vertex(v[0]); st.add_vertex(v[2]); st.add_vertex(v[3])
	return st.commit()

static func _create_cyl_mesh(top_r: float, bot_r: float, height: float, seg: int = 12) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hy: float = height * 0.5
	for i in range(seg):
		var a0: float = float(i) / float(seg) * TAU
		var a1: float = float(i + 1) / float(seg) * TAU
		var p_b0 = Vector3(cos(a0) * bot_r, -hy, sin(a0) * bot_r)
		var p_b1 = Vector3(cos(a1) * bot_r, -hy, sin(a1) * bot_r)
		var p_t0 = Vector3(cos(a0) * top_r, hy, sin(a0) * top_r)
		var p_t1 = Vector3(cos(a1) * top_r, hy, sin(a1) * top_r)
		var n0 = Vector3(cos(a0), 0, sin(a0)).normalized()
		var n1 = Vector3(cos(a1), 0, sin(a1)).normalized()
		st.set_normal(n0); st.add_vertex(p_b0)
		st.set_normal(n1); st.add_vertex(p_b1)
		st.set_normal(n1); st.add_vertex(p_t1)
		st.set_normal(n0); st.add_vertex(p_b0)
		st.set_normal(n1); st.add_vertex(p_t1)
		st.set_normal(n0); st.add_vertex(p_t0)
		st.set_normal(Vector3(0, 1, 0))
		st.add_vertex(Vector3(0, hy, 0)); st.add_vertex(p_t0); st.add_vertex(p_t1)
		st.set_normal(Vector3(0, -1, 0))
		st.add_vertex(Vector3(0, -hy, 0)); st.add_vertex(p_b1); st.add_vertex(p_b0)
	return st.commit()

static func _create_sphere_mesh(r: float, rings: int = 6, seg: int = 8) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings):
		var lat0 = PI * (-0.5 + float(i) / float(rings))
		var z0 = sin(lat0) * r
		var zr0 = cos(lat0) * r
		var lat1 = PI * (-0.5 + float(i + 1) / float(rings))
		var z1 = sin(lat1) * r
		var zr1 = cos(lat1) * r
		for j in range(seg):
			var lng0 = float(j) / float(seg) * TAU
			var lng1 = float(j + 1) / float(seg) * TAU
			var p0 = Vector3(cos(lng0) * zr0, z0, sin(lng0) * zr0)
			var p1 = Vector3(cos(lng1) * zr0, z0, sin(lng1) * zr0)
			var p2 = Vector3(cos(lng1) * zr1, z1, sin(lng1) * zr1)
			var p3 = Vector3(cos(lng0) * zr1, z1, sin(lng0) * zr1)
			st.set_normal(p0.normalized()); st.add_vertex(p0)
			st.set_normal(p1.normalized()); st.add_vertex(p1)
			st.set_normal(p2.normalized()); st.add_vertex(p2)
			st.set_normal(p0.normalized()); st.add_vertex(p0)
			st.set_normal(p2.normalized()); st.add_vertex(p2)
			st.set_normal(p3.normalized()); st.add_vertex(p3)
	return st.commit()
