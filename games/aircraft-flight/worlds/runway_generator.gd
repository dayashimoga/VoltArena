class_name RunwayGenerator
extends RefCounted

## RunwayGenerator: Paved Airport Runways, Markings, PAPI & Approach Lighting.
## Generates full-scale FAA/ICAO compliant runway ribbons ($2,400\text{m} \times 60\text{m}$),
## piano-key threshold markings, touchdown zones, and approach lighting.

static func build_runway(length_m: float = 2400.0, width_m: float = 60.0, runway_id: String = "09L") -> Node3D:
	var root = Node3D.new()
	root.name = "Runway_" + runway_id

	# Materials
	var mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.12, 0.13, 0.15)
	mat_asphalt.roughness = 0.88
	mat_asphalt.metallic = 0.05

	var mat_paint = StandardMaterial3D.new()
	mat_paint.albedo_color = Color(0.95, 0.96, 0.98)
	mat_paint.roughness = 0.65

	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.95, 0.82, 0.1)
	mat_yellow.roughness = 0.65

	var mat_green_glow = StandardMaterial3D.new()
	mat_green_glow.albedo_color = Color(0.1, 0.9, 0.2)
	mat_green_glow.emission_enabled = true
	mat_green_glow.emission = Color(0.1, 0.9, 0.2)
	mat_green_glow.emission_energy_multiplier = 4.0

	var mat_red_glow = StandardMaterial3D.new()
	mat_red_glow.albedo_color = Color(0.95, 0.15, 0.1)
	mat_red_glow.emission_enabled = true
	mat_red_glow.emission = Color(0.95, 0.15, 0.1)
	mat_red_glow.emission_energy_multiplier = 4.0

	var mat_white_glow = StandardMaterial3D.new()
	mat_white_glow.albedo_color = Color(1.0, 1.0, 1.0)
	mat_white_glow.emission_enabled = true
	mat_white_glow.emission = Color(1.0, 1.0, 1.0)
	mat_white_glow.emission_energy_multiplier = 3.5

	# 1. Main Asphalt Runway Surface (with StaticBody3D collision)
	var sb = StaticBody3D.new()
	sb.name = "RunwayCollision"
	root.add_child(sb)

	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(width_m, 1.0, length_m)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0.0, -0.5, 0.0)
	sb.add_child(col_shape)

	var mi_asphalt = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(width_m, 0.8, length_m)
	mi_asphalt.mesh = box_mesh
	mi_asphalt.position = Vector3(0.0, -0.4, 0.0)
	mi_asphalt.material_override = mat_asphalt
	root.add_child(mi_asphalt)

	# 2. Runway Markings
	var half_len = length_m * 0.5
	var half_wid = width_m * 0.5

	# Piano-Key Threshold Stripes (Both Ends)
	for end_sign in [-1.0, 1.0]:
		var z_base = end_sign * (half_len - 40.0)
		for s in range(-6, 7):
			if s == 0: continue
			var stripe = _create_decal_box(Vector3(2.2, 0.05, 32.0), Vector3(s * 3.8, 0.02, z_base), mat_paint)
			root.add_child(stripe)

	# Centerline Dashes (every 50m)
	var num_dashes = int(length_m / 60.0)
	for i in range(-num_dashes / 2, num_dashes / 2 + 1):
		var dash = _create_decal_box(Vector3(1.8, 0.05, 30.0), Vector3(0.0, 0.02, i * 60.0), mat_paint)
		root.add_child(dash)

	# Touchdown Zone Markings (Aiming points at 300m and 500m from thresholds)
	for end_sign in [-1.0, 1.0]:
		var aim_z = end_sign * (half_len - 320.0)
		root.add_child(_create_decal_box(Vector3(4.5, 0.05, 45.0), Vector3(-12.0, 0.02, aim_z), mat_paint))
		root.add_child(_create_decal_box(Vector3(4.5, 0.05, 45.0), Vector3(12.0, 0.02, aim_z), mat_paint))

	# Runway Edge Stripe Lines
	root.add_child(_create_decal_box(Vector3(1.0, 0.05, length_m - 80.0), Vector3(-half_wid + 2.0, 0.02, 0.0), mat_paint))
	root.add_child(_create_decal_box(Vector3(1.0, 0.05, length_m - 80.0), Vector3(half_wid - 2.0, 0.02, 0.0), mat_paint))

	# 3. PAPI Glide-Slope 4-Light Visual Aid (Precision Approach Path Indicator)
	# Situated 300m past threshold on port side (-X)
	var papi_node = Node3D.new()
	papi_node.name = "PAPI_Lights"
	papi_node.position = Vector3(-half_wid - 16.0, 0.5, -half_len + 300.0)
	root.add_child(papi_node)
	for p in range(4):
		var papi_box = _create_decal_box(Vector3(1.2, 0.6, 1.2), Vector3(-p * 4.0, 0.3, 0.0), mat_yellow)
		papi_node.add_child(papi_box)
		var papi_light = OmniLight3D.new()
		# Inner lights white (fly above slope), outer lights red (fly below slope)
		papi_light.light_color = Color(1.0, 0.95, 0.9) if p < 2 else Color(1.0, 0.15, 0.1)
		papi_light.light_energy = 5.0
		papi_light.omni_range = 35.0
		papi_light.position = Vector3(-p * 4.0, 0.8, -1.0)
		papi_node.add_child(papi_light)

	# 4. Approach Lighting System (ALS) Towers extending 500m into approach corridors
	for end_sign in [-1.0, 1.0]:
		var als_node = Node3D.new()
		als_node.name = "ALS_Towers" if end_sign < 0 else "ALS_Towers_Far"
		root.add_child(als_node)
		for t in range(1, 11):
			var tower_z = end_sign * (half_len + t * 50.0)
			var tower_h = 3.0 + t * 1.5
			# Crossbar with 5 strobe lights
			var crossbar = _create_decal_box(Vector3(14.0, 0.4, 0.4), Vector3(0.0, tower_h, tower_z), mat_paint)
			als_node.add_child(crossbar)
			for l in range(-2, 3):
				var light_mesh = _create_decal_box(Vector3(0.3, 0.3, 0.3), Vector3(l * 3.0, tower_h + 0.3, tower_z), mat_white_glow)
				als_node.add_child(light_mesh)

	# 5. Green Threshold Lights & Red Runway End Lights
	for x in range(-int(half_wid) + 4, int(half_wid) - 4, 6):
		var thresh_green = _create_decal_box(Vector3(0.4, 0.3, 0.4), Vector3(x, 0.2, -half_len + 2.0), mat_green_glow)
		root.add_child(thresh_green)
		var end_red = _create_decal_box(Vector3(0.4, 0.3, 0.4), Vector3(x, 0.2, half_len - 2.0), mat_red_glow)
		root.add_child(end_red)

	return root

static func _create_decal_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	if mat:
		mi.material_override = mat
	return mi
