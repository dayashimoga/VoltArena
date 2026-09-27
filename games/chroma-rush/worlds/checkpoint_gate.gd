class_name CheckpointGate
extends Area3D

## Interactive objective gate in Chroma Rush
## Features glowing emissive pillars, overhead crossbar, and 3D accessibility symbol.
## Triggers verified objective delivery when entered with matching color.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

signal gate_passed(vehicle: ChromaVehicle, is_match: bool)
signal checkpoint_entered(body: Node3D)

@export var gate_id: String = "gate_1"
@export var target_color: int = ChromaConstants.ChromaColor.CRIMSON
@export var gate_width: float = 12.0
@export var gate_height: float = 6.0

var pillar_left: MeshInstance3D
var pillar_right: MeshInstance3D
var crossbar: MeshInstance3D
var symbol_label: Label3D
var collision_box: CollisionShape3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_CHECKPOINTS
	collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	setup_gate_visuals()
	setup_gate_collision()

	body_entered.connect(_on_body_entered)

func setup_gate_visuals() -> void:
	# Left Pillar
	pillar_left = MeshInstance3D.new()
	pillar_left.name = "PillarLeft"
	var col_mesh = BoxMesh.new()
	col_mesh.size = Vector3(1.2, gate_height, 1.2)
	pillar_left.mesh = col_mesh
	pillar_left.position = Vector3(-gate_width * 0.5, gate_height * 0.5, 0)
	add_child(pillar_left)

	# Right Pillar
	pillar_right = MeshInstance3D.new()
	pillar_right.name = "PillarRight"
	pillar_right.mesh = col_mesh
	pillar_right.position = Vector3(gate_width * 0.5, gate_height * 0.5, 0)
	add_child(pillar_right)

	# Overhead Crossbar
	crossbar = MeshInstance3D.new()
	crossbar.name = "Crossbar"
	var bar_mesh = BoxMesh.new()
	bar_mesh.size = Vector3(gate_width + 1.2, 1.0, 1.4)
	crossbar.mesh = bar_mesh
	crossbar.position = Vector3(0, gate_height + 0.5, 0)
	add_child(crossbar)

	# Accessibility Symbol Billboard
	symbol_label = Label3D.new()
	symbol_label.name = "GateSymbol"
	symbol_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbol_label.pixel_size = 0.02
	symbol_label.font_size = 64
	symbol_label.outline_size = 12
	symbol_label.outline_modulate = Color(0.02, 0.02, 0.04)
	symbol_label.position = Vector3(0, gate_height + 1.8, 0)
	add_child(symbol_label)

	apply_target_color(target_color)

func setup_gate_collision() -> void:
	if not has_node("GateCollision"):
		collision_box = CollisionShape3D.new()
		collision_box.name = "GateCollision"
		var box = BoxShape3D.new()
		box.size = Vector3(gate_width, gate_height, 3.0)
		collision_box.shape = box
		collision_box.position = Vector3(0, gate_height * 0.5, 0)
		add_child(collision_box)

func apply_target_color(new_color: int) -> void:
	target_color = new_color
	var col = ChromaConstants.get_color_value(target_color)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 3.0
	mat.roughness = 0.15
	mat.metallic = 0.8

	if pillar_left:
		pillar_left.material_override = mat
	if pillar_right:
		pillar_right.material_override = mat
	if crossbar:
		crossbar.material_override = mat

	if symbol_label:
		symbol_label.text = ChromaConstants.get_color_symbol(target_color)
		symbol_label.modulate = col.lightened(0.3)

func _on_body_entered(body: Node3D) -> void:
	checkpoint_entered.emit(body)
	if body is ChromaVehicle:
		var is_match = (body.current_color == target_color)
		gate_passed.emit(body, is_match)
		if is_match:
			_trigger_success_flash()

func _trigger_success_flash() -> void:
	# Subtle visual bloom pulse
	if crossbar and crossbar.material_override:
		var mat = crossbar.material_override as StandardMaterial3D
		var tween = create_tween()
		if tween:
			tween.tween_property(mat, "emission_energy_multiplier", 6.0, 0.1)
			tween.tween_property(mat, "emission_energy_multiplier", 3.0, 0.35)
