class_name AeroMovingHazard
extends AnimatableBody3D

## Dynamic kinetic obstacle: rotating energy barriers, swinging pendulums,
## and moving crushers that test precision driving and reward stunt near-misses.

const AeroConstants = preload("res://games/aero-rush/core/aero_constants.gd")

enum HazardType {
	ROTATING_BARRIER,
	OSCILLATING_CRUSHER,
	SWINGING_PENDULUM
}

@export var hazard_type: HazardType = HazardType.ROTATING_BARRIER
@export var cycle_speed: float = 2.0
@export var motion_distance: float = 6.0

var time_elapsed: float = 0.0
var initial_pos: Vector3 = Vector3.ZERO
var hazard_mesh: MeshInstance3D = null
var near_miss_area: Area3D = null

func _ready() -> void:
	collision_layer = AeroConstants.LAYER_WORLD
	collision_mask = AeroConstants.LAYER_PLAYER | AeroConstants.LAYER_ENEMIES

	initial_pos = position
	_build_hazard_shape()
	_build_near_miss_detector()

func _build_hazard_shape() -> void:
	var col = CollisionShape3D.new()
	col.name = "HazardCollisionShape"
	var box = BoxShape3D.new()
	box.size = Vector3(5.5, 1.2, 1.2)
	col.shape = box
	add_child(col)

	hazard_mesh = MeshInstance3D.new()
	hazard_mesh.name = "HazardMeshVisual"
	var mesh = BoxMesh.new()
	mesh.size = Vector3(5.5, 1.2, 1.2)
	hazard_mesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.15, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1) * 3.5
	mat.roughness = 0.3
	hazard_mesh.material_override = mat
	add_child(hazard_mesh)

func _build_near_miss_detector() -> void:
	near_miss_area = Area3D.new()
	near_miss_area.name = "NearMissSensor"
	near_miss_area.collision_layer = 0
	near_miss_area.collision_mask = AeroConstants.LAYER_PLAYER

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(8.5, 3.5, 3.5)
	col.shape = box
	near_miss_area.add_child(col)
	add_child(near_miss_area)

	near_miss_area.body_entered.connect(_on_near_miss_entered)

func _on_near_miss_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_signal("stunt_action_triggered"):
		var dist = global_position.distance_to(body.global_position)
		body.stunt_action_triggered.emit(AeroConstants.StuntType.NEAR_MISS, 250, "NEAR MISS")

func _physics_process(delta: float) -> void:
	time_elapsed += delta * cycle_speed

	match hazard_type:
		HazardType.ROTATING_BARRIER:
			rotate_y(delta * cycle_speed * 1.5)
		HazardType.OSCILLATING_CRUSHER:
			var offset = sin(time_elapsed) * motion_distance
			position = initial_pos + global_basis.x * offset
		HazardType.SWINGING_PENDULUM:
			var angle = sin(time_elapsed) * 0.75
			rotation.z = angle
