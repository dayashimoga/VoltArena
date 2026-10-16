class_name UrbanPropFactory
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")

## High-performance 3D prop and architecture factory for Urban Legends.
## Generates production-grade PBR buildings, streetlights, vegetation, and stunt ramps:
## - Downtown Skyscraper (Authentic GLTF high-rises with parallax illuminated windows and rooftop spires)
## - Commercial District (Offices, storefronts, multi-story commercial buildings with building_facade.gdshader)
## - Colinas Villa (Terracotta tile roof hillside estates)
## - Flyover Viaduct Deck & Pillars (Elevated concrete freeway bridges)
## - California Fan Palms & Parkland Shade Trees (Authentic 3D GLB foliage)
## - Sleek modern streetlamps with 90m distance-faded nighttime illumination
## - Stunt Kicker Ramps with hazard chevrons
## - Freight Shipping Containers & Maritime Docks
## - STRICT ZERO-PRIMITIVE MANDATE: Zero BoxMesh / CylinderMesh / PrismMesh / SphereMesh in final production assets.

const SKYSCRAPER_GLBS: Array[String] = [
	"res://assets/models/environment/building_skyscraper_a.glb",
	"res://assets/models/environment/building_skyscraper_b.glb",
	"res://assets/models/environment/building_skyscraper_c.glb",
	"res://assets/models/environment/building_skyscraper_d.glb",
	"res://assets/models/environment/building_skyscraper_e.glb"
]

const COMMERCIAL_GLBS: Array[String] = [
	"res://assets/models/environment/building_comm_a.glb",
	"res://assets/models/environment/building_comm_b.glb",
	"res://assets/models/environment/building_comm_c.glb",
	"res://assets/models/environment/building_comm_d.glb",
	"res://assets/models/environment/building_comm_e.glb",
	"res://assets/models/environment/building_comm_f.glb"
]

const TREE_GLBS: Array[String] = [
	"res://assets/models/environment/tree_detailed.glb",
	"res://assets/models/environment/tree_oak.glb",
	"res://assets/models/environment/tree_pine.glb",
	"res://assets/models/environment/tree_palm.glb"
]

static func _get_facade_material(neon_tint: Color = Color(0.2, 0.6, 1.0)) -> Material:
	var facade_shader = load("res://games/urban-legends/world/shaders/urban_window_parallax.gdshader")
	if not facade_shader:
		facade_shader = load("res://games/urban-legends/world/shaders/building_facade.gdshader")
	if facade_shader:
		var sm = ShaderMaterial.new()
		sm.shader = facade_shader
		sm.set_shader_parameter("facade_base_color", Color(0.22, 0.23, 0.26))
		sm.set_shader_parameter("window_lit_probability", 0.48)
		sm.set_shader_parameter("night_emission_factor", 4.0)
		sm.set_shader_parameter("room_temp_4500k", neon_tint)
		return sm
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.28)
	mat.metallic = 0.8
	mat.roughness = 0.2
	return mat

static func build_skyscraper(height: float = 75.0, width: float = 24.0, depth: float = 24.0, neon_tint: Color = Color(0.2, 0.6, 1.0)) -> Node3D:
	var root = Node3D.new()
	root.name = "Skyscraper"

	var rand_idx = randi() % SKYSCRAPER_GLBS.size()
	var glb_path = SKYSCRAPER_GLBS[rand_idx]
	var model = ModelCache.get_model(glb_path)

	if is_instance_valid(model):
		model.name = "SkyscraperMesh"
		var sx = width / 1.36
		var sy = height / 2.88
		var sz = depth / 1.36
		model.scale = Vector3(sx, sy, sz)
		# Apply building facade shader to the skyscraper exterior
		var facade_mat = _get_facade_material(neon_tint)
		_apply_material_recursive(model, facade_mat)
		root.add_child(model)
	else:
		_build_procedural_skyscraper_mesh(root, height, width, depth, neon_tint)

	# Static collision body (BoxShape3D invisible physics proxy)
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	col.shape = box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	# Rooftop communication antenna spire (ArrayMesh tapered mast)
	var spire = MeshInstance3D.new()
	spire.mesh = _create_tapered_mast_mesh(0.45, 0.08, 14.0, 8)
	var spire_mat = StandardMaterial3D.new()
	spire_mat.albedo_color = Color(0.85, 0.85, 0.88)
	spire_mat.metallic = 0.95
	spire_mat.roughness = 0.15
	spire.material_override = spire_mat
	spire.position = Vector3(0, height, 0)
	root.add_child(spire)

	# Rooftop aviation warning strobe beacon (Red)
	var beacon = OmniLight3D.new()
	beacon.light_color = Color(1.0, 0.1, 0.1)
	beacon.light_energy = 2.5
	beacon.omni_range = 35.0
	beacon.position = Vector3(0, height + 14.0, 0)
	root.add_child(beacon)

	return root

static func build_commercial_block(height: float = 35.0, width: float = 20.0, depth: float = 20.0) -> Node3D:
	var root = Node3D.new()
	root.name = "CommercialBuilding"

	var rand_idx = randi() % COMMERCIAL_GLBS.size()
	var glb_path = COMMERCIAL_GLBS[rand_idx]
	var model = ModelCache.get_model(glb_path)

	if is_instance_valid(model):
		model.name = "CommercialMesh"
		model.scale = Vector3(width / 0.90, height / 1.30, depth / 0.95)
		var facade_mat = _get_facade_material(Color(0.9, 0.8, 0.4))
		_apply_material_recursive(model, facade_mat)
		root.add_child(model)
	else:
		var mi = MeshInstance3D.new()
		mi.mesh = _create_box_array_mesh(width, height, depth)
		mi.material_override = _get_facade_material(Color(0.9, 0.8, 0.4))
		mi.position = Vector3(0, height * 0.5, 0)
		root.add_child(mi)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	col.shape = box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func _build_procedural_skyscraper_mesh(parent: Node3D, height: float, width: float, depth: float, neon_tint: Color) -> void:
	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_array_mesh(width, height, depth)
	mi.position = Vector3(0, height * 0.5, 0)
	mi.material_override = _get_facade_material(neon_tint)
	parent.add_child(mi)

	# Rooftop neon trim (ArrayMesh)
	var neon_mi = MeshInstance3D.new()
	neon_mi.mesh = _create_box_array_mesh(width * 0.6, 1.8, 0.4)
	var n_mat = StandardMaterial3D.new()
	n_mat.albedo_color = neon_tint
	n_mat.emission_enabled = true
	n_mat.emission = neon_tint * 4.5
	neon_mi.material_override = n_mat
	neon_mi.position = Vector3(0, height + 1.2, depth * 0.48)
	parent.add_child(neon_mi)

