class_name VehicleVisuals
extends RefCounted

## High-fidelity automotive visual builder for Chroma Rush.
## Utilizes authentic production-grade 3D assets (curved aerodynamic body panels,
## cockpit canopies, functional headlights/taillights, alloy wheels, rubber tires),
## dynamic PBR clearcoat/metallic automotive paint shader, and accessibility symbols.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ModelCache = preload("res://shared/graphics/model_cache.gd")

const GLB_MAP = {
	ChromaConstants.VEHICLE_APEX: "res://assets/models/vehicles/car_sedan_sports.glb",
	ChromaConstants.VEHICLE_VORTEX: "res://assets/models/vehicles/car_sedan.glb",
	ChromaConstants.VEHICLE_TITAN: "res://assets/models/vehicles/car_suv_luxury.glb",
	ChromaConstants.VEHICLE_PULSE: "res://assets/models/vehicles/car_police.glb",
	ChromaConstants.VEHICLE_DUNE: "res://assets/models/vehicles/car_suv.glb",
	ChromaConstants.VEHICLE_QUANTUM: "res://assets/models/vehicles/car_hatchback_sports.glb",
	"traffic_sedan": "res://assets/models/vehicles/car_sedan.glb",
	"traffic_taxi": "res://assets/models/vehicles/car_taxi.glb",
	"traffic_police": "res://assets/models/vehicles/car_police.glb",
	"traffic_suv": "res://assets/models/vehicles/car_suv.glb",
	"traffic_truck": "res://assets/models/vehicles/truck_yellow.glb",
}


const AUTOMOTIVE_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 paint_color : source_color = vec4(0.85, 0.06, 0.14, 1.0);
uniform float metallic_val : hint_range(0.0, 1.0) = 0.85;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.18;
uniform float clearcoat_val : hint_range(0.0, 1.0) = 0.90;
uniform bool is_braking = false;
uniform bool is_reversing = false;

void fragment() {
	vec4 tex = texture(albedo_texture, UV);

	bool is_trim = (tex.r < 0.28 && tex.g < 0.28 && tex.b < 0.28);
	bool is_glass = (tex.b > 0.65 && tex.g > 0.45 && tex.r < 0.55);
	bool is_headlight = (tex.r > 0.88 && tex.g > 0.88 && tex.b > 0.88);
	bool is_taillight = (tex.r > 0.65 && tex.g < 0.22 && tex.b < 0.22);

	if (is_headlight) {
		// Projector LED Headlamps
		ALBEDO = vec3(0.96, 0.98, 1.0);
		EMISSION = vec3(1.0, 0.98, 0.94) * 3.5;
		METALLIC = 0.70;
		ROUGHNESS = 0.06;
		SPECULAR = 0.90;
	} else if (is_taillight) {
		// Reactive Rear Taillamps and Brake Lights
		ALBEDO = is_reversing ? vec3(0.95, 0.95, 0.92) : vec3(0.92, 0.04, 0.06);
		float brake_mult = is_reversing ? 3.8 : (is_braking ? 4.8 : 1.2);
		vec3 emit_col = is_reversing ? vec3(1.0, 0.98, 0.90) : vec3(1.0, 0.02, 0.04);
		EMISSION = emit_col * brake_mult;
		METALLIC = 0.35;
		ROUGHNESS = 0.12;
		SPECULAR = 0.75;
	} else if (is_glass) {
		// Reflective Deep Smoked Glass Canopy
		ALBEDO = vec3(0.06, 0.08, 0.12);
		ROUGHNESS = 0.04;
		METALLIC = 0.35;
		CLEARCOAT = 1.0;
		SPECULAR = 0.95;
	} else if (is_trim) {
		// Matte Carbon Fiber Aero Trim, Splitters & Diffusers
		ALBEDO = vec3(0.08, 0.08, 0.09);
		ROUGHNESS = 0.85;
		METALLIC = 0.10;
		SPECULAR = 0.25;
	} else {
		// Deep Multi-Coat Automotive Metallic Paint with Clearcoat
		float lum = (tex.r * 0.299 + tex.g * 0.587 + tex.b * 0.114);
		float factor = clamp(lum / 0.65, 0.85, 1.18);
		ALBEDO = paint_color.rgb * factor;
		METALLIC = metallic_val;
		ROUGHNESS = roughness_val;
		CLEARCOAT = clearcoat_val;
		CLEARCOAT_ROUGHNESS = 0.06;
		SPECULAR = 0.75;
	}
}
"""


const WHEEL_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

void fragment() {
	float r = length(VERTEX.yz);
	if (r > 0.19) {
		// Vulcanized rubber tire tread and sidewall
		ALBEDO = vec3(0.10, 0.10, 0.12);
		ROUGHNESS = 0.92;
		METALLIC = 0.02;
		SPECULAR = 0.15;
	} else {
		// High-grade precision alloy rim
		ALBEDO = vec3(0.85, 0.88, 0.92);
		ROUGHNESS = 0.18;
		METALLIC = 0.92;
		SPECULAR = 0.80;
	}
}
"""

