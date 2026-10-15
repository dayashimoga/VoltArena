class_name UrbanVehicleVisuals
extends RefCounted

const UrbanConstants = preload("res://games/urban-legends/core/urban_constants.gd")
const UrbanVehicleCatalog = preload("res://games/urban-legends/vehicles/urban_vehicle_catalog.gd")

## High-fidelity procedural 3D automotive model generator for Urban Legends.
## Constructs realistic sports cars, supercars, muscle cars, SUVs, and classic cruisers.
## Includes aerodynamic body shells, tinted glass, spoilers, working headlights,
## reactive brake lights, dual exhaust tips, and articulated wheels with alloy rims and brake calipers.

static func build_vehicle_visual(vehicle_node: Node3D, vehicle_id: String, paint_color: Color) -> Dictionary:
	# Root chassis holder for pitch/roll weight transfer
	var chassis_node = Node3D.new()
	chassis_node.name = "ChassisMeshRoot"
	vehicle_node.add_child(chassis_node)

	var def = UrbanVehicleCatalog.get_vehicle_def(vehicle_id)
	var dims: Vector3 = def.get("dimensions", Vector3(1.95, 1.15, 4.45))

	# PBR Materials
	var paint_mat = StandardMaterial3D.new()
	paint_mat.albedo_color = paint_color
	paint_mat.metallic = 0.85
	paint_mat.roughness = 0.22
	paint_mat.clearcoat_enabled = true
	paint_mat.clearcoat = 0.95
	paint_mat.clearcoat_roughness = 0.15

	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.08, 0.12, 0.18, 0.65)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.95
	glass_mat.roughness = 0.08

	var dark_trim_mat = StandardMaterial3D.new()
	dark_trim_mat.albedo_color = Color(0.12, 0.12, 0.14)
	dark_trim_mat.metallic = 0.4
	dark_trim_mat.roughness = 0.6

	var chrome_mat = StandardMaterial3D.new()
	chrome_mat.albedo_color = Color(0.92, 0.92, 0.95)
	chrome_mat.metallic = 0.98
	chrome_mat.roughness = 0.1

	var headlight_mat = StandardMaterial3D.new()
	headlight_mat.albedo_color = Color(0.95, 0.98, 1.0)
	headlight_mat.emission_enabled = true
	headlight_mat.emission = Color(0.9, 0.95, 1.0)
	headlight_mat.emission_energy_multiplier = 2.5

	var taillight_mat = StandardMaterial3D.new()
	taillight_mat.albedo_color = Color(0.85, 0.05, 0.05)
	taillight_mat.emission_enabled = true
	taillight_mat.emission = Color(0.95, 0.05, 0.05)
	taillight_mat.emission_energy_multiplier = 1.8

	# 1. Main Lower Body
	var lower_body = MeshInstance3D.new()
	lower_body.name = "LowerBody"
	var lower_mesh = BoxMesh.new()
	lower_mesh.size = Vector3(dims.x, dims.y * 0.48, dims.z)
	lower_body.mesh = lower_mesh
	lower_body.material_override = paint_mat
	lower_body.position = Vector3(0, dims.y * 0.38, 0)
	chassis_node.add_child(lower_body)

	# 2. Upper Cabin / Greenhouse
	var cabin = MeshInstance3D.new()
	cabin.name = "Cabin"
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(dims.x * 0.82, dims.y * 0.52, dims.z * 0.48)
	cabin.mesh = cabin_mesh
	cabin.material_override = glass_mat
	# Shift cabin slightly backward for sports/supercars
	var cabin_z = 0.15 if vehicle_id == UrbanConstants.VEHICLE_VORTEX_GT else -0.05
	cabin.position = Vector3(0, dims.y * 0.82, cabin_z)
	chassis_node.add_child(cabin)

	# 3. Roof Panel
	var roof = MeshInstance3D.new()
	roof.name = "Roof"
	var roof_mesh = BoxMesh.new()
	roof_mesh.size = Vector3(dims.x * 0.78, 0.06, dims.z * 0.44)
	roof.mesh = roof_mesh
	roof.material_override = paint_mat
	roof.position = Vector3(0, dims.y * 1.08, cabin_z)
	chassis_node.add_child(roof)

	# 4. Front Hood Slope & Bumper
	var hood = MeshInstance3D.new()
	hood.name = "FrontHood"
	var hood_mesh = BoxMesh.new()
	hood_mesh.size = Vector3(dims.x * 0.92, 0.14, dims.z * 0.32)
	hood.mesh = hood_mesh
	hood.material_override = paint_mat
	hood.position = Vector3(0, dims.y * 0.58, -dims.z * 0.32)
	hood.rotation.x = deg_to_rad(4.0)
	chassis_node.add_child(hood)

	# Front Splitter / Grille
	var splitter = MeshInstance3D.new()
	splitter.name = "FrontSplitter"
	var split_mesh = BoxMesh.new()
	split_mesh.size = Vector3(dims.x * 0.96, 0.08, 0.25)
	splitter.mesh = split_mesh
	splitter.material_override = dark_trim_mat
	splitter.position = Vector3(0, dims.y * 0.18, -dims.z * 0.49)
	chassis_node.add_child(splitter)

	# 5. Rear Deck & Diffuser / Spoiler
	if vehicle_id in [UrbanConstants.VEHICLE_VORTEX_GT, UrbanConstants.VEHICLE_SPECTER_R]:
		# Aerodynamic Rear Wing Spoiler
		var spoiler_wing = MeshInstance3D.new()
		spoiler_wing.name = "SpoilerWing"
		var wing_mesh = BoxMesh.new()
		wing_mesh.size = Vector3(dims.x * 0.88, 0.05, 0.28)
		spoiler_wing.mesh = wing_mesh
		spoiler_wing.material_override = dark_trim_mat
		spoiler_wing.position = Vector3(0, dims.y * 0.88, dims.z * 0.46)
		chassis_node.add_child(spoiler_wing)

		# Spoiler uprights
		for sx in [-0.55, 0.55]:
			var strut = MeshInstance3D.new()
			var strut_mesh = BoxMesh.new()
			strut_mesh.size = Vector3(0.04, 0.28, 0.12)
			strut.mesh = strut_mesh
			strut.material_override = dark_trim_mat
			strut.position = Vector3(sx, dims.y * 0.74, dims.z * 0.46)
			chassis_node.add_child(strut)

	# Rear Diffuser
	var diffuser = MeshInstance3D.new()
	diffuser.name = "RearDiffuser"
	var diff_mesh = BoxMesh.new()
	diff_mesh.size = Vector3(dims.x * 0.92, 0.12, 0.22)
	diffuser.mesh = diff_mesh
	diffuser.material_override = dark_trim_mat
	diffuser.position = Vector3(0, dims.y * 0.2, dims.z * 0.48)
	chassis_node.add_child(diffuser)

	# 6. Dual Headlights
	for hx in [-dims.x * 0.38, dims.x * 0.38]:
		var hl = MeshInstance3D.new()
		var hl_mesh = BoxMesh.new()
		hl_mesh.size = Vector3(0.24, 0.10, 0.08)
		hl.mesh = hl_mesh
		hl.material_override = headlight_mat
		hl.position = Vector3(hx, dims.y * 0.52, -dims.z * 0.48)
		chassis_node.add_child(hl)

	# 7. Dual Taillights
	for tx in [-dims.x * 0.38, dims.x * 0.38]:
		var tl = MeshInstance3D.new()
		var tl_mesh = BoxMesh.new()
		tl_mesh.size = Vector3(0.28, 0.12, 0.08)
		tl.mesh = tl_mesh
		tl.material_override = taillight_mat
		tl.position = Vector3(tx, dims.y * 0.55, dims.z * 0.48)
		chassis_node.add_child(tl)

	# 8. Quad Exhaust Pipes
	for ex in [-0.32, -0.20, 0.20, 0.32]:
		var ep = MeshInstance3D.new()
		var ep_mesh = CylinderMesh.new()
		ep_mesh.top_radius = 0.05
		ep_mesh.bottom_radius = 0.05
		ep_mesh.height = 0.15
		ep.mesh = ep_mesh
		ep.material_override = chrome_mat
		ep.position = Vector3(ex, dims.y * 0.22, dims.z * 0.49)
		ep.rotation.x = deg_to_rad(90.0)
		chassis_node.add_child(ep)

	# 9. 4 Articulated Wheels with Rubber Tires & Alloy Rims
	var wheel_nodes: Array[Node3D] = []
	var wheel_offsets = [
		Vector3(-dims.x * 0.46, 0.36, -dims.z * 0.32), # FL
		Vector3(dims.x * 0.46, 0.36, -dims.z * 0.32),  # FR
		Vector3(-dims.x * 0.47, 0.36, dims.z * 0.32),   # RL
		Vector3(dims.x * 0.47, 0.36, dims.z * 0.32)    # RR
	]

	var tire_mat = StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.12, 0.12, 0.13)
	tire_mat.roughness = 0.85
	tire_mat.metallic = 0.1

	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.88, 0.88, 0.92)
	rim_mat.metallic = 0.95
	rim_mat.roughness = 0.2

	var caliper_mat = StandardMaterial3D.new()
	caliper_mat.albedo_color = Color(0.9, 0.1, 0.1) # Racing red brake caliper
	caliper_mat.metallic = 0.5
	caliper_mat.roughness = 0.3

	for i in range(4):
		var wheel_holder = Node3D.new()
		wheel_holder.name = "WheelHolder_%d" % i
		wheel_holder.position = wheel_offsets[i]
		vehicle_node.add_child(wheel_holder)

		# Tire cylinder
		var tire_mesh = CylinderMesh.new()
		tire_mesh.top_radius = UrbanConstants.TIRE_RADIUS
		tire_mesh.bottom_radius = UrbanConstants.TIRE_RADIUS
		tire_mesh.height = 0.26
		var tire_inst = MeshInstance3D.new()
		tire_inst.mesh = tire_mesh
		tire_inst.material_override = tire_mat
		tire_inst.rotation.z = deg_to_rad(90.0)
		wheel_holder.add_child(tire_inst)

		# Alloy Rim Face
		var rim_mesh = CylinderMesh.new()
		rim_mesh.top_radius = UrbanConstants.TIRE_RADIUS * 0.68
		rim_mesh.bottom_radius = UrbanConstants.TIRE_RADIUS * 0.68
		rim_mesh.height = 0.27
		var rim_inst = MeshInstance3D.new()
		rim_inst.mesh = rim_mesh
		rim_inst.material_override = rim_mat
		rim_inst.rotation.z = deg_to_rad(90.0)
		wheel_holder.add_child(rim_inst)

		# Brake Caliper
		var caliper_mesh = BoxMesh.new()
		caliper_mesh.size = Vector3(0.08, 0.12, 0.14)
		var cal_inst = MeshInstance3D.new()
		cal_inst.mesh = caliper_mesh
		cal_inst.material_override = caliper_mat
		cal_inst.position = Vector3(0, UrbanConstants.TIRE_RADIUS * 0.42, 0)
		wheel_holder.add_child(cal_inst)

		wheel_nodes.append(wheel_holder)

	return {
		"chassis_node": chassis_node,
		"wheels": wheel_nodes,
		"paint_material": paint_mat,
		"taillight_material": taillight_mat
	}