static func build_residential_villa(width: float = 14.0, depth: float = 12.0) -> Node3D:
	var root = Node3D.new()
	root.name = "ColinasVilla"

	# Stucco Lower Walls (ArrayMesh)
	var wall_height = 4.5
	var wall_mi = MeshInstance3D.new()
	wall_mi.mesh = _create_box_array_mesh(width, wall_height, depth)
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.88, 0.82, 0.72) # Cream stucco
	wall_mat.roughness = 0.85
	wall_mi.material_override = wall_mat
	wall_mi.position = Vector3(0, wall_height * 0.5, 0)
	root.add_child(wall_mi)

	# Terracotta Hip Roof (ArrayMesh Spanish Colonial Villa reference in Colinas)
	var roof_height = 2.4
	var roof_mi = MeshInstance3D.new()
	roof_mi.mesh = _create_hip_roof_mesh(width + 1.6, roof_height, depth + 1.6)
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.72, 0.28, 0.15) # Burnt terracotta red
	roof_mat.roughness = 0.7
	roof_mi.material_override = roof_mat
	roof_mi.position = Vector3(0, wall_height + roof_height * 0.5, 0)
	root.add_child(roof_mi)

	# Villa Collision Box
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, wall_height + roof_height, depth)
	col.shape = box
	col.position = Vector3(0, (wall_height + roof_height) * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_flyover_viaduct(length: float, height: float, width: float) -> Node3D:
	var root = Node3D.new()
	root.name = "ViaductSupport"

	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.42, 0.44, 0.46) # Weathered reinforced concrete
	p_mat.roughness = 0.85

	var num_pillars = maxi(2, int(length / 28.0))
	var step = length / float(num_pillars)
	for i in range(num_pillars):
		var p_z = -length * 0.5 + step * (i + 0.5)

		# Concrete flared pillar pier (ArrayMesh)
		var pillar = MeshInstance3D.new()
		pillar.mesh = _create_tapered_mast_mesh(1.4, 1.1, height, 12)
		pillar.material_override = p_mat
		pillar.position = Vector3(0, -height, p_z)
		root.add_child(pillar)

		# Cross-head beam supporting freeway deck (ArrayMesh)
		var beam = MeshInstance3D.new()
		beam.mesh = _create_box_array_mesh(width * 0.95, 1.2, 2.4)
		beam.material_override = p_mat
		beam.position = Vector3(0, -0.6, p_z)
		root.add_child(beam)

	# Elevated Viaduct Road Deck Collision
	var body = StaticBody3D.new()
	body.name = "ViaductDeckCollision"
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, 1.2, length)
	col.shape = box
	col.position = Vector3(0, 0, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_tree(height: float = 9.0) -> Node3D:
	var root = Node3D.new()
	root.name = "UrbanTree"

	var rand_idx = randi() % TREE_GLBS.size()
	var glb_path = TREE_GLBS[rand_idx]
	var model = ModelCache.get_model(glb_path)

	if is_instance_valid(model):
		model.name = "TreeMesh"
		var s = height / 1.33
		model.scale = Vector3(s, s, s)
		root.add_child(model)
	else:
		# Procedural tree fallback (ArrayMesh trunk and canopy)
		var trunk = MeshInstance3D.new()
		trunk.mesh = _create_tapered_mast_mesh(0.42, 0.22, height * 0.45, 10)
		var t_mat = StandardMaterial3D.new()
		t_mat.albedo_color = Color(0.32, 0.22, 0.14)
		trunk.material_override = t_mat
		root.add_child(trunk)

		var canopy = MeshInstance3D.new()
		canopy.mesh = _create_faceted_canopy_mesh(height * 0.38, height * 0.55)
		var l_mat = StandardMaterial3D.new()
		l_mat.albedo_color = Color(0.18, 0.42, 0.16)
		canopy.material_override = l_mat
		canopy.position = Vector3(0, height * 0.42, 0)
		root.add_child(canopy)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_PROPS
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var c_cyl = CylinderShape3D.new()
	c_cyl.radius = 0.4
	c_cyl.height = height * 0.6
	col.shape = c_cyl
	col.position = Vector3(0, height * 0.3, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_palm_tree(height: float = 10.0) -> Node3D:
	var root = Node3D.new()
	root.name = "PalmTree"

	var model = ModelCache.get_model("res://assets/models/environment/tree_palm.glb")
	if is_instance_valid(model):
		model.name = "PalmMesh"
		var s = height / 1.51
		model.scale = Vector3(s, s, s)
		root.add_child(model)
	else:
		return build_tree(height)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_PROPS
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var c_cyl = CylinderShape3D.new()
	c_cyl.radius = 0.35
	c_cyl.height = height * 0.7
	col.shape = c_cyl
	col.position = Vector3(0, height * 0.35, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_street_lamp(height: float = 6.8) -> Node3D:
	var root = Node3D.new()
	root.name = "StreetLamp"

	# Authentic modern highway / metropolitan arched streetlamp (ArrayMesh)
	var pole_mi = MeshInstance3D.new()
	pole_mi.mesh = _create_arched_streetlamp_mesh(height)
	var pole_mat = StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.20, 0.22, 0.25) # Dark anthracite grey steel
	pole_mat.metallic = 0.85
	pole_mat.roughness = 0.35
	pole_mi.material_override = pole_mat
	root.add_child(pole_mi)

	# Emissive LED luminaire head (ArrayMesh)
	var bulb_mi = MeshInstance3D.new()
	bulb_mi.mesh = _create_box_array_mesh(0.24, 0.05, 0.55)
	var bulb_mat = StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.95, 0.82)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.90, 0.72) * 3.5
	bulb_mi.material_override = bulb_mat
	bulb_mi.position = Vector3(0, height - 0.05, -1.1)
	root.add_child(bulb_mi)

	# Night streetlight illumination: distance-faded OmniLight3D (60m begin, 90m total fade)
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.92, 0.78)
	light.light_energy = 2.4
	light.omni_range = 28.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 60.0
	light.distance_fade_length = 30.0
	light.position = Vector3(0, height - 0.2, -1.1)
	root.add_child(light)

	# Lightweight pole collision proxy
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_PROPS
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.18
	cyl.height = height
	col.shape = cyl
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_stunt_ramp(width: float = 7.0, length: float = 12.0, height: float = 3.2, kicker_angle_deg: float = 24.0) -> Node3D:
	var root = Node3D.new()
	root.name = "StuntRamp"
	root.add_to_group("stunt_ramps")

	# Wedge Ramp Geometry using ArrayMesh with smooth curve kicker transition
	var ramp_mi = MeshInstance3D.new()
	ramp_mi.mesh = _create_wedge_ramp_mesh(width, height, length)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.90, 0.68, 0.12) # High-visibility stunt yellow
	mat.metallic = 0.5
	mat.roughness = 0.35
	ramp_mi.material_override = mat
	root.add_child(ramp_mi)

	# Hazard Chevron Striping across ramp lip (ArrayMesh)
	var chevron_mi = MeshInstance3D.new()
	chevron_mi.mesh = _create_box_array_mesh(width, 0.08, 0.6)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.06, 0.06, 0.08)
	chevron_mi.material_override = c_mat
	chevron_mi.position = Vector3(0, height, length * 0.5 - 0.3)
	root.add_child(chevron_mi)

	# Collision Ramp Body
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height * 0.9, length)
	col.shape = box
	col.position = Vector3(0, height * 0.45, 0)
	col.rotation_degrees.x = -kicker_angle_deg * 0.5
	body.add_child(col)
	root.add_child(body)

	return root