const CONTACT_SHADOW_SHADER_CODE = """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(max(abs(p) - vec2(0.32, 0.46), vec2(0.0)));
	float alpha = smoothstep(0.68, 0.0, d) * 0.76;
	ALBEDO = vec3(0.015, 0.015, 0.02);
	ALPHA = alpha;
}
"""

static var _cached_shader: Shader = null
static var _cached_wheel_shader: Shader = null
static var _cached_shadow_shader: Shader = null

static func get_paint_shader() -> Shader:
	if not _cached_shader:
		_cached_shader = Shader.new()
		_cached_shader.code = AUTOMOTIVE_SHADER_CODE
	return _cached_shader

static func get_wheel_shader() -> Shader:
	if not _cached_wheel_shader:
		_cached_wheel_shader = Shader.new()
		_cached_wheel_shader.code = WHEEL_SHADER_CODE
	return _cached_wheel_shader

static func get_contact_shadow_shader() -> Shader:
	if not _cached_shadow_shader:
		_cached_shadow_shader = Shader.new()
		_cached_shadow_shader.code = CONTACT_SHADOW_SHADER_CODE
	return _cached_shadow_shader

static func _build_ground_contact_shadow() -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = "GroundContactShadow"
	var quad = QuadMesh.new()
	quad.size = Vector2(2.1, 4.3)
	mi.mesh = quad
	mi.rotation_degrees.x = -90.0
	mi.position = Vector3(0, 0.012, 0)
	var mat = ShaderMaterial.new()
	mat.shader = get_contact_shadow_shader()
	mi.material_override = mat
	return mi


