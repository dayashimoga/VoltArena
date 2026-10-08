class_name AeroVehicleVisuals
extends RefCounted

## High-fidelity automotive visual constructor and dynamics animator for AeroRush.
## Builds fictional performance stunt vehicles with PBR automotive paint, LED headlamps,
## reactive brake/taillights, alloy wheels, carbon aero diffusers, active stunt spoiler,
## ventilated brake discs with calipers, exhaust VFX, skid smoke, sparks, and wingtip air trails.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")
const AeroVehicleCatalog = preload("res://games/aero-rush/vehicles/aero_vehicle_catalog.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")

const AUTOMOTIVE_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 paint_color : source_color = vec4(0.08, 0.58, 0.95, 1.0);
uniform float metallic_val : hint_range(0.0, 1.0) = 0.88;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.16;
uniform bool is_braking = false;
uniform bool is_reversing = false;
uniform bool is_boosting = false;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	bool is_trim = (tex.r < 0.28 && tex.g < 0.28 && tex.b < 0.28);
	bool is_glass = (tex.b > 0.65 && tex.g > 0.45 && tex.r < 0.55);
	bool is_headlight = (tex.r > 0.88 && tex.g > 0.88 && tex.b > 0.88);
	bool is_taillight = (tex.r > 0.65 && tex.g < 0.22 && tex.b < 0.22);

	if (is_headlight) {
		// Projector LED Headlamps with high emission
		ALBEDO = vec3(0.96, 0.98, 1.0);
		EMISSION = vec3(1.0, 0.98, 0.94) * 3.8;
		METALLIC = 0.75;
		ROUGHNESS = 0.05;
		SPECULAR = 0.90;
	} else if (is_taillight) {
		// Reactive Rear Taillamps and Dynamic Brake Light Glow
		ALBEDO = is_reversing ? vec3(0.98, 0.98, 0.92) : vec3(0.95, 0.04, 0.06);
		float brake_mult = is_reversing ? 4.0 : (is_braking ? 5.5 : 1.5);
		vec3 emit_col = is_reversing ? vec3(1.0, 0.98, 0.90) : vec3(1.0, 0.02, 0.04);
		EMISSION = emit_col * brake_mult;
		METALLIC = 0.35;
		ROUGHNESS = 0.10;
		SPECULAR = 0.80;
	} else if (is_glass) {
		// Reflective Deep Smoked Glass Canopy
		ALBEDO = vec3(0.04, 0.06, 0.10);
		ROUGHNESS = 0.04;
		METALLIC = 0.45;
		SPECULAR = 0.95;
	} else if (is_trim) {
		// Matte Carbon Fiber Splitters, Side Skirts & Rear Diffuser
		ALBEDO = vec3(0.08, 0.08, 0.09);
		ROUGHNESS = 0.82;
		METALLIC = 0.12;
		SPECULAR = 0.30;
	} else {
		// Multi-Coat Automotive Metallic Paint
		float lum = (tex.r * 0.299 + tex.g * 0.587 + tex.b * 0.114);
		float factor = clamp(lum / 0.65, 0.85, 1.18);
		ALBEDO = paint_color.rgb * factor;
		METALLIC = metallic_val;
		ROUGHNESS = roughness_val;
		SPECULAR = 0.80;
		if (is_boosting) {
			EMISSION = paint_color.rgb * 0.4;
		}
	}
}
"""

const WHEEL_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

void fragment() {
	float r = length(VERTEX.yz);
	if (r > 0.18) {
		// Vulcanized Rubber Tire Tread and Sidewall
		ALBEDO = vec3(0.10, 0.10, 0.12);
		ROUGHNESS = 0.92;
		METALLIC = 0.02;
		SPECULAR = 0.15;
	} else {
		// Diamond-Cut Precision Alloy Rim & Carbon Rotor
		ALBEDO = vec3(0.85, 0.87, 0.90);
		ROUGHNESS = 0.18;
		METALLIC = 0.95;
		SPECULAR = 0.90;
	}
}
"""

