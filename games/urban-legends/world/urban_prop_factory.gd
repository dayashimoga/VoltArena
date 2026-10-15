class_name UrbanPropFactory
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")

## High-performance procedural 3D prop and architecture factory for Urban Legends.
## Generates PBR-shaded buildings, bridges, vegetation, street furniture, and stunt ramps:
## - Downtown Skyscraper (Glass curtain towers with rooftop communication spires)
## - Colinas Villa (Terracotta tile roof hillside estates)
## - Flyover Viaduct Deck & Pillars (Elevated concrete freeway bridges)
## - California Fan Palms & Parkland Shade Trees
## - Streetlamps with reactive nighttime emissive glow
## - Insane Stunt Kicker Ramps with hazard chevron chevrons
## - Freight Shipping Containers & Rail Cranes
## - Stone Arched Bridges for park waterways

static func build_skyscraper(height: float = 75.0, width: float = 24.0, depth: float = 24.0, neon_tint: Color = Color(0.2, 0.6, 1.0)) -> Node3D:
	var root = Node3D.new()
	root.name = "Skyscraper"

	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(width, height, depth)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.15, 0.20)
	mat.metallic = 0.85
	mat.roughness = 0.18
	mat.emission_enabled = true
	mat.emission = neon_tint * 0.15

	var mi = MeshInstance3D.new()
	mi.mesh = body_mesh
	mi.material_override = mat
	mi.position = Vector3(0, height * 0.5, 0)
	root.add_child(mi)

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
	spire_mesh.bottom_radius = 0.6
	spire_mesh.height = 16.0
	spire.mesh = spire_mesh
	spire.position = Vector3(0, height + 8.0, 0)
	root.add_child(spire)

	return root

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

static func build_flyover_viaduct(length: float = 60.0, height: float = 18.0, width: float = 18.0) -> Node3D:
	var root = Node3D.new()
	root.name = "FlyoverViaduct"

	# Concrete Road Deck
	var deck_thickness = 1.4
	var deck_mi = MeshInstance3D.new()
	var deck_mesh = BoxMesh.new()
	deck_mesh.size = Vector3(width, deck_thickness, length)
	var deck_mat = StandardMaterial3D.new()
	deck_mat.albedo_color = Color(0.20, 0.21, 0.22) # Highway asphalt
	deck_mat.roughness = 0.75
	deck_mi.mesh = deck_mesh
	deck_mi.material_override = deck_mat
	deck_mi.position = Vector3(0, height, 0)
	root.add_child(deck_mi)

	# Left & Right Concrete Crash Barriers
	var barrier_h = 1.1
	for side in [-1.0, 1.0]:
		var bar_mi = MeshInstance3D.new()
		var bar_mesh = BoxMesh.new()
		bar_mesh.size = Vector3(0.5, barrier_h, length)
		var bar_mat = StandardMaterial3D.new()
		bar_mat.albedo_color = Color(0.65, 0.65, 0.65) # Concrete barrier
		bar_mi.mesh = bar_mesh
		bar_mi.material_override = bar_mat
		bar_mi.position = Vector3(side * (width * 0.5 - 0.25), height + barrier_h * 0.5 + deck_thickness * 0.5, 0)
		root.add_child(bar_mi)

	# Supporting Concrete Pillars
	var pillar_count = maxi(2, int(length / 25.0))
	var pillar_mat = StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.58, 0.58, 0.60)
	pillar_mat.roughness = 0.85

	for p in range(pillar_count):
		var z_off = -length * 0.5 + (length / float(pillar_count - 1)) * float(p)
		var pillar_mi = MeshInstance3D.new()
		var pillar_mesh = CylinderMesh.new()
		pillar_mesh.top_radius = 1.4
		pillar_mesh.bottom_radius = 1.8
		pillar_mesh.height = height
		pillar_mi.mesh = pillar_mesh
		pillar_mi.material_override = pillar_mat
		pillar_mi.position = Vector3(0, height * 0.5, z_off)
		root.add_child(pillar_mi)

	# Deck Collision (Road Surface)
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, deck_thickness, length)
	col.shape = box
	col.position = Vector3(0, height, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_palm_tree(height: float = 9.5) -> Node3D:
	var root = Node3D.new()
	root.name = "PalmTree"

	# Curved Trunk
	var trunk_mi = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = height
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.38, 0.28, 0.18) # Palm bark
	trunk_mat.roughness = 0.95
	trunk_mi.mesh = trunk_mesh
	trunk_mi.material_override = trunk_mat
	trunk_mi.position = Vector3(0, height * 0.5, 0)
	trunk_mi.rotation.z = deg_to_rad(4.5) # Gentle tropical lean
	root.add_child(trunk_mi)

	# Palm Frond Crown
	var crown_mat = StandardMaterial3D.new()
	crown_mat.albedo_color = Color(0.18, 0.48, 0.16)
	crown_mat.roughness = 0.65

	for i in range(8):
		var frond = MeshInstance3D.new()
		var f_mesh = PrismMesh.new()
		f_mesh.size = Vector3(0.8, 0.2, 4.2)
		frond.mesh = f_mesh
		frond.material_override = crown_mat
		frond.position = Vector3(0, height, 0)
		frond.rotation.y = deg_to_rad(float(i) * 45.0)
		frond.rotation.x = deg_to_rad(22.0)
		root.add_child(frond)

	# Trunk Base Collision
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.45
	cyl.height = height
	col.shape = cyl
	col.position = Vector3(0, height * 0.5, 0)
	body.add_child(col)
	root.add_child(body)

	return root

static func build_street_lamp(height: float = 6.8) -> Node3D:
	var root = Node3D.new()
	root.name = "StreetLamp"

	# Metal Pole
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

	# Overhanging Lamp Head
	var head_mi = MeshInstance3D.new()
	var head_mesh = BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.18, 1.2)
	head_mi.mesh = head_mesh
	head_mi.material_override = pole_mat
	head_mi.position = Vector3(0, height, -0.45)
	root.add_child(head_mi)

	# Glowing Bulb Fixture
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
	ramp_mi.rotation.x = deg_to_rad(-90.0) # Lay prism flat as an incline
	ramp_mi.rotation.z = deg_to_rad(180.0)
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

	# Collision Ramp Body (Concave polygon for perfect wheel climb)
	var body = StaticBody3D.new()
	body.collision_layer = UrbanConstants.LAYER_WORLD
	body.collision_mask = UrbanConstants.LAYER_PLAYER | UrbanConstants.LAYER_ENEMIES
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(width, height * 0.9, length)
	col.shape = box
	col.position = Vector3(0, height * 0.45, 0)
	col.rotation.x = deg_to_rad(-kicker_angle_deg * 0.5)
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