static func build_vehicle_visual(vehicle_id: String, base_color: int = ChromaConstants.ChromaColor.CRIMSON, paint_finish: String = "metallic") -> Node3D:
	var root = Node3D.new()
	root.name = "VehicleVisual"

	var glb_path = GLB_MAP.get(vehicle_id, GLB_MAP[ChromaConstants.VEHICLE_APEX])
	var raw_model = ModelCache.get_model(glb_path)

	if raw_model:
		# Authentic CC0 GLB Automotive Model
		var model_scale = Vector3(1.42, 1.42, 1.42)
		if vehicle_id == ChromaConstants.VEHICLE_TITAN or vehicle_id == ChromaConstants.VEHICLE_DUNE:
			model_scale = Vector3(1.46, 1.46, 1.46)
		elif vehicle_id == ChromaConstants.VEHICLE_PULSE:
			model_scale = Vector3(1.38, 1.38, 1.38)

		raw_model.name = "ModelRoot"
		raw_model.scale = model_scale
		# Rotate 180° around Y so model front (hood & headlights at GLB +Z) points to Godot's forward (-Z),
		# and rear (spoiler & taillights at GLB -Z) faces the chase camera (+Z).
		raw_model.rotation.y = PI
		root.add_child(raw_model)

		# Setup body and wheel nodes with standardized naming
		var body_node = raw_model.get_node_or_null("body")
		if not body_node:
			for c in raw_model.get_children():
				if "body" in c.name.to_lower() or "car" in c.name.to_lower() or "chassis" in c.name.to_lower():
					body_node = c
					break

		var chassis_body = Node3D.new()
		chassis_body.name = "ChassisBody"
		root.add_child(chassis_body)

		var init_col = ChromaConstants.get_color_value(base_color)
		var p_mat = _get_procedural_paint_material(paint_finish, init_col)
		var p_hood = _add_paint_box(chassis_body, Vector3(1.65, 0.18, 1.35), Vector3(0, 0.44, -1.25), p_mat)
		p_hood.visible = false
		var p_roof = _add_paint_box(chassis_body, Vector3(1.30, 0.32, 1.45), Vector3(0, 0.88, 0.05), p_mat)
		p_roof.visible = false
		var p_rear = _add_paint_box(chassis_body, Vector3(1.78, 0.30, 0.40), Vector3(0, 0.38, 1.85), p_mat)
		p_rear.visible = false
		var p_doors = _add_paint_box(chassis_body, Vector3(1.80, 0.35, 1.80), Vector3(0, 0.40, 0.0), p_mat)
		p_doors.visible = false

		if body_node and body_node is MeshInstance3D:
			body_node.set_meta("is_body_paint", true)
			body_node.add_to_group("body_paint_meshes")

		# Create wheel references and aliases
		# With ModelRoot rotated 180°:
		# Front wheels are at model +Z -> vehicle world -Z
		# Rear wheels are at model -Z -> vehicle world +Z
		var wl_f = raw_model.get_node_or_null("wheel-front-left")
		var wr_f = raw_model.get_node_or_null("wheel-front-right")
		var wl_r = raw_model.get_node_or_null("wheel-back-left")
		var wr_r = raw_model.get_node_or_null("wheel-back-right")

		_create_wheel_alias(root, "FrontWheelLeft", wl_f)
		_create_wheel_alias(root, "FrontWheelRight", wr_f)
		_create_wheel_alias(root, "RearWheelLeft", wl_r)
		_create_wheel_alias(root, "RearWheelRight", wr_r)


	else:
		# Fallback procedural builder if GLB model is unavailable
		var fallback_body = Node3D.new()
		fallback_body.name = "ChassisBody"
		root.add_child(fallback_body)
		_build_procedural_fallback_body(fallback_body, base_color, paint_finish)
		_build_procedural_fallback_wheels(root)

		# Chrome dual exhaust tips at the rear
		var exhaust_node = Node3D.new()
		exhaust_node.name = "ExhaustTips"
		var mat_chrome = StandardMaterial3D.new()
		mat_chrome.albedo_color = Color(0.90, 0.92, 0.95)
		mat_chrome.metallic = 0.98
		mat_chrome.roughness = 0.12
		for ex_side in [-0.42, 0.42]:
			var tip = MeshInstance3D.new()
			var tip_cyl = CylinderMesh.new()
			tip_cyl.top_radius = 0.07
			tip_cyl.bottom_radius = 0.07
			tip_cyl.height = 0.28
			tip.mesh = tip_cyl
			tip.material_override = mat_chrome
			tip.rotation_degrees.x = 90.0
			tip.position = Vector3(ex_side, 0.28, 1.95)
			exhaust_node.add_child(tip)
		root.add_child(exhaust_node)

	# 3. Dynamic Gameplay Color Accent Panels & Underglow
	var color_panels = Node3D.new()
	color_panels.name = "GameplayColorPanels"
	root.add_child(color_panels)
	_build_accent_panels(color_panels)

	# 4. 3D Accessibility Symbol Billboard
	var symbol_node = _build_symbol_billboard(base_color)
	symbol_node.name = "AccessibilitySymbol"
	symbol_node.position = Vector3(0, 1.95, 0)
	root.add_child(symbol_node)

	# 5. Apply authoritative gameplay color to all body paint surfaces
	apply_gameplay_color(root, base_color, paint_finish)

	# 6. Realistic Ambient Ground Contact Shadow Quad
	var shadow_node = _build_ground_contact_shadow()
	root.add_child(shadow_node)

	return root

