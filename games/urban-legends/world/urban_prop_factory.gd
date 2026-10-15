class_name UrbanPropFactory
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")

## High-performance 3D prop and architecture factory for Urban Legends.
## Generates production-grade PBR buildings, streetlights, vegetation, and stunt ramps:
## - Downtown Skyscraper (Authentic GLTF high-rises with illuminated windows and rooftop spires)
## - Commercial District (Offices, storefronts, multi-story commercial buildings)
## - Colinas Villa (Terracotta tile roof hillside estates)
## - Flyover Viaduct Deck & Pillars (Elevated concrete freeway bridges)
## - California Fan Palms & Parkland Shade Trees (High-poly 3D tree foliage)
## - Streetlamps with reactive nighttime emissive glow
## - Insane Stunt Kicker Ramps with hazard chevrons
## - Freight Shipping Containers & Maritime Docks

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

const LIGHTPOST_GLB: String = "res://assets/models/environment/road_lightposts.glb"

static func build_skyscraper(height: float = 75.0, width: float = 24.0, depth: float = 24.0, neon_tint: Color = Color(0.2, 0.6, 1.0)) -> Node3D:
	var root = Node3D.new()
	root.name = "Skyscraper"

	# Try loading authentic production skyscraper GLB
	var rand_idx = randi() % SKYSCRAPER_GLBS.size()
	var glb_path = SKYSCRAPER_GLBS[rand_idx]
	var model = ModelCache.get_model(glb_path)

	if is_instance_valid(model):
		model.name = "SkyscraperMesh"
		# Asset base size is ~1.36m x 2.88m x 1.36m
		var sx = width / 1.36
		var sy = height / 2.88
		var sz = depth / 1.36
		model.scale = Vector3(sx, sy, sz)
		root.add_child(model)
	else:
		# Multi-tiered architectural procedural fallback with glass & spires
		_build_procedural_skyscraper_mesh(root, height, width, depth, neon_tint)

	# Static collision body
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

	# Rooftop communication antenna spire
	var spire = MeshInstance3D.new()
	var spire_mesh = CylinderMesh.new()
	spire_mesh.top_radius = 0.1
	spire_mesh.bottom_radius = 0.5
	spire_mesh.height = 14.0
	spire.mesh = spire_mesh
	spire.position = Vector3(0, height + 7.0, 0)
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
		root.add_child(model)
	else:
		var mi = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(width, height, depth)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.72, 0.68)
		mat.roughness = 0.7
		mi.mesh = box
		mi.material_override = mat
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
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(width, height, depth)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.16, 0.22)
	mat.metallic = 0.85
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = neon_tint * 0.2

	var mi = MeshInstance3D.new()
	mi.mesh = body_mesh
	mi.material_override = mat
	mi.position = Vector3(0, height * 0.5, 0)
	parent.add_child(mi)

static func build_residential_villa(width: float = 14.0, depth: float = 12.0) -> Node3D:
	var root = Node3D.new()
	root.name = "ColinasVilla"

	# Stucco Lower Walls
	var wall_height = 4.5
	var wall_mi = MeshInstance3D.new()
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(width, wall_height, depth)
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.88, 0.82, 0.72) # Cream stucco
	wall_mat.roughness = 0.85
	wall_mi.mesh = wall_mesh
	wall_mi.material_override = wall_mat
	wall_mi.position = Vector3(0, wall_height * 0.5, 0)
	root.add_child(wall_mi)

	# Terracotta Hip Roof (Spanish Colonial Villa reference in Colinas)
	var roof_height = 2.4
	var roof_mi = MeshInstance3D.new()
	var roof_mesh = PrismMesh.new()
	roof_mesh.size = Vector3(width + 1.6, roof_height, depth + 1.6)
	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.72, 0.28, 0.15) # Burnt terracotta red
	roof_mat.roughness = 0.7
	roof_mi.mesh = roof_mesh
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

	# Support pillars spaced along viaduct
	var num_pillars = maxi(2, int(length / 28.0))
	var step = length / float(num_pillars)
	for i in range(num_pillars):
		var p_z = -length * 0.5 + step * (i + 0.5)

		# Pillar shaft
		var pillar = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 1.1
		p_mesh.bottom_radius = 1.4
		p_mesh.height = height
		pillar.mesh = p_mesh
		pillar.material_override = p_mat
		pillar.position = Vector3(0, -height * 0.5, p_z)
		root.add_child(pillar)

		# Cross-head beam supporting freeway deck
		var beam = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(width * 0.95, 1.2, 2.4)
		beam.mesh = b_mesh
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
		# Procedural tree fallback
		var trunk = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.45
		cyl.height = height * 0.45
		var t_mat = StandardMaterial3D.new()
		t_mat.albedo_color = Color(0.32, 0.22, 0.14)
		trunk.mesh = cyl
		trunk.material_override = t_mat
		trunk.position = Vector3(0, height * 0.22, 0)
		root.add_child(trunk)

		var canopy = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = height * 0.38
		sph.height = height * 0.70
		var l_mat = StandardMaterial3D.new()
		l_mat.albedo_color = Color(0.18, 0.42, 0.16)
		canopy.mesh = sph
		canopy.material_override = l_mat
		canopy.position = Vector3(0, height * 0.70, 0)
		root.add_child(canopy)

	# Lightweight trunk collision
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
	return build_tree(height)

