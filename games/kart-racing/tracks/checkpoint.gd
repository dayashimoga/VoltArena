class_name RaceCheckpoint
extends Area3D

signal checkpoint_hit(kart: KartController, checkpoint_index: int)

@export var checkpoint_index: int = 0
@export var is_finish_line: bool = false
@export var checkpoint_width: float = 18.0

func _ready() -> void:
	collision_layer = GameConstants.LAYER_CHECKPOINTS
	collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_ENEMIES
	body_entered.connect(_on_body_entered)
	setup_trigger_volume()

func setup_trigger_volume() -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(checkpoint_width, 6.0, 3.0)
	col.shape = box
	add_child(col)

	# Finish line visual arch if finish line
	if is_finish_line:
		var arch = MeshInstance3D.new()
		var arch_mesh = BoxMesh.new()
		arch_mesh.size = Vector3(checkpoint_width, 0.8, 1.2)
		arch.mesh = arch_mesh
		arch.position = Vector3(0, 5.0, 0)
		arch.material_override = MaterialGenerator.get_material("neon_cyan")
		add_child(arch)

func _on_body_entered(body: Node3D) -> void:
	if body is KartController:
		body.last_valid_checkpoint_pos = global_position
		body.last_valid_checkpoint_rot = rotation.y
		checkpoint_hit.emit(body, checkpoint_index)
