class_name AeroCheckpoint
extends Area3D

## Holographic checkpoint and race gantry for AeroRush: Impossible Circuit.
## Detects vehicle traversal, provides safe respawn transforms, and visual feedback.
## Features dedicated professional start/finish gantries with countdown signal clusters
## and slender, wide holographic gates that never block the player's chase camera view.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

signal checkpoint_passed(checkpoint_idx: int, vehicle: CharacterBody3D)

@export var checkpoint_index: int = 0
@export var is_finish_line: bool = false
@export var is_start_line: bool = false
@export var gate_width: float = 24.0
@export var gate_height: float = 8.5

var is_activated: bool = false
var mesh_arch: MeshInstance3D = null
var signal_lights: Array[MeshInstance3D] = []

func _ready() -> void:
	collision_layer = AeroConstants.LAYER_CHECKPOINTS
	collision_mask = AeroConstants.LAYER_PLAYER | AeroConstants.LAYER_ENEMIES

	monitoring = true
	monitorable = true

	if is_start_line:
		gate_width = 32.0
		gate_height = 11.5
	elif is_finish_line:
		gate_width = 28.0
		gate_height = 10.0

	_build_gate_shape()
	_build_visual_arch()

	body_entered.connect(_on_body_entered)

func _build_gate_shape() -> void:
	var col = CollisionShape3D.new()
	col.name = "CheckpointGateShape"
	var box = BoxShape3D.new()
	box.size = Vector3(gate_width, gate_height, 4.0)
	col.shape = box
	col.position = Vector3(0, gate_height * 0.5, 0)
	add_child(col)

func _build_visual_arch() -> void:
	if is_start_line:
		_build_start_gantry()
	else:
		_build_holographic_gate()

func _build_start_gantry() -> void:
	# 1. Structural Carbon-Steel Overhead Gantry Beam
	var gantry_beam = MeshInstance3D.new()
	gantry_beam.name = "StartGantryBeam"
	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(gate_width + 1.0, 1.2, 1.4)
	gantry_beam.mesh = beam_mesh

	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.14, 0.16, 0.20)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.35
	gantry_beam.material_override = steel_mat
	gantry_beam.position = Vector3(0, gate_height, 0)
	add_child(gantry_beam)

	# 2. Glowing Digital Gantry Banner
	var banner = MeshInstance3D.new()
	banner.name = "StartBanner"
	var banner_mesh = BoxMesh.new()
	banner_mesh.size = Vector3(18.0, 0.7, 0.08)
	banner.mesh = banner_mesh
	var banner_mat = StandardMaterial3D.new()
	banner_mat.albedo_color = Color(0.08, 0.85, 1.0)
	banner_mat.emission_enabled = true
	banner_mat.emission = Color(0.08, 0.85, 1.0) * 2.2
	banner.material_override = banner_mat
	banner.position = Vector3(0, gate_height + 0.1, -0.72)
	add_child(banner)

	# 3. Overhead Race Countdown Signal Lamps (5 cluster lights)
	for i in range(5):
		var lamp = MeshInstance3D.new()
		lamp.name = "StartLamp_%d" % i
		var lamp_mesh = CylinderMesh.new()
		lamp_mesh.top_radius = 0.32
		lamp_mesh.bottom_radius = 0.32
		lamp_mesh.height = 0.25
		lamp.mesh = lamp_mesh
		lamp.rotation_degrees.x = 90.0

		var lamp_mat = StandardMaterial3D.new()
		lamp_mat.albedo_color = Color(0.95, 0.15, 0.10)
		lamp_mat.emission_enabled = true
		lamp_mat.emission = Color(0.95, 0.15, 0.10) * 2.5
		lamp.material_override = lamp_mat

		var offset_x = -3.2 + float(i) * 1.6
		lamp.position = Vector3(offset_x, gate_height - 0.9, -0.65)
		add_child(lamp)
		signal_lights.append(lamp)

	# 4. Wide Lateral Support Pylons (placed well clear at X = +-16.5m)
	for sign_x in [-1.0, 1.0]:
		var pylon = MeshInstance3D.new()
		pylon.name = "GantryPylon_%s" % ("L" if sign_x < 0 else "R")
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(1.1, gate_height, 1.1)
		pylon.mesh = p_mesh
		pylon.material_override = steel_mat
		pylon.position = Vector3(sign_x * (gate_width * 0.5), gate_height * 0.5, 0)
		add_child(pylon)

		# Vertical Cyan Accent Strip
		var strip = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.08, gate_height * 0.95, 0.12)
		strip.mesh = s_mesh
		var strip_mat = StandardMaterial3D.new()
		strip_mat.albedo_color = Color(0.05, 0.85, 1.0)
		strip_mat.emission_enabled = true
		strip_mat.emission = Color(0.05, 0.85, 1.0) * 1.8
		strip.material_override = strip_mat
		strip.position = Vector3(sign_x * (gate_width * 0.5 - 0.58), gate_height * 0.5, 0)
		add_child(strip)

	# 5. Checkered Starting Line Deck Ribbon with Procedural Pattern
	var line_mesh = MeshInstance3D.new()
	line_mesh.name = "CheckeredStartLine"
	var quad = BoxMesh.new()
	quad.size = Vector3(16.0, 0.02, 2.0)
	line_mesh.mesh = quad

	var check_shader = Shader.new()
	check_shader.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

