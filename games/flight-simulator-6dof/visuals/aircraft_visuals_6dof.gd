class_name AircraftVisuals6DoF
extends Node3D

## Visual airframe generator and control surface animator for the 6-DoF Aircraft.
## Implements painted aluminum PBR (metallic 0.35, roughness 0.22, clearcoat),
## tinted canopy glass, articulated control surfaces (ailerons, flaps, elevators, rudder),
## and polar-UV propeller blur disk.

var painted_aluminum_mat: StandardMaterial3D
var canopy_glass_mat: StandardMaterial3D
var propeller_blur_mat: ShaderMaterial

# Articulated Control Surface Meshes
var left_aileron: Node3D
var right_aileron: Node3D
var left_flap: Node3D
var right_flap: Node3D
var left_elevator: Node3D
var right_elevator: Node3D
var rudder: Node3D
var prop_blur_mesh: MeshInstance3D

func _ready() -> void:
	_setup_materials()
	_build_airframe()

func _setup_materials() -> void:
	# Painted Aluminum PBR
	painted_aluminum_mat = StandardMaterial3D.new()
	painted_aluminum_mat.albedo_color = Color(0.92, 0.94, 0.96)
	painted_aluminum_mat.metallic = 0.35
	painted_aluminum_mat.roughness = 0.22
	painted_aluminum_mat.clearcoat_enabled = true
	painted_aluminum_mat.clearcoat = 1.0
	painted_aluminum_mat.clearcoat_roughness = 0.1

	# Canopy Glass
	canopy_glass_mat = StandardMaterial3D.new()
	canopy_glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	canopy_glass_mat.albedo_color = Color(0.1, 0.15, 0.18, 0.25)
	canopy_glass_mat.metallic = 0.1
	canopy_glass_mat.roughness = 0.05
	canopy_glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Propeller Blur Shader
	var shader = load("res://games/flight-simulator-6dof/shaders/prop_blur.gdshader")
	if shader:
		propeller_blur_mat = ShaderMaterial.new()
		propeller_blur_mat.shader = shader

func _build_airframe() -> void:
	# Instantiate base 3D model if available
	var glb_path = "res://assets/models/vehicles/aircraft_propeller.glb"
	var base_model: Node3D = null
	if ResourceLoader.exists(glb_path):
		var scene = load(glb_path) as PackedScene
		if scene:
			base_model = scene.instantiate() as Node3D
			# Scale to true 6-DoF trainer dimensions (approx 8.5m length, 10.5m span)
			base_model.scale = Vector3(2.4, 2.4, 2.4)
			# Re-center and align with coordinate convention (nose -Z)
			base_model.position = Vector3(0.0, 0.0, 0.2)
			_apply_materials_to_model(base_model)
			add_child(base_model)

	# If GLB not available or for additional articulated detail, build precision aerodynamic geometry
	_build_articulated_surfaces()
	_build_propeller_disc()

func _apply_materials_to_model(node: Node) -> void:
	for c in node.get_children():
		if c is MeshInstance3D:
			c.material_override = painted_aluminum_mat
		_apply_materials_to_model(c)

func _build_articulated_surfaces() -> void:
	# 1. Left and Right Ailerons (Outboard wings at Z = +0.05)
	left_aileron = _create_control_surface(Vector3(-3.8, 0.45, 0.75), Vector3(1.8, 0.06, 0.35))
	right_aileron = _create_control_surface(Vector3(3.8, 0.45, 0.75), Vector3(1.8, 0.06, 0.35))

	# 2. Left and Right Fowler Flaps (Inboard wings at Z = +0.0)
	left_flap = _create_control_surface(Vector3(-1.4, 0.4, 0.75), Vector3(1.6, 0.08, 0.45))
	right_flap = _create_control_surface(Vector3(1.4, 0.4, 0.75), Vector3(1.6, 0.08, 0.45))

	# 3. Elevators (Horizontal Stabilizer at Z = +4.6)
	left_elevator = _create_control_surface(Vector3(-0.9, 0.3, 4.85), Vector3(1.4, 0.05, 0.3))
	right_elevator = _create_control_surface(Vector3(0.9, 0.3, 4.85), Vector3(1.4, 0.05, 0.3))

	# 4. Rudder (Vertical Stabilizer at Z = +4.7, Y = +1.1)
	rudder = _create_control_surface(Vector3(0.0, 1.25, 4.95), Vector3(0.08, 1.3, 0.38), true)

func _create_control_surface(pos: Vector3, size: Vector3, is_vertical: bool = false) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = pos

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	mesh_inst.material_override = painted_aluminum_mat

	# Hinge offset: place mesh slightly behind the pivot hinge
	if not is_vertical:
		mesh_inst.position = Vector3(0, 0, size.z * 0.5)
	else:
		mesh_inst.position = Vector3(0, 0, size.z * 0.5)

	pivot.add_child(mesh_inst)
	add_child(pivot)
	return pivot

func _build_propeller_disc() -> void:
	prop_blur_mesh = MeshInstance3D.new()
	prop_blur_mesh.name = "PropellerBlurDisk"

	var quad = QuadMesh.new()
	quad.size = Vector2(2.1, 2.1)
	prop_blur_mesh.mesh = quad
	# Position in front of the nose spinner
	prop_blur_mesh.position = Vector3(0.0, 0.05, -2.15)
	# Quad default faces +Z, rotate 180 to face -Z forward
	prop_blur_mesh.rotation.y = PI

	if propeller_blur_mat:
		prop_blur_mesh.material_override = propeller_blur_mat

	add_child(prop_blur_mesh)

func _process(delta: float) -> void:
	var controller = get_parent() as AircraftController
	if not controller:
		return

	# Animate ailerons
	var max_aileron_rad = deg_to_rad(18.0)
	if left_aileron:
		left_aileron.rotation.x = -controller.roll_input * max_aileron_rad
	if right_aileron:
		right_aileron.rotation.x = controller.roll_input * max_aileron_rad

	# Animate flaps
	var flap_rad = deg_to_rad(controller.flaps_angles[controller.flaps_index])
	if left_flap:
		left_flap.rotation.x = lerp(left_flap.rotation.x, flap_rad, 8.0 * delta)
	if right_flap:
		right_flap.rotation.x = lerp(right_flap.rotation.x, flap_rad, 8.0 * delta)

	# Animate elevators
	var max_elev_rad = deg_to_rad(20.0)
	var elev_target = -controller.pitch_input * max_elev_rad
	if left_elevator:
		left_elevator.rotation.x = elev_target
	if right_elevator:
		right_elevator.rotation.x = elev_target

	# Animate rudder
	var max_rudder_rad = deg_to_rad(25.0)
	if rudder:
		rudder.rotation.y = -controller.rudder_input * max_rudder_rad