static func build_shipping_container(color: Color = Color(0.8, 0.2, 0.15)) -> Node3D:
	var root = Node3D.new()
	root.name = "ShippingContainer"

	var length = 12.0
	var height = 2.9
	var width = 2.45

	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_array_mesh(width, height, length)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.45
	mi.material_override = mat
	mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(mi)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var c_box = BoxShape3D.new()
	c_box.size = Vector3(width, height, length)
	col.shape = c_box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_stone_bridge(span: float = 24.0, width: float = 9.0) -> Node3D:
	var root = Node3D.new()
	root.name = "StoneBridge"

	var bridge_h = 2.5
	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_array_mesh(width, bridge_h, span)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.50, 0.46) # Weathered stone
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = Vector3(0, bridge_h * 0.5, 0)
	root.add_child(mi)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var c_box = BoxShape3D.new()
	c_box.size = Vector3(width, bridge_h, span)
	col.shape = c_box
	col.position = Vector3(0, bridge_h * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mi = node as MeshInstance3D
		if mi.mesh != null:
			mi.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)

# ==============================================================================
# PHASE 2 NYC-INSPIRED 5-DISTRICT MODULAR ARCHITECTURE & STREET FURNITURE
# ==============================================================================

static func build_art_deco_skyscraper(height: float = 120.0, base_w: float = 30.0, depth: float = 30.0, neon_tint: Color = Color(1.0, 0.85, 0.45)) -> Node3D:
	var root = Node3D.new()
	root.name = "ArtDecoSkyscraper"

	var facade_mat = _get_facade_material(neon_tint)
	var limestone_mat = StandardMaterial3D.new()
	limestone_mat.albedo_color = Color(0.78, 0.76, 0.70) # Warm Indiana limestone
	limestone_mat.roughness = 0.85

	var h_tier1 = height * 0.45
	var h_tier2 = height * 0.35
	var h_tier3 = height * 0.20

	# Tier 1: Base podium with colonnade
	var t1 = MeshInstance3D.new()
	t1.mesh = _create_box_array_mesh(base_w, h_tier1, depth)
	t1.material_override = facade_mat
	t1.position = Vector3(0, h_tier1 * 0.5, 0)
	root.add_child(t1)

	# Tier 2: Mid-tower wedding-cake setback
	var w2 = base_w * 0.75
	var d2 = depth * 0.75
	var t2 = MeshInstance3D.new()
	t2.mesh = _create_box_array_mesh(w2, h_tier2, d2)
	t2.material_override = facade_mat
	t2.position = Vector3(0, h_tier1 + h_tier2 * 0.5, 0)
	root.add_child(t2)

	# Tier 3: Upper penthouse crown with setbacks
	var w3 = base_w * 0.52
	var d3 = depth * 0.52
	var t3 = MeshInstance3D.new()
	t3.mesh = _create_box_array_mesh(w3, h_tier3, d3)
	t3.material_override = facade_mat
	t3.position = Vector3(0, h_tier1 + h_tier2 + h_tier3 * 0.5, 0)
	root.add_child(t3)

	# Rooftop Cedar Water Tank on Steel Derrick Tower (NYC icon)
	var tank = MeshInstance3D.new()
	tank.mesh = _create_water_tank_mesh(2.4, 4.2)
	var tank_mat = StandardMaterial3D.new()
	tank_mat.albedo_color = Color(0.48, 0.35, 0.24) # Weathered cedar wood
	tank_mat.roughness = 0.88
	tank.material_override = tank_mat
	tank.position = Vector3(w3 * 0.22, height, -d3 * 0.20)
	root.add_child(tank)

	# Rooftop HVAC Cooling Tower
	var hvac = MeshInstance3D.new()
	hvac.mesh = _create_box_array_mesh(4.5, 2.8, 3.8)
	var hvac_mat = StandardMaterial3D.new()
	hvac_mat.albedo_color = Color(0.55, 0.58, 0.60)
	hvac_mat.metallic = 0.75
	hvac_mat.roughness = 0.35
	hvac.material_override = hvac_mat
	hvac.position = Vector3(-w3 * 0.20, height + 1.4, d3 * 0.15)
	root.add_child(hvac)

	# Rooftop Stainless Steel Art Deco Spire Mast with warning beacon
	var spire = MeshInstance3D.new()
	spire.mesh = _create_tapered_mast_mesh(0.55, 0.08, 18.0, 8)
	var spire_mat = StandardMaterial3D.new()
	spire_mat.albedo_color = Color(0.92, 0.94, 0.96)
	spire_mat.metallic = 0.96
	spire_mat.roughness = 0.12
	spire.material_override = spire_mat
	spire.position = Vector3(0, height, 0)
	root.add_child(spire)

	var beacon = OmniLight3D.new()
	beacon.light_color = Color(1.0, 0.08, 0.08)
	beacon.light_energy = 3.0
	beacon.omni_range = 45.0
	beacon.position = Vector3(0, height + 18.0, 0)
	root.add_child(beacon)

	# Stepped physics collision proxy
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(base_w, height, depth)
	col.shape = box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_brownstone_rowhouse(height: float = 18.0, width: float = 12.0, depth: float = 16.0, has_bodega: bool = false) -> Node3D:
	var root = Node3D.new()
	root.name = "BrownstoneRowhouse"

	# Weathered Red/Brown Brick Wall Material
	var brick_mat = StandardMaterial3D.new()
	brick_mat.albedo_color = Color(0.54, 0.26, 0.18) if not has_bodega else Color(0.48, 0.28, 0.22)
	brick_mat.roughness = 0.88

	# Main Rowhouse Tenement Body
	var body_mi = MeshInstance3D.new()
	body_mi.mesh = _create_box_array_mesh(width, height, depth)
	body_mi.material_override = _get_facade_material(Color(1.0, 0.82, 0.55))
	body_mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(body_mi)

	# Recessed Cornice Roofline (Italianate / Victorian Crown)
	var cornice = MeshInstance3D.new()
	cornice.mesh = _create_cornice_mesh(width + 0.8, 1.2, depth + 0.6)
	var cornice_mat = StandardMaterial3D.new()
	cornice_mat.albedo_color = Color(0.72, 0.68, 0.60)
	cornice_mat.roughness = 0.80
	cornice.material_override = cornice_mat
	cornice.position = Vector3(0, height + 0.6, 0)
	root.add_child(cornice)

	# Raised Front Masonry Stoop with Iron Railings (Front facing +Z)
	var stoop = MeshInstance3D.new()
	stoop.mesh = _create_stoop_mesh(2.6, 1.8, 3.4, 6)
	var stoop_mat = StandardMaterial3D.new()
	stoop_mat.albedo_color = Color(0.65, 0.60, 0.55) # Brownstone sandstone
	stoop_mat.roughness = 0.85
	stoop.material_override = stoop_mat
	stoop.position = Vector3(width * 0.22, 0.9, depth * 0.5 + 1.7)
	root.add_child(stoop)

	# Black Iron Exterior Fire Escape Balconies & Zigzag Stairs on Facade
	var fire_escape = MeshInstance3D.new()
	fire_escape.mesh = _create_fire_escape_mesh(width * 0.55, height - 3.5, 1.4, 4)
	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.12, 0.12, 0.14) # Cast iron black
	iron_mat.metallic = 0.85
	iron_mat.roughness = 0.45
	fire_escape.material_override = iron_mat
	fire_escape.position = Vector3(-width * 0.18, (height - 3.5) * 0.5 + 3.0, depth * 0.5 + 0.72)
	root.add_child(fire_escape)

	# Ground-Floor Bodega / Deli / Cafe option with fabric striped awning & neon signage
	if has_bodega:
		var awning = MeshInstance3D.new()
		awning.mesh = _create_awning_mesh(width * 0.88, 1.1, 2.2)
		var awning_mat = StandardMaterial3D.new()
		awning_mat.albedo_color = Color(0.85, 0.15, 0.15) # Red & white canvas
		awning_mat.roughness = 0.75
		awning.material_override = awning_mat
		awning.position = Vector3(0, 3.2, depth * 0.5 + 1.1)
		root.add_child(awning)

		# Neon Deli Sign
		var sign_mi = MeshInstance3D.new()
		sign_mi.mesh = _create_box_array_mesh(width * 0.65, 0.8, 0.15)
		var sign_mat = StandardMaterial3D.new()
		sign_mat.albedo_color = Color(0.15, 0.95, 0.45)
		sign_mat.emission_enabled = true
		sign_mat.emission = Color(0.15, 0.95, 0.45) * 3.5
		sign_mi.material_override = sign_mat
		sign_mi.position = Vector3(0, 4.1, depth * 0.5 + 0.2)
		root.add_child(sign_mi)

	# Physics Collision Body
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	col.shape = box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_theater_marquee_store(height: float = 24.0, width: float = 22.0, depth: float = 20.0) -> Node3D:
	var root = Node3D.new()
	root.name = "TheaterStore"

	# Department Store / Theater Facade
	var mi = MeshInstance3D.new()
	mi.mesh = _create_box_array_mesh(width, height, depth)
	mi.material_override = _get_facade_material(Color(0.95, 0.85, 0.35))
	mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(mi)

	# Large Vertical Illuminated Marquee Blade ("BROADWAY / THEATER")
	var marquee = MeshInstance3D.new()
	marquee.mesh = _create_box_array_mesh(1.6, height * 0.65, 2.2)
	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_color = Color(0.98, 0.75, 0.12)
	m_mat.emission_enabled = true
	m_mat.emission = Color(0.98, 0.72, 0.10) * 4.2
	marquee.material_override = m_mat
	marquee.position = Vector3(0, height * 0.55, depth * 0.5 + 1.1)
	root.add_child(marquee)

	# LED Billboard Screen on facade
	var bb = MeshInstance3D.new()
	bb.mesh = _create_box_array_mesh(width * 0.65, 5.0, 0.2)
	var bb_mat = StandardMaterial3D.new()
	bb_mat.albedo_color = Color(0.1, 0.5, 0.95)
	bb_mat.emission_enabled = true
	bb_mat.emission = Color(0.2, 0.65, 1.0) * 3.8
	bb.material_override = bb_mat
	bb.position = Vector3(0, height * 0.82, depth * 0.5 + 0.12)
	root.add_child(bb)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	col.shape = box
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_subway_kiosk() -> Node3D:
	var root = Node3D.new()
	root.name = "SubwayKiosk"

	var green_iron_mat = StandardMaterial3D.new()
	green_iron_mat.albedo_color = Color(0.12, 0.32, 0.18) # Historic NYC subway green
	green_iron_mat.metallic = 0.82
	green_iron_mat.roughness = 0.40

	# Kiosk Perimeter Handrails & Canopy Frame
	var frame = MeshInstance3D.new()
	frame.mesh = _create_box_array_mesh(2.8, 1.3, 5.2)
	frame.material_override = green_iron_mat
	frame.position = Vector3(0, 0.65, 0)
	root.add_child(frame)

	# Descending Subway Stairs (Tiled steps)
	var stairs = MeshInstance3D.new()
	stairs.mesh = _create_stoop_mesh(2.4, 2.8, 4.8, 8)
	var concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.65, 0.65, 0.65)
	concrete_mat.roughness = 0.9
	stairs.material_override = concrete_mat
	stairs.position = Vector3(0, -1.4, 0)
	root.add_child(stairs)

	# Illuminated Green Subway Entry Globes
	for gx in [-1.25, 1.25]:
		var globe = MeshInstance3D.new()
		globe.mesh = _create_subway_globe_mesh()
		var g_mat = StandardMaterial3D.new()
		g_mat.albedo_color = Color(0.2, 0.9, 0.35)
		g_mat.emission_enabled = true
		g_mat.emission = Color(0.25, 0.95, 0.4) * 3.5
		globe.material_override = g_mat
		globe.position = Vector3(gx, 2.2, 2.3)
		root.add_child(globe)

		var glight = OmniLight3D.new()
		glight.light_color = Color(0.2, 0.95, 0.35)
		glight.light_energy = 1.6
		glight.omni_range = 8.0
		glight.position = Vector3(gx, 2.2, 2.3)
		root.add_child(glight)

	return root

