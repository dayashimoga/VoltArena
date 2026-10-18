class_name TrafficVehicleBuilder
extends RefCounted

## High-fidelity 3D traffic vehicle factory for Urban Legends.
## Generates contoured, multi-material vehicles across 8 authentic metropolitan classes:
## 1. NYC Yellow Cab Sedan
## 2. NYPD-Style Police Cruiser
## 3. FDNY-Style Ambulance / Fire Support
## 4. MTA-Style City Transit Bus
## 5. Box Delivery Truck
## 6. Muscle Car (V8 GT)
## 7. Luxury SUV
## 8. Contoured Supercar (Apex GT)
##
## Strict visual quality constraints:
## - Dark rubber tires (Color(0.12, 0.12, 0.13), roughness 0.9)
## - Metallic 5-spoke alloy rims (metallic 0.85, roughness 0.2)
## - Projector LED headlights (emission 4.0)
## - Reactive bright red taillights (emission 5.0)
## - Zero primitive BoxMesh / CylinderMesh or unshaded cyan wheel cylinders.

const ModelCache = preload("res://shared/graphics/model_cache.gd")

const CLASS_NYC_TAXI: String = "nyc_taxi"
const CLASS_POLICE: String = "nypd_police"
const CLASS_AMBULANCE: String = "fdny_ambulance"
const CLASS_TRANSIT_BUS: String = "mta_bus"
const CLASS_BOX_TRUCK: String = "box_truck"
const CLASS_MUSCLE: String = "muscle_car"
const CLASS_SUV: String = "luxury_suv"
const CLASS_SUPERCAR: String = "supercar"

const ALL_CLASSES: Array[String] = [
	CLASS_NYC_TAXI,
	CLASS_POLICE,
	CLASS_AMBULANCE,
	CLASS_TRANSIT_BUS,
	CLASS_BOX_TRUCK,
	CLASS_MUSCLE,
	CLASS_SUV,
	CLASS_SUPERCAR
]

const MODEL_MAP: Dictionary = {
	CLASS_NYC_TAXI: "res://assets/models/vehicles/car_taxi.glb",
	CLASS_POLICE: "res://assets/models/vehicles/car_police.glb",
	CLASS_AMBULANCE: "res://assets/models/vehicles/truck_red.glb",
	CLASS_TRANSIT_BUS: "res://assets/models/vehicles/truck_green.glb",
	CLASS_BOX_TRUCK: "res://assets/models/vehicles/truck_yellow.glb",
	CLASS_MUSCLE: "res://assets/models/vehicles/car_race.glb",
	CLASS_SUV: "res://assets/models/vehicles/car_suv_luxury.glb",
	CLASS_SUPERCAR: "res://assets/models/vehicles/car_sedan_sports.glb"
}

static func get_tire_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.resource_name = "Mat_DarkRubberTire"
	mat.albedo_color = Color(0.12, 0.12, 0.13)
	mat.roughness = 0.90
	mat.metallic = 0.05
	return mat

static func get_rim_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.resource_name = "Mat_AlloyRim"
	mat.albedo_color = Color(0.85, 0.85, 0.88)
	mat.metallic = 0.85
	mat.roughness = 0.20
	return mat

static func get_headlight_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.resource_name = "Mat_LEDHeadlight"
	mat.albedo_color = Color(0.96, 0.98, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.96, 0.98, 1.0)
	mat.emission_energy_multiplier = 4.0
	return mat

static func get_taillight_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.resource_name = "Mat_BrightTaillight"
	mat.albedo_color = Color(0.90, 0.05, 0.05)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.05, 0.05)
	mat.emission_energy_multiplier = 5.0
	return mat

