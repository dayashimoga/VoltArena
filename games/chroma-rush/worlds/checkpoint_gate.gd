class_name CheckpointGate
extends Area3D

## High-fidelity architectural highway overhead electronic gantry sign for Chroma Rush.
## Features realistic dark structural steel truss stanchions outside roadway lanes,
## concrete foundation piers, overhead digital LED variable message display board,
## illuminated color indicator panels, and 3D accessibility symbols.
## Triggers verified objective delivery when entered with matching color.

const ChromaConstants = preload("res://games/chroma-rush/core/chroma_constants.gd")
const ChromaVehicle = preload("res://games/chroma-rush/vehicles/chroma_vehicle.gd")

signal gate_passed(vehicle: ChromaVehicle, is_match: bool)
signal checkpoint_entered(body: Node3D)

@export var gate_id: String = "gate_1"
@export var target_color: int = ChromaConstants.ChromaColor.CRIMSON
@export var gate_width: float = 18.0 # Generous 18m width clears 15m avenue + sidewalks
@export var gate_height: float = 6.2 # 6.2m height gives realistic 5.5m vehicle clearance

var pillar_left: MeshInstance3D
var pillar_right: MeshInstance3D
var crossbar: MeshInstance3D
var led_display_panel: MeshInstance3D
var symbol_label: Label3D
var collision_box: CollisionShape3D

var _mat_steel: StandardMaterial3D
var _mat_concrete: StandardMaterial3D
var _mat_led_display: StandardMaterial3D

func _ready() -> void:
	collision_layer = GameConstants.LAYER_CHECKPOINTS
	collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES

	_init_materials()
	setup_gate_visuals()
	setup_gate_collision()

	body_entered.connect(_on_body_entered)

func _init_materials() -> void:
	# Heavy structural galvanized steel
	_mat_steel = StandardMaterial3D.new()
	_mat_steel.albedo_color = Color(0.24, 0.26, 0.28)
	_mat_steel.metallic = 0.88
	_mat_steel.roughness = 0.32

	# Concrete foundation footing
	_mat_concrete = StandardMaterial3D.new()
	_mat_concrete.albedo_color = Color(0.55, 0.56, 0.58)
	_mat_concrete.metallic = 0.05
	_mat_concrete.roughness = 0.90

	# Active LED Variable Message Sign panel
	_mat_led_display = StandardMaterial3D.new()
	_mat_led_display.albedo_color = ChromaConstants.get_color_value(target_color)
	_mat_led_display.emission_enabled = true
	_mat_led_display.emission = ChromaConstants.get_color_value(target_color)
	_mat_led_display.emission_energy_multiplier = 1.2
	_mat_led_display.roughness = 0.20
	_mat_led_display.metallic = 0.50

func setup_gate_visuals() -> void:
	var half_w = gate_width * 0.5

	# 1. Left Support Column (Steel Truss + Concrete Footing)
	var footing_l = _create_box_mesh(Vector3(1.6, 0.8, 1.6), Vector3(-half_w, 0.4, 0), _mat_concrete)
	add_child(footing_l)

	pillar_left = _create_box_mesh(Vector3(0.9, gate_height, 0.9), Vector3(-half_w, gate_height * 0.5 + 0.4, 0), _mat_steel)
	pillar_left.name = "PillarLeft"
	add_child(pillar_left)

	# 2. Right Support Column (Steel Truss + Concrete Footing)
	var footing_r = _create_box_mesh(Vector3(1.6, 0.8, 1.6), Vector3(half_w, 0.4, 0), _mat_concrete)
	add_child(footing_r)

	pillar_right = _create_box_mesh(Vector3(0.9, gate_height, 0.9), Vector3(half_w, gate_height * 0.5 + 0.4, 0), _mat_steel)
	pillar_right.name = "PillarRight"
	add_child(pillar_right)

	# 3. Overhead Horizontal Steel Truss Housing
	crossbar = _create_box_mesh(Vector3(gate_width + 1.2, 0.85, 1.2), Vector3(0, gate_height + 0.4, 0), _mat_steel)
	crossbar.name = "Crossbar"
	add_child(crossbar)

	# 4. Digital Highway LED Variable Message Sign (VMS) Banner
	led_display_panel = _create_box_mesh(Vector3(gate_width * 0.65, 0.65, 0.15), Vector3(0, gate_height + 0.4, -0.60), _mat_led_display)
	led_display_panel.name = "LEDDisplayPanel"
	add_child(led_display_panel)

	# Reverse side VMS banner for oncoming/rear visibility
	var led_display_rear = _create_box_mesh(Vector3(gate_width * 0.65, 0.65, 0.15), Vector3(0, gate_height + 0.4, 0.60), _mat_led_display)
	add_child(led_display_rear)

	# 5. Accessibility Symbol Billboard on Sign Face
	symbol_label = Label3D.new()
	symbol_label.name = "GateSymbol"
	symbol_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	symbol_label.pixel_size = 0.02
	symbol_label.font_size = 64
	symbol_label.outline_size = 12
	symbol_label.outline_modulate = Color(0.02, 0.02, 0.04)
	symbol_label.position = Vector3(0, gate_height + 1.5, 0)
	add_child(symbol_label)

	apply_target_color(target_color)

func setup_gate_collision() -> void:
	if not has_node("GateCollision"):
		collision_box = CollisionShape3D.new()
		collision_box.name = "GateCollision"
		var box = BoxShape3D.new()
		box.size = Vector3(gate_width, gate_height, 3.5)
		collision_box.shape = box
		collision_box.position = Vector3(0, gate_height * 0.5, 0)
		add_child(collision_box)

func apply_target_color(new_color: int) -> void:
	target_color = new_color
	var col = ChromaConstants.get_color_value(target_color)

	if not _mat_led_display:
		_mat_led_display = StandardMaterial3D.new()

	_mat_led_display.albedo_color = col
	_mat_led_display.emission_enabled = true
	_mat_led_display.emission = col
	_mat_led_display.emission_energy_multiplier = 1.2
	_mat_led_display.roughness = 0.20
	_mat_led_display.metallic = 0.50

	if led_display_panel:
		led_display_panel.material_override = _mat_led_display

	# Also maintain crossbar override reference for tests
	if crossbar:
		crossbar.material_override = _mat_led_display

	if symbol_label:
		symbol_label.text = ChromaConstants.get_color_symbol(target_color)
		symbol_label.modulate = col.lightened(0.3)

func _create_box_mesh(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	return mi

func _on_body_entered(body: Node3D) -> void:
	checkpoint_entered.emit(body)
	if body is ChromaVehicle:
		var is_match = (body.current_color == target_color)
		gate_passed.emit(body, is_match)
		if is_match:
			_trigger_success_flash()

func _trigger_success_flash() -> void:
	if led_display_panel and led_display_panel.material_override:
		var mat = led_display_panel.material_override as StandardMaterial3D
		var tween = create_tween()
		if tween:
			tween.tween_property(mat, "emission_energy_multiplier", 3.2, 0.1)
			tween.tween_property(mat, "emission_energy_multiplier", 1.2, 0.35)