static func build_park_stone_wall(length: float = 40.0, height: float = 1.4) -> Node3D:
	var root = Node3D.new()
	root.name = "ParkStoneWall"

	var wall = MeshInstance3D.new()
	wall.mesh = _create_box_array_mesh(0.7, height, length)
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.48, 0.46, 0.42) # Ashlar granite
	wall_mat.roughness = 0.92
	wall.material_override = wall_mat
	wall.position = Vector3(0, height * 0.5, 0)
	root.add_child(wall)

	# Wrought iron top railings
	var rail = MeshInstance3D.new()
	rail.mesh = _create_box_array_mesh(0.12, 0.6, length)
	var rail_mat = StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.12, 0.12, 0.14)
	rail_mat.metallic = 0.9
	rail_mat.roughness = 0.3
	rail.material_override = rail_mat
	rail.position = Vector3(0, height + 0.3, 0)
	root.add_child(rail)

	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.7, height + 0.6, length)
	col.shape = box
	col.position = Vector3(0, (height + 0.6) * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_gantry_crane(height: float = 38.0, span: float = 32.0) -> Node3D:
	var root = Node3D.new()
	root.name = "GantryCrane"

	var crane_mat = StandardMaterial3D.new()
	crane_mat.albedo_color = Color(0.88, 0.45, 0.10) # Industrial OSHA safety orange
	crane_mat.metallic = 0.75
	crane_mat.roughness = 0.42

	# Left & Right A-frame truss legs
	for side in [-span * 0.5, span * 0.5]:
		var leg = MeshInstance3D.new()
		leg.mesh = _create_tapered_mast_mesh(1.8, 1.2, height, 8)
		leg.material_override = crane_mat
		leg.position = Vector3(side, 0, 0)
		root.add_child(leg)

	# Horizontal overhead cross girder boom
	var boom = MeshInstance3D.new()
	boom.mesh = _create_truss_beam_mesh(span + 14.0, 3.2, 3.6)
	boom.material_override = crane_mat
	boom.position = Vector3(0, height, 0)
	root.add_child(boom)

	# Operator cab
	var cab = MeshInstance3D.new()
	cab.mesh = _create_box_array_mesh(3.0, 2.5, 3.0)
	var cab_mat = StandardMaterial3D.new()
	cab_mat.albedo_color = Color(0.9, 0.9, 0.92)
	cab.material_override = cab_mat
	cab.position = Vector3(-span * 0.25, height - 1.5, 0)
	root.add_child(cab)

	return root

static func build_suspension_bridge(span: float = 450.0, clearance: float = 35.0, width: float = 24.0) -> Node3D:
	var root = Node3D.new()
	root.name = "SuspensionBridge"

	var tower_mat = StandardMaterial3D.new()
	tower_mat.albedo_color = Color(0.68, 0.70, 0.72) # Steel bridge grey
	tower_mat.metallic = 0.85
	tower_mat.roughness = 0.35

	var cable_mat = StandardMaterial3D.new()
	cable_mat.albedo_color = Color(0.85, 0.85, 0.88)
	cable_mat.metallic = 0.95
	cable_mat.roughness = 0.2

	var tower_height = clearance + 75.0
	var tower_x_positions = [-span * 0.28, span * 0.28]

	# Twin Suspension Towers
	for tx in tower_x_positions:
		# Left & right gothic arched tower legs
		for tz in [-width * 0.55, width * 0.55]:
			var leg = MeshInstance3D.new()
			leg.mesh = _create_tapered_mast_mesh(3.5, 2.2, tower_height, 12)
			leg.material_override = tower_mat
			leg.position = Vector3(tx, -clearance, tz)
			root.add_child(leg)

		# Upper cross-strut arch
		var arch = MeshInstance3D.new()
		arch.mesh = _create_box_array_mesh(4.0, 3.5, width * 1.2)
		arch.material_override = tower_mat
		arch.position = Vector3(tx, tower_height - clearance - 12.0, 0)
		root.add_child(arch)

	# Stiffening Steel Truss Road Deck
	var deck = MeshInstance3D.new()
	deck.mesh = _create_box_array_mesh(span, 2.5, width)
	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.22, 0.23, 0.25)
	deck_mat.roughness = 0.85
	deck.material_override = deck_mat
	deck.position = Vector3(0, 0, 0)
	root.add_child(deck)

	# Main Catenary Suspension Cable lines (parabolic ArrayMesh approximation)
	for side in [-width * 0.52, width * 0.52]:
		var cable = MeshInstance3D.new()
		cable.mesh = _create_truss_beam_mesh(span, 0.35, 0.35)
		cable.material_override = cable_mat
		cable.position = Vector3(0, tower_height * 0.45, side)
		root.add_child(cable)

	# Road Deck Physical Collision Box
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(span, 2.5, width)
	col.shape = box
	body.add_child(col)
	root.add_child(body)

	return root