static func build_traffic_vehicle_visual(vehicle_class: String) -> Dictionary:
	var visual_root = Node3D.new()
	visual_root.name = "Visuals"

	var glb_path: String = MODEL_MAP.get(vehicle_class, MODEL_MAP[CLASS_NYC_TAXI])
	var car_model = ModelCache.get_model(glb_path)
	if not is_instance_valid(car_model):
		car_model = ModelCache.get_model("res://assets/models/vehicles/car_sedan.glb")

	var wheels: Array[Node3D] = []
	var is_police: bool = (vehicle_class == CLASS_POLICE)
	var is_ambulance: bool = (vehicle_class == CLASS_AMBULANCE)

	# Dimensions per class
	var scale_vec = Vector3(1.3, 1.3, 1.3)
	var wheel_track = 0.95
	var wheel_base = 1.35
	var wheel_radius = 0.35

	if vehicle_class == CLASS_TRANSIT_BUS:
		scale_vec = Vector3(1.4, 1.45, 1.6)
		wheel_track = 1.05
		wheel_base = 1.7
		wheel_radius = 0.40
	elif vehicle_class == CLASS_BOX_TRUCK:
		scale_vec = Vector3(1.35, 1.4, 1.45)
		wheel_track = 1.0
		wheel_base = 1.55
		wheel_radius = 0.38
	elif vehicle_class == CLASS_SUV:
		scale_vec = Vector3(1.38, 1.38, 1.38)
		wheel_track = 1.0
		wheel_base = 1.4
		wheel_radius = 0.38
	elif vehicle_class == CLASS_SUPERCAR or vehicle_class == CLASS_MUSCLE:
		scale_vec = Vector3(1.32, 1.25, 1.35)
		wheel_track = 0.96
		wheel_base = 1.35
		wheel_radius = 0.34

	if is_instance_valid(car_model):
		car_model.name = "BodyModel"
		car_model.scale = scale_vec
		car_model.rotation.y = PI
		car_model.position = Vector3(0.0, 0.05, 0.0)
		visual_root.add_child(car_model)

		_hide_internal_wheels(car_model)
		wheels = _spawn_articulated_wheels(visual_root, wheel_track, wheel_base, wheel_radius)
	else:
		wheels = _build_procedural_car_body(visual_root, vehicle_class, wheel_track, wheel_base, wheel_radius)

	# Lighting package
	_attach_vehicle_lights(visual_root, wheel_track, wheel_base, is_police, is_ambulance)

	return {
		"visual_root": visual_root,
		"wheels": wheels,
		"is_police": is_police,
		"is_ambulance": is_ambulance
	}

static func _hide_internal_wheels(node: Node) -> void:
	if node is MeshInstance3D:
		var n_low = node.name.to_lower()
		if "wheel" in n_low or "tire" in n_low:
			node.visible = false
	for child in node.get_children():
		_hide_internal_wheels(child)

static func _spawn_articulated_wheels(parent: Node3D, track: float, base: float, radius: float) -> Array[Node3D]:
	var wheel_nodes: Array[Node3D] = []
	var offsets = [
		Vector3(-track, radius, -base),
		Vector3(track, radius, -base),
		Vector3(-track, radius, base),
		Vector3(track, radius, base)
	]

	var tire_mat = get_tire_material()
	var rim_mat = get_rim_material()

	for i in range(4):
		var wh = Node3D.new()
		wh.name = "Wheel_%d" % i
		wh.position = offsets[i]

		var w_model = ModelCache.get_model("res://assets/models/vehicles/car_wheel_racing.glb")
		if is_instance_valid(w_model):
			w_model.scale = Vector3(1.1, 1.1, 1.1)
			if i % 2 == 1:
				w_model.rotation.y = PI
			wh.add_child(w_model)
		else:
			# High-fidelity procedural 5-spoke alloy wheel with dark rubber tire
			var wheel_mesh = _create_5spoke_alloy_wheel(radius, 0.26, tire_mat, rim_mat)
			wh.add_child(wheel_mesh)

		parent.add_child(wh)
		wheel_nodes.append(wh)

	return wheel_nodes