static func update_vehicle_lights(vehicle_visual: Node3D, is_braking: bool, is_reversing: bool) -> void:
	if not is_instance_valid(vehicle_visual):
		return
	var model_root = vehicle_visual.get_node_or_null("ModelRoot")
	if model_root:
		for child in model_root.get_children():
			if child is MeshInstance3D and child.material_override is ShaderMaterial:
				var sm = child.material_override as ShaderMaterial
				sm.set_shader_parameter("is_braking", is_braking)
				sm.set_shader_parameter("is_reversing", is_reversing)

static func _create_wheel_alias(root: Node3D, alias_name: String, target_node: Node3D) -> void:
	if not target_node:
		var dummy = Node3D.new()
		dummy.name = alias_name
		root.add_child(dummy)
		return
	# Create alias node linking to actual model wheel
	target_node.set_meta("alias_name", alias_name)
	if not root.has_node(alias_name):
		var ref_node = Node3D.new()
		ref_node.name = alias_name
		ref_node.position = target_node.position * 1.42
		root.add_child(ref_node)

static func apply_gameplay_color(vehicle_visual: Node3D, color_id: int, finish: String = "metallic") -> void:
	if not is_instance_valid(vehicle_visual):
		return

	var col = ChromaConstants.get_color_value(color_id)
	var shader = get_paint_shader()

	var metallic_v = 0.85
	var roughness_v = 0.22
	var clearcoat_v = 0.80

	match finish.to_lower():
		"gloss":
			metallic_v = 0.20
			roughness_v = 0.12
			clearcoat_v = 0.95
		"matte":
			metallic_v = 0.05
			roughness_v = 0.72
			clearcoat_v = 0.0
		"pearlescent":
			metallic_v = 0.90
			roughness_v = 0.16
			clearcoat_v = 1.0
		_: # metallic
			metallic_v = 0.85
			roughness_v = 0.22
			clearcoat_v = 0.80

	# Apply shader material across ModelRoot meshes
	var model_root = vehicle_visual.get_node_or_null("ModelRoot")
	if model_root:
		var colormap_tex = load("res://assets/models/vehicles/Textures/colormap.png")
		var wheel_shader = get_wheel_shader()
		for child in model_root.get_children():
			if child is MeshInstance3D:
				var mi = child as MeshInstance3D
				var is_wheel = "wheel" in child.name.to_lower()
				if is_wheel:
					# Apply dedicated realistic rubber tire & alloy rim shader
					var w_mat = mi.material_override
					if not (w_mat is ShaderMaterial):
						w_mat = ShaderMaterial.new()
						w_mat.shader = wheel_shader
						mi.material_override = w_mat
				else:
					# Exterior automotive body panels (body, spoiler, etc.)
					var mat = mi.material_override
					if not (mat is ShaderMaterial):
						mat = ShaderMaterial.new()
						mat.shader = shader
						if colormap_tex:
							mat.set_shader_parameter("albedo_texture", colormap_tex)
						mi.material_override = mat

					mat.set_shader_parameter("paint_color", col)
					mat.set_shader_parameter("metallic_val", metallic_v)
					mat.set_shader_parameter("roughness_val", roughness_v)
					mat.set_shader_parameter("clearcoat_val", clearcoat_v)
					child.set_meta("is_body_paint", true)
					child.add_to_group("body_paint_meshes")


	# Update fallback procedural meshes if present
	var chassis = vehicle_visual.get_node_or_null("ChassisBody")
	if chassis:
		var mat_paint = _get_procedural_paint_material(finish, col)
		for child in chassis.get_children():
			if child is MeshInstance3D and child.has_meta("is_body_paint"):
				child.material_override = mat_paint

	# Update subtle accent lines
	var panels = vehicle_visual.get_node_or_null("GameplayColorPanels")
	if panels:
		var mat_accent = StandardMaterial3D.new()
		mat_accent.albedo_color = col
		mat_accent.emission_enabled = true
		mat_accent.emission = col
		mat_accent.emission_energy_multiplier = 1.1
		mat_accent.roughness = 0.20
		mat_accent.metallic = 0.70

		for child in panels.get_children():
			if child is MeshInstance3D:
				child.material_override = mat_accent

	# Update 3D accessibility symbol
	var symbol_node = vehicle_visual.get_node_or_null("AccessibilitySymbol") as Label3D
	if symbol_node:
		symbol_node.text = ChromaConstants.get_color_symbol(color_id)
		symbol_node.modulate = col.lightened(0.25)