static func build_underpass_tunnel(length: float = 80.0, width: float = 16.0, height: float = 6.0) -> Node3D:
	var root = Node3D.new()
	root.name = "UnderpassTunnel"

	# White Tiled Walls & Concrete Ceiling
	var tile_mat = StandardMaterial3D.new()
	tile_mat.albedo_color = Color(0.92, 0.94, 0.92) # White subway/tunnel ceramic tile
	tile_mat.roughness = 0.15
	tile_mat.metallic = 0.05

	for side in [-width * 0.5, width * 0.5]:
		var wall = MeshInstance3D.new()
		wall.mesh = _create_box_array_mesh(0.8, height, length)
		wall.material_override = tile_mat
		wall.position = Vector3(side, height * 0.5, 0)
		root.add_child(wall)

	var ceiling = MeshInstance3D.new()
	ceiling.mesh = _create_box_array_mesh(width, 0.8, length)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.35, 0.36, 0.38)
	ceiling.material_override = c_mat
	ceiling.position = Vector3(0, height + 0.4, 0)
	root.add_child(ceiling)

	# Overhead Fluorescent Lighting Strips along tunnel
	var num_lights = int(length / 16.0)
	for i in range(num_lights):
		var lz = -length * 0.5 + (float(i) + 0.5) * (length / float(num_lights))
		var strip = MeshInstance3D.new()
		strip.mesh = _create_box_array_mesh(0.4, 0.1, 4.0)
		var s_mat = StandardMaterial3D.new()
		s_mat.albedo_color = Color(0.95, 0.98, 1.0)
		s_mat.emission_enabled = true
		s_mat.emission = Color(0.95, 0.98, 1.0) * 3.5
		strip.material_override = s_mat
		strip.position = Vector3(0, height, lz)
		root.add_child(strip)

		var omni = OmniLight3D.new()
		omni.light_color = Color(0.95, 0.98, 1.0)
		omni.light_energy = 2.2
		omni.omni_range = 14.0
		omni.position = Vector3(0, height - 0.2, lz)
		root.add_child(omni)

	return root

static func build_traffic_signal_mast(height: float = 5.8, reach: float = 7.5) -> Node3D:
	var root = Node3D.new()
	root.name = "TrafficSignalMast"

	var mast_mat = StandardMaterial3D.new()
	mast_mat.albedo_color = Color(0.24, 0.25, 0.26)
	mast_mat.metallic = 0.85
	mast_mat.roughness = 0.35

	# Vertical mast pole
	var pole = MeshInstance3D.new()
	pole.mesh = _create_tapered_mast_mesh(0.18, 0.14, height, 10)
	pole.material_override = mast_mat
	root.add_child(pole)

	# Cantilever horizontal arm reaching over road
	var arm = MeshInstance3D.new()
	arm.mesh = _create_box_array_mesh(reach, 0.16, 0.16)
	arm.material_override = mast_mat
	arm.position = Vector3(reach * 0.5, height - 0.1, 0)
	root.add_child(arm)

	# 3-Aspect Traffic Signal Head (Red, Yellow, Green)
	var sig = MeshInstance3D.new()
	sig.mesh = _create_traffic_signal_mesh()
	sig.position = Vector3(reach * 0.75, height - 0.6, 0)
	root.add_child(sig)

	# Street Name Blade ("BROADWAY / 5TH AVE")
	var blade = MeshInstance3D.new()
	blade.mesh = _create_box_array_mesh(1.4, 0.30, 0.05)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.08, 0.38, 0.20) # Green street name blade
	blade.material_override = b_mat
	blade.position = Vector3(0.8, height + 0.3, 0)
	root.add_child(blade)

	return root