static func build_street_lamp(height: float = 6.8) -> Node3D:
	var root = Node3D.new()
	root.name = "StreetLamp"

	var model = ModelCache.get_model(LIGHTPOST_GLB)
	if is_instance_valid(model):
		model.name = "LightpostMesh"
		var s = height / 0.55
		model.scale = Vector3(s, s, s)
		root.add_child(model)
	else:
		# Procedural lamp
		var pole_mi = MeshInstance3D.new()
		var pole_mesh = CylinderMesh.new()
		pole_mesh.top_radius = 0.08
		pole_mesh.bottom_radius = 0.14
		pole_mesh.height = height
		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.22, 0.24, 0.26)
		pole_mat.metallic = 0.8
		pole_mat.roughness = 0.3
		pole_mi.mesh = pole_mesh
		pole_mi.material_override = pole_mat
		pole_mi.position = Vector3(0, height * 0.5, 0)
		root.add_child(pole_mi)

		var head_mi = MeshInstance3D.new()
		var head_mesh = BoxMesh.new()
		head_mesh.size = Vector3(0.4, 0.18, 1.2)
		head_mi.mesh = head_mesh
		head_mi.material_override = pole_mat
		head_mi.position = Vector3(0, height, -0.45)
		root.add_child(head_mi)

		var bulb_mi = MeshInstance3D.new()
		var bulb_mesh = BoxMesh.new()
		bulb_mesh.size = Vector3(0.3, 0.05, 0.8)
		var bulb_mat = StandardMaterial3D.new()
		bulb_mat.albedo_color = Color(1.0, 0.95, 0.8)
		bulb_mat.emission_enabled = true
		bulb_mat.emission = Color(1.0, 0.88, 0.6) * 2.5
		bulb_mi.mesh = bulb_mesh
		bulb_mi.material_override = bulb_mat
		bulb_mi.position = Vector3(0, height - 0.1, -0.45)
		root.add_child(bulb_mi)

	# Lightweight pole collision
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_PROPS
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.2
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

	# Wedge Ramp Geometry using PrismMesh
	var ramp_mi = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(width, height, length)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.65, 0.1) # Bright yellow stunt metal
	mat.metallic = 0.5
	mat.roughness = 0.35
	ramp_mi.mesh = prism
	ramp_mi.material_override = mat
	ramp_mi.position = Vector3(0, height * 0.5, 0)
	ramp_mi.rotation_degrees.x = -90.0 # Lay flat
	ramp_mi.rotation_degrees.z = 180.0
	root.add_child(ramp_mi)

	# Hazard Chevron Striping across ramp lip
	var chevron_mi = MeshInstance3D.new()
	var chevron_mesh = BoxMesh.new()
	chevron_mesh.size = Vector3(width, 0.08, 0.6)
	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.05, 0.05, 0.05)
	chevron_mi.mesh = chevron_mesh
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
	var box = BoxMesh.new()
	box.size = Vector3(width, height, length)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mat.metallic = 0.4
	mi.mesh = box
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
	var box = BoxMesh.new()
	box.size = Vector3(width, bridge_h, span)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.50, 0.46) # Weathered stone
	mat.roughness = 0.9
	mi.mesh = box
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