static func build_vehicle_visuals(vehicle_id: String, paint_color: Color = Color.WHITE) -> Dictionary:
	var def = AeroVehicleCatalog.get_vehicle_definition(vehicle_id)
	var chosen_color = paint_color if paint_color != Color.WHITE else def.get("default_color", Color(0.08, 0.58, 0.95))

	var root = Node3D.new()
	root.name = "VehicleVisualsRoot"

	# 1. Main Chassis Visual Container (rolls, pitches, dives)
	var chassis_node = Node3D.new()
	chassis_node.name = "ChassisNode"
	root.add_child(chassis_node)

	# 2. Instance Real GLB Body Mesh
	var glb_path = def.get("glb_path", "res://assets/models/vehicles/car_race_future.glb")
	var body_model = ModelCache.get_model(glb_path)
	if not body_model:
		body_model = Node3D.new()
	body_model.name = "BodyModel"
	chassis_node.add_child(body_model)

	# Clean GLB: Hide any static embedded wheel meshes inside imported model
	_hide_internal_wheels(body_model)

	# Apply Automotive Shader
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = AUTOMOTIVE_SHADER_CODE
	mat.shader = shader
	mat.set_shader_parameter("paint_color", chosen_color)
	mat.set_shader_parameter("metallic_val", 0.88)
	mat.set_shader_parameter("roughness_val", 0.16)
	_apply_material_to_meshes(body_model, mat)

	# 3. Add High-Performance Aerodynamic Kit
	var active_wing = _build_active_aero_wing(chosen_color)
	chassis_node.add_child(active_wing)

	var splitter = _build_front_splitter()
	chassis_node.add_child(splitter)

	var diffuser = _build_rear_diffuser()
	chassis_node.add_child(diffuser)

	var underglow = _build_neon_underglow(chosen_color)
	chassis_node.add_child(underglow)

	# 4. Create Articulated Wheel Hubs with Brake Discs & Calipers
	var wheel_glb_path = def.get("wheel_glb_path", "res://assets/models/vehicles/car_wheel_racing.glb")
	var wheel_mat = ShaderMaterial.new()
	var w_shader = Shader.new()
	w_shader.code = WHEEL_SHADER_CODE
	wheel_mat.shader = w_shader

	var wheel_offsets = [
		Vector3(-0.76, 0.32, -1.22), # Front Left
		Vector3(0.76, 0.32, -1.22),  # Front Right
		Vector3(-0.78, 0.34, 1.22),  # Rear Left
		Vector3(0.78, 0.34, 1.22)    # Rear Right
	]

	var wheels: Array[Node3D] = []
	var wheel_names = ["FrontLeftWheel", "FrontRightWheel", "RearLeftWheel", "RearRightWheel"]

	for i in range(4):
		var hub = Node3D.new()
		hub.name = wheel_names[i]
		hub.position = wheel_offsets[i]
		root.add_child(hub)

		# Add Brake Disc Rotor
		var rotor = _build_brake_disc(i % 2 == 1)
		hub.add_child(rotor)

		# Articulated Wheel Mesh
		var wheel_mesh = ModelCache.get_model(wheel_glb_path)
		if not wheel_mesh:
			wheel_mesh = Node3D.new()
		wheel_mesh.name = "WheelMesh"
		if i % 2 == 1:
			wheel_mesh.rotation_degrees.y = 180.0
		_apply_material_to_meshes(wheel_mesh, wheel_mat)
		hub.add_child(wheel_mesh)
		wheels.append(hub)

	# 5. Boost Exhaust Emitters (Dual Tailpipe Thrusters)
	var exhaust_left = _create_exhaust_particles(Vector3(-0.32, 0.36, 1.95), chosen_color)
	var exhaust_right = _create_exhaust_particles(Vector3(0.32, 0.36, 1.95), chosen_color)
	chassis_node.add_child(exhaust_left)
	chassis_node.add_child(exhaust_right)

	# 6. Tire Smoke Emitters (Drift & Burnout)
	var smoke_left = _create_smoke_particles(Vector3(-0.78, 0.08, 1.22))
	var smoke_right = _create_smoke_particles(Vector3(0.78, 0.08, 1.22))
	root.add_child(smoke_left)
	root.add_child(smoke_right)

	# 7. Landing Contact Spark Emitter
	var sparks = _create_spark_particles()
	root.add_child(sparks)

	# 8. High-Speed Wingtip Air Trail Emitters
	var trail_left = _create_air_trail_particles(Vector3(-0.85, 0.88, 1.80))
	var trail_right = _create_air_trail_particles(Vector3(0.85, 0.88, 1.80))
	chassis_node.add_child(trail_left)
	chassis_node.add_child(trail_right)

	# 9. Touchdown Dust Burst Emitter
	var dust_burst = _create_dust_burst_particles()
	root.add_child(dust_burst)

	return {
		"root": root,
		"chassis": chassis_node,
		"body_model": body_model,
		"body_material": mat,
		"wheels": wheels,
		"active_wing": active_wing,
		"exhaust_emitters": [exhaust_left, exhaust_right],
		"smoke_emitters": [smoke_left, smoke_right],
		"sparks_emitter": sparks,
		"air_trails": [trail_left, trail_right],
		"dust_burst": dust_burst,
		"paint_color": chosen_color
	}