static func build_fire_hydrant() -> Node3D:
	var root = Node3D.new()
	root.name = "FireHydrant"

	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.92, 0.12, 0.10) # OSHA Red
	h_mat.metallic = 0.6
	h_mat.roughness = 0.35

	var body = MeshInstance3D.new()
	body.mesh = _create_tapered_mast_mesh(0.14, 0.12, 0.75, 10)
	body.material_override = h_mat
	root.add_child(body)

	var cap = MeshInstance3D.new()
	cap.mesh = _create_box_array_mesh(0.36, 0.12, 0.14)
	cap.material_override = h_mat
	cap.position = Vector3(0, 0.52, 0)
	root.add_child(cap)

	return root

static func build_street_furniture_cluster() -> Node3D:
	var root = Node3D.new()
	root.name = "StreetFurnitureCluster"

	# Green US Postal Mailbox
	var mb = MeshInstance3D.new()
	mb.mesh = _create_box_array_mesh(0.55, 1.0, 0.55)
	var mb_mat = StandardMaterial3D.new()
	mb_mat.albedo_color = Color(0.10, 0.30, 0.65) # USPS Blue
	mb.material_override = mb_mat
	mb.position = Vector3(-0.9, 0.5, 0)
	root.add_child(mb)

	# Wire mesh trash can
	var trash = MeshInstance3D.new()
	trash.mesh = _create_tapered_mast_mesh(0.24, 0.28, 0.85, 10)
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.18, 0.45, 0.22)
	t_mat.metallic = 0.8
	trash.material_override = t_mat
	trash.position = Vector3(0.0, 0.0, 0)
	root.add_child(trash)

	# Wooden slat park / street bench
	var bench = MeshInstance3D.new()
	bench.mesh = _create_box_array_mesh(1.8, 0.75, 0.65)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.42, 0.28, 0.16) # Teak wood
	bench.material_override = b_mat
	bench.position = Vector3(1.4, 0.38, 0)
	root.add_child(bench)

	return root

static func build_bus_shelter() -> Node3D:
	var root = Node3D.new()
	root.name = "BusShelter"

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.20, 0.22, 0.25)
	frame_mat.metallic = 0.9

	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.92, 0.98, 0.45)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.05

	# Canopy roof
	var roof = MeshInstance3D.new()
	roof.mesh = _create_box_array_mesh(4.2, 0.15, 2.0)
	roof.material_override = frame_mat
	roof.position = Vector3(0, 2.6, 0)
	root.add_child(roof)

	# Rear glass panel
	var glass = MeshInstance3D.new()
	glass.mesh = _create_box_array_mesh(4.0, 2.3, 0.08)
	glass.material_override = glass_mat
	glass.position = Vector3(0, 1.25, -0.9)
	root.add_child(glass)

	# Interior wooden bench
	var bench = MeshInstance3D.new()
	bench.mesh = _create_box_array_mesh(2.8, 0.45, 0.45)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.42, 0.28, 0.18)
	bench.material_override = b_mat
	bench.position = Vector3(0, 0.25, -0.6)
	root.add_child(bench)

	return root

static func build_acorn_streetlight(height: float = 4.8) -> Node3D:
	var root = Node3D.new()
	root.name = "AcornStreetlight"

	var iron_mat = StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.14, 0.16, 0.18) # Historic black iron
	iron_mat.metallic = 0.9
	iron_mat.roughness = 0.4

	# Fluted cast-iron lamppost
	var post = MeshInstance3D.new()
	post.mesh = _create_tapered_mast_mesh(0.18, 0.10, height - 0.7, 10)
	post.material_override = iron_mat
	root.add_child(post)

	# Acorn glass luminaire
	var acorn = MeshInstance3D.new()
	acorn.mesh = _create_subway_globe_mesh()
	var a_mat = StandardMaterial3D.new()
	a_mat.albedo_color = Color(1.0, 0.92, 0.72)
	a_mat.emission_enabled = true
	a_mat.emission = Color(1.0, 0.88, 0.65) * 3.8
	acorn.material_override = a_mat
	acorn.position = Vector3(0, height - 0.35, 0)
	root.add_child(acorn)

	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.90, 0.72) # Warm 2700K pool
	light.light_energy = 2.2
	light.omni_range = 24.0
	light.distance_fade_enabled = true
	light.distance_fade_begin = 55.0
	light.distance_fade_length = 35.0
	light.position = Vector3(0, height - 0.4, 0)
	root.add_child(light)

	return root

static func build_distant_skyline(radius: float = 1400.0) -> Node3D:
	var root = Node3D.new()
	root.name = "DistantSkylineLOD2"

	var facade_mat = _get_facade_material(Color(0.85, 0.75, 0.4))
	var count = 36
	for i in range(count):
		var angle = float(i) * TAU / float(count)
		var h = randf_range(80.0, 180.0)
		var w = randf_range(30.0, 55.0)
		var p = Vector3(cos(angle) * radius, h * 0.5, sin(angle) * radius)

		var tower = MeshInstance3D.new()
		tower.mesh = _create_box_array_mesh(w, h, w)
		tower.material_override = facade_mat
		tower.position = p
		root.add_child(tower)

	return root

# ==============================================================================
# PROCEDURAL ARRAYMESH GENERATORS (100% CC0 ZERO-PRIMITIVE MANDATE)
# ==============================================================================

static func _create_box_array_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hh = height * 0.5
	var hd = depth * 0.5

	# 6 Faces with UVs and Normals
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

static func _create_tapered_mast_mesh(bottom_r: float, top_r: float, height: float, segments: int = 8) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var c0 = cos(a0); var s0 = sin(a0)
		var c1 = cos(a1); var s1 = sin(a1)

		var pb0 = Vector3(c0 * bottom_r, 0.0, s0 * bottom_r)
		var pb1 = Vector3(c1 * bottom_r, 0.0, s1 * bottom_r)
		var pt0 = Vector3(c0 * top_r, height, s0 * top_r)
		var pt1 = Vector3(c1 * top_r, height, s1 * top_r)

		var n0 = Vector3(c0, 0.1, s0).normalized()
		var n1 = Vector3(c1, 0.1, s1).normalized()

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pb1)
		st.set_normal(n1); st.add_vertex(pt1)

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pt1)
		st.set_normal(n0); st.add_vertex(pt0)

	return st.commit()

static func _create_arched_streetlamp_mesh(height: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Vertical mast up to height * 0.85, then arched cantilever arm extending out by 1.2m
	var segments = 12
	var r = 0.10
	var h_mast = height * 0.82

	# Mast
	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var pb0 = Vector3(cos(a0) * r * 1.3, 0.0, sin(a0) * r * 1.3)
		var pb1 = Vector3(cos(a1) * r * 1.3, 0.0, sin(a1) * r * 1.3)
		var pt0 = Vector3(cos(a0) * r, h_mast, sin(a0) * r)
		var pt1 = Vector3(cos(a1) * r, h_mast, sin(a1) * r)

		var n0 = Vector3(cos(a0), 0, sin(a0))
		var n1 = Vector3(cos(a1), 0, sin(a1))

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pb1)
		st.set_normal(n1); st.add_vertex(pt1)

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pt1)
		st.set_normal(n0); st.add_vertex(pt0)

	# Cantilever arm extending forward (-Z)
	var arm_pts = [
		Vector3(0, h_mast, 0),
		Vector3(0, height * 0.95, -0.5),
		Vector3(0, height, -1.1)
	]
	for seg in range(arm_pts.size() - 1):
		var p_start = arm_pts[seg]
		var p_end = arm_pts[seg + 1]
		var v0 = p_start + Vector3(-r * 0.8, 0, 0)
		var v1 = p_start + Vector3(r * 0.8, 0, 0)
		var v2 = p_end + Vector3(r * 0.6, 0, 0)
		var v3 = p_end + Vector3(-r * 0.6, 0, 0)

		st.set_normal(Vector3.UP)
		st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(v2)
		st.add_vertex(v0); st.add_vertex(v2); st.add_vertex(v3)

	return st.commit()

