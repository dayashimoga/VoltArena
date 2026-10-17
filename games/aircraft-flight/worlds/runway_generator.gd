class_name RunwayGenerator
extends RefCounted

## RunwayGenerator: Paved Airport Runways, Markings, PAPI & Approach Lighting.
## Generates full-scale FAA/ICAO compliant runway ribbons (Runway 09L/27R — 3,000m x 45m),
## high-res grooved asphalt, white piano-key threshold markings, touchdown zones,
## aiming points, centerline dashes, 60m edge lights, threshold light bars,
## and a calibrated 4-box 3.0° PAPI Glide Slope Indicator.

static func build_runway(length_m: float = 3000.0, width_m: float = 45.0, runway_id: String = "09L") -> Node3D:
	var root = Node3D.new()
	root.name = "Runway_" + runway_id

	# Materials (Calibrated dark grooved grey asphalt & crisp matte white ICAO markings)
	var mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.22, 0.22, 0.24) # Dark grooved grey asphalt
	mat_asphalt.roughness = 0.92
	mat_asphalt.metallic = 0.0
	mat_asphalt.specular = 0.05

	var mat_paint = StandardMaterial3D.new()
	mat_paint.albedo_color = Color(0.92, 0.92, 0.90) # Crisp white ICAO markings (no neon blue reflection)
	mat_paint.roughness = 0.95
	mat_paint.metallic = 0.0
	mat_paint.specular = 0.04

	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.95, 0.82, 0.10)
	mat_yellow.roughness = 0.65

	var mat_green_glow = StandardMaterial3D.new()
	mat_green_glow.albedo_color = Color(0.12, 0.95, 0.25)
	mat_green_glow.emission_enabled = true
	mat_green_glow.emission = Color(0.12, 0.95, 0.25)
	mat_green_glow.emission_energy_multiplier = 4.5

	var mat_red_glow = StandardMaterial3D.new()
	mat_red_glow.albedo_color = Color(0.98, 0.15, 0.10)
	mat_red_glow.emission_enabled = true
	mat_red_glow.emission = Color(0.98, 0.15, 0.10)
	mat_red_glow.emission_energy_multiplier = 4.5

	var mat_white_glow = StandardMaterial3D.new()
	mat_white_glow.albedo_color = Color(1.0, 1.0, 1.0)
	mat_white_glow.emission_enabled = true
	mat_white_glow.emission = Color(1.0, 1.0, 1.0)
	mat_white_glow.emission_energy_multiplier = 4.0

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
	mi_asphalt.mesh = _create_box_mesh(Vector3(width_m, 0.8, length_m))
	mi_asphalt.position = Vector3(0.0, -0.4, 0.0)
	mi_asphalt.material_override = mat_asphalt
	root.add_child(mi_asphalt)

	# 2. Runway Markings
	var half_len = length_m * 0.5
	var half_wid = width_m * 0.5

	# Piano-Key Threshold Stripes (Both Ends: 10 stripes per end)
	for end_sign in [-1.0, 1.0]:
		var z_base = end_sign * (half_len - 35.0)
		for s in range(-5, 6):
			if s == 0: continue
			var stripe_x = (float(s) - 0.5 * signf(s)) * 3.4
			var stripe = _create_decal_box(Vector3(1.8, 0.05, 30.0), Vector3(stripe_x, 0.02, z_base), mat_paint)
			root.add_child(stripe)

	# Aiming Point Markings (300m from each threshold: 45m x 4m high-contrast blocks)
	for end_sign in [-1.0, 1.0]:
		var aim_z = end_sign * (half_len - 300.0)
		root.add_child(_create_decal_box(Vector3(4.0, 0.05, 45.0), Vector3(-10.0, 0.02, aim_z), mat_paint))
		root.add_child(_create_decal_box(Vector3(4.0, 0.05, 45.0), Vector3(10.0, 0.02, aim_z), mat_paint))

	# Touchdown Zone Markings (150m, 450m, and 600m from each threshold)
	for end_sign in [-1.0, 1.0]:
		for dist in [150.0, 450.0, 600.0]:
			var tdz_z = end_sign * (half_len - dist)
			root.add_child(_create_decal_box(Vector3(1.6, 0.05, 22.0), Vector3(-12.0, 0.02, tdz_z), mat_paint))
			root.add_child(_create_decal_box(Vector3(1.6, 0.05, 22.0), Vector3(-8.5, 0.02, tdz_z), mat_paint))
			root.add_child(_create_decal_box(Vector3(1.6, 0.05, 22.0), Vector3(8.5, 0.02, tdz_z), mat_paint))
			root.add_child(_create_decal_box(Vector3(1.6, 0.05, 22.0), Vector3(12.0, 0.02, tdz_z), mat_paint))

	# Centerline Dashes (every 60m: 30m length, 1.5m width)
	var num_dashes = int(length_m / 60.0)
	for i in range(-num_dashes / 2, num_dashes / 2 + 1):
		var dash = _create_decal_box(Vector3(1.5, 0.05, 30.0), Vector3(0.0, 0.02, i * 60.0), mat_paint)
		root.add_child(dash)

	# Continuous Runway Edge Stripes
	root.add_child(_create_decal_box(Vector3(1.0, 0.05, length_m - 70.0), Vector3(-half_wid + 1.8, 0.02, 0.0), mat_paint))
	root.add_child(_create_decal_box(Vector3(1.0, 0.05, length_m - 70.0), Vector3(half_wid - 1.8, 0.02, 0.0), mat_paint))

	# 3. Calibrated 4-Box 3.0° PAPI Glide Slope Indicator
	# Located alongside touchdown zone at 300m past threshold on port side (-X)
	var papi_node = Node3D.new()
	papi_node.name = "PAPI_Lights"
	papi_node.position = Vector3(-half_wid - 15.0, 0.5, -half_len + 300.0)
	root.add_child(papi_node)

	for p in range(4):
		var box_pos = Vector3(-p * 3.5, 0.3, 0.0)
		var papi_box = _create_decal_box(Vector3(1.2, 0.6, 1.2), box_pos, mat_yellow)
		papi_node.add_child(papi_box)

		# Standard 4-box 3.0° PAPI setup (boxes 0,1 white; boxes 2,3 red on nominal slope)
		var is_white = (p < 2)
		var p_color = Color(1.0, 0.98, 0.92) if is_white else Color(1.0, 0.15, 0.10)
		var lens_mat = StandardMaterial3D.new()
		lens_mat.albedo_color = p_color
		lens_mat.emission_enabled = true
		lens_mat.emission = p_color
		lens_mat.emission_energy_multiplier = 5.0

		var lens = _create_decal_box(Vector3(0.4, 0.3, 0.15), box_pos + Vector3(0.0, 0.0, -0.65), lens_mat)
		papi_node.add_child(lens)

		var papi_light = OmniLight3D.new()
		papi_light.light_color = p_color
		papi_light.light_energy = 3.5
		papi_light.omni_range = 30.0
		papi_light.position = box_pos + Vector3(0.0, 0.4, -1.0)
		papi_node.add_child(papi_light)

	# 4. Crisp Point-Source Runway Edge Lights (60m Spacing)
	var edge_lights_node = Node3D.new()
	edge_lights_node.name = "RunwayEdgeLights"
	root.add_child(edge_lights_node)

	var edge_x = half_wid + 1.2
	var edge_step = 60.0
	var num_edge = int(length_m / edge_step)
	for i in range(-num_edge / 2, num_edge / 2 + 1):
		var lz = i * edge_step
		for side in [-1.0, 1.0]:
			var fixture = _create_decal_box(Vector3(0.22, 0.45, 0.22), Vector3(side * edge_x, 0.22, lz), mat_yellow)
			edge_lights_node.add_child(fixture)
			var bulb = _create_decal_box(Vector3(0.18, 0.18, 0.18), Vector3(side * edge_x, 0.50, lz), mat_white_glow)
			edge_lights_node.add_child(bulb)

	# 5. Threshold Light Bars (Green Approach / Red Departure)
	var thresh_lights_node = Node3D.new()
	thresh_lights_node.name = "ThresholdLightBars"
	root.add_child(thresh_lights_node)

	for x in range(-int(half_wid) + 3, int(half_wid) - 2, 4):
		var green_bar = _create_decal_box(Vector3(0.35, 0.25, 0.35), Vector3(float(x), 0.15, -half_len + 2.0), mat_green_glow)
		thresh_lights_node.add_child(green_bar)
		var red_bar = _create_decal_box(Vector3(0.35, 0.25, 0.35), Vector3(float(x), 0.15, half_len - 2.0), mat_red_glow)
		thresh_lights_node.add_child(red_bar)

	# 6. Approach Lighting System (ALS) Towers extending 500m into approach corridors
	for end_sign in [-1.0, 1.0]:
		var als_node = Node3D.new()
		als_node.name = "ALS_Towers" if end_sign < 0 else "ALS_Towers_Far"
		root.add_child(als_node)
		for t in range(1, 11):
			var tower_z = end_sign * (half_len + t * 50.0)
			var tower_h = 3.0 + t * 1.5
			var crossbar = _create_decal_box(Vector3(14.0, 0.4, 0.4), Vector3(0.0, tower_h, tower_z), mat_paint)
			als_node.add_child(crossbar)
			for l in range(-2, 3):
				var light_mesh = _create_decal_box(Vector3(0.3, 0.3, 0.3), Vector3(l * 3.0, tower_h + 0.3, tower_z), mat_white_glow)
				als_node.add_child(light_mesh)

	return root

static func _create_decal_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_mesh(size)
	mi.position = pos
	if mat:
		mi.material_override = mat
	return mi

static func _create_box_mesh(size: Vector3) -> ArrayMesh:
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

	return st.commit()
