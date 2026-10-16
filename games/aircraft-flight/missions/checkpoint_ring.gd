class_name CheckpointRing
extends Area3D

## CheckpointRing: 3D Aerial Slalom Ring with Precision Orientation Detection.
## Detects when aircraft crosses plane and evaluates orientation (Upright, Knife-Edge, Inverted).

enum RingOrientation {
	ANY,
	UPRIGHT,
	KNIFE_EDGE, # 90 degree roll
	INVERTED    # 180 degree roll
}

@export var ring_radius: float = 35.0
@export var required_orientation: RingOrientation = RingOrientation.ANY
@export var ring_index: int = 0
@export var is_final_ring: bool = false

var is_activated: bool = false
var ring_mesh: MeshInstance3D
var ring_material: StandardMaterial3D

signal ring_passed(index: int, orientation_matched: bool, roll_deg: float)

func _ready() -> void:
	collision_layer = 32 | 128 # Layer 6 Checkpoints (Bit 5 = 32) + legacy Bit 7
	collision_mask = 2 # Layer 2 Player
	monitoring = true

	_build_ring_visuals()
	body_entered.connect(_on_body_entered)

func _build_ring_visuals() -> void:
	# Tubular ring geometry using ArrayMesh
	ring_mesh = MeshInstance3D.new()
	var major_r: float = ring_radius - 1.25
	var minor_r: float = 1.25
	ring_mesh.mesh = _create_torus_tube_mesh(major_r, minor_r, 32, 8)
	ring_mesh.rotation_degrees.x = 90.0

	ring_material = StandardMaterial3D.new()
	var ring_col = Color(0.1, 0.85, 1.0) if not is_final_ring else Color(1.0, 0.85, 0.1)
	ring_material.albedo_color = ring_col
	ring_material.emission_enabled = true
	ring_material.emission = ring_col
	ring_material.emission_energy_multiplier = 4.0
	ring_mesh.material_override = ring_material
	add_child(ring_mesh)

	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var cyl = CylinderShape3D.new()
	cyl.radius = ring_radius
	cyl.height = 8.0
	col_shape.shape = cyl
	col_shape.rotation_degrees.x = 90.0
	add_child(col_shape)

static func _create_torus_tube_mesh(major_r: float, minor_r: float, radial_seg: int = 32, tubular_seg: int = 8) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(radial_seg):
		var u0: float = float(i) / float(radial_seg) * TAU
		var u1: float = float(i + 1) / float(radial_seg) * TAU
		for j in range(tubular_seg):
			var v0: float = float(j) / float(tubular_seg) * TAU
			var v1: float = float(j + 1) / float(tubular_seg) * TAU

			var p0 = Vector3((major_r + minor_r * cos(v0)) * cos(u0), (major_r + minor_r * cos(v0)) * sin(u0), minor_r * sin(v0))
			var p1 = Vector3((major_r + minor_r * cos(v0)) * cos(u1), (major_r + minor_r * cos(v0)) * sin(u1), minor_r * sin(v0))
			var p2 = Vector3((major_r + minor_r * cos(v1)) * cos(u1), (major_r + minor_r * cos(v1)) * sin(u1), minor_r * sin(v1))
			var p3 = Vector3((major_r + minor_r * cos(v1)) * cos(u0), (major_r + minor_r * cos(v1)) * sin(u0), minor_r * sin(v1))

			var n0 = Vector3(cos(v0) * cos(u0), cos(v0) * sin(u0), sin(v0))
			var n1 = Vector3(cos(v0) * cos(u1), cos(v0) * sin(u1), sin(v0))
			var n2 = Vector3(cos(v1) * cos(u1), cos(v1) * sin(u1), sin(v1))
			var n3 = Vector3(cos(v1) * cos(u0), cos(v1) * sin(u0), sin(v1))

			st.set_normal(n0)
			st.add_vertex(p0)
			st.set_normal(n1)
			st.add_vertex(p1)
			st.set_normal(n2)
			st.add_vertex(p2)

			st.set_normal(n0)
			st.add_vertex(p0)
			st.set_normal(n2)
			st.add_vertex(p2)
			st.set_normal(n3)
			st.add_vertex(p3)
	return st.commit()

func _on_body_entered(body: Node3D) -> void:
	if is_activated:
		return

	if body is CharacterBody3D:
		is_activated = true
		var roll_deg = rad_to_deg(body.global_transform.basis.get_euler().z)
		var orientation_matched = _evaluate_orientation(roll_deg)

		# Visual celebration flash:
		ring_material.emission = Color(0.2, 1.0, 0.4) if orientation_matched else Color(1.0, 0.6, 0.1)
		ring_material.emission_energy_multiplier = 8.0

		ring_passed.emit(ring_index, orientation_matched, roll_deg)

func _evaluate_orientation(roll_deg: float) -> bool:
	var abs_roll = absf(roll_deg)
	match required_orientation:
		RingOrientation.ANY:
			return true
		RingOrientation.UPRIGHT:
			return abs_roll < 35.0
		RingOrientation.KNIFE_EDGE:
			return absf(abs_roll - 90.0) < 30.0
		RingOrientation.INVERTED:
			return abs_roll > 145.0
		_:
			return true