static func _hide_internal_wheels(node: Node) -> void:
	if "wheel" in node.name.to_lower():
		if node is VisualInstance3D:
			(node as VisualInstance3D).visible = false
	for child in node.get_children():
		_hide_internal_wheels(child)

static func _build_brake_disc(is_right_side: bool) -> Node3D:
	var root = Node3D.new()
	root.name = "BrakeAssembly"

	# Steel Ventilated Rotor Disc
	var rotor = MeshInstance3D.new()
	rotor.name = "RotorDisc"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.22
	cyl.height = 0.03
	rotor.mesh = cyl
	rotor.rotation_degrees.z = 90.0

	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.75, 0.76, 0.78)
	r_mat.metallic = 0.95
	r_mat.roughness = 0.22
	rotor.material_override = r_mat
	root.add_child(rotor)

	# Performance Race-Red Brake Caliper
	var caliper = MeshInstance3D.new()
	caliper.name = "BrakeCaliper"
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.12, 0.16)
	caliper.mesh = box
	caliper.position = Vector3(0.02 if is_right_side else -0.02, 0.14, 0.0)

	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_color = Color(0.88, 0.08, 0.08)
	c_mat.metallic = 0.70
	c_mat.roughness = 0.20
	caliper.material_override = c_mat
	root.add_child(caliper)

	return root

static func _build_active_aero_wing(accent_col: Color) -> Node3D:
	var wing_root = Node3D.new()
	wing_root.name = "ActiveAeroWing"
	wing_root.position = Vector3(0.0, 0.72, 1.65)

	# Twin Carbon Aerodynamic Stanchions / Struts
	var mat_carbon = StandardMaterial3D.new()
	mat_carbon.albedo_color = Color(0.10, 0.10, 0.12)
	mat_carbon.metallic = 0.85
	mat_carbon.roughness = 0.35

	for side in [-0.38, 0.38]:
		var strut = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.04, 0.28, 0.14)
		strut.mesh = s_box
		strut.material_override = mat_carbon
		strut.position = Vector3(side, 0.14, 0.0)
		strut.rotation_degrees.x = 14.0
		wing_root.add_child(strut)

	# Main Downforce Wing Blade
	var blade = MeshInstance3D.new()
	blade.name = "WingBlade"
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.68, 0.04, 0.34)
	blade.mesh = b_box
	blade.position = Vector3(0.0, 0.28, 0.04)

	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.08, 0.09, 0.11)
	blade_mat.metallic = 0.85
	blade_mat.roughness = 0.25
	blade.material_override = blade_mat
	wing_root.add_child(blade)

	# Sculpted Endplates with Accent Neon Trim
	for side in [-0.84, 0.84]:
		var endplate = MeshInstance3D.new()
		var ep_box = BoxMesh.new()
		ep_box.size = Vector3(0.03, 0.16, 0.38)
		endplate.mesh = ep_box
		endplate.position = Vector3(side, 0.28, 0.04)

		var ep_mat = StandardMaterial3D.new()
		ep_mat.albedo_color = accent_col
		ep_mat.emission_enabled = true
		ep_mat.emission = accent_col * 1.5
		ep_mat.metallic = 0.5
		ep_mat.roughness = 0.3
		endplate.material_override = ep_mat
		wing_root.add_child(endplate)

	return wing_root

