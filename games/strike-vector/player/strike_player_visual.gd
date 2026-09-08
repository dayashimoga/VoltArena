class_name StrikePlayerVisual
extends Node3D

## Visual representation and skeletal animator for Strike Vector player operative.
## Utilizes rigged humanoid soldier 3D model with skeletal AnimationPlayer,
## dynamic weapon socket, and speed-synchronized locomotion states.

const ModelCacheScript = preload("res://shared/graphics/model_cache.gd")

var weapon_socket: Marker3D
var character_model: Node3D = null
var current_anim_state: String = "idle"
var is_sliding: bool = false
var is_crouching: bool = false

func _ready() -> void:
	build_visual()

func build_visual() -> void:
	# Clear existing children if rebuilding
	for c in get_children():
		c.queue_free()

	# 1. Instantiate authentic rigged soldier model via ModelCache
	character_model = ModelCacheScript.get_character("soldier")
	if character_model:
		character_model.name = "SoldierRig"
		character_model.rotation_degrees.y = 180.0 # Align forward with -Z
		add_child(character_model)

		# Weapon Socket attached to right hand region
		weapon_socket = Marker3D.new()
		weapon_socket.name = "WeaponSocket"
		weapon_socket.position = Vector3(0.30, 1.05, -0.32)
		add_child(weapon_socket)
	else:
		_build_fallback_rig()

func _build_fallback_rig() -> void:
	var mat_armor = MaterialGenerator.get_material("sci_fi_metal")
	var mat_suit = MaterialGenerator.get_material("dark_hull")
	var mat_visor = MaterialGenerator.get_material("neon_cyan")

	var torso = MeshInstance3D.new()
	var t_mesh = CapsuleMesh.new()
	t_mesh.radius = 0.28
	t_mesh.height = 0.85
	torso.mesh = t_mesh
	torso.material_override = mat_armor
	torso.position = Vector3(0, 1.15, 0)
	add_child(torso)

	var head = MeshInstance3D.new()
	var h_mesh = SphereMesh.new()
	h_mesh.radius = 0.20
	h_mesh.height = 0.40
	head.mesh = h_mesh
	head.material_override = mat_suit
	head.position = Vector3(0, 1.65, 0)
	add_child(head)

	var visor = MeshInstance3D.new()
	var v_mesh = BoxMesh.new()
	v_mesh.size = Vector3(0.24, 0.08, 0.12)
	visor.mesh = v_mesh
	visor.material_override = mat_visor
	visor.position = Vector3(0, 1.66, -0.16)
	add_child(visor)

	weapon_socket = Marker3D.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.position = Vector3(0.32, 1.05, -0.35)
	add_child(weapon_socket)

func update_animation(horizontal_speed: float, is_on_floor: bool, sliding: bool, crouching: bool, strafe_input: float, delta: float) -> void:
	is_sliding = sliding
	is_crouching = crouching

	# Lateral strafe banking
	rotation.z = lerpf(rotation.z, deg_to_rad(-strafe_input * 6.0), 10.0 * delta)

	# Slide / Crouch pitch modulation
	if is_sliding:
		rotation.x = lerpf(rotation.x, deg_to_rad(-20.0), 14.0 * delta)
		position.y = lerpf(position.y, -0.35, 12.0 * delta)
	elif is_crouching:
		rotation.x = lerpf(rotation.x, 0.0, 10.0 * delta)
		position.y = lerpf(position.y, -0.30, 10.0 * delta)
	else:
		rotation.x = lerpf(rotation.x, 0.0, 10.0 * delta)
		position.y = lerpf(position.y, 0.0, 10.0 * delta)

	# Skeletal Animation State resolution
	var desired_anim = "idle"
	if not is_on_floor:
		desired_anim = "aim"
	elif is_sliding:
		desired_anim = "run"
	elif horizontal_speed > 4.5:
		desired_anim = "run"
	elif horizontal_speed > 0.4:
		desired_anim = "walk"
	else:
		desired_anim = "idle"

	if desired_anim != current_anim_state and is_instance_valid(character_model):
		current_anim_state = desired_anim
		ModelCacheScript.play_animation(character_model, current_anim_state, 0.2)
