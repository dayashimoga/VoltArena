class_name StrikePlayerVisual
extends Node3D

## Visual representation and procedural animator for Strike Vector player.
## Produces an articulated cyberpunk commando with weapon sockets, visor glow, and animations.

var weapon_socket: Marker3D
var torso: MeshInstance3D
var head: MeshInstance3D
var visor: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D

var walk_cycle: float = 0.0
var is_sliding: bool = false
var is_crouching: bool = false

func _ready() -> void:
	build_visual()

func build_visual() -> void:
	# Materials
	var mat_armor = MaterialGenerator.get_material("sci_fi_metal")
	var mat_suit = MaterialGenerator.get_material("dark_hull")
	var mat_visor = MaterialGenerator.get_material("neon_cyan")

	# Torso
	torso = _add_part(self, Vector3(0.55, 0.70, 0.32), Vector3(0, 1.15, 0), mat_armor)
	torso.name = "Torso"

	# Head & Visor
	head = _add_part(torso, Vector3(0.28, 0.30, 0.28), Vector3(0, 0.50, 0), mat_armor)
	head.name = "Head"
	visor = _add_part(head, Vector3(0.24, 0.10, 0.12), Vector3(0, 0.04, -0.14), mat_visor)
	visor.name = "Visor"

	# Arms
	left_arm = _add_part(torso, Vector3(0.18, 0.55, 0.18), Vector3(-0.38, -0.05, 0), mat_suit)
	left_arm.name = "LeftArm"
	right_arm = _add_part(torso, Vector3(0.18, 0.55, 0.18), Vector3(0.38, -0.05, 0), mat_suit)
	right_arm.name = "RightArm"

	# Weapon Socket attached to right arm
	weapon_socket = Marker3D.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.position = Vector3(0.05, -0.22, -0.28)
	right_arm.add_child(weapon_socket)

	# Legs
	left_leg = _add_part(self, Vector3(0.22, 0.75, 0.22), Vector3(-0.16, 0.40, 0), mat_suit)
	left_leg.name = "LeftLeg"
	right_leg = _add_part(self, Vector3(0.22, 0.75, 0.22), Vector3(0.16, 0.40, 0), mat_suit)
	right_leg.name = "RightLeg"

func _add_part(parent: Node, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func update_animation(horizontal_speed: float, is_on_floor: bool, sliding: bool, crouching: bool, strafe_input: float, delta: float) -> void:
	is_sliding = sliding
	is_crouching = crouching

	if is_sliding:
		# Low profile slide pose
		position.y = lerpf(position.y, -0.45, 14.0 * delta)
		rotation.x = deg_to_rad(-25.0)
		if is_instance_valid(left_leg) and is_instance_valid(right_leg):
			left_leg.rotation.x = deg_to_rad(-60.0)
			right_leg.rotation.x = deg_to_rad(45.0)
		return

	# Reset slide tilt
	rotation.x = lerpf(rotation.x, 0.0, 10.0 * delta)
	if is_crouching:
		position.y = lerpf(position.y, -0.35, 10.0 * delta)
	else:
		position.y = lerpf(position.y, 0.0, 10.0 * delta)

	# Strafe tilt
	rotation.z = lerpf(rotation.z, deg_to_rad(-strafe_input * 8.0), 10.0 * delta)

	# Walk / Run leg swing
	if is_on_floor and horizontal_speed > 0.5:
		walk_cycle += delta * horizontal_speed * 1.8
		var swing = sin(walk_cycle) * 0.55
		if is_instance_valid(left_leg): left_leg.rotation.x = swing
		if is_instance_valid(right_leg): right_leg.rotation.x = -swing
		if is_instance_valid(left_arm): left_arm.rotation.x = -swing * 0.7
	else:
		if is_instance_valid(left_leg): left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, 10.0 * delta)
		if is_instance_valid(right_leg): right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, 10.0 * delta)
		if is_instance_valid(left_arm): left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, 10.0 * delta)