static func _build_front_splitter() -> Node3D:
	var root = Node3D.new()
	root.name = "FrontSplitter"

	var mat_carbon = StandardMaterial3D.new()
	mat_carbon.albedo_color = Color(0.09, 0.09, 0.11)
	mat_carbon.metallic = 0.6
	mat_carbon.roughness = 0.5

	# Main lower carbon lip
	var lip = MeshInstance3D.new()
	var lip_box = BoxMesh.new()
	lip_box.size = Vector3(1.62, 0.04, 0.42)
	lip.mesh = lip_box
	lip.material_override = mat_carbon
	lip.position = Vector3(0.0, 0.14, -1.88)
	root.add_child(lip)

	# Carbon Dive-Plane Canards
	for side in [-0.78, 0.78]:
		var canard = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.16, 0.03, 0.22)
		canard.mesh = c_box
		canard.material_override = mat_carbon
		canard.position = Vector3(side, 0.26, -1.75)
		canard.rotation_degrees.z = -18.0 if side > 0 else 18.0
		root.add_child(canard)

	return root

static func _build_rear_diffuser() -> Node3D:
	var root = Node3D.new()
	root.name = "RearDiffuser"

	var mat_carbon = StandardMaterial3D.new()
	mat_carbon.albedo_color = Color(0.07, 0.08, 0.09)
	mat_carbon.metallic = 0.5
	mat_carbon.roughness = 0.6

	# Diffuser Under-Tray
	var tray = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(1.42, 0.05, 0.45)
	tray.mesh = t_box
	tray.material_override = mat_carbon
	tray.position = Vector3(0.0, 0.18, 1.86)
	tray.rotation_degrees.x = -10.0
	root.add_child(tray)

	# 4 Vertical Aerodynamic Strakes
	for x_pos in [-0.48, -0.16, 0.16, 0.48]:
		var strake = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.02, 0.12, 0.38)
		strake.mesh = s_box
		strake.material_override = mat_carbon
		strake.position = Vector3(x_pos, 0.18, 1.86)
		strake.rotation_degrees.x = -10.0
		root.add_child(strake)

	return root

static func _build_neon_underglow(col: Color) -> Node3D:
	var root = Node3D.new()
	root.name = "NeonUnderglow"

	var u_mat = StandardMaterial3D.new()
	u_mat.albedo_color = col
	u_mat.emission_enabled = true
	u_mat.emission = col * 2.5
	u_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

	for side in [-0.75, 0.75]:
		var tube = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.04, 0.03, 1.85)
		tube.mesh = box
		tube.material_override = u_mat
		tube.position = Vector3(side, 0.16, 0.0)
		root.add_child(tube)

	return root

static func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var orig_mat = node.get_active_material(0)
		var texture_to_use: Texture2D = null
		if orig_mat and orig_mat is StandardMaterial3D and orig_mat.albedo_texture:
			texture_to_use = orig_mat.albedo_texture
		elif ResourceLoader.exists("res://assets/models/vehicles/Textures/colormap.png"):
			texture_to_use = load("res://assets/models/vehicles/Textures/colormap.png") as Texture2D

		if material is ShaderMaterial:
			var cloned_mat = material.duplicate() as ShaderMaterial
			if texture_to_use:
				cloned_mat.set_shader_parameter("albedo_texture", texture_to_use)
			node.material_override = cloned_mat
		else:
			node.material_override = material
	for child in node.get_children():
		_apply_material_to_meshes(child, material)

static func _create_exhaust_particles(pos: Vector3, flame_color: Color) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "ExhaustParticles"
	particles.position = pos
	particles.emitting = false
	particles.amount = 32
	particles.lifetime = 0.25
	particles.explosiveness = 0.0

	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 0, 1)
	p_mat.spread = 6.0
	p_mat.initial_velocity_min = 12.0
	p_mat.initial_velocity_max = 20.0
	p_mat.scale_min = 0.12
	p_mat.scale_max = 0.28
	p_mat.color = flame_color * 1.8
	particles.process_material = p_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.08
	draw_mesh.height = 0.16
	var d_mat = StandardMaterial3D.new()
	d_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	d_mat.albedo_color = Color(1.0, 0.7, 0.2)
	d_mat.emission_enabled = true
	d_mat.emission = Color(1.0, 0.6, 0.1) * 3.0
	draw_mesh.material = d_mat
	particles.draw_pass_1 = draw_mesh

	return particles