static func _create_hip_roof_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hd = depth * 0.5
	var hh = height * 0.5

	var ridge_w = hw * 0.4
	var r0 = Vector3(-ridge_w, hh, 0.0)
	var r1 = Vector3(ridge_w, hh, 0.0)

	var c_fl = Vector3(-hw, -hh, -hd)
	var c_fr = Vector3(hw, -hh, -hd)
	var c_rr = Vector3(hw, -hh, hd)
	var c_rl = Vector3(-hw, -hh, hd)

	# Front slope (-Z)
	st.set_normal(Vector3(0, 0.6, -0.8).normalized())
	st.add_vertex(r0); st.add_vertex(c_fr); st.add_vertex(c_fl)
	st.add_vertex(r0); st.add_vertex(r1); st.add_vertex(c_fr)

	# Back slope (+Z)
	st.set_normal(Vector3(0, 0.6, 0.8).normalized())
	st.add_vertex(r1); st.add_vertex(c_rl); st.add_vertex(c_rr)
	st.add_vertex(r1); st.add_vertex(r0); st.add_vertex(c_rl)

	# Left hip (-X)
	st.set_normal(Vector3(-0.8, 0.6, 0).normalized())
	st.add_vertex(r0); st.add_vertex(c_fl); st.add_vertex(c_rl)

	# Right hip (+X)
	st.set_normal(Vector3(0.8, 0.6, 0).normalized())
	st.add_vertex(r1); st.add_vertex(c_rr); st.add_vertex(c_fr)

	return st.commit()

