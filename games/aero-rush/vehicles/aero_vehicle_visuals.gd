class_name AeroVehicleVisuals
extends RefCounted

## High-fidelity automotive visual constructor and dynamics animator for AeroRush.
## Builds real 3D production GLB vehicles with PBR automotive paint, LED headlamps,
## reactive brake/taillights, alloy wheels, rubber tires, exhaust VFX, and skid smoke.

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
		float brake_mult = is_reversing ? 4.0 : (is_braking ? 5.2 : 1.4);
		vec3 emit_col = is_reversing ? vec3(1.0, 0.98, 0.90) : vec3(1.0, 0.02, 0.04);
		EMISSION = emit_col * brake_mult;
		METALLIC = 0.35;
		ROUGHNESS = 0.10;
		SPECULAR = 0.80;
	} else if (is_glass) {
		// Reflective Deep Smoked Glass Canopy
		ALBEDO = vec3(0.05, 0.07, 0.11);
		ROUGHNESS = 0.04;
		METALLIC = 0.40;
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

	# Apply Automotive Shader
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = AUTOMOTIVE_SHADER_CODE
	mat.shader = shader
	mat.set_shader_parameter("paint_color", chosen_color)
	mat.set_shader_parameter("metallic_val", 0.88)
	mat.set_shader_parameter("roughness_val", 0.16)
	_apply_material_to_meshes(body_model, mat)

	# 3. Create Wheel Hubs and Wheels
	var wheel_glb_path = def.get("wheel_glb_path", "res://assets/models/vehicles/car_wheel_racing.glb")
	var wheel_mat = ShaderMaterial.new()
	var w_shader = Shader.new()
	w_shader.code = WHEEL_SHADER_CODE
	wheel_mat.shader = w_shader

	var wheel_offsets = [
		Vector3(-0.85, 0.32, -1.25), # Front Left
		Vector3(0.85, 0.32, -1.25),  # Front Right
		Vector3(-0.88, 0.34, 1.25),  # Rear Left
		Vector3(0.88, 0.34, 1.25)    # Rear Right
	]

	var wheels: Array[Node3D] = []
	var wheel_names = ["FrontLeftWheel", "FrontRightWheel", "RearLeftWheel", "RearRightWheel"]

	for i in range(4):
		var hub = Node3D.new()
		hub.name = wheel_names[i]
		hub.position = wheel_offsets[i]
		root.add_child(hub)

		var wheel_mesh = ModelCache.get_model(wheel_glb_path)
		if not wheel_mesh:
			wheel_mesh = Node3D.new()
		wheel_mesh.name = "WheelMesh"
		# Flip right wheels to face outward correctly
		if i % 2 == 1:
			wheel_mesh.rotation_degrees.y = 180.0
		_apply_material_to_meshes(wheel_mesh, wheel_mat)
		hub.add_child(wheel_mesh)
		wheels.append(hub)

	# 4. Boost Exhaust Emitters (Dual Tailpipe Flames)
	var exhaust_left = _create_exhaust_particles(Vector3(-0.35, 0.38, 2.05), chosen_color)
	var exhaust_right = _create_exhaust_particles(Vector3(0.35, 0.38, 2.05), chosen_color)
	chassis_node.add_child(exhaust_left)
	chassis_node.add_child(exhaust_right)

	# 5. Tire Smoke Emitters (for drift & burnout)
	var smoke_left = _create_smoke_particles(Vector3(-0.88, 0.08, 1.25))
	var smoke_right = _create_smoke_particles(Vector3(0.88, 0.08, 1.25))
	root.add_child(smoke_left)
	root.add_child(smoke_right)

	# 6. Spark Emitter (scraping/landing contact)
	var sparks = _create_spark_particles()
	root.add_child(sparks)

	return {
		"root": root,
		"chassis": chassis_node,
		"body_model": body_model,
		"body_material": mat,
		"wheels": wheels,
		"exhaust_emitters": [exhaust_left, exhaust_right],
		"smoke_emitters": [smoke_left, smoke_right],
		"sparks_emitter": sparks,
		"paint_color": chosen_color
	}

static func _apply_material_to_meshes(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		var orig_mat = node.get_active_material(0)
		if orig_mat and orig_mat is StandardMaterial3D and orig_mat.albedo_texture:
			if material is ShaderMaterial:
				var cloned_mat = material.duplicate() as ShaderMaterial
				cloned_mat.set_shader_parameter("albedo_texture", orig_mat.albedo_texture)
				node.material_override = cloned_mat
			else:
				node.material_override = material
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