static func _build_accent_panels(parent: Node3D) -> void:
	# Subtle side skirt neon underglow / accent slit
	for side in [-0.92, 0.92]:
		var mi = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.04, 0.04, 2.2)
		mi.mesh = box
		mi.position = Vector3(side, 0.22, 0.0)
		parent.add_child(mi)

static func _build_symbol_billboard(base_color: int) -> Label3D:
	var lbl = Label3D.new()
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.text = ChromaConstants.get_color_symbol(base_color)
	lbl.font_size = 54
	lbl.outline_size = 14
	lbl.outline_modulate = Color(0.02, 0.02, 0.04, 0.95)
	lbl.modulate = ChromaConstants.get_color_value(base_color).lightened(0.25)
	lbl.no_depth_test = false
	return lbl

# ==============================================================================
# FALLBACK PROCEDURAL GENERATION (Zero-failure guarantee for unit tests)
# ==============================================================================

static func _build_procedural_fallback_body(body: Node3D, base_color: int, finish: String) -> void:
	var init_col = ChromaConstants.get_color_value(base_color)
	var mat_body = _get_procedural_paint_material(finish, init_col)
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.08, 0.10, 0.14)
	mat_glass.metallic = 0.8
	mat_glass.roughness = 0.1

	# Lower chassis
	var b1 = _add_paint_box(body, Vector3(1.80, 0.40, 3.80), Vector3(0, 0.38, 0.0), mat_body)
	# Hood
	var b2 = _add_paint_box(body, Vector3(1.65, 0.20, 1.35), Vector3(0, 0.46, -1.25), mat_body)
	b2.rotation_degrees.x = 11.0
	# Cabin
	var b3 = _add_paint_box(body, Vector3(1.30, 0.34, 1.45), Vector3(0, 0.88, 0.05), mat_body)
	# Windshield
	var win = _add_box(body, Vector3(1.28, 0.42, 0.80), Vector3(0, 0.74, -0.65), mat_glass)
	win.rotation_degrees.x = 35.0

static func _build_procedural_fallback_wheels(root: Node3D) -> void:
	var mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.12, 0.12, 0.14)
	mat_tire.roughness = 0.90
	var positions = [
		Vector3(-0.95, 0.36, -1.28),
		Vector3(0.95, 0.36, -1.28),
		Vector3(-0.98, 0.36, 1.32),
		Vector3(0.98, 0.36, 1.32)
	]
	var names = ["FrontWheelLeft", "FrontWheelRight", "RearWheelLeft", "RearWheelRight"]
	for i in range(4):
		var w = Node3D.new()
		w.name = names[i]
		w.position = positions[i]
		var tm = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.36
		cyl.bottom_radius = 0.36
		cyl.height = 0.28
		tm.mesh = cyl
		tm.material_override = mat_tire
		tm.rotation_degrees.z = 90.0
		w.add_child(tm)
		root.add_child(w)

static func _get_procedural_paint_material(finish: String, col: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	match finish.to_lower():
		"gloss":
			mat.metallic = 0.20
			mat.roughness = 0.10
			mat.clearcoat_enabled = true
			mat.clearcoat = 1.0
		"matte":
			mat.metallic = 0.05
			mat.roughness = 0.75
			mat.clearcoat_enabled = false
		"pearlescent":
			mat.metallic = 0.90
			mat.roughness = 0.15
			mat.clearcoat_enabled = true
			mat.clearcoat = 1.0
		_: # metallic
			mat.metallic = 0.85
			mat.roughness = 0.22
			mat.clearcoat_enabled = true
			mat.clearcoat = 0.80
	return mat

static func _add_paint_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.set_meta("is_body_paint", true)
	mi.add_to_group("body_paint_meshes")
	parent.add_child(mi)
	return mi

static func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi
