class_name PuzzleElements
extends RefCounted

## Reusable Modular Puzzle Framework for Skybound Odyssey & RoboForge Arena.
## Includes PressurePlate, PuzzleSwitch, MovableBox, PuzzleDoor, WindCurrent, and GrappleAnchor.

const InteractionAreaScript = preload("res://shared/gameplay/interaction_area.gd")

# ==============================================================================
# 1. PRESSURE PLATE
# ==============================================================================
class PressurePlate extends Area3D:
	signal state_changed(is_pressed: bool)

	var plate_mesh: Node3D
	var is_pressed: bool = false
	var pressing_bodies: Array[Node3D] = []
	var rest_y: float = 0.05
	var pressed_y: float = -0.05

	func _init() -> void:
		name = "PressurePlate"
		collision_layer = 0
		collision_mask = GameConstants.LAYER_PLAYER | GameConstants.LAYER_WORLD

	func _ready() -> void:
		# Base ring
		var base = MeshInstance3D.new()
		var cyl_base = CylinderMesh.new()
		cyl_base.top_radius = 1.4
		cyl_base.bottom_radius = 1.45
		cyl_base.height = 0.15
		base.mesh = cyl_base
		base.material_override = MaterialGenerator.get_material("ancient_stone" if MaterialGenerator._cached_materials.has("ancient_stone") else "dark_hull")
		base.position = Vector3(0, 0.075, 0)
		add_child(base)

		# Moving center disc
		plate_mesh = MeshInstance3D.new()
		var cyl_plate = CylinderMesh.new()
		cyl_plate.top_radius = 1.15
		cyl_plate.bottom_radius = 1.15
		cyl_plate.height = 0.12
		plate_mesh.mesh = cyl_plate
		plate_mesh.material_override = MaterialGenerator.get_material("neon_cyan")
		plate_mesh.position = Vector3(0, rest_y + 0.06, 0)
		add_child(plate_mesh)

		# Trigger collision
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(2.2, 0.4, 2.2)
		col.shape = box
		col.position = Vector3(0, 0.2, 0)
		add_child(col)

		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

	func _on_body_entered(body: Node3D) -> void:
		if not pressing_bodies.has(body):
			pressing_bodies.append(body)
		_evaluate_state()

	func _on_body_exited(body: Node3D) -> void:
		pressing_bodies.erase(body)
		_evaluate_state()

	func _evaluate_state() -> void:
		var should_press = pressing_bodies.size() > 0
		if should_press != is_pressed:
			is_pressed = should_press
			if is_inside_tree():
				var tween = create_tween()
				var target_y = pressed_y if is_pressed else rest_y
				tween.tween_property(plate_mesh, "position:y", target_y + 0.06, 0.15)
			state_changed.emit(is_pressed)

# ==============================================================================
# 2. PUZZLE SWITCH
# ==============================================================================
class PuzzleSwitch extends Node3D:
	signal switch_toggled(is_on: bool)

	var is_on: bool = false
	var lever_mesh: Node3D
	var area: Area3D

	func _ready() -> void:
		var base = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.6, 0.8, 0.6)
		base.mesh = b_box
		base.material_override = MaterialGenerator.get_material("sci_fi_metal")
		base.position = Vector3(0, 0.4, 0)
		add_child(base)

		lever_mesh = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.12, 0.5, 0.12)
		lever_mesh.mesh = l_box
		lever_mesh.material_override = MaterialGenerator.get_material("neon_orange")
		lever_mesh.position = Vector3(0, 0.8, 0)
		lever_mesh.rotation_degrees.z = -25.0
		add_child(lever_mesh)

		area = Area3D.new()
		area.collision_layer = 0
		area.collision_mask = GameConstants.LAYER_PLAYER
		var col = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 1.8
		col.shape = sphere
		col.position = Vector3(0, 0.8, 0)
		area.add_child(col)
		add_child(area)

		var ia = InteractionAreaScript.new()
		ia.prompt_message = "Press E to Activate Switch"
		ia.interacted.connect(func(_p): toggle())
		add_child(ia)

	func toggle() -> void:
		is_on = not is_on
		if lever_mesh and is_inside_tree():
			var tween = create_tween()
			var target_rot = 25.0 if is_on else -25.0
			tween.tween_property(lever_mesh, "rotation_degrees:z", target_rot, 0.2)
		switch_toggled.emit(is_on)

# ==============================================================================
# 3. PUZZLE DOOR / GATE
# ==============================================================================
class PuzzleDoor extends Node3D:
	@export var required_activations: int = 1
	var current_activations: int = 0
	var door_slab: AnimatableBody3D
	var is_open: bool = false
	var closed_pos: Vector3 = Vector3.ZERO
	var open_offset: Vector3 = Vector3(0, 5.0, 0)

	func _ready() -> void:
		door_slab = AnimatableBody3D.new()
		door_slab.collision_layer = GameConstants.LAYER_WORLD
		door_slab.collision_mask = 0

		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(4.0, 5.0, 0.6)
		mesh_inst.mesh = box
		mesh_inst.material_override = MaterialGenerator.get_material("dark_hull")
		mesh_inst.position = Vector3(0, 2.5, 0)
		door_slab.add_child(mesh_inst)

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(4.0, 5.0, 0.6)
		col.shape = col_box
		col.position = Vector3(0, 2.5, 0)
		door_slab.add_child(col)

		add_child(door_slab)
		closed_pos = door_slab.position

	func register_trigger(trigger_signal: Signal) -> void:
		trigger_signal.connect(func(active: bool):
			if active:
				current_activations += 1
			else:
				current_activations = maxi(0, current_activations - 1)
			_evaluate_door()
		)

	func _evaluate_door() -> void:
		var should_open = current_activations >= required_activations
		if should_open != is_open:
			is_open = should_open
			if is_inside_tree():
				var tween = create_tween()
				var target_pos = closed_pos + open_offset if is_open else closed_pos
				tween.tween_property(door_slab, "position", target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# ==============================================================================
# 4. WIND CURRENT (UPWARD DRAFT FOR GLIDER)
# ==============================================================================
class WindCurrent extends Area3D:
	@export var upward_force: float = 24.0

	func _ready() -> void:
		collision_layer = 0
		collision_mask = GameConstants.LAYER_PLAYER

		var col = CollisionShape3D.new()
		var cyl = CylinderShape3D.new()
		cyl.radius = 3.5
		cyl.height = 18.0
		col.shape = cyl
		col.position = Vector3(0, 9.0, 0)
		add_child(col)

	func _physics_process(delta: float) -> void:
		for b in get_overlapping_bodies():
			if "velocity" in b:
				# Apply upward thermal lift
				b.velocity.y = move_toward(b.velocity.y, upward_force, 35.0 * delta)

# ==============================================================================
# 5. GRAPPLE ANCHOR
# ==============================================================================
class GrappleAnchor extends Node3D:
	func _ready() -> void:
		add_to_group("grapple_anchors")
		var sphere = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 0.4
		s_mesh.height = 0.8
		sphere.mesh = s_mesh
		sphere.material_override = MaterialGenerator.get_material("neon_cyan")
		add_child(sphere)