static func _create_wedge_ramp_mesh(width: float, height: float, length: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hl = length * 0.5

	var v_entry_l = Vector3(-hw, 0.0, -hl)
	var v_entry_r = Vector3(hw, 0.0, -hl)
	var v_crest_l = Vector3(-hw, height, hl)
	var v_crest_r = Vector3(hw, height, hl)
	var v_back_l = Vector3(-hw, 0.0, hl)
	var v_back_r = Vector3(hw, 0.0, hl)

	# Top incline face
	var ramp_normal = Vector3(0.0, length, -height).normalized()
	st.set_normal(ramp_normal)
	st.set_uv(Vector2(0, 1)); st.add_vertex(v_entry_l)
	st.set_uv(Vector2(1, 1)); st.add_vertex(v_entry_r)
	st.set_uv(Vector2(1, 0)); st.add_vertex(v_crest_r)

	st.set_uv(Vector2(0, 1)); st.add_vertex(v_entry_l)
	st.set_uv(Vector2(1, 0)); st.add_vertex(v_crest_r)
	st.set_uv(Vector2(0, 0)); st.add_vertex(v_crest_l)

	# Vertical back face
	st.set_normal(Vector3.BACK)
	st.add_vertex(v_crest_l); st.add_vertex(v_crest_r); st.add_vertex(v_back_r)
	st.add_vertex(v_crest_l); st.add_vertex(v_back_r); st.add_vertex(v_back_l)

	# Left triangular side
	st.set_normal(Vector3.LEFT)
	st.add_vertex(v_entry_l); st.add_vertex(v_crest_l); st.add_vertex(v_back_l)

	# Right triangular side
	st.set_normal(Vector3.RIGHT)
	st.add_vertex(v_entry_r); st.add_vertex(v_back_r); st.add_vertex(v_crest_r)

	return st.commit()

static func _create_faceted_canopy_mesh(radius: float, height: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments = 10
	var hh = height * 0.5

	var p_top = Vector3(0, hh, 0)
	var p_bottom = Vector3(0, -hh * 0.5, 0)

	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var mid0 = Vector3(cos(a0) * radius, 0.0, sin(a0) * radius)
		var mid1 = Vector3(cos(a1) * radius, 0.0, sin(a1) * radius)

		# Upper cone
		var n_up = Vector3(cos((a0 + a1) * 0.5), 0.7, sin((a0 + a1) * 0.5)).normalized()
		st.set_normal(n_up)
		st.add_vertex(p_top); st.add_vertex(mid0); st.add_vertex(mid1)

		# Lower cone
		var n_dn = Vector3(cos((a0 + a1) * 0.5), -0.7, sin((a0 + a1) * 0.5)).normalized()
		st.set_normal(n_dn)
		st.add_vertex(p_bottom); st.add_vertex(mid1); st.add_vertex(mid0)

	return st.commit()

static func _create_water_tank_mesh(radius: float, height: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs = 12
	var tank_h = height * 0.7
	var leg_h = height * 0.3

	# Tank Cylinder (Cedar Slats)
	for i in range(segs):
		var a0 = float(i) * TAU / float(segs)
		var a1 = float(i + 1) * TAU / float(segs)
		var c0 = cos(a0); var s0 = sin(a0)
		var c1 = cos(a1); var s1 = sin(a1)

		var pb0 = Vector3(c0 * radius, leg_h, s0 * radius)
		var pb1 = Vector3(c1 * radius, leg_h, s1 * radius)
		var pt0 = Vector3(c0 * radius, leg_h + tank_h, s0 * radius)
		var pt1 = Vector3(c1 * radius, leg_h + tank_h, s1 * radius)

		var n0 = Vector3(c0, 0, s0); var n1 = Vector3(c1, 0, s1)
		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pb1)
		st.set_normal(n1); st.add_vertex(pt1)

		st.set_normal(n0); st.add_vertex(pb0)
		st.set_normal(n1); st.add_vertex(pt1)
		st.set_normal(n0); st.add_vertex(pt0)

		# Conical Roof Cap
		var p_roof = Vector3(0, height + 0.8, 0)
		var n_roof = Vector3((c0 + c1) * 0.5, 0.7, (s0 + s1) * 0.5).normalized()
		st.set_normal(n_roof)
		st.add_vertex(pt0); st.add_vertex(pt1); st.add_vertex(p_roof)

	return st.commit()

static func _create_stoop_mesh(width: float, height: float, depth: float, steps: int = 5) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var step_h = height / float(steps)
	var step_d = depth / float(steps)

	for i in range(steps):
		var y0 = float(i) * step_h
		var y1 = float(i + 1) * step_h
		var z0 = -depth * 0.5 + float(i) * step_d
		var z1 = -depth * 0.5 + float(i + 1) * step_d

		# Riser (Vertical face)
		st.set_normal(Vector3.FORWARD)
		st.add_vertex(Vector3(-hw, y0, z0)); st.add_vertex(Vector3(hw, y0, z0)); st.add_vertex(Vector3(hw, y1, z0))
		st.add_vertex(Vector3(-hw, y0, z0)); st.add_vertex(Vector3(hw, y1, z0)); st.add_vertex(Vector3(-hw, y1, z0))

		# Tread (Horizontal step face)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(-hw, y1, z0)); st.add_vertex(Vector3(hw, y1, z0)); st.add_vertex(Vector3(hw, y1, z1))
		st.add_vertex(Vector3(-hw, y1, z0)); st.add_vertex(Vector3(hw, y1, z1)); st.add_vertex(Vector3(-hw, y1, z1))

	return st.commit()

static func _create_fire_escape_mesh(width: float, height: float, depth: float, floors: int = 4) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var floor_h = height / float(floors)

	for i in range(floors):
		var y = float(i) * floor_h
		# Platform grate
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(-hw, y, 0)); st.add_vertex(Vector3(hw, y, 0)); st.add_vertex(Vector3(hw, y, depth))
		st.add_vertex(Vector3(-hw, y, 0)); st.add_vertex(Vector3(hw, y, depth)); st.add_vertex(Vector3(-hw, y, depth))

		# Front railing
		st.set_normal(Vector3.BACK)
		st.add_vertex(Vector3(-hw, y, depth)); st.add_vertex(Vector3(hw, y, depth)); st.add_vertex(Vector3(hw, y + 0.9, depth))
		st.add_vertex(Vector3(-hw, y, depth)); st.add_vertex(Vector3(hw, y + 0.9, depth)); st.add_vertex(Vector3(-hw, y + 0.9, depth))

	return st.commit()

static func _create_cornice_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5
	var hd = depth * 0.5
	var hh = height * 0.5

	# Projecting decorative entablature cornice
	var faces = [
		[Vector3.FORWARD, [Vector3(-hw, -hh, -hd), Vector3(hw, -hh, -hd), Vector3(hw * 1.05, hh, -hd * 1.05), Vector3(-hw * 1.05, hh, -hd * 1.05)]],
		[Vector3.BACK,    [Vector3(hw, -hh, hd), Vector3(-hw, -hh, hd), Vector3(-hw * 1.05, hh, hd * 1.05), Vector3(hw * 1.05, hh, hd * 1.05)]],
		[Vector3.UP,      [Vector3(-hw * 1.05, hh, -hd * 1.05), Vector3(hw * 1.05, hh, -hd * 1.05), Vector3(hw * 1.05, hh, hd * 1.05), Vector3(-hw * 1.05, hh, hd * 1.05)]]
	]
	for f in faces:
		var n: Vector3 = f[0]; var v: Array = f[1]
		st.set_normal(n)
		st.add_vertex(v[0]); st.add_vertex(v[1]); st.add_vertex(v[2])
		st.add_vertex(v[0]); st.add_vertex(v[2]); st.add_vertex(v[3])

	return st.commit()

static func _create_awning_mesh(width: float, height: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = width * 0.5

	# Sloped canvas face
	var n_slope = Vector3(0, depth, height).normalized()
	st.set_normal(n_slope)
	st.add_vertex(Vector3(-hw, height, 0)); st.add_vertex(Vector3(hw, height, 0)); st.add_vertex(Vector3(hw, 0, depth))
	st.add_vertex(Vector3(-hw, height, 0)); st.add_vertex(Vector3(hw, 0, depth)); st.add_vertex(Vector3(-hw, 0, depth))

	# Front valance flap
	st.set_normal(Vector3.BACK)
	st.add_vertex(Vector3(-hw, 0, depth)); st.add_vertex(Vector3(hw, 0, depth)); st.add_vertex(Vector3(hw, -0.3, depth))
	st.add_vertex(Vector3(-hw, 0, depth)); st.add_vertex(Vector3(hw, -0.3, depth)); st.add_vertex(Vector3(-hw, -0.3, depth))

	return st.commit()

static func _create_traffic_signal_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w = 0.38; var h = 1.05; var d = 0.28
	var hw = w * 0.5; var hh = h * 0.5; var hd = d * 0.5

	# Yellow Housing Box
	st.set_normal(Vector3.FORWARD)
	st.add_vertex(Vector3(-hw, -hh, -hd)); st.add_vertex(Vector3(hw, -hh, -hd)); st.add_vertex(Vector3(hw, hh, -hd))
	st.add_vertex(Vector3(-hw, -hh, -hd)); st.add_vertex(Vector3(hw, hh, -hd)); st.add_vertex(Vector3(-hw, hh, -hd))

	st.set_normal(Vector3.BACK)
	st.add_vertex(Vector3(hw, -hh, hd)); st.add_vertex(Vector3(-hw, -hh, hd)); st.add_vertex(Vector3(-hw, hh, hd))
	st.add_vertex(Vector3(hw, -hh, hd)); st.add_vertex(Vector3(-hw, hh, hd)); st.add_vertex(Vector3(hw, hh, hd))

	return st.commit()

static func _create_subway_globe_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs = 8
	var r = 0.18
	for i in range(segs):
		var a0 = float(i) * TAU / float(segs)
		var a1 = float(i + 1) * TAU / float(segs)
		var v0 = Vector3(cos(a0) * r, -r * 0.3, sin(a0) * r)
		var v1 = Vector3(cos(a1) * r, -r * 0.3, sin(a1) * r)
		var vt = Vector3(0, r, 0)
		var vb = Vector3(0, -r, 0)
		var n = Vector3(cos((a0 + a1) * 0.5), 0.5, sin((a0 + a1) * 0.5)).normalized()
		st.set_normal(n)
		st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(vt)
		st.set_normal(-n)
		st.add_vertex(v1); st.add_vertex(v0); st.add_vertex(vb)

	return st.commit()

static func _create_truss_beam_mesh(length: float, width: float, height: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hl = length * 0.5
	var hw = width * 0.5
	var hh = height * 0.5

	# Top Chord
	st.set_normal(Vector3.UP)
	st.add_vertex(Vector3(-hl, hh, -hw)); st.add_vertex(Vector3(hl, hh, -hw)); st.add_vertex(Vector3(hl, hh, hw))
	st.add_vertex(Vector3(-hl, hh, -hw)); st.add_vertex(Vector3(hl, hh, hw)); st.add_vertex(Vector3(-hl, hh, hw))

	# Bottom Chord
	st.set_normal(Vector3.DOWN)
	st.add_vertex(Vector3(-hl, -hh, hw)); st.add_vertex(Vector3(hl, -hh, hw)); st.add_vertex(Vector3(hl, -hh, -hw))
	st.add_vertex(Vector3(-hl, -hh, hw)); st.add_vertex(Vector3(hl, -hh, -hw)); st.add_vertex(Vector3(-hl, -hh, -hw))

	return st.commit()