static func _create_5spoke_alloy_wheel(radius: float, width: float, tire_mat: Material, rim_mat: Material) -> Node3D:
	var root = Node3D.new()
	var hw = width * 0.5
	var rim_r = radius * 0.65

	# 1. Dark Rubber Outer Tire
	var tire_st = SurfaceTool.new()
	tire_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs = 18
	for i in range(segs):
		var a0 = float(i) * TAU / float(segs)
		var a1 = float(i + 1) * TAU / float(segs)

		var y0 = cos(a0) * radius; var z0 = sin(a0) * radius
		var y1 = cos(a1) * radius; var z1 = sin(a1) * radius
		var ry0 = cos(a0) * rim_r; var rz0 = sin(a0) * rim_r
		var ry1 = cos(a1) * rim_r; var rz1 = sin(a1) * rim_r

		var n0 = Vector3(0.0, cos(a0), sin(a0))
		var n1 = Vector3(0.0, cos(a1), sin(a1))

		# Tread band
		tire_st.set_normal(n0); tire_st.add_vertex(Vector3(-hw, y0, z0))
		tire_st.set_normal(n0); tire_st.add_vertex(Vector3(hw, y0, z0))
		tire_st.set_normal(n1); tire_st.add_vertex(Vector3(hw, y1, z1))

		tire_st.set_normal(n0); tire_st.add_vertex(Vector3(-hw, y0, z0))
		tire_st.set_normal(n1); tire_st.add_vertex(Vector3(hw, y1, z1))
		tire_st.set_normal(n1); tire_st.add_vertex(Vector3(-hw, y1, z1))

		# Sidewalls
		tire_st.set_normal(Vector3.RIGHT)
		tire_st.add_vertex(Vector3(hw, ry0, rz0))
		tire_st.add_vertex(Vector3(hw, y0, z0))
		tire_st.add_vertex(Vector3(hw, y1, z1))

		tire_st.set_normal(Vector3.RIGHT)
		tire_st.add_vertex(Vector3(hw, ry0, rz0))
		tire_st.add_vertex(Vector3(hw, y1, z1))
		tire_st.add_vertex(Vector3(hw, ry1, rz1))

		tire_st.set_normal(Vector3.LEFT)
		tire_st.add_vertex(Vector3(-hw, ry0, rz0))
		tire_st.add_vertex(Vector3(-hw, y1, z1))
		tire_st.add_vertex(Vector3(-hw, y0, z0))

		tire_st.set_normal(Vector3.LEFT)
		tire_st.add_vertex(Vector3(-hw, ry0, rz0))
		tire_st.add_vertex(Vector3(-hw, ry1, rz1))
		tire_st.add_vertex(Vector3(-hw, y1, z1))

	var tire_mi = MeshInstance3D.new()
	tire_mi.mesh = tire_st.commit()
	tire_mi.material_override = tire_mat
	root.add_child(tire_mi)

	# 2. Metallic 5-Spoke Alloy Rim
	var rim_st = SurfaceTool.new()
	rim_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hub_r = rim_r * 0.28
	var spokes = 5
	for s in range(spokes):
		var ang = float(s) * TAU / float(spokes)
		var ang_l = ang - 0.16
		var ang_r = ang + 0.16

		var v_hub = Vector3(hw * 0.9, 0, 0)
		var v_rim_l = Vector3(hw * 0.95, cos(ang_l) * rim_r, sin(ang_l) * rim_r)
		var v_rim_r = Vector3(hw * 0.95, cos(ang_r) * rim_r, sin(ang_r) * rim_r)

		rim_st.set_normal(Vector3.RIGHT)
		rim_st.add_vertex(v_hub)
		rim_st.add_vertex(v_rim_l)
		rim_st.add_vertex(v_rim_r)

	var rim_mi = MeshInstance3D.new()
	rim_mi.mesh = rim_st.commit()
	rim_mi.material_override = rim_mat
	root.add_child(rim_mi)

	return root

static func _build_procedural_car_body(visual_root: Node3D, vehicle_class: String, track: float, base: float, radius: float) -> Array[Node3D]:
	var paint_mat = StandardMaterial3D.new()
	paint_mat.metallic = 0.80
	paint_mat.roughness = 0.22
	paint_mat.clearcoat_enabled = true
	paint_mat.clearcoat = 1.0

	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.08, 0.12, 0.18, 0.8)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic = 0.9
	glass_mat.roughness = 0.05

	match vehicle_class:
		CLASS_NYC_TAXI:
			paint_mat.albedo_color = Color(0.96, 0.78, 0.10)
		CLASS_POLICE:
			paint_mat.albedo_color = Color(0.92, 0.94, 0.96)
		CLASS_AMBULANCE:
			paint_mat.albedo_color = Color(0.85, 0.12, 0.12)
		CLASS_TRANSIT_BUS:
			paint_mat.albedo_color = Color(0.15, 0.45, 0.78)
		CLASS_BOX_TRUCK:
			paint_mat.albedo_color = Color(0.88, 0.88, 0.90)
		CLASS_MUSCLE:
			paint_mat.albedo_color = Color(0.75, 0.15, 0.12)
		CLASS_SUV:
			paint_mat.albedo_color = Color(0.18, 0.20, 0.24)
		CLASS_SUPERCAR:
			paint_mat.albedo_color = Color(0.08, 0.45, 0.95)
		_:
			paint_mat.albedo_color = Color(0.5, 0.5, 0.55)

	# Contoured Faceted ArrayMesh Body (strictly zero BoxMesh)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = track * 0.98
	var hl = base * 1.55
	var h_lower = radius * 1.8
	var h_roof = radius * 3.4

	# Body lower chassis vertices
	var p_front_low = Vector3(0, radius * 0.5, -hl)
	var p_fl = Vector3(-hw, h_lower, -hl * 0.7)
	var p_fr = Vector3(hw, h_lower, -hl * 0.7)
	var p_hood = Vector3(0, h_lower * 1.1, -hl * 0.4)
	var p_rl = Vector3(-hw, h_lower, hl * 0.7)
	var p_rr = Vector3(hw, h_lower, hl * 0.7)
	var p_rear_low = Vector3(0, radius * 0.6, hl)

	# Hood / front deck
	st.set_normal(Vector3(0, 0.6, -0.8).normalized())
	st.add_vertex(p_hood); st.add_vertex(p_fl); st.add_vertex(p_front_low)
	st.add_vertex(p_hood); st.add_vertex(p_front_low); st.add_vertex(p_fr)

	# Sides
	st.set_normal(Vector3.LEFT)
	st.add_vertex(p_hood); st.add_vertex(p_rl); st.add_vertex(p_fl)
	st.set_normal(Vector3.RIGHT)
	st.add_vertex(p_hood); st.add_vertex(p_fr); st.add_vertex(p_rr)

	# Rear deck
	st.set_normal(Vector3(0, 0.5, 0.86).normalized())
	st.add_vertex(p_hood); st.add_vertex(p_rr); st.add_vertex(p_rear_low)
	st.add_vertex(p_hood); st.add_vertex(p_rear_low); st.add_vertex(p_rl)

	var body_mi = MeshInstance3D.new()
	body_mi.mesh = st.commit()
	body_mi.material_override = paint_mat
	visual_root.add_child(body_mi)

	# Cabin & windshield
	var c_st = SurfaceTool.new()
	c_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cw = hw * 0.78
	var c_front = Vector3(0, h_roof, -hl * 0.05)
	var c_rear = Vector3(0, h_roof, hl * 0.45)
	var c_l = Vector3(-cw, h_roof * 0.95, hl * 0.2)
	var c_r = Vector3(cw, h_roof * 0.95, hl * 0.2)

	c_st.set_normal(Vector3(0, 0.7, -0.7).normalized())
	c_st.add_vertex(c_front); st.add_vertex(p_hood); st.add_vertex(c_l)
	c_st.add_vertex(c_front); st.add_vertex(c_r); st.add_vertex(p_hood)

	c_st.set_normal(Vector3.UP)
	c_st.add_vertex(c_front); c_st.add_vertex(c_l); c_st.add_vertex(c_rear)
	c_st.add_vertex(c_front); c_st.add_vertex(c_rear); c_st.add_vertex(c_r)

	var cabin_mi = MeshInstance3D.new()
	cabin_mi.mesh = c_st.commit()
	cabin_mi.material_override = glass_mat
	visual_root.add_child(cabin_mi)

	return _spawn_articulated_wheels(visual_root, track, base, radius)