static func _create_smoke_particles(pos: Vector3) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "TireSmokeParticles"
	particles.position = pos
	particles.emitting = false
	particles.amount = 40
	particles.lifetime = 0.6
	particles.explosiveness = 0.0

	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 0.5, 1)
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 2.0
	p_mat.initial_velocity_max = 5.0
	p_mat.scale_min = 0.25
	p_mat.scale_max = 0.85
	p_mat.color = Color(0.85, 0.85, 0.88, 0.45)
	particles.process_material = p_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.2
	draw_mesh.height = 0.4
	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.albedo_color = Color(0.8, 0.8, 0.8, 0.35)
	d_mat.roughness = 0.95
	draw_mesh.material = d_mat
	particles.draw_pass_1 = draw_mesh

	return particles

static func _create_spark_particles() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "SparksParticles"
	particles.position = Vector3(0, 0.1, 0)
	particles.emitting = false
	particles.amount = 24
	particles.lifetime = 0.35
	particles.explosiveness = 0.85
	particles.one_shot = true

	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 75.0
	p_mat.initial_velocity_min = 6.0
	p_mat.initial_velocity_max = 14.0
	p_mat.scale_min = 0.05
	p_mat.scale_max = 0.10
	p_mat.color = Color(1.0, 0.85, 0.3)
	particles.process_material = p_mat

	var draw_mesh = BoxMesh.new()
	draw_mesh.size = Vector3(0.04, 0.04, 0.04)
	var d_mat = StandardMaterial3D.new()
	d_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	d_mat.albedo_color = Color(1.0, 0.9, 0.4)
	d_mat.emission_enabled = true
	d_mat.emission = Color(1.0, 0.8, 0.2) * 4.0
	draw_mesh.material = d_mat
	particles.draw_pass_1 = draw_mesh

	return particles

static func _create_air_trail_particles(pos: Vector3) -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "AirTrailParticles"
	particles.position = pos
	particles.emitting = false
	particles.amount = 36
	particles.lifetime = 0.4
	particles.explosiveness = 0.0

	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 0, 1)
	p_mat.spread = 4.0
	p_mat.initial_velocity_min = 8.0
	p_mat.initial_velocity_max = 14.0
	p_mat.scale_min = 0.06
	p_mat.scale_max = 0.18
	p_mat.color = Color(0.85, 0.95, 1.0, 0.5)
	particles.process_material = p_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.06
	draw_mesh.height = 0.12
	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.4)
	d_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	draw_mesh.material = d_mat
	particles.draw_pass_1 = draw_mesh

	return particles

static func _create_dust_burst_particles() -> GPUParticles3D:
	var particles = GPUParticles3D.new()
	particles.name = "DustBurstParticles"
	particles.position = Vector3(0, 0.12, 0)
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 0.6
	particles.explosiveness = 0.9
	particles.one_shot = true

	var p_mat = ParticleProcessMaterial.new()
	p_mat.direction = Vector3(0, 0.4, 0)
	p_mat.spread = 80.0
	p_mat.initial_velocity_min = 4.0
	p_mat.initial_velocity_max = 9.0
	p_mat.scale_min = 0.2
	p_mat.scale_max = 0.7
	p_mat.color = Color(0.75, 0.72, 0.68, 0.4)
	particles.process_material = p_mat

	var draw_mesh = SphereMesh.new()
	draw_mesh.radius = 0.18
	draw_mesh.height = 0.36
	var d_mat = StandardMaterial3D.new()
	d_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	d_mat.albedo_color = Color(0.7, 0.68, 0.65, 0.35)
	d_mat.roughness = 0.95
	draw_mesh.material = d_mat
	particles.draw_pass_1 = draw_mesh

	return particles
