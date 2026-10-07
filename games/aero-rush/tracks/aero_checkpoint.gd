class_name AeroCheckpoint
extends Area3D

## Holographic checkpoint and recovery gate for AeroRush.
## Detects vehicle traversal, provides safe respawn transforms, and visual feedback.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

signal checkpoint_passed(checkpoint_idx: int, vehicle: CharacterBody3D)

@export var checkpoint_index: int = 0
@export var is_finish_line: bool = false
@export var is_start_line: bool = false
@export var gate_width: float = 16.0
@export var gate_height: float = 8.0

var is_activated: bool = false
var mesh_arch: MeshInstance3D = null

func _ready() -> void:
	collision_layer = AeroConstants.LAYER_CHECKPOINTS
	collision_mask = AeroConstants.LAYER_PLAYER | AeroConstants.LAYER_ENEMIES

	monitoring = true
	monitorable = true

	_build_gate_shape()
	_build_visual_arch()

	body_entered.connect(_on_body_entered)

func _build_gate_shape() -> void:
	var col = CollisionShape3D.new()
	col.name = "CheckpointGateShape"
	var box = BoxShape3D.new()
	box.size = Vector3(gate_width, gate_height, 3.5)
	col.shape = box
	col.position = Vector3(0, gate_height * 0.5, 0)
	add_child(col)

func _build_visual_arch() -> void:
	mesh_arch = MeshInstance3D.new()
	mesh_arch.name = "HoloArchVisual"

	var quad = BoxMesh.new()
	quad.size = Vector3(gate_width + 1.2, 0.6, 0.6)
	mesh_arch.mesh = quad

	var mat = StandardMaterial3D.new()
	var col = Color(0.1, 0.9, 1.0) if not is_finish_line else Color(1.0, 0.85, 0.1)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 3.0
	mesh_arch.material_override = mat
	mesh_arch.position = Vector3(0, gate_height, 0)
	add_child(mesh_arch)

	# Left & Right Pylons
	for sign_x in [-1.0, 1.0]:
		var pylon = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.35
		p_cyl.bottom_radius = 0.45
		p_cyl.height = gate_height
		pylon.mesh = p_cyl
		pylon.material_override = mat
		pylon.position = Vector3(sign_x * (gate_width * 0.5 + 0.5), gate_height * 0.5, 0)
		add_child(pylon)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		var fwd = -global_basis.z.normalized()
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
		mat.emission_energy_multiplier = 6.0
		var tw = create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 3.0, 0.6)

func get_recovery_transform() -> Transform3D:
	return global_transform if is_inside_tree() else transform