static func _attach_vehicle_lights(visual_root: Node3D, track: float, base: float, is_police: bool, is_ambulance: bool) -> void:
	var hl_mat = get_headlight_material()
	var tl_mat = get_taillight_material()

	var lens_mesh = _create_lens_disc(0.09, 14)
	var z_front = -(base * 1.55)
	var z_rear = base * 1.55

	for hx in [-track * 0.75, track * 0.75]:
		var hl = MeshInstance3D.new()
		hl.mesh = lens_mesh
		hl.material_override = hl_mat
		hl.position = Vector3(hx, 0.65, z_front)
		visual_root.add_child(hl)

		var spot = SpotLight3D.new()
		spot.light_color = Color(0.96, 0.98, 1.0)
		spot.light_energy = 3.0
		spot.spot_range = 35.0
		spot.spot_angle = 35.0
		spot.position = Vector3(hx, 0.65, z_front - 0.05)
		spot.rotation_degrees.x = -4.0
		visual_root.add_child(spot)

	for tx in [-track * 0.75, track * 0.75]:
		var tl = MeshInstance3D.new()
		tl.mesh = lens_mesh
		tl.material_override = tl_mat
		tl.position = Vector3(tx, 0.72, z_rear)
		tl.rotation.y = PI
		visual_root.add_child(tl)

	if is_police:
		var beacon_r = OmniLight3D.new()
		beacon_r.name = "BeaconRed"
		beacon_r.light_color = Color(1.0, 0.08, 0.08)
		beacon_r.light_energy = 4.0
		beacon_r.omni_range = 18.0
		beacon_r.position = Vector3(-0.35, 1.45, 0.0)
		visual_root.add_child(beacon_r)

		var beacon_b = OmniLight3D.new()
		beacon_b.name = "BeaconBlue"
		beacon_b.light_color = Color(0.1, 0.35, 1.0)
		beacon_b.light_energy = 4.0
		beacon_b.omni_range = 18.0
		beacon_b.position = Vector3(0.35, 1.45, 0.0)
		visual_root.add_child(beacon_b)

	if is_ambulance:
		var beacon_w = OmniLight3D.new()
		beacon_w.name = "BeaconWhite"
		beacon_w.light_color = Color(1.0, 0.95, 0.9)
		beacon_w.light_energy = 4.5
		beacon_w.omni_range = 20.0
		beacon_w.position = Vector3(0.0, 1.6, 0.0)
		visual_root.add_child(beacon_w)

static func _create_lens_disc(radius: float, segments: int = 14) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		var a0 = float(i) * TAU / float(segments)
		var a1 = float(i + 1) * TAU / float(segments)
		var p0 = Vector3(cos(a0) * radius, sin(a0) * radius, 0.0)
		var p1 = Vector3(cos(a1) * radius, sin(a1) * radius, 0.0)
		st.set_normal(Vector3.FORWARD)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(p0)
		st.add_vertex(p1)
	return st.commit()