void fragment() {
	vec2 uv_scaled = UV * vec2(16.0, 3.0);
	vec2 check_grid = floor(uv_scaled);
	float check = mod(check_grid.x + check_grid.y, 2.0);
	vec3 col = (check > 0.5) ? vec3(0.96, 0.96, 0.98) : vec3(0.08, 0.09, 0.11);
	ALBEDO = col;
	ROUGHNESS = 0.55;
	METALLIC = 0.08;
}
"""
	var check_mat = ShaderMaterial.new()
	check_mat.shader = check_shader
	line_mesh.material_override = check_mat
	line_mesh.position = Vector3(0, 0.02, 0)
	add_child(line_mesh)

func _build_holographic_gate() -> void:
	# Holographic Checkpoint Arch
	mesh_arch = MeshInstance3D.new()
	mesh_arch.name = "HoloArchVisual"

	var arch_box = BoxMesh.new()
	arch_box.size = Vector3(gate_width, 0.45, 0.45)
	mesh_arch.mesh = arch_box

	var holo_col = Color(1.0, 0.82, 0.12) if is_finish_line else Color(0.08, 0.88, 1.0)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(holo_col.r, holo_col.g, holo_col.b, 0.65)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = holo_col * 2.2
	mat.roughness = 0.2
	mesh_arch.material_override = mat
	mesh_arch.position = Vector3(0, gate_height, 0)
	add_child(mesh_arch)

	# Slender Side holographic pylons at wide stance (outside track)
	for sign_x in [-1.0, 1.0]:
		var pylon = MeshInstance3D.new()
		pylon.name = "HoloPylon_%s" % ("L" if sign_x < 0 else "R")
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.18
		p_cyl.bottom_radius = 0.24
		p_cyl.height = gate_height
		pylon.mesh = p_cyl
		pylon.material_override = mat
		pylon.position = Vector3(sign_x * (gate_width * 0.5), gate_height * 0.5, 0)
		add_child(pylon)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		var cp_pos = global_position if is_inside_tree() else position
		var cp_basis = global_basis if is_inside_tree() else transform.basis
		if body.has_method("update_checkpoint"):
			body.update_checkpoint(cp_pos, cp_basis)

		if not is_activated:
			is_activated = true
			_pulse_visual()

		checkpoint_passed.emit(checkpoint_index, body)

func _pulse_visual() -> void:
	if mesh_arch and mesh_arch.material_override is StandardMaterial3D:
		var mat = mesh_arch.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 4.5
		var tw = create_tween()
		if tw:
			tw.tween_property(mat, "emission_energy_multiplier", 2.2, 0.5)

func get_recovery_transform() -> Transform3D:
	return global_transform if is_inside_tree() else transform
